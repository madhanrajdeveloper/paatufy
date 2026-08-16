import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/player/presentation/widgets/song_options_modal.dart';
import 'package:paatufy/features/search/presentation/screens/search_screen.dart';
import 'package:paatufy/models/search_result.dart';
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
      songs = await provider.getArtistTopSongs(widget.id, artistName: widget.title);
    }

    songs = songs.map((s) {
      if (s.artist.trim().isEmpty || s.artist == 'Unknown Artist') {
        return Song(
          id: s.id,
          provider: s.provider,
          providerId: s.providerId,
          title: s.title,
          artist: widget.subtitle ?? widget.title,
          album: widget.title,
          artworkUrl: s.artworkUrl ?? widget.artworkUrl,
          durationSeconds: s.durationSeconds,
          streamUrl: s.streamUrl,
        );
      }
      return s;
    }).toList();

    if (mounted) {
      setState(() {
        _tracks = songs;
        _loading = false;
      });
    }
  }

  void _onPlayTrack(List<Song> queue, int index) {
    final audioHandler = ref.read(audioHandlerProvider);

    if (widget.type == DetailType.album || widget.type == DetailType.playlist) {
      HiveService.addRecentlyPlayedItem(
        id: widget.id,
        type: widget.type.name,
        title: widget.title,
        subtitle: widget.subtitle ?? widget.title,
        artworkUrl: widget.artworkUrl,
      );
    }

    audioHandler.playQueue(queue, initialIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = ref.read(audioHandlerProvider);
    final currentSong = ref.watch(currentSongProvider).value;
    final isPlaying = ref.watch(isPlayingProvider);
    final isShuffle = ref.watch(shuffleStateProvider).value ?? audioHandler.isShuffle;

    final bool isThisListPlaying = _tracks.any((s) => s.id == currentSong?.id);
    final bool isCurrentlyPlaying = isThisListPlaying && isPlaying;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.surfaceElevated,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
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
                    CachedNetworkImage(imageUrl: widget.artworkUrl!, fit: BoxFit.cover)
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
                  if (widget.type == DetailType.album)
                    ValueListenableBuilder(
                      valueListenable: HiveService.getSavedAlbums().listenable(),
                      builder: (context, box, _) {
                        final isSaved = HiveService.isAlbumSaved(widget.id);
                        return IconButton(
                          icon: Icon(
                            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isSaved ? const Color(0xFF22C55E) : AppTheme.textSecondary,
                            size: 28,
                          ),
                          onPressed: () {
                            HiveService.toggleSaveAlbum(
                              AlbumSummary(
                                id: widget.id,
                                title: widget.title,
                                artist: widget.subtitle ?? 'Various Artists',
                                artworkUrl: widget.artworkUrl,
                                provider: 'JioSaavn',
                              ),
                            );
                          },
                        );
                      },
                    )
                  else if (widget.type == DetailType.playlist)
                    ValueListenableBuilder(
                      valueListenable: HiveService.getSavedPlaylists().listenable(),
                      builder: (context, box, _) {
                        final isSaved = HiveService.isPlaylistSaved(widget.id);
                        return IconButton(
                          icon: Icon(
                            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isSaved ? const Color(0xFF22C55E) : AppTheme.textSecondary,
                            size: 28,
                          ),
                          onPressed: () {
                            HiveService.toggleSavePlaylist(
                              PlaylistSummary(
                                id: widget.id,
                                title: widget.title,
                                subtitle: widget.subtitle,
                                artworkUrl: widget.artworkUrl,
                                trackCount: _tracks.length,
                                provider: 'JioSaavn',
                              ),
                            );
                          },
                        );
                      },
                    ),

                  // Shuffle Button: Starts from a random song and enables shuffle
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: isShuffle ? const Color(0xFF22C55E) : AppTheme.textSecondary,
                      size: 26,
                    ),
                    onPressed: () {
                      if (_tracks.isNotEmpty) {
                        final randomIndex = Random().nextInt(_tracks.length);
                        if (!isShuffle) audioHandler.toggleShuffle();
                        _onPlayTrack(_tracks, randomIndex);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
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
                        if (_tracks.isEmpty) return;
                        if (isCurrentlyPlaying) {
                          audioHandler.pause();
                        } else if (isThisListPlaying) {
                          audioHandler.play();
                        } else {
                          _onPlayTrack(_tracks, 0);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
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
                  final isCurrentPlaying = currentSong?.id == song.id;

                  return ValueListenableBuilder<Box<Song>>(
                    valueListenable: HiveService.getLikedSongs().listenable(),
                    builder: (context, Box<Song> likedBox, _) {
                      final isLiked = likedBox.containsKey(song.id);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        leading: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrentPlaying ? const Color(0xFF22C55E) : AppTheme.textSecondary,
                            fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrentPlaying ? const Color(0xFF22C55E) : AppTheme.textPrimary,
                            fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (isLiked) ...[
                              const Icon(Icons.favorite_rounded, color: Color(0xFF22C55E), size: 12),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 20),
                              onPressed: () => SongOptionsModal.show(context, song, audioHandler),
                            ),
                            IconButton(
                              icon: Icon(
                                (isCurrentPlaying && isPlaying) ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                                color: isCurrentPlaying ? const Color(0xFF22C55E) : AppTheme.textSecondary,
                                size: 24,
                              ),
                              onPressed: () => _onPlayTrack(_tracks, index),
                            ),
                          ],
                        ),
                        onTap: () => _onPlayTrack(_tracks, index),
                      );
                    },
                  );
                },
                childCount: _tracks.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}