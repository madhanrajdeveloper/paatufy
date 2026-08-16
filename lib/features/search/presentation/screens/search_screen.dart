import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/data/audio_handler.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Instant Live Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search songs, albums, artists...',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textPrimary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textPrimary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: _executeSearch,
              ),
            ),

            // Main Content Area
            Expanded(
              child: query.isEmpty
                  ? _buildBrowseView(audioHandler)
                  : Column(
                      children: [
                        // Filter Chips
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: ['All', 'Songs', 'Artists', 'Albums', 'Playlists'].map((f) {
                              final isSelected = filter == f;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: isSelected,
                                  onSelected: (_) => ref.read(searchFilterProvider.notifier).state = f,
                                  selectedColor: const Color(0xFF22C55E),
                                  backgroundColor: AppTheme.surfaceElevated,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.black : AppTheme.textPrimary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Search Results
                        Expanded(
                          child: searchResults.when(
                            data: (data) => _buildResultsList(data, filter, audioHandler),
                            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
                            error: (err, _) => Center(
                              child: Text('Search failed: $err', style: const TextStyle(color: AppTheme.textSecondary)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseView(PaatufyAudioHandler audioHandler) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 4 Recent Searches (Tracks, Albums, Playlists, Artists)
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
                    const Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton(
                      onPressed: () => HiveService.clearRecentSearches(),
                      child: const Text('Clear', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                      contentPadding: EdgeInsets.zero,
                      leading: isArtist
                          ? CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.surfaceElevated,
                              backgroundImage: item['artworkUrl'] != null ? CachedNetworkImageProvider(item['artworkUrl']) : null,
                              child: item['artworkUrl'] == null ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary) : null,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: item['artworkUrl'] != null
                                  ? CachedNetworkImage(imageUrl: item['artworkUrl'], width: 48, height: 48, fit: BoxFit.cover)
                                  : Container(width: 48, height: 48, color: AppTheme.surfaceElevated),
                            ),
                      title: Text(item['title'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${(item['type'] ?? 'song').toString().toUpperCase()} • ${item['subtitle'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
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

        // Browse All Genres Grid
        const Text('Browse All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Transform.rotate(
                        angle: 0.3,
                        child: Icon(genre['icon'], size: 48, color: Colors.black.withOpacity(0.25)),
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

  Widget _buildResultsList(UniversalSearchResult data, String filter, PaatufyAudioHandler audioHandler) {
    if (data.songs.isEmpty && data.albums.isEmpty && data.artists.isEmpty && data.playlists.isEmpty) {
      return const Center(child: Text('No results found', style: TextStyle(color: AppTheme.textSecondary)));
    }

    if (filter == 'Songs') {
      return ListView.builder(
        itemCount: data.songs.length,
        itemBuilder: (context, index) => _buildSongTile(data.songs[index], audioHandler),
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

    // Default 'All' View
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (data.songs.isNotEmpty) ...[
          const Text('Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...data.songs.take(5).map((song) => _buildSongTile(song, audioHandler)),
          const SizedBox(height: 16),
        ],
        if (data.albums.isNotEmpty) ...[
          const Text('Albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.albums.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildAlbumCard(data.albums[index]),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (data.playlists.isNotEmpty) ...[
          const Text('Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildPlaylistCard(data.playlists[index]),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (data.artists.isNotEmpty) ...[
          const Text('Artists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) => _buildArtistCard(data.artists[index]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSongTile(Song song, PaatufyAudioHandler audioHandler) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: song.artworkUrl != null
            ? CachedNetworkImage(imageUrl: song.artworkUrl!, width: 48, height: 48, fit: BoxFit.cover)
            : Container(width: 48, height: 48, color: AppTheme.surfaceElevated),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
        onPressed: () => SongOptionsModal.show(context, song, audioHandler),
      ),
      onTap: () => _onPlaySong(song, audioHandler),
    );
  }

  Widget _buildAlbumsGrid(List<AlbumSummary> albums) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.8,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) => _buildAlbumCard(albums[index]),
    );
  }

  Widget _buildPlaylistsGrid(List<PlaylistSummary> playlists) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.8,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) => _buildPlaylistCard(playlists[index]),
    );
  }

  Widget _buildArtistsGrid(List<ArtistSummary> artists) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) => _buildArtistCard(artists[index]),
    );
  }

  Widget _buildAlbumCard(AlbumSummary album) {
    return GestureDetector(
      onTap: () => _onOpenAlbum(album),
      child: SizedBox(
        width: 125,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: album.artworkUrl != null
                  ? CachedNetworkImage(imageUrl: album.artworkUrl!, width: 125, height: 125, fit: BoxFit.cover)
                  : Container(width: 125, height: 125, color: AppTheme.surfaceElevated),
            ),
            const SizedBox(height: 6),
            Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(PlaylistSummary playlist) {
    return GestureDetector(
      onTap: () => _onOpenPlaylist(playlist),
      child: SizedBox(
        width: 125,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: playlist.artworkUrl != null
                  ? CachedNetworkImage(imageUrl: playlist.artworkUrl!, width: 125, height: 125, fit: BoxFit.cover)
                  : Container(width: 125, height: 125, color: AppTheme.surfaceElevated),
            ),
            const SizedBox(height: 6),
            Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${playlist.trackCount} Tracks', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(ArtistSummary artist) {
    return GestureDetector(
      onTap: () => _onOpenArtist(artist),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.surfaceElevated,
            backgroundImage: artist.artworkUrl != null ? CachedNetworkImageProvider(artist.artworkUrl!) : null,
            child: artist.artworkUrl == null ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary) : null,
          ),
          const SizedBox(height: 6),
          Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}