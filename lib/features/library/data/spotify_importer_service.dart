import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:paatufy/features/search/data/jiosaavn_provider.dart';
import 'package:paatufy/models/song.dart';

class SpotifyTrackInfo {
  final String title;
  final String artist;
  final int durationSeconds;
  final String? artworkUrl;

  SpotifyTrackInfo({
    required this.title,
    required this.artist,
    this.durationSeconds = 0,
    this.artworkUrl,
  });
}

class SpotifyPlaylistData {
  final String title;
  final String? coverUrl;
  final List<SpotifyTrackInfo> tracks;

  SpotifyPlaylistData({
    required this.title,
    this.coverUrl,
    required this.tracks,
  });
}

class SpotifyImporterService {
  final Dio _dio = Dio();
  final JioSaavnProvider _provider;

  SpotifyImporterService(this._provider);

  String? extractPlaylistId(String urlOrUri) {
    final clean = urlOrUri.trim();
    final regex = RegExp(r'(?:playlist[/:]|embed/playlist/)([a-zA-Z0-9]+)');
    final match = regex.firstMatch(clean);
    return match?.group(1);
  }

  Future<SpotifyPlaylistData?> fetchSpotifyPlaylist(String playlistId) async {
    try {
      final embedUrl = 'https://open.spotify.com/embed/playlist/$playlistId';
      final response = await _dio.get(
        embedUrl,
        options: Options(headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        }),
      );

      final html = response.data.toString();
      final regex = RegExp(r'<script\s+id="__NEXT_DATA__"\s+type="application/json">\s*(.*?)\s*<\/script>', dotAll: true);
      final match = regex.firstMatch(html);

      if (match != null) {
        final jsonData = jsonDecode(match.group(1)!);
        final entity = jsonData['props']?['pageProps']?['state']?['data']?['entity'];

        if (entity != null) {
          final String title = entity['name'] ?? entity['title'] ?? 'Imported Spotify Playlist';
          String? coverUrl;

          if (entity['coverArt']?['sources'] is List && (entity['coverArt']['sources'] as List).isNotEmpty) {
            coverUrl = entity['coverArt']['sources'][0]['url'];
          } else if (entity['images'] is List && (entity['images'] as List).isNotEmpty) {
            coverUrl = entity['images'][0]['url'];
          }

          final List rawTracks = entity['trackList'] as List? ?? [];
          final List<SpotifyTrackInfo> tracks = [];

          for (var item in rawTracks) {
            if (item is Map) {
              final trackTitle = item['title'] ?? item['name'] ?? '';
              final trackArtist = item['subtitle'] ?? item['artists']?[0]?['name'] ?? 'Unknown Artist';
              final durationMs = item['duration'] as int? ?? 0;

              if (trackTitle.toString().trim().isNotEmpty) {
                tracks.add(SpotifyTrackInfo(
                  title: trackTitle.toString().trim(),
                  artist: trackArtist.toString().trim(),
                  durationSeconds: durationMs > 0 ? (durationMs / 1000).round() : 0,
                  artworkUrl: coverUrl,
                ));
              }
            }
          }

          return SpotifyPlaylistData(title: title, coverUrl: coverUrl, tracks: tracks);
        }
      }

      // Fallback via oEmbed
      final oembedRes = await _dio.get('https://open.spotify.com/oembed', queryParameters: {'url': 'https://open.spotify.com/playlist/$playlistId'});
      if (oembedRes.data is Map) {
        return SpotifyPlaylistData(
          title: oembedRes.data['title'] ?? 'Spotify Playlist',
          coverUrl: oembedRes.data['thumbnail_url'],
          tracks: [],
        );
      }
    } catch (_) {}
    return null;
  }

  Future<Song?> matchAndResolveTrack(SpotifyTrackInfo spotifyTrack) async {
    try {
      final query = '${spotifyTrack.title} ${spotifyTrack.artist}'.trim();
      var results = await _provider.searchSongs(query);

      if (results.isNotEmpty) {
        return results.first;
      }

      results = await _provider.searchSongs(spotifyTrack.title);
      if (results.isNotEmpty) {
        return results.first;
      }
    } catch (_) {}
    return null;
  }
}