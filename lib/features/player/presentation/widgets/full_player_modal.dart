import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/player/presentation/widgets/equalizer_visualizer.dart';
import 'package:paatufy/features/player/presentation/widgets/queue_modal.dart';
import 'package:paatufy/features/player/presentation/widgets/realtime_lyrics_view.dart';
import 'package:paatufy/features/player/presentation/widgets/sleep_timer_modal.dart';
import 'package:paatufy/features/player/presentation/widgets/song_options_modal.dart';
import 'package:paatufy/models/song.dart';

class FullPlayerModal extends ConsumerStatefulWidget {
  const FullPlayerModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.background,
      builder: (_) => const FullPlayerModal(),
    );
  }

  @override
  ConsumerState<FullPlayerModal> createState() => _FullPlayerModalState();
}

class _FullPlayerModalState extends ConsumerState<FullPlayerModal> {
  double? _dragPosition;
  bool _showLyrics = false;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatSleepClock(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.read(audioHandlerProvider);
    final mediaItem = ref.watch(currentSongProvider).value ?? audioHandler.mediaItem.value;
    final isPlaying = ref.watch(isPlayingProvider);

    final position = ref.watch(playerPositionStreamProvider).value ?? Duration.zero;
    final totalDuration = ref.watch(playerDurationStreamProvider).value ??
        (mediaItem?.duration ?? const Duration(seconds: 1));

    final isShuffle = ref.watch(shuffleStateProvider).value ?? audioHandler.isShuffle;
    final loopMode = ref.watch(loopModeStreamProvider).value ?? audioHandler.player.loopMode;
    final sleepTimer = ref.watch(sleepTimerRemainingProvider).value;

    final maxVal = totalDuration.inMilliseconds.toDouble();
    final currentVal = (_dragPosition != null
            ? _dragPosition!
            : position.inMilliseconds.toDouble())
        .clamp(0.0, maxVal > 0 ? maxVal : 1.0);

    if (mediaItem == null) return const SizedBox.shrink();

    final currentSong = audioHandler.currentSong ??
        Song(
          id: mediaItem.id,
          provider: mediaItem.id.startsWith('audius_') ? 'Audius' : 'JioSaavn',
          providerId: mediaItem.id.replaceAll('saavn_', '').replaceAll('audius_', ''),
          title: mediaItem.title,
          artist: mediaItem.artist ?? 'Various Artists',
          album: mediaItem.album,
          artworkUrl: mediaItem.artUri?.toString(),
          durationSeconds: mediaItem.duration?.inSeconds ?? 0,
        );

    final artworkDimension = MediaQuery.of(context).size.width * 0.78;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Top Safe Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showLyrics ? 'LYRICS' : 'PLAYING FROM PLAYLIST',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mediaItem.album ?? 'Paatufy Stream',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
                    onPressed: () => SongOptionsModal.show(context, currentSong, audioHandler),
                  ),
                ],
              ),

              // 2. Central Stage: Album Art OR Realtime Karaoke Synced Lyrics
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 320),
                    firstCurve: Curves.easeInOutCubic,
                    secondCurve: Curves.easeInOutCubic,
                    crossFadeState: _showLyrics ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    
                    // Front Canvas: Album Cover
                    firstChild: Center(
                      child: Container(
                        width: artworkDimension,
                        height: artworkDimension,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.20),
                              blurRadius: 36,
                              spreadRadius: 6,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: mediaItem.artUri != null
                              ? CachedNetworkImage(
                                  imageUrl: mediaItem.artUri.toString(),
                                  width: artworkDimension,
                                  height: artworkDimension,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppTheme.surfaceElevated,
                                    child: const Icon(Icons.music_note_rounded, size: 80, color: AppTheme.textSecondary),
                                  ),
                                )
                              : Container(
                                  color: AppTheme.surfaceElevated,
                                  child: const Icon(Icons.music_note_rounded, size: 80, color: AppTheme.textSecondary),
                                ),
                        ),
                      ),
                    ),

                    // Back Canvas: Spotify Karaoke Real-time Lyrics
                    secondChild: Container(
                      height: MediaQuery.of(context).size.height * 0.44,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.divider, width: 0.8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: RealtimeLyricsView(song: currentSong),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Track Info, Equalizer, Like Action & Lyrics Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                mediaItem.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            EqualizerVisualizer(isPlaying: isPlaying, size: 16),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          mediaItem.artist ?? 'Various Artists',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  
                  // Real-time Lyrics quick-toggle button
                  IconButton(
                    icon: Icon(
                      Icons.lyrics_rounded,
                      color: _showLyrics ? AppTheme.primaryPurple : AppTheme.textSecondary,
                      size: 26,
                    ),
                    tooltip: 'Toggle Lyrics',
                    onPressed: () {
                      setState(() => _showLyrics = !_showLyrics);
                    },
                  ),

                  // Like button
                  ValueListenableBuilder<Box<Song>>(
                    valueListenable: HiveService.getLikedSongs().listenable(),
                    builder: (context, Box<Song> likedBox, _) {
                      final isLiked = likedBox.containsKey(mediaItem.id);

                      return IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isLiked ? AppTheme.primary : AppTheme.textSecondary,
                          size: 26,
                        ),
                        onPressed: () async {
                          await HiveService.toggleLikeSong(currentSong);
                        },
                      );
                    },
                  ),
                ],
              ),

              // 4. Progress Slider & Timestamps
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                      thumbColor: Colors.white,
                      overlayColor: AppTheme.primaryGlow,
                    ),
                    child: Slider(
                      value: currentVal,
                      min: 0.0,
                      max: maxVal > 0 ? maxVal : 1.0,
                      onChanged: (val) {
                        setState(() => _dragPosition = val);
                      },
                      onChangeEnd: (val) {
                        audioHandler.seek(Duration(milliseconds: val.round()));
                        setState(() => _dragPosition = null);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(
                            _dragPosition != null
                                ? Duration(milliseconds: _dragPosition!.toInt())
                                : position,
                          ),
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        Text(
                          _formatDuration(totalDuration),
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 5. Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: isShuffle ? AppTheme.primaryPurple : AppTheme.textSecondary,
                      size: 24,
                    ),
                    onPressed: audioHandler.toggleShuffle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 36, color: AppTheme.textPrimary),
                    onPressed: audioHandler.skipToPrevious,
                  ),
                  GestureDetector(
                    onTap: isPlaying ? audioHandler.pause : audioHandler.play,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                      child: Center(
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 36, color: AppTheme.textPrimary),
                    onPressed: audioHandler.skipToNext,
                  ),
                  IconButton(
                    icon: Icon(
                      loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                      color: loopMode != LoopMode.off ? AppTheme.primaryPurple : AppTheme.textSecondary,
                      size: 24,
                    ),
                    onPressed: audioHandler.toggleRepeatMode,
                  ),
                ],
              ),

              // 6. Bottom Actions (Timer & Queue)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: sleepTimer != null ? AppTheme.primaryGlow : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: sleepTimer != null ? AppTheme.primaryPurple : AppTheme.textSecondary,
                    ),
                    label: Text(
                      sleepTimer != null ? _formatSleepClock(sleepTimer) : 'Timer',
                      style: GoogleFonts.poppins(
                        color: sleepTimer != null ? AppTheme.primaryPurple : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: sleepTimer != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onPressed: () => SleepTimerModal.show(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.queue_music_rounded, color: AppTheme.textSecondary, size: 26),
                    onPressed: () => QueueModal.show(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}