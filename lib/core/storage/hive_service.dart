import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:paatufy/models/search_result.dart';
import 'package:paatufy/models/song.dart';
import 'package:paatufy/models/user_playlist.dart';

class RecentlyPlayedItem {
  final String id;
  final String type; // 'song', 'album', 'playlist'
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
  static const String likedSongsBox = 'liked_songs';
  static const String savedAlbumsBox = 'saved_albums';
  static const String savedPlaylistsBox = 'saved_playlists';
  static const String userPlaylistsBox = 'user_custom_playlists';
  static const String recentlyPlayedBox = 'recently_played_items';
  static const String recentSearchesBox = 'recent_searches_items';

  static const int sixHoursMs = 6 * 60 * 60 * 1000;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SongAdapter());
    await Hive.openBox<Song>(likedSongsBox);
    await Hive.openBox<String>(savedAlbumsBox);
    await Hive.openBox<String>(savedPlaylistsBox);
    await Hive.openBox<String>(userPlaylistsBox);
    await Hive.openBox<String>(recentlyPlayedBox);
    await Hive.openBox<String>(recentSearchesBox);

    cleanExpiredRecentlyPlayed();
  }

  static Box<Song> getLikedSongs() => Hive.box<Song>(likedSongsBox);
  static Box<String> getSavedAlbums() => Hive.box<String>(savedAlbumsBox);
  static Box<String> getSavedPlaylists() => Hive.box<String>(savedPlaylistsBox);
  static Box<String> getUserPlaylists() => Hive.box<String>(userPlaylistsBox);
  static Box<String> getRecentlyPlayed() => Hive.box<String>(recentlyPlayedBox);
  static Box<String> getRecentSearches() => Hive.box<String>(recentSearchesBox);

  // --- Liked Songs ---
  static bool isSongLiked(String id) => getLikedSongs().containsKey(id);

  static Future<void> toggleLikeSong(Song song) async {
    final box = getLikedSongs();
    if (box.containsKey(song.id)) {
      await box.delete(song.id);
    } else {
      final copy = song.copyWith();
      await box.put(copy.id, copy);
    }
  }

  // --- User Custom Playlists ---
  static Future<UserPlaylist> createUserPlaylist(
    String name, {
    String? description,
    String? artworkUrl,
    Song? initialSong,
    List<Song>? songs,
    bool isSpotifyImported = false,
  }) async {
    final box = getUserPlaylists();
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
    return playlist;
  }

  static Future<void> deleteUserPlaylist(String playlistId) async {
    final box = getUserPlaylists();
    await box.delete(playlistId);
  }

  static Future<void> addSongToUserPlaylist(String playlistId, Song song) async {
    final box = getUserPlaylists();
    final raw = box.get(playlistId);
    if (raw != null) {
      final playlist = UserPlaylist.fromJson(raw);
      if (!playlist.songs.any((s) => s.id == song.id)) {
        playlist.songs.add(song.copyWith());
        await box.put(playlistId, playlist.toJson());
      }
    }
  }

  static Future<void> removeSongFromUserPlaylist(String playlistId, String songId) async {
    final box = getUserPlaylists();
    final raw = box.get(playlistId);
    if (raw != null) {
      final playlist = UserPlaylist.fromJson(raw);
      playlist.songs.removeWhere((s) => s.id == songId);
      await box.put(playlistId, playlist.toJson());
    }
  }

  static List<UserPlaylist> getUserPlaylistsList() {
    final box = getUserPlaylists();
    return box.values.map((str) => UserPlaylist.fromJson(str)).toList().reversed.toList();
  }

  // --- Saved Albums ---
  static bool isAlbumSaved(String id) => getSavedAlbums().containsKey(id);

  static Future<void> toggleSaveAlbum(AlbumSummary album) async {
    final box = getSavedAlbums();
    if (box.containsKey(album.id)) {
      await box.delete(album.id);
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
    }
  }

  static List<AlbumSummary> getSavedAlbumsList() {
    final box = getSavedAlbums();
    return box.values.map((str) {
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

  // --- Saved Playlists ---
  static bool isPlaylistSaved(String id) => getSavedPlaylists().containsKey(id);

  static Future<void> toggleSavePlaylist(PlaylistSummary playlist) async {
    final box = getSavedPlaylists();
    if (box.containsKey(playlist.id)) {
      await box.delete(playlist.id);
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
    }
  }

  static List<PlaylistSummary> getSavedPlaylistsList() {
    final box = getSavedPlaylists();
    return box.values.map((str) {
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

  // --- Recently Played (6-Hour TTL) ---
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
  }

  static Future<void> removeRecentlyPlayedItem(String id) async {
    final box = getRecentlyPlayed();
    await box.delete(id);
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
          if (now - timestamp > sixHoursMs) {
            keysToDelete.add(key);
          }
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

  // --- Recent Searches (Max 4 Items: Songs, Albums, Playlists, Artists) ---
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
    final box = getRecentSearches();
    await box.delete(id);
  }

  static Future<void> clearRecentSearches() async {
    final box = getRecentSearches();
    await box.clear();
  }
}