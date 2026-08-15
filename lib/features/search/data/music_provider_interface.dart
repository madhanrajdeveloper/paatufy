import 'package:paatufy/models/song.dart';

abstract class MusicProvider {
  Future<List<Song>> searchSongs(String query);
  Future<Song?> getSong(String id);
  Future<String?> getStreamUrl(String id);
}