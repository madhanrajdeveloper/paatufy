import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/library/presentation/widgets/playlist_collage_cover.dart';
import 'package:paatufy/features/player/presentation/widgets/song_options_modal.dart';
import 'package:paatufy/models/song.dart';
import 'package:paatufy/models/user_playlist.dart';

class UserPlaylistScreen extends ConsumerWidget {
  final String playlistId;

  const UserPlaylistScreen({super.key, required this.playlistId});

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

  void _showDeletePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Delete Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await HiveService.deleteUserPlaylist(playlistId);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final currentSong = ref.watch(currentSongProvider).value;
    final isPlaying = ref.watch(isPlayingProvider);
    final isShuffle = ref.watch(shuffleStateProvider).value ?? audioHandler.isShuffle;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ValueListenableBuilder<Box<String>>(
        valueListenable: HiveService.getUserPlaylists().listenable(),
        builder: (context, Box<String> box, _) {
          final raw = box.get(playlistId);
          if (raw == null) {
            return const Center(child: Text('Playlist not found', style: TextStyle(color: AppTheme.textSecondary)));
          }

          final playlist = UserPlaylist.fromJson(raw);
          final tracks = playlist.songs;
          final bool isThisListPlaying = tracks.any((s) => s.id == currentSong?.id);
          final bool isCurrentlyPlaying = isThisListPlaying && isPlaying;
          final String durationString = _formatTotalDuration(tracks);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppTheme.surfaceElevated,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textPrimary),
                    onPressed: () => _showDeletePlaylistDialog(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlaylistCollageCover(
                        playlist: playlist,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 0,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    playlist.name,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (playlist.isSpotifyImported) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.primary, width: 0.5),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.download_done_rounded, size: 12, color: AppTheme.primary),
                                        SizedBox(width: 3),
                                        Text(
                                          'Spotify Import',
                                          style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              durationString.isNotEmpty
                                  ? '${tracks.length} Songs • $durationString'
                                  : '${tracks.length} Songs',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: isShuffle ? AppTheme.primary : AppTheme.textSecondary,
                          size: 26,
                        ),
                        onPressed: () {
                          if (tracks.isNotEmpty) {
                            final randomIndex = Random().nextInt(tracks.length);
                            if (!isShuffle) audioHandler.toggleShuffle();
                            audioHandler.playQueue(tracks, initialIndex: randomIndex);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primary,
                        child: IconButton(
                          icon: Icon(
                            isCurrentlyPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 32,
                          ),
                          onPressed: () {
                            if (tracks.isEmpty) return;
                            if (isCurrentlyPlaying) {
                              audioHandler.pause();
                            } else if (isThisListPlaying) {
                              audioHandler.play();
                            } else {
                              audioHandler.playQueue(tracks, initialIndex: 0);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (tracks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off_rounded, size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 16),
                        Text('No songs added yet', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = tracks[index];
                      final isCurrentTrack = currentSong?.id == song.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: song.artworkUrl != null
                              ? CachedNetworkImage(imageUrl: song.artworkUrl!, width: 48, height: 48, fit: BoxFit.cover)
                              : Container(width: 48, height: 48, color: AppTheme.surfaceElevated),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrentTrack ? AppTheme.primary : AppTheme.textPrimary,
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
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.textSecondary, size: 20),
                              onPressed: () => HiveService.removeSongFromUserPlaylist(playlistId, song.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 20),
                              onPressed: () => SongOptionsModal.show(context, song, audioHandler),
                            ),
                            IconButton(
                              icon: Icon(
                                (isCurrentTrack && isPlaying) ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                                color: isCurrentTrack ? AppTheme.primary : AppTheme.textSecondary,
                                size: 24,
                              ),
                              onPressed: () => audioHandler.playQueue(tracks, initialIndex: index),
                            ),
                          ],
                        ),
                        onTap: () => audioHandler.playQueue(tracks, initialIndex: index),
                      );
                    },
                    childCount: tracks.length,
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