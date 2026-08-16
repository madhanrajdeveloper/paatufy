import 'dart:convert';
import 'package:paatufy/models/song.dart';

class UserPlaylist {
  final String id;
  final String name;
  final String? description;
  final String? artworkUrl;
  final List<Song> songs;
  final int createdAt;
  final bool isSpotifyImported;

  UserPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.artworkUrl,
    required this.songs,
    required this.createdAt,
    this.isSpotifyImported = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'artworkUrl': artworkUrl,
      'isSpotifyImported': isSpotifyImported,
      'songs': songs.map((x) {
        return {
          'id': x.id,
          'provider': x.provider,
          'providerId': x.providerId,
          'title': x.title,
          'artist': x.artist,
          'album': x.album,
          'artworkUrl': x.artworkUrl,
          'durationSeconds': x.durationSeconds,
          'streamUrl': x.streamUrl,
        };
      }).toList(),
      'createdAt': createdAt,
    };
  }

  factory UserPlaylist.fromMap(Map<String, dynamic> map) {
    final desc = map['description']?.toString() ?? '';
    final bool isImported = map['isSpotifyImported'] == true || desc.toLowerCase().contains('spotify');

    return UserPlaylist(
      id: map['id'] ?? '',
      name: map['name'] ?? 'My Playlist',
      description: map['description'],
      artworkUrl: map['artworkUrl'],
      isSpotifyImported: isImported,
      songs: map['songs'] != null
          ? (map['songs'] as List).map((x) {
              final s = Map<String, dynamic>.from(x);
              return Song(
                id: s['id'] ?? '',
                provider: s['provider'] ?? 'JioSaavn',
                providerId: s['providerId'] ?? '',
                title: s['title'] ?? 'Unknown',
                artist: s['artist'] ?? 'Unknown Artist',
                album: s['album'],
                artworkUrl: s['artworkUrl'],
                durationSeconds: s['durationSeconds'] ?? 0,
                streamUrl: s['streamUrl'],
              );
            }).toList()
          : [],
      createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserPlaylist.fromJson(String source) => UserPlaylist.fromMap(jsonDecode(source));
}