import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => AddToPlaylistModal(song: song),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Give your playlist a name',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
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
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final playlist = await HiveService.createUserPlaylist(name, initialSong: song);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added to "${playlist.name}"'), duration: const Duration(seconds: 2)),
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
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Add to Playlist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 28),
              ),
              title: const Text('New Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => _showCreatePlaylistDialog(context),
            ),
            const Divider(color: AppTheme.divider),
            Expanded(
              child: ValueListenableBuilder<Box<String>>(
                valueListenable: HiveService.getUserPlaylists().listenable(),
                builder: (context, Box<String> box, _) {
                  final playlists = HiveService.getUserPlaylistsList();

                  if (playlists.isEmpty) {
                    return const Center(
                      child: Text('No custom playlists yet', style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }

                  return ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final bool alreadyInPlaylist = playlist.songs.any((s) => s.id == song.id);

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: playlist.artworkUrl != null
                              ? CachedNetworkImage(imageUrl: playlist.artworkUrl!, width: 48, height: 48, fit: BoxFit.cover)
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: AppTheme.surface,
                                  child: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                                ),
                        ),
                        title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${playlist.songs.length} songs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        trailing: alreadyInPlaylist
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22)
                            : null,
                        onTap: () async {
                          if (alreadyInPlaylist) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Already in "${playlist.name}"'), duration: const Duration(seconds: 1)),
                            );
                          } else {
                            await HiveService.addSongToUserPlaylist(playlist.id, song);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to "${playlist.name}"'), duration: const Duration(seconds: 2)),
                              );
                            }
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}