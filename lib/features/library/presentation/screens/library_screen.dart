import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/library/presentation/screens/liked_songs_screen.dart';
import 'package:paatufy/features/library/presentation/screens/user_playlist_screen.dart';
import 'package:paatufy/features/library/presentation/widgets/playlist_collage_cover.dart';
import 'package:paatufy/features/library/presentation/widgets/spotify_import_modal.dart';
import 'package:paatufy/features/search/presentation/screens/entity_detail_screen.dart';
import 'package:paatufy/models/search_result.dart';
import 'package:paatufy/models/song.dart';
import 'package:paatufy/models/user_playlist.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
            hintText: 'My Playlist Name',
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
                final playlist = await HiveService.createUserPlaylist(controller.text);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Your Library', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
            tooltip: 'Import from Spotify',
            onPressed: () => SpotifyImportModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.textPrimary, size: 28),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Liked Songs Tile
          ValueListenableBuilder<Box<Song>>(
            valueListenable: HiveService.getLikedSongs().listenable(),
            builder: (context, box, _) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A148C), AppTheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                ),
                title: const Text('Liked Songs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text('Playlist • ${box.length} songs', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedSongsScreen())),
              );
            },
          ),
          const SizedBox(height: 8),

          // 2. Custom User Playlists & Spotify Imports
          ValueListenableBuilder<Box<String>>(
            valueListenable: HiveService.getUserPlaylists().listenable(),
            builder: (context, box, _) {
              final userPlaylists = HiveService.getUserPlaylistsList();
              return Column(
                children: userPlaylists.map((playlist) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Stack(
                      children: [
                        PlaylistCollageCover(
                          playlist: playlist,
                          width: 56,
                          height: 56,
                          borderRadius: 6,
                        ),
                        if (playlist.isSpotifyImported)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.download_done_rounded, color: AppTheme.primary, size: 12),
                            ),
                          ),
                      ],
                    ),
                    title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Row(
                      children: [
                        if (playlist.isSpotifyImported) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'Spotify',
                              style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            'Playlist • ${playlist.songs.length} songs',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserPlaylistScreen(playlistId: playlist.id)),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // 3. Saved Albums
          ValueListenableBuilder<Box<String>>(
            valueListenable: HiveService.getSavedAlbums().listenable(),
            builder: (context, box, _) {
              final albums = HiveService.getSavedAlbumsList();
              return Column(
                children: albums.map((album) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: album.artworkUrl != null
                          ? CachedNetworkImage(imageUrl: album.artworkUrl!, width: 56, height: 56, fit: BoxFit.cover)
                          : Container(width: 56, height: 56, color: AppTheme.surfaceElevated),
                    ),
                    title: Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('Album • ${album.artist}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                  );
                }).toList(),
              );
            },
          ),

          // 4. Saved Playlists
          ValueListenableBuilder<Box<String>>(
            valueListenable: HiveService.getSavedPlaylists().listenable(),
            builder: (context, box, _) {
              final playlists = HiveService.getSavedPlaylistsList();
              return Column(
                children: playlists.map((playlist) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: playlist.artworkUrl != null
                          ? CachedNetworkImage(imageUrl: playlist.artworkUrl!, width: 56, height: 56, fit: BoxFit.cover)
                          : Container(width: 56, height: 56, color: AppTheme.surfaceElevated),
                    ),
                    title: Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('Playlist • ${playlist.trackCount} tracks', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}