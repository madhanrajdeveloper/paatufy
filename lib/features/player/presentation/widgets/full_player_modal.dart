import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/player/presentation/widgets/equalizer_visualizer.dart';
import 'package:paatufy/features/player/presentation/widgets/queue_modal.dart';
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
                        const Text(
                          'PLAYING FROM PLAYLIST',
                          style: TextStyle(
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
                    onPressed: () {
                      final currentSong = audioHandler.currentSong;
                      final songToOption = currentSong != null
                          ? currentSong.copyWith()
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
                      SongOptionsModal.show(context, songToOption, audioHandler);
                    },
                  ),
                ],
              ),

              // 2. Artwork Canvas
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  height: MediaQuery.of(context).size.width * 0.82,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.55),
                        blurRadius: 28,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: mediaItem.artUri != null
                        ? CachedNetworkImage(
                            imageUrl: mediaItem.artUri.toString(),
                            width: MediaQuery.of(context).size.width * 0.82,
                            height: MediaQuery.of(context).size.width * 0.82,
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

              // 3. Track Info, Equalizer & Like Action
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
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            EqualizerVisualizer(isPlaying: isPlaying, size: 16),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mediaItem.artist ?? 'Various Artists',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
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
                ],
              ),

              // 4. Progress Bar & Timestamps
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: Colors.white.withOpacity(0.12),
                      thumbColor: Colors.white,
                      overlayColor: AppTheme.primary.withOpacity(0.2),
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
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                        Text(
                          _formatDuration(totalDuration),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
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
                      color: isShuffle ? AppTheme.primary : AppTheme.textSecondary,
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
                          color: Colors.black,
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
                      color: loopMode != LoopMode.off ? AppTheme.primary : AppTheme.textSecondary,
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
                      backgroundColor: sleepTimer != null ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: sleepTimer != null ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    label: Text(
                      sleepTimer != null ? _formatSleepClock(sleepTimer) : 'Timer',
                      style: TextStyle(
                        color: sleepTimer != null ? AppTheme.primary : AppTheme.textSecondary,
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