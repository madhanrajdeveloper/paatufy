import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paatufy/models/lyric_line.dart';
import 'package:paatufy/models/song.dart';

final lyricsServiceProvider = Provider<LyricsService>((ref) => LyricsService(Dio()));

final songLyricsProvider = FutureProvider.family<List<LyricLine>, Song>((ref, song) async {
  final service = ref.watch(lyricsServiceProvider);
  return service.fetchSyncedLyrics(song);
});

class LyricsService {
  final Dio _dio;

  LyricsService(this._dio) {
    _dio.options.headers = {
      'User-Agent': 'PaatufyApp/1.0.0 (https://github.com/paatufy)',
      'Accept': 'application/json',
    };
    _dio.options.connectTimeout = const Duration(seconds: 4);
    _dio.options.receiveTimeout = const Duration(seconds: 4);
  }

  String _cleanString(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
        .replaceAll(RegExp(r'feat\..*|ft\..*', caseSensitive: false), '')
        .replaceAll(RegExp(r'from\s+.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'[-–—].*'), '')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim();
  }

  bool _isTitleMatch(String sourceTitle, String candidateTitle) {
    final cleanSource = _cleanString(sourceTitle);
    final cleanCandidate = _cleanString(candidateTitle);

    if (cleanSource.isEmpty || cleanCandidate.isEmpty) return false;
    return cleanCandidate.contains(cleanSource) || cleanSource.contains(cleanCandidate);
  }

  bool _isDurationMatch(int expectedSeconds, dynamic candidateDuration) {
    if (expectedSeconds <= 0 || candidateDuration == null) return true;
    final int dur = (candidateDuration is num) ? candidateDuration.round() : 0;
    if (dur <= 0) return true;
    return (expectedSeconds - dur).abs() <= 5; // Must be within 5 seconds tolerance
  }

  Future<List<LyricLine>> fetchSyncedLyrics(Song song) async {
    final cleanTrack = _cleanString(song.title);
    final isGenericArtist = song.artist.toLowerCase().contains('various') ||
        song.artist.toLowerCase().contains('unknown');
    final cleanArtist = isGenericArtist ? '' : _cleanString(song.artist.split(',').first.split('&').first);

    // Strategy 1: Exact Query
    if (cleanArtist.isNotEmpty) {
      try {
        final resp = await _dio.get(
          'https://lrclib.net/api/get',
          queryParameters: {
            'track_name': cleanTrack,
            'artist_name': cleanArtist,
            if (song.durationSeconds > 0) 'duration': song.durationSeconds,
          },
        );

        if (resp.statusCode == 200 && resp.data != null) {
          final data = resp.data as Map<String, dynamic>;
          if (_isTitleMatch(song.title, data['trackName'] ?? '') &&
              _isDurationMatch(song.durationSeconds, data['duration'])) {
            final synced = data['syncedLyrics'] as String?;
            if (synced != null && synced.trim().isNotEmpty) {
              return LyricLine.parseLrc(synced);
            }
          }
        }
      } catch (_) {}
    }

    // Strategy 2: Search Query with Candidate Verification
    try {
      final query = cleanArtist.isNotEmpty ? '$cleanTrack $cleanArtist' : cleanTrack;
      final searchResp = await _dio.get(
        'https://lrclib.net/api/search',
        queryParameters: {'q': query},
      );

      if (searchResp.statusCode == 200 && searchResp.data is List) {
        final list = searchResp.data as List;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final trackName = item['trackName'] as String? ?? '';
            final synced = item['syncedLyrics'] as String?;

            if (synced != null &&
                synced.trim().isNotEmpty &&
                _isTitleMatch(song.title, trackName) &&
                _isDurationMatch(song.durationSeconds, item['duration'])) {
              return LyricLine.parseLrc(synced);
            }
          }
        }
      }
    } catch (_) {}

    return [];
  }
}