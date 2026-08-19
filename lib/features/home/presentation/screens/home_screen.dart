import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/services/app_update_service.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/core/widgets/shimmer_loading.dart';
import 'package:paatufy/core/widgets/update_dialog.dart';
import 'package:paatufy/features/audio/data/audio_handler.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paatufy/features/library/presentation/screens/user_playlist_screen.dart';
import 'package:paatufy/features/library/presentation/widgets/playlist_collage_cover.dart';
import 'package:paatufy/features/library/presentation/widgets/spotify_import_modal.dart';
import 'package:paatufy/features/profile/presentation/screens/profile_screen.dart';
import 'package:paatufy/features/profile/presentation/screens/settings_screen.dart';
import 'package:paatufy/features/search/data/jiosaavn_provider.dart';
import 'package:paatufy/features/search/presentation/screens/entity_detail_screen.dart';
import 'package:paatufy/models/search_result.dart';
import 'package:paatufy/models/song.dart';
import 'package:paatufy/models/user_playlist.dart';

final jioSaavnProviderInstance = Provider<JioSaavnProvider>((ref) => JioSaavnProvider(Dio()));

final List<String> _tamilSeeds = [
  'Latest Tamil Hits',
  'New Tamil Songs',
  'Trending Tamil',
  'Tamil Top 50',
  'Kollywood New Releases',
  'Tamil Pop 2026',
  'Anirudh Latest Hits',
  'Tamil Melody Hits',
  'Tamil Acoustic Chill',
  'Sai Abhyankkar Hits',
];

final List<String> _englishSeeds = [
  'Latest English Hits',
  'New English Pop',
  'Billboard Hot 100',
  'Today Top Hits English',
  'Global Pop 2026',
  'Viral English Songs',
  'English Chill Hits',
  'Trending English Beats',
];

final homeDiscoveryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final provider = ref.watch(jioSaavnProviderInstance);

  final random = Random();
  final shuffledTamil = List<String>.from(_tamilSeeds)..shuffle(random);
  final shuffledEnglish = List<String>.from(_englishSeeds)..shuffle(random);

  final tamilSeed = shuffledTamil.first;
  final englishSeed = shuffledEnglish.first;
  final tamilAlbumSeed = shuffledTamil[1];
  final englishAlbumSeed = shuffledEnglish[1];

  final results = await Future.wait([
    provider.searchAll(tamilSeed),
    provider.searchAll(englishSeed),
    provider.searchAll(tamilAlbumSeed),
    provider.searchAll(englishAlbumSeed),
  ]);

  final List<Song> mixedQuickPicks = [];
  final tamilSongs = results[0].songs;
  final englishSongs = results[1].songs;
  final maxSongs = max(tamilSongs.length, englishSongs.length);

  for (int i = 0; i < maxSongs && mixedQuickPicks.length < 6; i++) {
    if (i < tamilSongs.length) mixedQuickPicks.add(tamilSongs[i]);
    if (i < englishSongs.length && mixedQuickPicks.length < 6) mixedQuickPicks.add(englishSongs[i]);
  }

  final List<AlbumSummary> mixedAlbums = [];
  final tamilAlbums = [...results[0].albums, ...results[2].albums];
  final englishAlbums = [...results[1].albums, ...results[3].albums];
  final maxAlbums = max(tamilAlbums.length, englishAlbums.length);

  for (int i = 0; i < maxAlbums && mixedAlbums.length < 8; i++) {
    if (i < tamilAlbums.length) mixedAlbums.add(tamilAlbums[i]);
    if (i < englishAlbums.length && mixedAlbums.length < 8) mixedAlbums.add(englishAlbums[i]);
  }

  final List<ArtistSummary> allArtists = [
    ...results[0].artists,
    ...results[1].artists,
    ...results[2].artists,
    ...results[3].artists,
  ].toSet().toList();

  final List<PlaylistSummary> mixedPlaylists = [];
  final tamilPlaylists = [...results[0].playlists, ...results[2].playlists];
  final englishPlaylists = [...results[1].playlists, ...results[3].playlists];
  final maxPlaylists = max(tamilPlaylists.length, englishPlaylists.length);

  for (int i = 0; i < maxPlaylists && mixedPlaylists.length < 8; i++) {
    if (i < tamilPlaylists.length) mixedPlaylists.add(tamilPlaylists[i]);
    if (i < englishPlaylists.length && mixedPlaylists.length < 8) mixedPlaylists.add(englishPlaylists[i]);
  }

  return {
    'quickPicks': mixedQuickPicks,
    'trendingAlbums': mixedAlbums,
    'topArtists': allArtists.take(8).toList(),
    'dailyMixes': mixedPlaylists,
  };
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final updateInfo = await AppUpdateService.checkForUpdate();
      if (updateInfo != null && updateInfo.isUpdateAvailable && mounted) {
        UpdateDialog.show(context, updateInfo);
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showRecentlyPlayedOptions(BuildContext context, RecentlyPlayedItem item, PaatufyAudioHandler handler) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: item.artworkUrl != null
                    ? CachedNetworkImage(imageUrl: item.artworkUrl!, width: 44, height: 44, fit: BoxFit.cover)
                    : Container(width: 44, height: 44, color: AppTheme.surface),
              ),
              title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Divider(color: AppTheme.divider),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Remove from recently played', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                HiveService.removeRecentlyPlayedItem(item.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onTapRecentItem(BuildContext context, RecentlyPlayedItem item, PaatufyAudioHandler handler) {
    if (item.type == 'album') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntityDetailScreen(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            artworkUrl: item.artworkUrl,
            type: DetailType.album,
          ),
        ),
      );
    } else if (item.type == 'playlist') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntityDetailScreen(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            artworkUrl: item.artworkUrl,
            type: DetailType.playlist,
          ),
        ),
      );
    } else {
      final song = Song(
        id: item.id,
        provider: item.id.startsWith('audius_') ? 'Audius' : 'JioSaavn',
        providerId: item.providerId ?? item.id.replaceAll('saavn_', '').replaceAll('audius_', ''),
        title: item.title,
        artist: item.subtitle,
        artworkUrl: item.artworkUrl,
        durationSeconds: item.durationSeconds,
        streamUrl: item.streamUrl,
      );
      handler.playSong(song);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discovery = ref.watch(homeDiscoveryProvider);
    final audioHandler = ref.read(audioHandlerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user ?? HiveService.getUserMeta(HiveService.activeUserId);
    final String userInitial = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim()[0].toUpperCase()
        : 'M';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Ultra-Smooth Symmetrical Corner Ambient Lighting Layer ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: IgnorePointer(
              child: Stack(
                children: [
                  // 1. Top-Left Soft Glow Blob
                  Positioned(
                    top: -60,
                    left: -60,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.ambientBlob,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.ambientBlobShadow,
                            blurRadius: 55,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Top-Right Soft Glow Blob (Mirrored)
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.ambientBlob,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.ambientBlobShadow,
                            blurRadius: 55,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. High-sigma Gaussian blur filter
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // 4. Subtle Radial Gradient Tint Overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.topRightCornerGlow,
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.topLeftCornerGlow,
                    ),
                  ),

                  // 5. Seamless bottom fade into pure background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.topVerticalFade,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Scrollable Page Content ──
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
              children: [
                // Top Header Row
                Row(
                  children: [
                    // App Logo with subtle purple glow
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGlow,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/Logo-Rounded.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/paatufy-purple.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.surfaceElevated,
                              child: const Icon(Icons.music_note_rounded, color: AppTheme.primaryPurple, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary, size: 22),
                      onPressed: () => ref.refresh(homeDiscoveryProvider),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                        ),
                        child: Center(
                          child: Text(
                            userInitial,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimary, size: 22),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Shelf 1: Recently Played ──
                ValueListenableBuilder(
                  valueListenable: HiveService.getRecentlyPlayed().listenable(),
                  builder: (context, Box<String> box, _) {
                    final recentItems = HiveService.getActiveRecentlyPlayed().take(8).toList();
                    if (recentItems.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recently Played',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 165,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recentItems.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = recentItems[index];
                              return GestureDetector(
                                onTap: () => _onTapRecentItem(context, item, audioHandler),
                                child: SizedBox(
                                  width: 110,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: item.artworkUrl != null
                                                ? CachedNetworkImage(imageUrl: item.artworkUrl!, width: 110, height: 110, fit: BoxFit.cover)
                                                : Container(width: 110, height: 110, color: AppTheme.surface),
                                          ),
                                          if (item.type != 'song')
                                            Positioned(
                                              bottom: 4,
                                              left: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                                                child: Text(
                                                  item.type.toUpperCase(),
                                                  style: const TextStyle(fontSize: 9, color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: GestureDetector(
                                              onTap: () => _showRecentlyPlayedOptions(context, item, audioHandler),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                                child: const Icon(Icons.more_vert_rounded, size: 16, color: AppTheme.textPrimary),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                      Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // ── Shelf 2: Your Playlists ──
                ValueListenableBuilder<Box<String>>(
                  valueListenable: HiveService.getUserPlaylists().listenable(),
                  builder: (context, box, _) {
                    final userPlaylists = HiveService.getUserPlaylistsList();
                    if (userPlaylists.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Your Playlists', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            GestureDetector(
                              onTap: () => SpotifyImportModal.show(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGlow,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.download_rounded, size: 14, color: AppTheme.primaryPurple),
                                    SizedBox(width: 4),
                                    Text('Import Spotify', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 175,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: userPlaylists.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final playlist = userPlaylists[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => UserPlaylistScreen(playlistId: playlist.id)),
                                ),
                                child: SizedBox(
                                  width: 115,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          PlaylistCollageCover(
                                            playlist: playlist,
                                            width: 115,
                                            height: 115,
                                            borderRadius: 8,
                                          ),
                                          if (playlist.isSpotifyImported)
                                            Positioned(
                                              top: 4,
                                              left: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: AppTheme.primary, width: 0.5),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.download_done_rounded, size: 10, color: AppTheme.primaryPurple),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'SPOTIFY',
                                                      style: TextStyle(fontSize: 8, color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      Text('${playlist.songs.length} songs', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // ── Shelf 3: Dynamic Recommendations Feed ──
                discovery.when(
                  data: (data) {
                    final quickPicks = data['quickPicks'] as List<Song>;
                    final trendingAlbums = data['trendingAlbums'] as List<AlbumSummary>;
                    final topArtists = data['topArtists'] as List<ArtistSummary>;
                    final dailyMixes = data['dailyMixes'] as List<PlaylistSummary>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Picks
                        if (quickPicks.isNotEmpty) ...[
                          Text('Quick Picks • Tamil & English', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.8,
                            ),
                            itemCount: quickPicks.length,
                            itemBuilder: (context, index) {
                              final song = quickPicks[index];
                              return GestureDetector(
                                onTap: () => audioHandler.playSong(song),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                                        child: song.artworkUrl != null
                                            ? CachedNetworkImage(imageUrl: song.artworkUrl!, width: 52, height: 52, fit: BoxFit.cover)
                                            : Container(width: 52, height: 52, color: AppTheme.surfaceElevated),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          song.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                        ],

                        // New Albums
                        if (trendingAlbums.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('New Albums • Tamil & English', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 190,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: trendingAlbums.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final album = trendingAlbums[index];
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
                                              : Container(width: 130, height: 130, color: AppTheme.surface),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text(album.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Popular Artists
                        if (topArtists.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Popular Artists', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 140,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: topArtists.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final artist = topArtists[index];
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
                                      Container(
                                        padding: const EdgeInsets.all(2.0),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppTheme.primaryGlow, width: 1.5),
                                        ),
                                        child: CircleAvatar(
                                          radius: 38,
                                          backgroundColor: AppTheme.surface,
                                          backgroundImage: artist.artworkUrl != null ? CachedNetworkImageProvider(artist.artworkUrl!) : null,
                                          child: artist.artworkUrl == null ? const Icon(Icons.person_rounded, color: AppTheme.textSecondary) : null,
                                        ),
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
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Made For You
                        if (dailyMixes.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Made For You • Tamil & English', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 190,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: dailyMixes.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final playlist = dailyMixes[index];
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
                                              : Container(width: 130, height: 130, color: AppTheme.surface),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text('${playlist.trackCount} Tracks', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const HomeFeedSkeleton(),
                  error: (err, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}