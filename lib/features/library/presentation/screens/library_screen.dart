import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/library/presentation/screens/liked_songs_screen.dart';
import 'package:paatufy/features/library/presentation/screens/user_playlist_screen.dart';
import 'package:paatufy/features/search/presentation/screens/entity_detail_screen.dart';
import 'package:paatufy/models/song.dart';
import 'package:paatufy/models/user_playlist.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

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
            hintText: 'My Playlist #1',
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
                final playlist = await HiveService.createUserPlaylist(name);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserPlaylistScreen(playlistId: playlist.id)),
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28, color: AppTheme.textPrimary),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        children: [
          // 1. Liked Songs Tile with Live Counter
          ValueListenableBuilder<Box<Song>>(
            valueListenable: HiveService.getLikedSongs().listenable(),
            builder: (context, Box<Song> box, _) {
              final likedCount = box.length;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryPurple, AppTheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                ),
                title: const Text('Liked Songs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('$likedCount songs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedSongsScreen()));
                },
              );
            },
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // 2. Custom User Playlists (Created by User)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Playlists', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                label: const Text('New', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<Box<String>>(
            valueListenable: HiveService.getUserPlaylists().listenable(),
            builder: (context, box, _) {
              final playlists = HiveService.getUserPlaylistsList();
              if (playlists.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.playlist_add_rounded, size: 40, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        const Text('Create your first playlist', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: playlists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserPlaylistScreen(playlistId: playlist.id),
                        ),
                      ),
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: playlist.artworkUrl != null
                                  ? CachedNetworkImage(imageUrl: playlist.artworkUrl!, width: 120, height: 120, fit: BoxFit.cover)
                                  : Container(
                                      width: 120,
                                      height: 120,
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF5B4BDB), AppTheme.primary],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 44),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('${playlist.songs.length} Songs', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // 3. Saved Albums
          const Text('Saved Albums', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: HiveService.getSavedAlbums().listenable(),
            builder: (context, box, _) {
              final savedAlbums = HiveService.getSavedAlbumsList();
              if (savedAlbums.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No saved albums yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                );
              }
              return SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: savedAlbums.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final album = savedAlbums[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EntityDetailScreen(
                            id: album.id,
                            title: album.title,
                            subtitle: album.artist,
                            artworkUrl: album.artworkUrl,
                            type: DetailType.album,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: album.artworkUrl != null
                                  ? CachedNetworkImage(imageUrl: album.artworkUrl!, width: 120, height: 120, fit: BoxFit.cover)
                                  : Container(width: 120, height: 120, color: AppTheme.surfaceElevated),
                            ),
                            const SizedBox(height: 6),
                            Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // 4. Saved Online Playlists
          const Text('Saved Playlists', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: HiveService.getSavedPlaylists().listenable(),
            builder: (context, box, _) {
              final savedPlaylists = HiveService.getSavedPlaylistsList();
              if (savedPlaylists.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No saved playlists yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                );
              }
              return SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: savedPlaylists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final playlist = savedPlaylists[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EntityDetailScreen(
                            id: playlist.id,
                            title: playlist.title,
                            subtitle: playlist.subtitle,
                            artworkUrl: playlist.artworkUrl,
                            type: DetailType.playlist,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: playlist.artworkUrl != null
                                  ? CachedNetworkImage(imageUrl: playlist.artworkUrl!, width: 120, height: 120, fit: BoxFit.cover)
                                  : Container(width: 120, height: 120, color: AppTheme.surfaceElevated),
                            ),
                            const SizedBox(height: 6),
                            Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('${playlist.trackCount} Tracks', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}