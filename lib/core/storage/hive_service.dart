import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/core/services/firestore_service.dart';
import 'package:paatufy/models/search_result.dart';
import 'package:paatufy/models/song.dart';
import 'package:paatufy/models/user_model.dart';
import 'package:paatufy/models/user_playlist.dart';

class RecentlyPlayedItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String? artworkUrl;
  final String? streamUrl;
  final String? providerId;
  final int durationSeconds;
  final int timestamp;

  RecentlyPlayedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.artworkUrl,
    this.streamUrl,
    this.providerId,
    this.durationSeconds = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'artworkUrl': artworkUrl,
        'streamUrl': streamUrl,
        'providerId': providerId,
        'durationSeconds': durationSeconds,
        'timestamp': timestamp,
      };

  factory RecentlyPlayedItem.fromMap(Map<String, dynamic> map) => RecentlyPlayedItem(
        id: map['id'] ?? '',
        type: map['type'] ?? 'song',
        title: map['title'] ?? 'Unknown',
        subtitle: map['subtitle'] ?? '',
        artworkUrl: map['artworkUrl'],
        streamUrl: map['streamUrl'],
        providerId: map['providerId'],
        durationSeconds: map['durationSeconds'] ?? 0,
        timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      );
}

class HiveService {
  static const String authSessionBox = 'auth_session_box';
  static const String usersMetaBox = 'global_users_meta_box';
  static String activeUserId = 'guest';

  static const int sixHoursMs = 6 * 60 * 60 * 1000;

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SongAdapter());
    }

    if (!Hive.isBoxOpen(authSessionBox)) {
      await Hive.openBox<String>(authSessionBox);
    }
    if (!Hive.isBoxOpen(usersMetaBox)) {
      await Hive.openBox<String>(usersMetaBox);
    }

    final sessionBox = Hive.box<String>(authSessionBox);
    final savedUserId = sessionBox.get('current_user_id');
    final savedToken = sessionBox.get('auth_token');

    if (savedUserId != null && savedToken != null && savedUserId.isNotEmpty) {
      activeUserId = savedUserId;
    }

    await _openUserScopedBoxes(activeUserId);
    cleanExpiredRecentlyPlayed();
  }

  static Future<void> switchUserContext(String userId) async {
    activeUserId = userId;
    await _openUserScopedBoxes(userId);
    cleanExpiredRecentlyPlayed();
  }

  static Future<void> _openUserScopedBoxes(String uid) async {
    await Future.wait([
      if (!Hive.isBoxOpen('liked_songs_$uid')) Hive.openBox<Song>('liked_songs_$uid'),
      if (!Hive.isBoxOpen('saved_albums_$uid')) Hive.openBox<String>('saved_albums_$uid'),
      if (!Hive.isBoxOpen('saved_playlists_$uid')) Hive.openBox<String>('saved_playlists_$uid'),
      if (!Hive.isBoxOpen('user_custom_playlists_$uid')) Hive.openBox<String>('user_custom_playlists_$uid'),
      if (!Hive.isBoxOpen('recently_played_$uid')) Hive.openBox<String>('recently_played_$uid'),
      if (!Hive.isBoxOpen('recent_searches_$uid')) Hive.openBox<String>('recent_searches_$uid'),
    ]);
  }

  /// Restores all user data, search history, and cache from Cloud Firestore into local Hive
  static Future<void> syncFromCloud(String userId) async {
    if (userId == 'guest' || userId.isEmpty) return;
    await _openUserScopedBoxes(userId);

    try {
      final results = await Future.wait([
        FirestoreService.fetchAllLikedSongs(userId),
        FirestoreService.fetchAllUserPlaylists(userId),
        FirestoreService.fetchAllSavedAlbums(userId),
        FirestoreService.fetchAllSavedPlaylists(userId),
        FirestoreService.fetchAllRecentlyPlayed(userId),
        FirestoreService.fetchAllRecentSearches(userId),
      ]).timeout(const Duration(seconds: 8));

      final cloudSongs = results[0] as List<Song>;
      final cloudPlaylists = results[1] as List<UserPlaylist>;
      final cloudAlbums = results[2] as List<AlbumSummary>;
      final cloudSavedLists = results[3] as List<PlaylistSummary>;
      final cloudRecents = results[4] as List<RecentlyPlayedItem>;
      final cloudSearches = results[5] as List<Map<String, dynamic>>;

      // 1. Liked Songs
      final likedBox = Hive.box<Song>('liked_songs_$userId');
      for (var song in cloudSongs) {
        await likedBox.put(song.id, song);
      }

      // 2. Playlists
      final playlistBox = Hive.box<String>('user_custom_playlists_$userId');
      for (var pl in cloudPlaylists) {
        await playlistBox.put(pl.id, pl.toJson());
      }

      // 3. Saved Albums
      final albumBox = Hive.box<String>('saved_albums_$userId');
      for (var alb in cloudAlbums) {
        final jsonStr = jsonEncode({
          'id': alb.id,
          'title': alb.title,
          'artist': alb.artist,
          'artworkUrl': alb.artworkUrl,
          'year': alb.year,
          'provider': alb.provider,
        });
        await albumBox.put(alb.id, jsonStr);
      }

      // 4. Saved Playlists
      final savedListBox = Hive.box<String>('saved_playlists_$userId');
      for (var pl in cloudSavedLists) {
        final jsonStr = jsonEncode({
          'id': pl.id,
          'title': pl.title,
          'subtitle': pl.subtitle,
          'artworkUrl': pl.artworkUrl,
          'trackCount': pl.trackCount,
          'provider': pl.provider,
        });
        await savedListBox.put(pl.id, jsonStr);
      }

      // 5. Recently Played
      final recentsBox = Hive.box<String>('recently_played_$userId');
      for (var r in cloudRecents) {
        await recentsBox.put(r.id, jsonEncode(r.toMap()));
      }

      // 6. Recent Searches
      final searchBox = Hive.box<String>('recent_searches_$userId');
      for (var s in cloudSearches) {
        if (s['id'] != null) {
          await searchBox.put(s['id'], jsonEncode(s));
        }
      }
    } catch (_) {}
  }

  // --- Auth Session & Token Management ---
  static Future<void> saveAuthSession({required String userId, required String token}) async {
    final sessionBox = Hive.box<String>(authSessionBox);
    await sessionBox.put('current_user_id', userId);
    await sessionBox.put('auth_token', token);
    await switchUserContext(userId);
  }

  static String? getAuthToken() {
    if (!Hive.isBoxOpen(authSessionBox)) return null;
    return Hive.box<String>(authSessionBox).get('auth_token');
  }

  static String? getCurrentUserId() {
    if (!Hive.isBoxOpen(authSessionBox)) return null;
    return Hive.box<String>(authSessionBox).get('current_user_id');
  }

  static Future<void> clearAuthSession() async {
    if (Hive.isBoxOpen(authSessionBox)) {
      await Hive.box<String>(authSessionBox).clear();
    }
    await switchUserContext('guest');
  }

  // --- Global Users Registry ---
  static Box<String> getUsersMetaBox() => Hive.box<String>(usersMetaBox);

  static Future<void> saveUserMeta(UserModel user) async {
    final box = getUsersMetaBox();
    await box.put(user.id, user.toJson());
  }

  static Future<void> deleteUserAccountAndData(String userId) async {
    await getUsersMetaBox().delete(userId);

    try {
      if (Hive.isBoxOpen('liked_songs_$userId')) await Hive.box<Song>('liked_songs_$userId').deleteFromDisk();
      if (Hive.isBoxOpen('saved_albums_$userId')) await Hive.box<String>('saved_albums_$userId').deleteFromDisk();
      if (Hive.isBoxOpen('saved_playlists_$userId')) await Hive.box<String>('saved_playlists_$userId').deleteFromDisk();
      if (Hive.isBoxOpen('user_custom_playlists_$userId')) await Hive.box<String>('user_custom_playlists_$userId').deleteFromDisk();
      if (Hive.isBoxOpen('recently_played_$userId')) await Hive.box<String>('recently_played_$userId').deleteFromDisk();
      if (Hive.isBoxOpen('recent_searches_$userId')) await Hive.box<String>('recent_searches_$userId').deleteFromDisk();
    } catch (_) {}
  }

  static UserModel? getUserMeta(String userId) {
    if (!Hive.isBoxOpen(usersMetaBox)) return null;
    final raw = getUsersMetaBox().get(userId);
    if (raw == null) return null;
    return UserModel.fromJson(raw);
  }

  static UserModel? getUserByEmail(String email) {
    if (!Hive.isBoxOpen(usersMetaBox)) return null;
    for (var str in getUsersMetaBox().values) {
      try {
        final u = UserModel.fromJson(str);
        if (u.email.toLowerCase() == email.trim().toLowerCase()) return u;
      } catch (_) {}
    }
    return null;
  }

  static List<UserModel> getAllUsers() {
    if (!Hive.isBoxOpen(usersMetaBox)) return [];
    return getUsersMetaBox().values.map((s) => UserModel.fromJson(s)).toList();
  }

  // --- User-Scoped Box Getters ---
  static Box<Song> getLikedSongs() => Hive.box<Song>('liked_songs_$activeUserId');
  static Box<String> getSavedAlbums() => Hive.box<String>('saved_albums_$activeUserId');
  static Box<String> getSavedPlaylists() => Hive.box<String>('saved_playlists_$activeUserId');
  static Box<String> getUserPlaylists() => Hive.box<String>('user_custom_playlists_$activeUserId');
  static Box<String> getRecentlyPlayed() => Hive.box<String>('recently_played_$activeUserId');
  static Box<String> getRecentSearches() => Hive.box<String>('recent_searches_$activeUserId');

  // --- Liked Songs (Hive + Cloud Sync) ---
  static bool isSongLiked(String id) => getLikedSongs().containsKey(id);

  static Future<void> toggleLikeSong(Song song) async {
    final box = getLikedSongs();
    final uid = activeUserId;
    if (box.containsKey(song.id)) {
      await box.delete(song.id);
      if (uid != 'guest') FirestoreService.removeLikedSong(uid, song.id).catchError((_) {});
    } else {
      await box.put(song.id, song.copyWith());
      if (uid != 'guest') FirestoreService.setLikedSong(uid, song).catchError((_) {});
    }
  }

  // --- User Custom Playlists (Hive + Cloud Sync) ---
  static Future<UserPlaylist> createUserPlaylist(
    String name, {
    String? description,
    String? artworkUrl,
    Song? initialSong,
    List<Song>? songs,
    bool isSpotifyImported = false,
  }) async {
    final box = getUserPlaylists();
    final uid = activeUserId;
    final id = 'playlist_${DateTime.now().millisecondsSinceEpoch}';
    final playlist = UserPlaylist(
      id: id,
      name: name.trim().isEmpty ? 'My Playlist' : name.trim(),
      description: description,
      artworkUrl: artworkUrl,
      isSpotifyImported: isSpotifyImported,
      songs: songs ?? (initialSong != null ? [initialSong.copyWith()] : []),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await box.put(id, playlist.toJson());
    if (uid != 'guest') FirestoreService.saveUserPlaylist(uid, playlist).catchError((_) {});
    return playlist;
  }

  static Future<void> deleteUserPlaylist(String playlistId) async {
    final uid = activeUserId;
    await getUserPlaylists().delete(playlistId);
    if (uid != 'guest') FirestoreService.deleteUserPlaylist(uid, playlistId).catchError((_) {});
  }

  static Future<void> addSongToUserPlaylist(String playlistId, Song song) async {
    final box = getUserPlaylists();
    final uid = activeUserId;
    final raw = box.get(playlistId);
    if (raw != null) {
      final playlist = UserPlaylist.fromJson(raw);
      if (!playlist.songs.any((s) => s.id == song.id)) {
        playlist.songs.add(song.copyWith());
        await box.put(playlistId, playlist.toJson());
        if (uid != 'guest') FirestoreService.saveUserPlaylist(uid, playlist).catchError((_) {});
      }
    }
  }

  static Future<void> removeSongFromUserPlaylist(String playlistId, String songId) async {
    final box = getUserPlaylists();
    final uid = activeUserId;
    final raw = box.get(playlistId);
    if (raw != null) {
      final playlist = UserPlaylist.fromJson(raw);
      playlist.songs.removeWhere((s) => s.id == songId);
      await box.put(playlistId, playlist.toJson());
      if (uid != 'guest') FirestoreService.saveUserPlaylist(uid, playlist).catchError((_) {});
    }
  }

  static List<UserPlaylist> getUserPlaylistsList() {
    return getUserPlaylists().values.map((str) => UserPlaylist.fromJson(str)).toList().reversed.toList();
  }

  // --- Saved Albums (Hive + Cloud Sync) ---
  static bool isAlbumSaved(String id) => getSavedAlbums().containsKey(id);

  static Future<void> toggleSaveAlbum(AlbumSummary album) async {
    final box = getSavedAlbums();
    final uid = activeUserId;
    if (box.containsKey(album.id)) {
      await box.delete(album.id);
      if (uid != 'guest') FirestoreService.removeAlbum(uid, album.id).catchError((_) {});
    } else {
      final jsonStr = jsonEncode({
        'id': album.id,
        'title': album.title,
        'artist': album.artist,
        'artworkUrl': album.artworkUrl,
        'year': album.year,
        'provider': album.provider,
      });
      await box.put(album.id, jsonStr);
      if (uid != 'guest') FirestoreService.saveAlbum(uid, album).catchError((_) {});
    }
  }

  static List<AlbumSummary> getSavedAlbumsList() {
    return getSavedAlbums().values.map((str) {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return AlbumSummary(
        id: map['id'],
        title: map['title'],
        artist: map['artist'],
        artworkUrl: map['artworkUrl'],
        year: map['year'],
        provider: map['provider'] ?? 'JioSaavn',
      );
    }).toList().reversed.toList();
  }

  // --- Saved Playlists (Hive + Cloud Sync) ---
  static bool isPlaylistSaved(String id) => getSavedPlaylists().containsKey(id);

  static Future<void> toggleSavePlaylist(PlaylistSummary playlist) async {
    final box = getSavedPlaylists();
    final uid = activeUserId;
    if (box.containsKey(playlist.id)) {
      await box.delete(playlist.id);
      if (uid != 'guest') FirestoreService.removePlaylist(uid, playlist.id).catchError((_) {});
    } else {
      final jsonStr = jsonEncode({
        'id': playlist.id,
        'title': playlist.title,
        'subtitle': playlist.subtitle,
        'artworkUrl': playlist.artworkUrl,
        'trackCount': playlist.trackCount,
        'provider': playlist.provider,
      });
      await box.put(playlist.id, jsonStr);
      if (uid != 'guest') FirestoreService.savePlaylist(uid, playlist).catchError((_) {});
    }
  }

  static List<PlaylistSummary> getSavedPlaylistsList() {
    return getSavedPlaylists().values.map((str) {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return PlaylistSummary(
        id: map['id'],
        title: map['title'],
        subtitle: map['subtitle'],
        artworkUrl: map['artworkUrl'],
        trackCount: map['trackCount'] ?? 0,
        provider: map['provider'] ?? 'JioSaavn',
      );
    }).toList().reversed.toList();
  }

  // --- Recently Played (Hive + Cloud Sync & Clear) ---
  static Future<void> addRecentlyPlayedItem({
    required String id,
    required String type,
    required String title,
    required String subtitle,
    String? artworkUrl,
    String? streamUrl,
    String? providerId,
    int durationSeconds = 0,
  }) async {
    final box = getRecentlyPlayed();
    final uid = activeUserId;
    final item = RecentlyPlayedItem(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      artworkUrl: artworkUrl,
      streamUrl: streamUrl,
      providerId: providerId,
      durationSeconds: durationSeconds,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await box.put(id, jsonEncode(item.toMap()));
    if (uid != 'guest') FirestoreService.addRecentlyPlayed(uid, item.toMap()).catchError((_) {});
  }

  static Future<void> removeRecentlyPlayedItem(String id) async {
    final uid = activeUserId;
    await getRecentlyPlayed().delete(id);
    if (uid != 'guest') FirestoreService.removeRecentlyPlayed(uid, id).catchError((_) {});
  }

  static Future<void> clearRecentlyPlayed() async {
    final uid = activeUserId;
    await getRecentlyPlayed().clear();
    if (uid != 'guest') await FirestoreService.clearRecentlyPlayed(uid).catchError((_) {});
  }

  static void cleanExpiredRecentlyPlayed() {
    final box = getRecentlyPlayed();
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<dynamic> keysToDelete = [];

    for (var key in box.keys) {
      try {
        final raw = box.get(key);
        if (raw != null) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final timestamp = map['timestamp'] as int? ?? 0;
          if (now - timestamp > sixHoursMs) keysToDelete.add(key);
        }
      } catch (_) {
        keysToDelete.add(key);
      }
    }
    box.deleteAll(keysToDelete);
  }

  static List<RecentlyPlayedItem> getActiveRecentlyPlayed() {
    cleanExpiredRecentlyPlayed();
    final box = getRecentlyPlayed();
    final List<RecentlyPlayedItem> items = [];

    for (var val in box.values) {
      try {
        final map = jsonDecode(val) as Map<String, dynamic>;
        items.add(RecentlyPlayedItem.fromMap(map));
      } catch (_) {}
    }

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  // --- Recent Searches (Hive + Cloud Sync & Clear) ---
  static Future<void> addRecentSearchItem({
    required String id,
    required String type,
    required String title,
    required String subtitle,
    String? artworkUrl,
    String? streamUrl,
    String? providerId,
    int durationSeconds = 0,
  }) async {
    final box = getRecentSearches();
    final uid = activeUserId;
    final item = {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'artworkUrl': artworkUrl,
      'streamUrl': streamUrl,
      'providerId': providerId,
      'durationSeconds': durationSeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await box.put(id, jsonEncode(item));
    if (uid != 'guest') FirestoreService.saveRecentSearch(uid, item).catchError((_) {});
  }

  static List<Map<String, dynamic>> getRecentSearchItems() {
    final box = getRecentSearches();
    final List<Map<String, dynamic>> items = [];

    for (var val in box.values) {
      try {
        final map = jsonDecode(val) as Map<String, dynamic>;
        items.add(map);
      } catch (_) {}
    }

    items.sort((a, b) => (b['timestamp'] as int? ?? 0).compareTo(a['timestamp'] as int? ?? 0));
    return items.take(4).toList();
  }

  static Future<void> removeRecentSearchItem(String id) async {
    final uid = activeUserId;
    await getRecentSearches().delete(id);
    if (uid != 'guest') FirestoreService.removeRecentSearch(uid, id).catchError((_) {});
  }

  static Future<void> clearRecentSearches() async {
    final uid = activeUserId;
    await getRecentSearches().clear();
    if (uid != 'guest') await FirestoreService.clearRecentSearches(uid).catchError((_) {});
  }
}