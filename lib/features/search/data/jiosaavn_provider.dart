import 'package:dio/dio.dart';
import 'package:paatufy/features/search/data/music_provider_interface.dart';
import 'package:paatufy/models/search_result.dart';
import 'package:paatufy/models/song.dart';

class JioSaavnProvider implements MusicProvider {
  final Dio _dio;
  final String _baseUrl = 'https://paatufy-backend.onrender.com';

  JioSaavnProvider(this._dio);

  Future<UniversalSearchResult> searchAll(String query) async {
    try {
      final results = await Future.wait([
        _dio.get('$_baseUrl/api/search/songs', queryParameters: {'query': query, 'limit': 40}).catchError((_) => Response(requestOptions: RequestOptions())),
        _dio.get('$_baseUrl/api/search/albums', queryParameters: {'query': query, 'limit': 20}).catchError((_) => Response(requestOptions: RequestOptions())),
        _dio.get('$_baseUrl/api/search/artists', queryParameters: {'query': query, 'limit': 20}).catchError((_) => Response(requestOptions: RequestOptions())),
        _dio.get('$_baseUrl/api/search/playlists', queryParameters: {'query': query, 'limit': 20}).catchError((_) => Response(requestOptions: RequestOptions())),
      ]);

      List<Song> songs = _extractList(results[0].data).map((e) => Song.fromJioSaavn(Map<String, dynamic>.from(e))).toList();
      List<AlbumSummary> albums = _extractList(results[1].data).map((e) => AlbumSummary.fromJioSaavn(Map<String, dynamic>.from(e))).toList();
      List<ArtistSummary> artists = _extractList(results[2].data).map((e) => ArtistSummary.fromJioSaavn(Map<String, dynamic>.from(e))).toList();
      List<PlaylistSummary> playlists = _extractList(results[3].data).map((e) => PlaylistSummary.fromJioSaavn(Map<String, dynamic>.from(e))).toList();

      dynamic topResult;
      if (artists.isNotEmpty && artists.first.name.toLowerCase() == query.trim().toLowerCase()) {
        topResult = artists.first;
      } else if (songs.isNotEmpty) {
        topResult = songs.first;
      } else if (albums.isNotEmpty) {
        topResult = albums.first;
      }

      return UniversalSearchResult(
        topResult: topResult,
        songs: songs,
        artists: artists,
        albums: albums,
        playlists: playlists,
      );
    } catch (_) {
      return UniversalSearchResult(songs: [], artists: [], albums: [], playlists: []);
    }
  }

  List _extractList(dynamic data) {
    if (data == null) return [];
    if (data is Map) {
      if (data['data']?['results'] is List) return data['data']['results'];
      if (data['data'] is List) return data['data'];
      if (data['results'] is List) return data['results'];
    }
    if (data is List) return data;
    return [];
  }

  Future<String?> resolveSongStreamUrl(String providerId, {String? songTitle}) async {
    try {
      final cleanId = providerId.replaceAll('saavn_', '').replaceAll('audius_', '');

      // 1. Query /api/songs?id={id}
      var response = await _dio.get('$_baseUrl/api/songs?id=$cleanId').catchError((_) => Response(requestOptions: RequestOptions()));
      var data = response.data?['data'] ?? response.data;
      var item = (data is List && data.isNotEmpty) ? data.first : data;

      if (item is Map && item.isNotEmpty) {
        final song = Song.fromJioSaavn(Map<String, dynamic>.from(item));
        if (song.streamUrl != null && song.streamUrl!.isNotEmpty) {
          return song.streamUrl;
        }
      }

      // 2. Query /api/songs/{id}
      response = await _dio.get('$_baseUrl/api/songs/$cleanId').catchError((_) => Response(requestOptions: RequestOptions()));
      data = response.data?['data'] ?? response.data;
      item = (data is List && data.isNotEmpty) ? data.first : data;
      if (item is Map && item.isNotEmpty) {
        final song = Song.fromJioSaavn(Map<String, dynamic>.from(item));
        if (song.streamUrl != null && song.streamUrl!.isNotEmpty) {
          return song.streamUrl;
        }
      }

      // 3. Fallback search by song title
      if (songTitle != null && songTitle.isNotEmpty) {
        final searchRes = await _dio.get('$_baseUrl/api/search/songs', queryParameters: {'query': songTitle, 'limit': 5});
        final sData = searchRes.data?['data'] ?? searchRes.data;
        final sList = _extractList(sData);
        if (sList.isNotEmpty) {
          final song = Song.fromJioSaavn(Map<String, dynamic>.from(sList.first));
          return song.streamUrl;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    try {
      final cleanId = albumId.replaceAll('saavn_', '');
      final response = await _dio.get('$_baseUrl/api/albums?id=$cleanId');
      final data = response.data['data'] ?? response.data;
      final rawSongs = (data is Map ? data['songs'] : null) ?? [];
      return (rawSongs as List).map((i) => Song.fromJioSaavn(Map<String, dynamic>.from(i))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    try {
      final cleanId = playlistId.replaceAll('saavn_', '');
      final response = await _dio.get('$_baseUrl/api/playlists?id=$cleanId');
      final data = response.data['data'] ?? response.data;
      final rawSongs = (data is Map ? data['songs'] : null) ?? [];
      return (rawSongs as List).map((i) => Song.fromJioSaavn(Map<String, dynamic>.from(i))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Song>> getArtistTopSongs(String artistId, {String? artistName}) async {
    try {
      final cleanId = artistId.replaceAll('saavn_', '');

      // 1. Try artist details endpoint
      var response = await _dio.get('$_baseUrl/api/artists?id=$cleanId').catchError((_) => Response(requestOptions: RequestOptions()));
      var data = response.data?['data'] ?? response.data;

      List rawSongs = [];
      if (data is Map) {
        if (data['topSongs'] is List && (data['topSongs'] as List).isNotEmpty) {
          rawSongs = data['topSongs'];
        } else if (data['songs'] is List && (data['songs'] as List).isNotEmpty) {
          rawSongs = data['songs'];
        }
      }

      // 2. Try artist songs endpoint
      if (rawSongs.isEmpty) {
        response = await _dio.get('$_baseUrl/api/artists/$cleanId/songs').catchError((_) => Response(requestOptions: RequestOptions()));
        data = response.data?['data'] ?? response.data;
        if (data is Map && data['results'] is List) {
          rawSongs = data['results'];
        } else if (data is List) {
          rawSongs = data;
        }
      }

      // 3. Fallback to direct search by artist name
      if (rawSongs.isEmpty && artistName != null && artistName.isNotEmpty) {
        final searchRes = await _dio.get('$_baseUrl/api/search/songs', queryParameters: {'query': artistName, 'limit': 30});
        final searchData = searchRes.data?['data'] ?? searchRes.data;
        if (searchData is Map && searchData['results'] is List) {
          rawSongs = searchData['results'];
        }
      }

      return rawSongs.map((i) => Song.fromJioSaavn(Map<String, dynamic>.from(i))).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    final res = await searchAll(query);
    return res.songs;
  }

  @override
  Future<Song?> getSong(String id) async => null;

  @override
  Future<String?> getStreamUrl(String id) => resolveSongStreamUrl(id);
}