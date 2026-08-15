import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/data/audio_handler.dart';
import 'package:paatufy/features/player/presentation/widgets/add_to_playlist_modal.dart';
import 'package:paatufy/features/player/presentation/widgets/sleep_timer_modal.dart';
import 'package:paatufy/models/song.dart';

class SongOptionsModal extends StatelessWidget {
  final Song song;
  final PaatufyAudioHandler audioHandler;

  const SongOptionsModal({
    super.key,
    required this.song,
    required this.audioHandler,
  });

  static void show(BuildContext context, Song song, PaatufyAudioHandler audioHandler) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SongOptionsModal(song: song, audioHandler: audioHandler),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: song.artworkUrl != null
                        ? CachedNetworkImage(imageUrl: song.artworkUrl!, width: 50, height: 50, fit: BoxFit.cover)
                        : Container(width: 50, height: 50, color: AppTheme.surface),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.divider, height: 20),

            // Live Reactive Liked Item
            ValueListenableBuilder<Box<Song>>(
              valueListenable: HiveService.getLikedSongs().listenable(),
              builder: (context, Box<Song> box, _) {
                final isLiked = box.containsKey(song.id);

                return ListTile(
                  leading: Icon(
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isLiked ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                  title: Text(
                    isLiked ? 'Remove from Liked Songs' : 'Like',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () async {
                    await HiveService.toggleLikeSong(song);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),

            // Add to Playlist Action
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: AppTheme.textPrimary),
              title: const Text('Add to playlist', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                AddToPlaylistModal.show(context, song);
              },
            ),

            ListTile(
              leading: const Icon(Icons.playlist_play_rounded, color: AppTheme.textPrimary),
              title: const Text('Play next', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                audioHandler.playNext(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playing next'), duration: Duration(seconds: 1)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.queue_music_rounded, color: AppTheme.textPrimary),
              title: const Text('Add to queue', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                audioHandler.addToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to queue'), duration: Duration(seconds: 1)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.timer_outlined, color: AppTheme.textPrimary),
              title: const Text('Sleep timer', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                SleepTimerModal.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}