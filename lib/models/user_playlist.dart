import 'dart:convert';
import 'package:paatufy/models/song.dart';

class UserPlaylist {
  final String id;
  final String name;
  final String? description;
  final List<Song> songs;
  final int createdAt;

  UserPlaylist({
    required this.id,
    required this.name,
    this.description,
    required this.songs,
    required this.createdAt,
  });

  String? get artworkUrl => songs.isNotEmpty ? songs.first.artworkUrl : null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'songs': songs
            .map((s) => {
                  'id': s.id,
                  'provider': s.provider,
                  'providerId': s.providerId,
                  'title': s.title,
                  'artist': s.artist,
                  'album': s.album,
                  'artworkUrl': s.artworkUrl,
                  'durationSeconds': s.durationSeconds,
                  'streamUrl': s.streamUrl,
                })
            .toList(),
        'createdAt': createdAt,
      };

  factory UserPlaylist.fromMap(Map<String, dynamic> map) => UserPlaylist(
        id: map['id'] ?? '',
        name: map['name'] ?? 'Untitled Playlist',
        description: map['description'],
        songs: (map['songs'] as List? ?? [])
            .map((item) => Song(
                  id: item['id'] ?? '',
                  provider: item['provider'] ?? 'JioSaavn',
                  providerId: item['providerId'] ?? '',
                  title: item['title'] ?? 'Unknown Track',
                  artist: item['artist'] ?? 'Unknown Artist',
                  album: item['album'],
                  artworkUrl: item['artworkUrl'],
                  durationSeconds: item['durationSeconds'] ?? 0,
                  streamUrl: item['streamUrl'],
                ))
            .toList(),
        createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      );

  String toJson() => jsonEncode(toMap());
  factory UserPlaylist.fromJson(String str) => UserPlaylist.fromMap(jsonDecode(str));
}