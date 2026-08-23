import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/data/audio_handler.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/player/data/lyrics_service.dart';
import 'package:paatufy/models/lyric_line.dart';
import 'package:paatufy/models/song.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class RealtimeLyricsView extends ConsumerStatefulWidget {
  final Song song;

  const RealtimeLyricsView({super.key, required this.song});

  @override
  ConsumerState<RealtimeLyricsView> createState() => _RealtimeLyricsViewState();
}

class _RealtimeLyricsViewState extends ConsumerState<RealtimeLyricsView> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener = ItemPositionsListener.create();

  int _currentLineIndex = -1;

  int _findCurrentIndex(List<LyricLine> lyrics, Duration currentPos) {
    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (currentPos >= lyrics[i].timestamp) {
        return i;
      }
    }
    return 0;
  }

  void _scrollToIndex(int index) {
    if (_scrollController.isAttached && index >= 0) {
      _scrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        alignment: 0.35,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(songLyricsProvider(widget.song));
    final audioHandler = ref.watch(audioHandlerProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final position = ref.watch(playerPositionStreamProvider).value ?? Duration.zero;

    return lyricsAsync.when(
      data: (lyrics) {
        if (lyrics.isEmpty) {
          return _LyricsFallbackVisualizer(isPlaying: isPlaying);
        }

        final targetIndex = _findCurrentIndex(lyrics, position);

        if (targetIndex != _currentLineIndex) {
          _currentLineIndex = targetIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToIndex(_currentLineIndex);
          });
        }

        return ScrollablePositionedList.builder(
          itemScrollController: _scrollController,
          itemPositionsListener: _positionsListener,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          itemCount: lyrics.length,
          itemBuilder: (context, index) {
            final line = lyrics[index];
            final isCurrent = index == _currentLineIndex;
            final isPast = index < _currentLineIndex;

            // Spotify-style animated 3-dot rhythm indicator for musical interludes
            if (line.isInstrumental) {
              final interludeElapsed = (position - line.timestamp).inMilliseconds;
              final progress = line.duration.inMilliseconds > 0
                  ? (interludeElapsed / line.duration.inMilliseconds).clamp(0.0, 1.0)
                  : 0.0;

              return _SpotifyBeatInterlude(
                isCurrent: isCurrent,
                isPast: isPast,
                isPlaying: isPlaying,
                progress: progress,
                onTap: () => audioHandler.seek(line.timestamp),
              );
            }

            return GestureDetector(
              onTap: () => audioHandler.seek(line.timestamp),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  line.text,
                  style: GoogleFonts.poppins(
                    fontSize: isCurrent ? 24 : 18,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: isCurrent
                        ? AppTheme.textPrimary
                        : (isPast
                            ? AppTheme.primaryPurple.withValues(alpha: 0.85)
                            : AppTheme.textMuted.withValues(alpha: 0.35)),
                    height: 1.35,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryPurple),
      ),
      error: (_, __) => _LyricsFallbackVisualizer(isPlaying: isPlaying),
    );
  }
}

/// Exact Spotify 3-Dot Musical Interlude Component
class _SpotifyBeatInterlude extends StatefulWidget {
  final bool isCurrent;
  final bool isPast;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTap;

  const _SpotifyBeatInterlude({
    required this.isCurrent,
    required this.isPast,
    required this.isPlaying,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_SpotifyBeatInterlude> createState() => _SpotifyBeatInterludeState();
}

class _SpotifyBeatInterludeState extends State<_SpotifyBeatInterlude>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying && widget.isCurrent) _waveController.repeat();
  }

  @override
  void didUpdateWidget(covariant _SpotifyBeatInterlude oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && widget.isCurrent) {
      if (!_waveController.isAnimating) _waveController.repeat();
    } else {
      if (_waveController.isAnimating) _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            final t = _waveController.value;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0, t),
                const SizedBox(width: 8),
                _buildDot(1, t),
                const SizedBox(width: 8),
                _buildDot(2, t),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDot(int index, double animValue) {
    double scale = 1.0;
    double opacity = 0.35;

    if (widget.isCurrent) {
      // Offset wave animation across the 3 dots
      final phase = (animValue * 2 * pi) - (index * 0.9);
      final wave = (sin(phase) + 1.0) / 2.0; // 0.0 -> 1.0
      scale = 1.0 + (wave * 0.45);
      opacity = 0.55 + (wave * 0.45);
    } else if (widget.isPast) {
      opacity = 0.75;
    }

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isCurrent
              ? AppTheme.textPrimary.withValues(alpha: opacity)
              : (widget.isPast
                  ? AppTheme.primaryPurple.withValues(alpha: 0.75)
                  : AppTheme.textMuted.withValues(alpha: 0.30)),
          boxShadow: widget.isCurrent
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.5 * opacity),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// Fallback visualizer when no lyrics exist for the entire track
class _LyricsFallbackVisualizer extends StatefulWidget {
  final bool isPlaying;

  const _LyricsFallbackVisualizer({required this.isPlaying});

  @override
  State<_LyricsFallbackVisualizer> createState() => _LyricsFallbackVisualizerState();
}

class _LyricsFallbackVisualizerState extends State<_LyricsFallbackVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isPlaying) _animController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LyricsFallbackVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    } else if (!widget.isPlaying && _animController.isAnimating) {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGlow,
            ),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final t = _animController.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar(18 + (t * 22)),
                    const SizedBox(width: 5),
                    _buildBar(36 - (t * 24)),
                    const SizedBox(width: 5),
                    _buildBar(14 + (t * 30)),
                    const SizedBox(width: 5),
                    _buildBar(42 - (t * 20)),
                    const SizedBox(width: 5),
                    _buildBar(22 + (t * 18)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Lyrics Not Available',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enjoying the track beats',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 4.5,
      height: height.clamp(8.0, 48.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}