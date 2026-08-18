import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/library/data/spotify_importer_service.dart';
import 'package:paatufy/features/library/presentation/screens/user_playlist_screen.dart';
import 'package:paatufy/features/search/presentation/screens/search_screen.dart';
import 'package:paatufy/models/song.dart';

class SpotifyImportModal extends ConsumerStatefulWidget {
  const SpotifyImportModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SpotifyImportModal(),
    );
  }

  @override
  ConsumerState<SpotifyImportModal> createState() => _SpotifyImportModalState();
}

class _SpotifyImportModalState extends ConsumerState<SpotifyImportModal> {
  final TextEditingController _urlController = TextEditingController();
  bool _isImporting = false;
  String _statusMessage = '';
  double _progress = 0.0;
  int _totalCount = 0;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _urlController.text = data!.text!.trim();
      });
    }
  }

  Future<void> _startImport() async {
    final input = _urlController.text.trim();
    if (input.isEmpty) return;

    final provider = ref.read(jioSaavnProviderInstance);
    final importer = SpotifyImporterService(provider);
    final playlistId = importer.extractPlaylistId(input);

    if (playlistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Spotify playlist link'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _statusMessage = 'Fetching Spotify playlist info...';
      _progress = 0.05;
    });

    final playlistData = await importer.fetchSpotifyPlaylist(playlistId);

    if (playlistData == null || playlistData.tracks.isEmpty) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to parse Spotify tracks. Ensure the playlist is public.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    _totalCount = playlistData.tracks.length;
    final List<Song> resolvedSongs = [];

    for (int i = 0; i < playlistData.tracks.length; i++) {
      final spotifyTrack = playlistData.tracks[i];

      setState(() {
        _statusMessage = 'Matching: ${spotifyTrack.title} (${i + 1}/$_totalCount)';
        _progress = (i + 1) / _totalCount;
      });

      final matchedSong = await importer.matchAndResolveTrack(spotifyTrack);
      if (matchedSong != null) {
        resolvedSongs.add(matchedSong);
      }

      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (resolvedSongs.isEmpty) {
      setState(() {
        _isImporting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not match tracks from this playlist.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final userPlaylist = await HiveService.createUserPlaylist(
      playlistData.title,
      description: 'Imported from Spotify • Ad-Free Playback',
      artworkUrl: playlistData.coverUrl,
      isSpotifyImported: true,
      songs: resolvedSongs,
    );

    if (mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserPlaylistScreen(playlistId: userPlaylist.id),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${resolvedSongs.length} tracks from Spotify!'),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.watch(audioHandlerProvider);
    final hasActiveMiniPlayer = audioHandler.mediaItem.value != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Provide 90px clearance for the MiniPlayer when keyboard is closed
    final bottomPadding = bottomInset > 0
        ? bottomInset + 20
        : (hasActiveMiniPlayer ? 90.0 : 24.0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.download_rounded, color: Color(0xFF22C55E), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Import Spotify Playlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Paste any public Spotify playlist link. Tracks will be converted to high-quality, continuous playback with zero ads.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            enabled: !_isImporting,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'https://open.spotify.com/playlist/...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, color: Color(0xFF22C55E), size: 20),
                onPressed: _pasteFromClipboard,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isImporting) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppTheme.surface,
                color: const Color(0xFF22C55E),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _statusMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isImporting ? null : _startImport,
              child: _isImporting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Convert & Import Playlist',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}