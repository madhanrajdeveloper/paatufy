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

final jioSaavnProviderInstance = Provider((ref) => JioSaavnProvider(Dio()));

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedFilterCategoryProvider = StateProvider<String>((ref) => 'All');

final universalSearchResultsProvider = FutureProvider.autoDispose<UniversalSearchResult>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) {
    return UniversalSearchResult(songs: [], artists: [], albums: [], playlists: []);
  }
  final provider = ref.watch(jioSaavnProviderInstance);
  return provider.searchAll(query);
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  final List<Map<String, dynamic>> _browseCategories = [
    {
      'title': 'Tamil Hits',
      'color': const Color(0xFFE91429),
      'icon': Icons.music_note_rounded,
      'image': 'https://c.saavncdn.com/editorial/Tamil-TopHits_20230526055811_500x500.jpg',
    },
    {
      'title': 'Pop Beats',
      'color': const Color(0xFF8D67AB),
      'icon': Icons.headphones_rounded,
      'image': 'https://c.saavncdn.com/editorial/PopRemix_20230307062402_500x500.jpg',
    },
    {
      'title': 'Hip-Hop',
      'color': const Color(0xFFBA5D07),
      'icon': Icons.mic_external_on_rounded,
      'image': 'https://c.saavncdn.com/editorial/DesiHipHop_20230713054133_500x500.jpg',
    },
    {
      'title': 'Bollywood',
      'color': const Color(0xFFD84000),
      'icon': Icons.movie_filter_rounded,
      'image': 'https://c.saavncdn.com/editorial/Hindi-TopHits_20230526060010_500x500.jpg',
    },
    {
      'title': 'Chill & Acoustic',
      'color': const Color(0xFF509BF5),
      'icon': Icons.spa_rounded,
      'image': 'https://c.saavncdn.com/editorial/ChillOut_20230623053351_500x500.jpg',
    },
    {
      'title': 'Workout Beat',
      'color': const Color(0xFF1E3264),
      'icon': Icons.fitness_center_rounded,
      'image': 'https://c.saavncdn.com/editorial/EDMPartyMix_20230811054707_500x500.jpg',
    },
    {
      'title': 'Indie India',
      'color': const Color(0xFF608108),
      'icon': Icons.album_rounded,
      'image': 'https://c.saavncdn.com/editorial/IndieIndia_20230825062534_500x500.jpg',
    },
    {
      'title': 'Devotional',
      'color': const Color(0xFF7D4B32),
      'icon': Icons.self_improvement_rounded,
      'image': 'https://c.saavncdn.com/editorial/BhaktiSangeet_20230519061405_500x500.jpg',
    },
  ];

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchQueryProvider.notifier).state = query;
      if (query.trim().isNotEmpty) {
        final box = HiveService.getRecentSearches();
        if (!box.values.contains(query.trim())) {
          box.add(query.trim());
        }
      }
    });
  }

  void _executeSearch(String query) {
    _controller.text = query;
    ref.read(searchQueryProvider.notifier).state = query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(universalSearchResultsProvider);
    final activeFilter = ref.watch(selectedFilterCategoryProvider);
    final query = ref.watch(searchQueryProvider);
    final audioHandler = ref.read(audioHandlerProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _controller,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search songs, albums, artists...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 22),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: query.trim().isEmpty
          ? _buildBrowseAndRecentView()
          : Column(
              children: [
                _buildFilterChips(activeFilter),
                Expanded(
                  child: searchResults.when(
                    data: (results) {
                      if (results.isEmpty) {
                        return const Center(
                          child: Text('No matching results found', style: TextStyle(color: AppTheme.textSecondary)),
                        );
                      }
                      return _buildCategorizedResultsView(results, activeFilter, audioHandler);
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    error: (err, _) => Center(
                      child: Text('Search error: $err', style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips(String active) {
    final filters = ['All', 'Songs', 'Artists', 'Albums', 'Playlists'];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == active;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => ref.read(selectedFilterCategoryProvider.notifier).state = filter,
            selectedColor: AppTheme.primary,
            backgroundColor: AppTheme.surfaceElevated,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrowseAndRecentView() {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
      children: [
        ValueListenableBuilder(
          valueListenable: HiveService.getRecentSearches().listenable(),
          builder: (context, Box<String> box, _) {
            final recentSearches = box.values.toList().reversed.take(6).toList();
            if (recentSearches.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => box.clear(),
                      child: const Text('Clear', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recentSearches
                      .map(
                        (term) => Chip(
                          backgroundColor: AppTheme.surfaceElevated,
                          label: Text(term, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textSecondary),
                          onDeleted: () {
                            final key = box.keys.firstWhere((k) => box.get(k) == term, orElse: () => null);
                            if (key != null) box.delete(key);
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
        const Text('Browse All', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: _browseCategories.length,
          itemBuilder: (context, index) {
            final cat = _browseCategories[index];
            return GestureDetector(
              onTap: () => _executeSearch(cat['title'] as String),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: cat['color'] as Color,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -12,
                        bottom: -10,
                        child: Transform.rotate(
                          angle: 0.45,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: cat['image'] as String,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.black26,
                                  child: Icon(cat['icon'] as IconData, color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          cat['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategorizedResultsView(UniversalSearchResult res, String filter, PaatufyAudioHandler audioHandler) {
    if (filter == 'Songs') {
      return ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
        itemCount: res.songs.length,
        itemBuilder: (context, index) => _buildSongTile(res.songs[index], audioHandler, res.songs, index),
      );
    }

    if (filter == 'Artists') {
      return GridView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemCount: res.artists.length,
        itemBuilder: (context, index) => _buildArtistCard(res.artists[index]),
      );
    }

    if (filter == 'Albums') {
      return GridView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: res.albums.length,
        itemBuilder: (context, index) => _buildAlbumCard(res.albums[index]),
      );
    }

    if (filter == 'Playlists') {
      return GridView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: res.playlists.length,
        itemBuilder: (context, index) => _buildPlaylistCard(res.playlists[index]),
      );
    }

    // Default: "All" View
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
      children: [
        if (res.topResult != null) ...[
          const Text('Top Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTopResultCard(res.topResult, audioHandler, res.songs),
          const SizedBox(height: 24),
        ],
        if (res.songs.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => ref.read(selectedFilterCategoryProvider.notifier).state = 'Songs',
                child: Text('See all (${res.songs.length})', style: const TextStyle(color: AppTheme.primary, fontSize: 13)),
              ),
            ],
          ),
          ...res.songs.take(5).toList().asMap().entries.map(
                (entry) => _buildSongTile(entry.value, audioHandler, res.songs, entry.key),
              ),
          const SizedBox(height: 24),
        ],
        if (res.artists.isNotEmpty) ...[
          const Text('Artists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: res.artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) => _buildArtistCard(res.artists[index]),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (res.albums.isNotEmpty) ...[
          const Text('Albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: res.albums.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _buildHorizontalAlbumCard(res.albums[index]),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (res.playlists.isNotEmpty) ...[
          const Text('Playlists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: res.playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => _buildHorizontalPlaylistCard(res.playlists[index]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSongTile(Song song, PaatufyAudioHandler audioHandler, List<Song> queue, int index) {
    return ValueListenableBuilder<Box<Song>>(
      valueListenable: HiveService.getLikedSongs().listenable(),
      builder: (context, Box<Song> likedBox, _) {
        final isLiked = likedBox.containsKey(song.id);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: song.artworkUrl != null
                ? CachedNetworkImage(imageUrl: song.artworkUrl!, width: 48, height: 48, fit: BoxFit.cover)
                : Container(width: 48, height: 48, color: AppTheme.surfaceElevated),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                icon: const Icon(Icons.play_arrow_rounded, color: AppTheme.textPrimary, size: 24),
                onPressed: () => audioHandler.playQueue(queue, initialIndex: index),
              ),
            ],
          ),
          onTap: () => audioHandler.playQueue(queue, initialIndex: index),
        );
      },
    );
  }

  Widget _buildArtistCard(ArtistSummary artist) {
    return GestureDetector(
      onTap: () => Navigator.push(
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
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.surfaceElevated,
            backgroundImage: artist.artworkUrl != null ? CachedNetworkImageProvider(artist.artworkUrl!) : null,
            child: artist.artworkUrl == null ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary) : null,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 85,
            child: Text(
              artist.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(AlbumSummary album) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.artworkUrl != null
                  ? CachedNetworkImage(imageUrl: album.artworkUrl!, fit: BoxFit.cover)
                  : Container(color: AppTheme.surfaceElevated),
            ),
          ),
          const SizedBox(height: 8),
          Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(PlaylistSummary playlist) {
    return GestureDetector(
      onTap: () => Navigator.push(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: playlist.artworkUrl != null
                  ? CachedNetworkImage(imageUrl: playlist.artworkUrl!, fit: BoxFit.cover)
                  : Container(color: AppTheme.surfaceElevated),
            ),
          ),
          const SizedBox(height: 8),
          Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text('${playlist.trackCount} Tracks', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHorizontalAlbumCard(AlbumSummary album) {
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
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.artworkUrl != null
                  ? CachedNetworkImage(imageUrl: album.artworkUrl!, width: 130, height: 130, fit: BoxFit.cover)
                  : Container(width: 130, height: 130, color: AppTheme.surfaceElevated),
            ),
            const SizedBox(height: 6),
            Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalPlaylistCard(PlaylistSummary playlist) {
    return GestureDetector(
      onTap: () => Navigator.push(
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
      ),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: playlist.artworkUrl != null
                  ? CachedNetworkImage(imageUrl: playlist.artworkUrl!, width: 130, height: 130, fit: BoxFit.cover)
                  : Container(width: 130, height: 130, color: AppTheme.surfaceElevated),
            ),
            const SizedBox(height: 6),
            Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${playlist.trackCount} Tracks', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopResultCard(dynamic top, PaatufyAudioHandler audioHandler, List<Song> queue) {
    if (top is Song) {
      return ValueListenableBuilder<Box<Song>>(
        valueListenable: HiveService.getLikedSongs().listenable(),
        builder: (context, Box<Song> likedBox, _) {
          final isLiked = likedBox.containsKey(top.id);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: top.artworkUrl != null
                      ? CachedNetworkImage(imageUrl: top.artworkUrl!, width: 64, height: 64, fit: BoxFit.cover)
                      : Container(width: 64, height: 64, color: AppTheme.surface),
                ),
                const SizedBox(height: 12),
                Text(top.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1),
                Row(
                  children: [
                    if (isLiked) ...[
                      const Icon(Icons.favorite_rounded, color: AppTheme.primary, size: 13),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        '${top.artist} • Song',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                      onPressed: () => SongOptionsModal.show(context, top, audioHandler),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 26),
                        onPressed: () => audioHandler.playQueue(queue, initialIndex: 0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}