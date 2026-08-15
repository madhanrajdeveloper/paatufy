import 'package:paatufy/models/song.dart';

class AlbumSummary {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final String? year;
  final String provider;

  AlbumSummary({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.year,
    required this.provider,
  });

  factory AlbumSummary.fromJioSaavn(Map<String, dynamic> json) {
    String? artwork;
    if (json['image'] is List && (json['image'] as List).isNotEmpty) {
      artwork = (json['image'] as List).last['url'] ?? (json['image'] as List).last['link'];
    } else if (json['image'] is String) {
      artwork = json['image'];
    }

    return AlbumSummary(
      id: json['id']?.toString() ?? '',
      title: (json['name'] ?? json['title'] ?? 'Unknown Album').toString().replaceAll('&quot;', '"').replaceAll('&amp;', '&'),
      artist: (json['artist'] ?? json['primaryArtists'] ?? 'Various Artists').toString().replaceAll('&quot;', '"').replaceAll('&amp;', '&'),
      artworkUrl: artwork,
      year: json['year']?.toString(),
      provider: 'JioSaavn',
    );
  }
}

class ArtistSummary {
  final String id;
  final String name;
  final String role;
  final String? artworkUrl;
  final String provider;

  ArtistSummary({
    required this.id,
    required this.name,
    required this.role,
    this.artworkUrl,
    required this.provider,
  });

  factory ArtistSummary.fromJioSaavn(Map<String, dynamic> json) {
    String? artwork;
    if (json['image'] is List && (json['image'] as List).isNotEmpty) {
      artwork = (json['image'] as List).last['url'] ?? (json['image'] as List).last['link'];
    } else if (json['image'] is String) {
      artwork = json['image'];
    }

    return ArtistSummary(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['title'] ?? 'Unknown Artist').toString().replaceAll('&quot;', '"').replaceAll('&amp;', '&'),
      role: json['role']?.toString() ?? 'Artist',
      artworkUrl: artwork,
      provider: 'JioSaavn',
    );
  }
}

class PlaylistSummary {
  final String id;
  final String title;
  final String? subtitle;
  final String? artworkUrl;
  final int trackCount;
  final String provider;

  PlaylistSummary({
    required this.id,
    required this.title,
    this.subtitle,
    this.artworkUrl,
    required this.trackCount,
    required this.provider,
  });

  factory PlaylistSummary.fromJioSaavn(Map<String, dynamic> json) {
    String? artwork;
    if (json['image'] is List && (json['image'] as List).isNotEmpty) {
      artwork = (json['image'] as List).last['url'] ?? (json['image'] as List).last['link'];
    } else if (json['image'] is String) {
      artwork = json['image'];
    }

    return PlaylistSummary(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? json['name'] ?? 'Playlist').toString().replaceAll('&quot;', '"').replaceAll('&amp;', '&'),
      subtitle: json['subtitle']?.toString().replaceAll('&quot;', '"').replaceAll('&amp;', '&'),
      artworkUrl: artwork,
      trackCount: int.tryParse(json['songCount']?.toString() ?? '0') ?? 0,
      provider: 'JioSaavn',
    );
  }
}

class UniversalSearchResult {
  final dynamic topResult; // Can be Song, ArtistSummary, or AlbumSummary
  final List<Song> songs;
  final List<ArtistSummary> artists;
  final List<AlbumSummary> albums;
  final List<PlaylistSummary> playlists;

  UniversalSearchResult({
    this.topResult,
    required this.songs,
    required this.artists,
    required this.albums,
    required this.playlists,
  });

  bool get isEmpty =>
      topResult == null && songs.isEmpty && artists.isEmpty && albums.isEmpty && playlists.isEmpty;
}