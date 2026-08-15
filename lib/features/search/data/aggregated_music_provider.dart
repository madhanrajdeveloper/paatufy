import 'package:paatufy/features/search/data/audius_provider.dart';
import 'package:paatufy/features/search/data/jiosaavn_provider.dart';
import 'package:paatufy/features/search/data/music_provider_interface.dart';
import 'package:paatufy/models/song.dart';

class AggregatedMusicProvider implements MusicProvider {
  final List<MusicProvider> _providers;

  AggregatedMusicProvider({
    required AudiusProvider audiusProvider,
    required JioSaavnProvider jioSaavnProvider,
  }) : _providers = [jioSaavnProvider, audiusProvider];

  @override
  Future<List<Song>> searchSongs(String query) async {
    // Run searches in parallel across all registered music providers
    final futures = _providers.map((p) => p.searchSongs(query).catchError((_) => <Song>[]));
    final nestedResults = await Future.wait(futures);

    final List<Song> combined = [];
    final Set<String> seenIdentifiers = {};

    // Interleave and merge without duplicates
    final maxLength = nestedResults.fold<int>(0, (max, list) => list.length > max ? list.length : max);

    for (int i = 0; i < maxLength; i++) {
      for (final list in nestedResults) {
        if (i < list.length) {
          final song = list[i];
          final key = '${song.title.toLowerCase()}_${song.artist.toLowerCase()}';
          if (!seenIdentifiers.contains(key)) {
            seenIdentifiers.add(key);
            combined.add(song);
          }
        }
      }
    }

    return combined;
  }

  @override
  Future<Song?> getSong(String id) async {
    for (final provider in _providers) {
      final song = await provider.getSong(id);
      if (song != null) return song;
    }
    return null;
  }

  @override
  Future<String?> getStreamUrl(String id) async {
    for (final provider in _providers) {
      final url = await provider.getStreamUrl(id);
      if (url != null) return url;
    }
    return null;
  }
}