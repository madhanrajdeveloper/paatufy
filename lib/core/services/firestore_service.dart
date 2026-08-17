import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/models/search_result.dart';
import 'package:paatufy/models/song.dart';
import 'package:paatufy/models/user_model.dart';
import 'package:paatufy/models/user_playlist.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User Profile & Preferences ---
  static Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  static Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  static Future<void> updateUserSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    await _db.collection('users').doc(userId).set(settings, SetOptions(merge: true));
  }

  static Future<void> updateUserStatus({
    required String userId,
    required String status,
    String? currentlyPlayingTitle,
  }) async {
    await _db.collection('users').doc(userId).update({
      'status': status,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
      'currentlyPlayingTitle': currentlyPlayingTitle,
    });
  }

  // --- Liked Songs ---
  static Future<void> setLikedSong(String userId, Song song) async {
    final songMap = {
      ...song.toMap(),
      'likedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _db.collection('users').doc(userId).collection('liked_songs').doc(song.id).set(songMap);
  }

  static Future<void> removeLikedSong(String userId, String songId) async {
    await _db.collection('users').doc(userId).collection('liked_songs').doc(songId).delete();
  }

  static Future<List<Song>> fetchAllLikedSongs(String userId) async {
    final snap = await _db.collection('users').doc(userId).collection('liked_songs').get();
    return snap.docs.map((doc) => Song.fromMap(doc.data())).toList();
  }

  // --- Custom & Imported Playlists ---
  static Future<void> saveUserPlaylist(String userId, UserPlaylist playlist) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .doc(playlist.id)
        .set(playlist.toMap(), SetOptions(merge: true));
  }

  static Future<void> deleteUserPlaylist(String userId, String playlistId) async {
    await _db.collection('users').doc(userId).collection('playlists').doc(playlistId).delete();
  }

  static Future<List<UserPlaylist>> fetchAllUserPlaylists(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('playlists')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => UserPlaylist.fromMap(doc.data())).toList();
  }

  // --- Saved Albums ---
  static Future<void> saveAlbum(String userId, AlbumSummary album) async {
    final albumMap = {
      'id': album.id,
      'title': album.title,
      'artist': album.artist,
      'artworkUrl': album.artworkUrl,
      'year': album.year,
      'provider': album.provider,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _db.collection('users').doc(userId).collection('saved_albums').doc(album.id).set(albumMap);
  }

  static Future<void> removeAlbum(String userId, String albumId) async {
    await _db.collection('users').doc(userId).collection('saved_albums').doc(albumId).delete();
  }

  static Future<List<AlbumSummary>> fetchAllSavedAlbums(String userId) async {
    final snap = await _db.collection('users').doc(userId).collection('saved_albums').get();
    return snap.docs.map((doc) {
      final map = doc.data();
      return AlbumSummary(
        id: map['id'],
        title: map['title'],
        artist: map['artist'],
        artworkUrl: map['artworkUrl'],
        year: map['year'],
        provider: map['provider'] ?? 'JioSaavn',
      );
    }).toList();
  }

  // --- Saved Playlists ---
  static Future<void> savePlaylist(String userId, PlaylistSummary playlist) async {
    final playlistMap = {
      'id': playlist.id,
      'title': playlist.title,
      'subtitle': playlist.subtitle,
      'artworkUrl': playlist.artworkUrl,
      'trackCount': playlist.trackCount,
      'provider': playlist.provider,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _db.collection('users').doc(userId).collection('saved_playlists').doc(playlist.id).set(playlistMap);
  }

  static Future<void> removePlaylist(String userId, String playlistId) async {
    await _db.collection('users').doc(userId).collection('saved_playlists').doc(playlistId).delete();
  }

  static Future<List<PlaylistSummary>> fetchAllSavedPlaylists(String userId) async {
    final snap = await _db.collection('users').doc(userId).collection('saved_playlists').get();
    return snap.docs.map((doc) {
      final map = doc.data();
      return PlaylistSummary(
        id: map['id'],
        title: map['title'],
        subtitle: map['subtitle'],
        artworkUrl: map['artworkUrl'],
        trackCount: map['trackCount'] ?? 0,
        provider: map['provider'] ?? 'JioSaavn',
      );
    }).toList();
  }

  // --- Recently Played ---
  static Future<void> addRecentlyPlayed(String userId, Map<String, dynamic> itemMap) async {
    final String id = itemMap['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _db.collection('users').doc(userId).collection('recently_played').doc(id).set(itemMap);
  }

  static Future<void> removeRecentlyPlayed(String userId, String id) async {
    await _db.collection('users').doc(userId).collection('recently_played').doc(id).delete();
  }

  static Future<void> clearRecentlyPlayed(String userId) async {
    final snap = await _db.collection('users').doc(userId).collection('recently_played').get();
    final batch = _db.batch();
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<List<RecentlyPlayedItem>> fetchAllRecentlyPlayed(String userId) async {
    final snap = await _db.collection('users').doc(userId).collection('recently_played').get();
    return snap.docs.map((doc) => RecentlyPlayedItem.fromMap(doc.data())).toList();
  }

  // --- Search History Cache ---
  static Future<void> saveRecentSearch(String userId, Map<String, dynamic> itemMap) async {
    final String id = itemMap['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _db.collection('users').doc(userId).collection('recent_searches').doc(id).set(itemMap);
  }

  static Future<void> removeRecentSearch(String userId, String id) async {
    await _db.collection('users').doc(userId).collection('recent_searches').doc(id).delete();
  }

  static Future<void> clearRecentSearches(String userId) async {
    final snap = await _db.collection('users').doc(userId).collection('recent_searches').get();
    final batch = _db.batch();
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<List<Map<String, dynamic>>> fetchAllRecentSearches(String userId) async {
    final snap = await _db.collection('users').doc(userId).collection('recent_searches').get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  // --- Delete User Account & Cloud Subcollections ---
  static Future<void> deleteUserData(String userId) async {
    final batch = _db.batch();

    final liked = await _db.collection('users').doc(userId).collection('liked_songs').get();
    for (var doc in liked.docs) {
      batch.delete(doc.reference);
    }

    final playlists = await _db.collection('users').doc(userId).collection('playlists').get();
    for (var doc in playlists.docs) {
      batch.delete(doc.reference);
    }

    final albums = await _db.collection('users').doc(userId).collection('saved_albums').get();
    for (var doc in albums.docs) {
      batch.delete(doc.reference);
    }

    final savedLists = await _db.collection('users').doc(userId).collection('saved_playlists').get();
    for (var doc in savedLists.docs) {
      batch.delete(doc.reference);
    }

    final recents = await _db.collection('users').doc(userId).collection('recently_played').get();
    for (var doc in recents.docs) {
      batch.delete(doc.reference);
    }

    final searches = await _db.collection('users').doc(userId).collection('recent_searches').get();
    for (var doc in searches.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_db.collection('users').doc(userId));
    await batch.commit();
  }
}