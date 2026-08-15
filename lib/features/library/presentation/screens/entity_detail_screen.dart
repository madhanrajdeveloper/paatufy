import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/search/presentation/screens/search_screen.dart';
import 'package:paatufy/models/song.dart';

enum DetailType { album, playlist, artist }

class EntityDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final String title;
  final String? subtitle;
  final String? artworkUrl;
  final DetailType type;

  const EntityDetailScreen({
    super.key,
    required this.id,
    required this.title,
    this.subtitle,
    this.artworkUrl,
    required this.type,
  });

  @override
  ConsumerState<EntityDetailScreen> createState() => _EntityDetailScreenState();
}

class _EntityDetailScreenState extends ConsumerState<EntityDetailScreen> {
  List<Song> _tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTracks();
  }

  Future<void> _fetchTracks() async {
    final provider = ref.read(jioSaavnProviderInstance);
    List<Song> songs = [];
    if (widget.type == DetailType.album) {
      songs = await provider.getAlbumSongs(widget.id);
    } else if (widget.type == DetailType.playlist) {
      songs = await provider.getPlaylistSongs(widget.id);
    } else {
      songs = await provider.getArtistTopSongs(widget.id);
    }

    if (mounted) {
      setState(() {
        _tracks = songs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.read(audioHandlerProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.surfaceElevated,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.artworkUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.artworkUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: AppTheme.surface),
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
                        Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        if (widget.subtitle != null)
                          Text(widget.subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        Text('${_tracks.length} Tracks', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary,
                    child: IconButton(
                      icon: const Icon(LucideIcons.play, color: Colors.black, size: 26),
                      onPressed: () {
                        if (_tracks.isNotEmpty) audioHandler.playSong(_tracks.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (_tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No tracks available', style: TextStyle(color: AppTheme.textSecondary))),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _tracks[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Text('${index + 1}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.play, color: AppTheme.textPrimary, size: 18),
                      onPressed: () => audioHandler.playSong(song),
                    ),
                    onTap: () => audioHandler.playSong(song),
                  );
                },
                childCount: _tracks.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}