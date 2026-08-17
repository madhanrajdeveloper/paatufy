import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/player/presentation/widgets/equalizer_visualizer.dart';
import 'package:paatufy/features/player/presentation/widgets/full_player_modal.dart';
import 'package:paatufy/models/song.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  double _dragOffsetY = 0.0;

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FullPlayerModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.watch(audioHandlerProvider);

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final mediaItem = mediaSnapshot.data;
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        final artworkUrl = mediaItem.artUri?.toString();

        return StreamBuilder<PlaybackState>(
          stream: audioHandler.playbackState,
          builder: (context, playbackSnapshot) {
            final playbackState = playbackSnapshot.data;
            final isPlaying = playbackState?.playing ?? false;

            return StreamBuilder<Duration>(
              stream: AudioService.position,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final totalDuration = mediaItem.duration ?? Duration.zero;
                final progress = (totalDuration.inMilliseconds > 0)
                    ? (position.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;

                final opacity = (1.0 - (_dragOffsetY / 80.0)).clamp(0.0, 1.0);

                return Transform.translate(
                  offset: Offset(0, _dragOffsetY),
                  child: Opacity(
                    opacity: opacity,
                    child: GestureDetector(
                      onTap: () => _openFullPlayer(context),
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta != null && details.primaryDelta! > 0) {
                          setState(() {
                            _dragOffsetY = (_dragOffsetY + details.primaryDelta!).clamp(0.0, 120.0);
                          });
                        }
                      },
                      onVerticalDragEnd: (details) {
                        if (_dragOffsetY > 30.0 || (details.primaryVelocity != null && details.primaryVelocity! > 250)) {
                          setState(() => _dragOffsetY = 0.0);
                          audioHandler.stop();
                        } else {
                          setState(() => _dragOffsetY = 0.0);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E242B),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Row(
                                children: [
                                  // Artwork Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: artworkUrl != null && artworkUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: artworkUrl,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Container(
                                              width: 44,
                                              height: 44,
                                              color: AppTheme.surfaceElevated,
                                              child: const Icon(Icons.music_note_rounded, color: Color(0xFF22C55E)),
                                            ),
                                          )
                                        : Container(
                                            width: 44,
                                            height: 44,
                                            color: AppTheme.surfaceElevated,
                                            child: const Icon(Icons.music_note_rounded, color: Color(0xFF22C55E)),
                                          ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Title & Artist Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          mediaItem.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (isPlaying) ...[
                                              EqualizerVisualizer(isPlaying: isPlaying, size: 14),
                                              const SizedBox(width: 6),
                                            ],
                                            Expanded(
                                              child: Text(
                                                mediaItem.artist ?? 'Unknown Artist',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Like Button
                                  ValueListenableBuilder<Box<Song>>(
                                    valueListenable: HiveService.getLikedSongs().listenable(),
                                    builder: (context, likedBox, _) {
                                      final isLiked = likedBox.containsKey(mediaItem.id);
                                      return IconButton(
                                        icon: Icon(
                                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          color: isLiked ? const Color(0xFF22C55E) : AppTheme.textSecondary,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          final song = Song(
                                            id: mediaItem.id,
                                            provider: mediaItem.extras?['provider'] ??
                                                (mediaItem.id.startsWith('audius_') ? 'Audius' : 'JioSaavn'),
                                            providerId: mediaItem.extras?['providerId'] ??
                                                mediaItem.id.replaceAll('saavn_', '').replaceAll('audius_', ''),
                                            title: mediaItem.title,
                                            artist: mediaItem.artist ?? 'Unknown Artist',
                                            album: mediaItem.album,
                                            artworkUrl: mediaItem.artUri?.toString(),
                                            durationSeconds: mediaItem.duration?.inSeconds ?? 0,
                                          );
                                          HiveService.toggleLikeSong(song);
                                        },
                                      );
                                    },
                                  ),

                                  // Previous Track
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 24),
                                    onPressed: () => audioHandler.skipToPrevious(),
                                  ),

                                  // Play / Pause
                                  IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      if (isPlaying) {
                                        audioHandler.pause();
                                      } else {
                                        audioHandler.play();
                                      }
                                    },
                                  ),

                                  // Next Track
                                  IconButton(
                                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
                                    onPressed: () => audioHandler.skipToNext(),
                                  ),
                                ],
                              ),
                            ),

                            // Progress Indicator
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 2.5,
                                backgroundColor: Colors.white.withOpacity(0.08),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}