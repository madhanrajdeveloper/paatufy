import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String provider;

  @HiveField(2)
  final String providerId;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String artist;

  @HiveField(5)
  final String? album;

  @HiveField(6)
  final String? artworkUrl;

  @HiveField(7)
  final int durationSeconds;

  @HiveField(8)
  final String? streamUrl;

  Song({
    required this.id,
    required this.provider,
    required this.providerId,
    required this.title,
    required this.artist,
    this.album,
    this.artworkUrl,
    required this.durationSeconds,
    this.streamUrl,
  });

  Song copyWith({
    String? id,
    String? provider,
    String? providerId,
    String? title,
    String? artist,
    String? album,
    String? artworkUrl,
    int? durationSeconds,
    String? streamUrl,
  }) {
    return Song(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      streamUrl: streamUrl ?? this.streamUrl,
    );
  }

  factory Song.fromAudius(Map<String, dynamic> json, String host) {
    return Song(
      id: 'audius_${json['id']}',
      provider: 'Audius',
      providerId: json['id'].toString(),
      title: json['title'] ?? 'Unknown Track',
      artist: json['user']?['name'] ?? 'Unknown Artist',
      album: null,
      artworkUrl: json['artwork']?['480x480'] ?? json['artwork']?['150x150'],
      durationSeconds: json['duration'] ?? 0,
      streamUrl: '$host/v1/tracks/${json['id']}/stream?app_name=PAATUFY',
    );
  }

  factory Song.fromJioSaavn(Map<String, dynamic> json) {
    String? artwork;
    if (json['image'] is List && (json['image'] as List).isNotEmpty) {
      artwork = (json['image'] as List).last['url'] ?? (json['image'] as List).last['link'];
    } else if (json['image'] is String) {
      artwork = json['image'];
    }

    String? stream;
    if (json['downloadUrl'] is List && (json['downloadUrl'] as List).isNotEmpty) {
      final list = json['downloadUrl'] as List;
      stream = list.last['url'] ?? list.last['link'];
    } else if (json['media_url'] is String) {
      stream = json['media_url'];
    }

    String artistName = 'Various Artists';
    if (json['primaryArtists'] != null && json['primaryArtists'].toString().trim().isNotEmpty) {
      artistName = json['primaryArtists'].toString();
    } else if (json['artist'] != null && json['artist'].toString().trim().isNotEmpty) {
      artistName = json['artist'].toString();
    } else if (json['singers'] != null && json['singers'].toString().trim().isNotEmpty) {
      artistName = json['singers'].toString();
    }

    String? albumName;
    if (json['album'] is Map) {
      albumName = json['album']['name'];
    } else if (json['album'] is String) {
      albumName = json['album'];
    }

    return Song(
      id: 'saavn_${json['id']}',
      provider: 'JioSaavn',
      providerId: json['id']?.toString() ?? '',
      title: (json['name'] ?? json['title'] ?? 'Unknown Track')
          .toString()
          .replaceAll('&quot;', '"')
          .replaceAll('&amp;', '&'),
      artist: artistName.replaceAll('&quot;', '"').replaceAll('&amp;', '&'),
      album: albumName?.replaceAll('&quot;', '"').replaceAll('&amp;', '&'),
      artworkUrl: artwork,
      durationSeconds: int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      streamUrl: stream,
    );
  }
}