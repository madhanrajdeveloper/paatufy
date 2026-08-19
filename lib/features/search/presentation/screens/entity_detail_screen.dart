import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/core/widgets/shimmer_loading.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/player/presentation/widgets/equalizer_visualizer.dart';
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
    try {
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
    } catch (_) {}

    if (mounted) {
      setState(() {
        _tracks = songs;
        _loading = false;
      });
    }
  }

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
    final String durationString = _formatTotalDuration(_tracks);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
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
                  if (widget.artworkUrl != null && widget.artworkUrl!.isNotEmpty)
                    CachedNetworkImage(imageUrl: widget.artworkUrl!, fit: BoxFit.cover)
                  else
                    Container(color: AppTheme.surface),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.background.withOpacity(0.4),
                          AppTheme.background.withOpacity(0.95),
                          AppTheme.background,
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
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
                        const SizedBox(height: 2),
                        Text(
                          _loading
                              ? 'Loading tracks...'
                              : durationString.isNotEmpty
                                  ? '${_tracks.length} Tracks • $durationString'
                                  : '${_tracks.length} Tracks',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
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
                            color: isSaved ? AppTheme.primary : AppTheme.textSecondary,
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
                            color: isSaved ? AppTheme.primary : AppTheme.textSecondary,
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

                  // Shuffle Button
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: isShuffle ? AppTheme.primary : AppTheme.textSecondary,
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
                    backgroundColor: AppTheme.primary,
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
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: SongListSkeleton(itemCount: 10),
              ),
            )
          else if (_tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No tracks available',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
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
                        leading: SizedBox(
                          width: 24,
                          child: isCurrentPlaying && isPlaying
                              ? const EqualizerVisualizer(isPlaying: true, size: 14)
                              : Text(
                                  '${index + 1}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isCurrentPlaying ? AppTheme.primary : AppTheme.textSecondary,
                                    fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrentPlaying ? AppTheme.primary : AppTheme.textPrimary,
                            fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (isLiked) ...[
                              const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 12),
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
                                (isCurrentPlaying && isPlaying) ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: isCurrentPlaying ? AppTheme.primary : AppTheme.textSecondary,
                                size: 24,
                              ),
                              onPressed: () {
                                if (isCurrentPlaying && isPlaying) {
                                  audioHandler.pause();
                                } else {
                                  _onPlayTrack(_tracks, index);
                                }
                              },
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
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}