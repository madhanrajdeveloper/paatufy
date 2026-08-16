import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/player/presentation/widgets/song_options_modal.dart';
import 'package:paatufy/models/song.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  String _formatTotalDuration(List<Song> songs) {
    final totalSeconds = songs.fold<int>(0, (sum, song) => sum + song.durationSeconds);
    if (totalSeconds <= 0) return '';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}'.trim();
    } else if (minutes > 0) {
      return '$minutes min ${seconds > 0 ? '$seconds sec' : ''}'.trim();
    } else {
      return '$seconds sec';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final currentSong = ref.watch(currentSongProvider).value;
    final isPlaying = ref.watch(isPlayingProvider);
    final isShuffle = ref.watch(shuffleStateProvider).value ?? audioHandler.isShuffle;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ValueListenableBuilder<Box<Song>>(
        valueListenable: HiveService.getLikedSongs().listenable(),
        builder: (context, Box<Song> box, _) {
          final likedSongs = box.values.toList().reversed.toList();
          final bool isThisListPlaying = likedSongs.any((s) => s.id == currentSong?.id);
          final bool isCurrentlyPlaying = isThisListPlaying && isPlaying;
          final String durationString = _formatTotalDuration(likedSongs);

          return CustomScrollView(
            slivers: [
              // Gradient Header
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppTheme.surfaceElevated,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Liked Songs',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4A148C), Color(0xFF22C55E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.favorite_rounded, color: Colors.white, size: 80),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppTheme.background.withOpacity(0.95)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Track Counter, Total Duration, Shuffle & Play Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Liked Songs',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              durationString.isNotEmpty
                                  ? '${likedSongs.length} Songs • $durationString'
                                  : '${likedSongs.length} Songs',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      // Shuffle Button
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: isShuffle ? const Color(0xFF22C55E) : AppTheme.textSecondary,
                          size: 26,
                        ),
                        onPressed: () {
                          if (likedSongs.isNotEmpty) {
                            final randomIndex = Random().nextInt(likedSongs.length);
                            if (!isShuffle) audioHandler.toggleShuffle();
                            audioHandler.playQueue(likedSongs, initialIndex: randomIndex);
                          }
                        },
                      ),
                      const SizedBox(width: 8),

                      // Play/Pause Button
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF22C55E),
                        child: IconButton(
                          icon: Icon(
                            isCurrentlyPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 32,
                          ),
                          onPressed: () {
                            if (likedSongs.isEmpty) return;
                            if (isCurrentlyPlaying) {
                              audioHandler.pause();
                            } else if (isThisListPlaying) {
                              audioHandler.play();
                            } else {
                              audioHandler.playQueue(likedSongs, initialIndex: 0);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Liked Songs List
              if (likedSongs.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'No liked songs yet',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = likedSongs[index];
                      final isCurrentTrack = currentSong?.id == song.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: song.artworkUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: song.artworkUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: AppTheme.surfaceElevated,
                                  child: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                                ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrentTrack ? const Color(0xFF22C55E) : AppTheme.textPrimary,
                            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_rounded, color: Color(0xFF22C55E), size: 22),
                              onPressed: () => HiveService.toggleLikeSong(song),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 20),
                              onPressed: () => SongOptionsModal.show(context, song, audioHandler),
                            ),
                            IconButton(
                              icon: Icon(
                                (isCurrentTrack && isPlaying) ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                                color: isCurrentTrack ? const Color(0xFF22C55E) : AppTheme.textSecondary,
                                size: 24,
                              ),
                              onPressed: () => audioHandler.playQueue(likedSongs, initialIndex: index),
                            ),
                          ],
                        ),
                        onTap: () => audioHandler.playQueue(likedSongs, initialIndex: index),
                      );
                    },
                    childCount: likedSongs.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          );
        },
      ),
    );
  }
}