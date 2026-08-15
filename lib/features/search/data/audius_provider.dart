import 'package:dio/dio.dart';
import 'package:paatufy/features/search/data/music_provider_interface.dart';
import 'package:paatufy/models/song.dart';

class AudiusProvider implements MusicProvider {
  final Dio _dio;
  String? _selectedHost;

  AudiusProvider(this._dio);

  Future<String> _getHost() async {
    if (_selectedHost != null) return _selectedHost!;
    try {
      final response = await _dio.get('https://api.audius.co');
      final List data = response.data['data'];
      _selectedHost = data.first;
      return _selectedHost!;
    } catch (_) {
      return 'https://discoveryprovider.audius.co';
    }
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    final host = await _getHost();
    final response = await _dio.get(
      '$host/v1/tracks/search',
      queryParameters: {'query': query, 'app_name': 'PAATUFY'},
    );

    final List results = response.data['data'] ?? [];
    return results.map((item) => Song.fromAudius(item, host)).toList();
  }

  @override
  Future<Song?> getSong(String id) async {
    final host = await _getHost();
    final response = await _dio.get('$host/v1/tracks/$id?app_name=PAATUFY');
    if (response.data['data'] != null) {
      return Song.fromAudius(response.data['data'], host);
    }
    return null;
  }

  @override
  Future<String?> getStreamUrl(String id) async {
    final host = await _getHost();
    return '$host/v1/tracks/$id/stream?app_name=PAATUFY';
  }
}