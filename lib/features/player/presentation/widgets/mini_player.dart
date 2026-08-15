import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/player/presentation/widgets/equalizer_visualizer.dart';
import 'package:paatufy/features/player/presentation/widgets/full_player_modal.dart';
import 'package:paatufy/models/song.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(currentSongProvider).value;
    final isPlaying = ref.watch(isPlayingProvider);
    final audioHandler = ref.read(audioHandlerProvider);

    final position = ref.watch(playerPositionStreamProvider).value ?? Duration.zero;
    final totalDuration = ref.watch(playerDurationStreamProvider).value ?? const Duration(seconds: 1);
    final progress = (totalDuration.inMilliseconds > 0)
        ? (position.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    if (mediaItem == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => FullPlayerModal.show(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: mediaItem.artUri != null
                        ? CachedNetworkImage(
                            imageUrl: mediaItem.artUri.toString(),
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                          )
                        : Container(width: 42, height: 42, color: AppTheme.divider),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mediaItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Row(
                          children: [
                            if (isPlaying) ...[
                              const EqualizerVisualizer(isPlaying: true, size: 10),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                mediaItem.artist ?? 'Various Artists',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<Box<Song>>(
                    valueListenable: HiveService.getLikedSongs().listenable(),
                    builder: (context, Box<Song> likedBox, _) {
                      final isLiked = likedBox.containsKey(mediaItem.id);

                      return IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isLiked ? AppTheme.primary : AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () async {
                          final current = audioHandler.currentSong;
                          final songToSave = current != null
                              ? current.copyWith()
                              : Song(
                                  id: mediaItem.id,
                                  provider: mediaItem.id.startsWith('audius_') ? 'Audius' : 'JioSaavn',
                                  providerId: mediaItem.id.replaceAll('saavn_', '').replaceAll('audius_', ''),
                                  title: mediaItem.title,
                                  artist: mediaItem.artist ?? 'Various Artists',
                                  album: mediaItem.album,
                                  artworkUrl: mediaItem.artUri?.toString(),
                                  durationSeconds: mediaItem.duration?.inSeconds ?? 0,
                                );
                          await HiveService.toggleLikeSong(songToSave);
                        },
                      );
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.textPrimary, size: 24),
                    onPressed: audioHandler.skipToPrevious,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppTheme.textPrimary,
                      size: 28,
                    ),
                    onPressed: isPlaying ? audioHandler.pause : audioHandler.play,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.skip_next_rounded, color: AppTheme.textPrimary, size: 24),
                    onPressed: audioHandler.skipToNext,
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: AppTheme.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}