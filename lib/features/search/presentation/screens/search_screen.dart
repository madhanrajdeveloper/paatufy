import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/core/widgets/shimmer_loading.dart';
import 'package:paatufy/features/audio/data/audio_handler.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/player/presentation/widgets/equalizer_visualizer.dart';
import 'package:paatufy/features/player/presentation/widgets/song_options_modal.dart';
import 'package:paatufy/features/search/data/jiosaavn_provider.dart';
import 'package:paatufy/features/search/presentation/screens/entity_detail_screen.dart';
import 'package:paatufy/models/search_result.dart';
import 'package:paatufy/models/song.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchFilterProvider = StateProvider<String>((ref) => 'All');
final jioSaavnProviderInstance = Provider((ref) => JioSaavnProvider(Dio()));

final searchResultsProvider = FutureProvider.autoDispose<UniversalSearchResult>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) {
    return UniversalSearchResult(songs: [], artists: [], albums: [], playlists: []);
  }

  final provider = ref.watch(jioSaavnProviderInstance);
  return await provider.searchAll(query);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  final List<String> _filters = ['All', 'Songs', 'Artists', 'Albums', 'Playlists'];

  final List<Map<String, dynamic>> _browseGenres = [
    {'title': 'Tamil Hits', 'color': const Color(0xFFE91E63), 'icon': Icons.music_note_rounded},
    {'title': 'Pop Beats', 'color': const Color(0xFF8E24AA), 'icon': Icons.headphones_rounded},
    {'title': 'Hip-Hop', 'color': const Color(0xFFFB8C00), 'icon': Icons.graphic_eq_rounded},
    {'title': 'Bollywood', 'color': const Color(0xFFD84315), 'icon': Icons.stars_rounded},
    {'title': 'Chill & Acoustic', 'color': const Color(0xFF1E88E5), 'icon': Icons.spa_rounded},
    {'title': 'Workout Beat', 'color': const Color(0xFF283593), 'icon': Icons.fitness_center_rounded},
    {'title': 'Indie India', 'color': const Color(0xFF43A047), 'icon': Icons.radio_rounded},
    {'title': 'Devotional', 'color': const Color(0xFF6D4C41), 'icon': Icons.self_improvement_rounded},
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();

    if (val.trim().isEmpty) {
      ref.read(searchQueryProvider.notifier).state = '';
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        ref.read(searchQueryProvider.notifier).state = val.trim();
      });
    }
    setState(() {});
  }

  void _executeSearch(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) return;

    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: query.length));
    ref.read(searchQueryProvider.notifier).state = query.trim();
    _focusNode.unfocus();
  }

  void _onPlaySong(Song song, PaatufyAudioHandler handler) {
    HiveService.addRecentSearchItem(
      id: song.id,
      type: 'song',
      title: song.title,
      subtitle: song.artist,
      artworkUrl: song.artworkUrl,
      streamUrl: song.streamUrl,
      providerId: song.providerId,
      durationSeconds: song.durationSeconds,
    );
    handler.playSong(song);
  }

  void _onOpenAlbum(AlbumSummary album) {
    HiveService.addRecentSearchItem(
      id: album.id,
      type: 'album',
      title: album.title,
      subtitle: album.artist,
      artworkUrl: album.artworkUrl,
    );
    Navigator.push(
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
    );
  }

  void _onOpenPlaylist(PlaylistSummary playlist) {
    HiveService.addRecentSearchItem(
      id: playlist.id,
      type: 'playlist',
      title: playlist.title,
      subtitle: playlist.subtitle ?? 'Playlist',
      artworkUrl: playlist.artworkUrl,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntityDetailScreen(
          id: playlist.id,
          title: playlist.title,
          subtitle: playlist.subtitle ?? 'Playlist',
          artworkUrl: playlist.artworkUrl,
          type: DetailType.playlist,
        ),
      ),
    );
  }

  void _onOpenArtist(ArtistSummary artist) {
    HiveService.addRecentSearchItem(
      id: artist.id,
      type: 'artist',
      title: artist.name,
      subtitle: 'Artist',
      artworkUrl: artist.artworkUrl,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntityDetailScreen(
          id: artist.id,
          title: artist.name,
          subtitle: 'Artist',
          artworkUrl: artist.artworkUrl,
          type: DetailType.artist,
        ),
      ),
    );
  }

  void _onTapRecentItem(Map<String, dynamic> item, PaatufyAudioHandler handler) {
    final type = item['type'] ?? 'song';

    if (type == 'album') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntityDetailScreen(
            id: item['id'],
            title: item['title'],
            subtitle: item['subtitle'],
            artworkUrl: item['artworkUrl'],
            type: DetailType.album,
          ),
        ),
      );
    } else if (type == 'playlist') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntityDetailScreen(
            id: item['id'],
            title: item['title'],
            subtitle: item['subtitle'],
            artworkUrl: item['artworkUrl'],
            type: DetailType.playlist,
          ),
        ),
      );
    } else if (type == 'artist') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntityDetailScreen(
            id: item['id'],
            title: item['title'],
            subtitle: 'Artist',
            artworkUrl: item['artworkUrl'],
            type: DetailType.artist,
          ),
        ),
      );
    } else {
      final song = Song(
        id: item['id'],
        provider: item['id'].toString().startsWith('audius_') ? 'Audius' : 'JioSaavn',
        providerId: item['providerId'] ?? item['id'].toString().replaceAll('saavn_', '').replaceAll('audius_', ''),
        title: item['title'] ?? 'Unknown Track',
        artist: item['subtitle'] ?? 'Various Artists',
        artworkUrl: item['artworkUrl'],
        durationSeconds: item['durationSeconds'] ?? 0,
        streamUrl: item['streamUrl'],
      );
      handler.playSong(song);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final filter = ref.watch(searchFilterProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final audioHandler = ref.read(audioHandlerProvider);
    final activeMediaItem = ref.watch(currentSongProvider).value ?? audioHandler.mediaItem.value;
    final isPlaying = ref.watch(isPlayingProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E242B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  cursorColor: AppTheme.primary,
                  decoration: InputDecoration(
                    hintText: 'Search songs, albums, artists...',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: _executeSearch,
                ),
              ),
            ),

            // 2. Filter Pills Selector
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = _filters[index];
                  final isSelected = filter == f;

                  return GestureDetector(
                    onTap: () => ref.read(searchFilterProvider.notifier).state = f,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : const Color(0xFF181E24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected && f != 'All') ...[
                            const Icon(Icons.check_rounded, color: Colors.black, size: 15),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            f,
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // 3. Main Content Area
            Expanded(
              child: query.isEmpty
                  ? _buildBrowseView(audioHandler)
                  : searchResults.when(
                      data: (data) => _buildResultsList(data, filter, audioHandler, activeMediaItem, isPlaying),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: SongListSkeleton(itemCount: 8),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Search failed: $err',
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseView(PaatufyAudioHandler audioHandler) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
      children: [
        // Recent Searches
        ValueListenableBuilder<Box<String>>(
          valueListenable: HiveService.getRecentSearches().listenable(),
          builder: (context, box, _) {
            final recentSearches = HiveService.getRecentSearchItems();
            if (recentSearches.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Searches',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () => HiveService.clearRecentSearches(),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentSearches.length,
                  itemBuilder: (context, index) {
                    final item = recentSearches[index];
                    final isArtist = item['type'] == 'artist';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 2),
                      leading: isArtist
                          ? CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.surfaceElevated,
                              backgroundImage: item['artworkUrl'] != null
                                  ? CachedNetworkImageProvider(item['artworkUrl'])
                                  : null,
                              child: item['artworkUrl'] == null
                                  ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary)
                                  : null,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: item['artworkUrl'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: item['artworkUrl'],
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 48,
                                        height: 48,
                                        color: AppTheme.surfaceElevated,
                                        child: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: AppTheme.surfaceElevated,
                                      child: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                                    ),
                            ),
                      title: Text(
                        item['title'] ?? 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                      ),
                      subtitle: Text(
                        '${(item['type'] ?? 'song').toString().toUpperCase()} • ${item['subtitle'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                        onPressed: () => HiveService.removeRecentSearchItem(item['id']),
                      ),
                      onTap: () => _onTapRecentItem(item, audioHandler),
                    );
                  },
                ),
                const SizedBox(height: 18),
              ],
            );
          },
        ),

        // Browse All Genres
        Text(
          'Browse All',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.65,
          ),
          itemCount: _browseGenres.length,
          itemBuilder: (context, index) {
            final genre = _browseGenres[index];
            return GestureDetector(
              onTap: () => _executeSearch(genre['title']),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: genre['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Text(
                      genre['title'],
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Transform.rotate(
                        angle: 0.28,
                        child: Icon(genre['icon'], size: 48, color: Colors.black.withOpacity(0.24)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultsList(
    UniversalSearchResult data,
    String filter,
    PaatufyAudioHandler audioHandler,
    dynamic activeMediaItem,
    bool isPlaying,
  ) {
    if (data.songs.isEmpty && data.albums.isEmpty && data.artists.isEmpty && data.playlists.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
      );
    }

    if (filter == 'Songs') {
      return ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
        itemCount: data.songs.length,
        itemBuilder: (context, index) => _buildSongTile(data.songs[index], audioHandler, activeMediaItem, isPlaying),
      );
    }

    if (filter == 'Albums') {
      return _buildAlbumsGrid(data.albums);
    }

    if (filter == 'Artists') {
      return _buildArtistsGrid(data.artists);
    }

    if (filter == 'Playlists') {
      return _buildPlaylistsGrid(data.playlists);
    }

    // Default 'All' Filter
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
      children: [
        if (data.songs.isNotEmpty) ...[
          Text('Songs', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          ...data.songs.take(4).map((song) => _buildSongTile(song, audioHandler, activeMediaItem, isPlaying)),
          const SizedBox(height: 20),
        ],
        if (data.albums.isNotEmpty) ...[
          Text('Albums', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.albums.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => SizedBox(
                width: 130,
                child: _buildAlbumCard(data.albums[index]),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (data.playlists.isNotEmpty) ...[
          Text('Playlists', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          SizedBox(
            height: 195,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => SizedBox(
                width: 130,
                child: _buildPlaylistCard(data.playlists[index]),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (data.artists.isNotEmpty) ...[
          Text('Artists', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) => SizedBox(
                width: 85,
                child: _buildArtistCard(data.artists[index]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSongTile(
    Song song,
    PaatufyAudioHandler audioHandler,
    dynamic activeMediaItem,
    bool isPlaying,
  ) {
    final isCurrent = activeMediaItem?.id == song.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: song.artworkUrl != null
            ? CachedNetworkImage(
                imageUrl: song.artworkUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppTheme.surfaceElevated,
                  child: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                color: AppTheme.surfaceElevated,
                child: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
              ),
      ),
      title: Row(
        children: [
          if (isCurrent && isPlaying) ...[
            const EqualizerVisualizer(isPlaying: true, size: 14),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: isCurrent ? AppTheme.primary : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        'Song • ${song.artist}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 20),
        onPressed: () => SongOptionsModal.show(context, song, audioHandler),
      ),
      onTap: () => _onPlaySong(song, audioHandler),
    );
  }

  Widget _buildAlbumsGrid(List<AlbumSummary> albums) {
    if (albums.isEmpty) {
      return Center(
        child: Text('No albums found', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.74,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) => _buildAlbumCard(albums[index]),
    );
  }

  Widget _buildPlaylistsGrid(List<PlaylistSummary> playlists) {
    if (playlists.isEmpty) {
      return Center(
        child: Text('No playlists found', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.74,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) => _buildPlaylistCard(playlists[index]),
    );
  }

  Widget _buildArtistsGrid(List<ArtistSummary> artists) {
    if (artists.isEmpty) {
      return Center(
        child: Text('No artists found', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) => _buildArtistCard(artists[index]),
    );
  }

  Widget _buildAlbumCard(AlbumSummary album) {
    return GestureDetector(
      onTap: () => _onOpenAlbum(album),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.artworkUrl != null && album.artworkUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: album.artworkUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surfaceElevated,
                        child: const Icon(Icons.album_rounded, color: AppTheme.textSecondary, size: 36),
                      ),
                    )
                  : Container(
                      color: AppTheme.surfaceElevated,
                      child: const Icon(Icons.album_rounded, color: AppTheme.textSecondary, size: 36),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            'Album • ${album.artist}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(PlaylistSummary playlist) {
    return GestureDetector(
      onTap: () => _onOpenPlaylist(playlist),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: playlist.artworkUrl != null && playlist.artworkUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: playlist.artworkUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surfaceElevated,
                        child: const Icon(Icons.playlist_play_rounded, color: AppTheme.textSecondary, size: 36),
                      ),
                    )
                  : Container(
                      color: AppTheme.surfaceElevated,
                      child: const Icon(Icons.playlist_play_rounded, color: AppTheme.textSecondary, size: 36),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            playlist.subtitle ?? 'Playlist',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(ArtistSummary artist) {
    return GestureDetector(
      onTap: () => _onOpenArtist(artist),
      child: Column(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: AppTheme.surfaceElevated,
            backgroundImage: artist.artworkUrl != null && artist.artworkUrl!.isNotEmpty
                ? CachedNetworkImageProvider(artist.artworkUrl!)
                : null,
            child: artist.artworkUrl == null || artist.artworkUrl!.isEmpty
                ? const Icon(Icons.person_rounded, size: 36, color: AppTheme.textSecondary)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            artist.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            'Artist',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}