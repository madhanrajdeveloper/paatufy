import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/library/presentation/widgets/playlist_collage_cover.dart';
import 'package:paatufy/models/song.dart';
import 'package:paatufy/models/user_playlist.dart';

class AddToPlaylistModal extends StatelessWidget {
  final Song song;

  const AddToPlaylistModal({super.key, required this.song});

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddToPlaylistModal(song: song),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist title',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await HiveService.createUserPlaylist(
                  controller.text,
                  initialSong: song,
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to ${controller.text.trim()}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add to Playlist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // New Playlist Action
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 28),
              ),
              title: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => _showCreatePlaylistDialog(context),
            ),

            // Custom Playlists (Excluding Spotify Imported)
            ValueListenableBuilder<Box<String>>(
              valueListenable: HiveService.getUserPlaylists().listenable(),
              builder: (context, box, _) {
                // Filter out Spotify imported playlists
                final userPlaylists = HiveService.getUserPlaylistsList()
                    .where((p) => !p.isSpotifyImported)
                    .toList();

                if (userPlaylists.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No custom playlists yet. Create one above!',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: userPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = userPlaylists[index];
                      final bool alreadyInPlaylist = playlist.songs.any((s) => s.id == song.id);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: PlaylistCollageCover(
                          playlist: playlist,
                          width: 48,
                          height: 48,
                          borderRadius: 4,
                        ),
                        title: Text(
                          playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${playlist.songs.length} songs',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        trailing: alreadyInPlaylist
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22)
                            : null,
                        onTap: () async {
                          if (alreadyInPlaylist) {
                            await HiveService.removeSongFromUserPlaylist(playlist.id, song.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed from ${playlist.name}')),
                              );
                            }
                          } else {
                            await HiveService.addSongToUserPlaylist(playlist.id, song);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to ${playlist.name}')),
                              );
                            }
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}