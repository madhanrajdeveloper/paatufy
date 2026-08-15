import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/models/song.dart';

class PaatufyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  List<Song> _queue = [];
  List<int> _shuffleIndices = [];
  int _currentIndex = -1;
  bool _isShuffle = false;

  Timer? _sleepTicker;
  DateTime? _sleepTargetTime;

  /// External callback to resolve high-bitrate streaming URLs on demand
  Future<String?> Function(Song song)? streamResolver;

  final StreamController<List<Song>> _queueController = StreamController<List<Song>>.broadcast();
  final StreamController<bool> _shuffleController = StreamController<bool>.broadcast();
  final StreamController<Duration?> _sleepTimerRemainingController = StreamController<Duration?>.broadcast();

  Stream<List<Song>> get queueStream => _queueController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<Duration?> get sleepTimerRemainingStream => _sleepTimerRemainingController.stream;

  List<Song> get currentQueue => _queue;
  int get currentIndex => _currentIndex;
  Song? get currentSong => (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;
  bool get isShuffle => _isShuffle;
  AudioPlayer get player => _player;

  PaatufyAudioHandler() {
    _initPlayer();
  }

  void _initPlayer() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ));
    });

    _player.positionStream.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });
  }

  Future<void> playQueue(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;
    _queue = List.from(songs);
    _currentIndex = (initialIndex >= 0 && initialIndex < _queue.length) ? initialIndex : 0;
    _generateShuffleIndices();
    _queueController.add(_queue);

    await _loadAndPlayCurrent();
  }

  Future<void> playSong(Song song) async {
    await playQueue([song], initialIndex: 0);
  }

  void playNext(Song song) {
    if (_queue.isEmpty) {
      playSong(song);
      return;
    }
    _queue.insert(_currentIndex + 1, song);
    _generateShuffleIndices();
    _queueController.add(_queue);
  }

  void addToQueue(Song song) {
    if (_queue.isEmpty) {
      playSong(song);
      return;
    }
    _queue.add(song);
    _generateShuffleIndices();
    _queueController.add(_queue);
  }

  Future<void> _loadAndPlayCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;
    var song = _queue[_currentIndex];

    // Notify OS Media notification controls
    mediaItem.add(MediaItem(
      id: song.id,
      album: song.album ?? 'Paatufy Stream',
      title: song.title,
      artist: song.artist,
      duration: Duration(seconds: song.durationSeconds),
      artUri: song.artworkUrl != null ? Uri.parse(song.artworkUrl!) : null,
    ));

    String? stream = song.streamUrl;

    // Dynamically resolve URL if search entity lacked direct stream payload
    if ((stream == null || stream.isEmpty) && streamResolver != null) {
      stream = await streamResolver!(song);
      if (stream != null && stream.isNotEmpty) {
        song = song.copyWith(streamUrl: stream);
        _queue[_currentIndex] = song;
      }
    }

    // Automatically record to Recently Played with resolved streamUrl
    await HiveService.addRecentlyPlayedItem(
      id: song.id,
      type: 'song',
      title: song.title,
      subtitle: song.artist,
      artworkUrl: song.artworkUrl,
      streamUrl: song.streamUrl,
      providerId: song.providerId,
      durationSeconds: song.durationSeconds,
    );

    if (stream != null && stream.isNotEmpty) {
      try {
        await _player.stop();
        await _player.setUrl(stream);
        await _player.play();
      } catch (e) {
        debugPrint('Audio playback failure: $e');
      }
    }
  }

  void _handleTrackCompletion() {
    if (_player.loopMode == LoopMode.one) {
      _player.seek(Duration.zero);
      _player.play();
      return;
    }

    if (hasNext) {
      skipToNext();
    } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
      _currentIndex = 0;
      _loadAndPlayCurrent();
    }
  }

  bool get hasNext => _currentIndex + 1 < _queue.length;
  bool get hasPrevious => _currentIndex > 0;

  @override
  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;

    if (_isShuffle) {
      final currentPosInShuffle = _shuffleIndices.indexOf(_currentIndex);
      if (currentPosInShuffle + 1 < _shuffleIndices.length) {
        _currentIndex = _shuffleIndices[currentPosInShuffle + 1];
        await _loadAndPlayCurrent();
      } else if (_player.loopMode == LoopMode.all) {
        _currentIndex = _shuffleIndices.first;
        await _loadAndPlayCurrent();
      }
    } else if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      await _loadAndPlayCurrent();
    } else if (_player.loopMode == LoopMode.all) {
      _currentIndex = 0;
      await _loadAndPlayCurrent();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_isShuffle) {
      final currentPosInShuffle = _shuffleIndices.indexOf(_currentIndex);
      if (currentPosInShuffle > 0) {
        _currentIndex = _shuffleIndices[currentPosInShuffle - 1];
        await _loadAndPlayCurrent();
      }
    } else if (_currentIndex > 0) {
      _currentIndex--;
      await _loadAndPlayCurrent();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      await _loadAndPlayCurrent();
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_isShuffle) {
      _generateShuffleIndices();
    }
    _shuffleController.add(_isShuffle);
  }

  void _generateShuffleIndices() {
    _shuffleIndices = List.generate(_queue.length, (i) => i);
    _shuffleIndices.shuffle(Random());
    if (_currentIndex >= 0 && _shuffleIndices.contains(_currentIndex)) {
      _shuffleIndices.remove(_currentIndex);
      _shuffleIndices.insert(0, _currentIndex);
    }
  }

  Future<void> toggleRepeatMode() async {
    final current = _player.loopMode;
    if (current == LoopMode.off) {
      await _player.setLoopMode(LoopMode.all);
    } else if (current == LoopMode.all) {
      await _player.setLoopMode(LoopMode.one);
    } else {
      await _player.setLoopMode(LoopMode.off);
    }
  }

  // --- Real-time Sleep Timer Clock ---
  void setSleepTimer(Duration? duration) {
    _sleepTicker?.cancel();

    if (duration == null) {
      _sleepTargetTime = null;
      _sleepTimerRemainingController.add(null);
      return;
    }

    _sleepTargetTime = DateTime.now().add(duration);
    _sleepTimerRemainingController.add(duration);

    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTargetTime == null) {
        timer.cancel();
        return;
      }

      final diff = _sleepTargetTime!.difference(DateTime.now());
      if (diff <= Duration.zero) {
        pause();
        _sleepTargetTime = null;
        _sleepTimerRemainingController.add(null);
        timer.cancel();
      } else {
        _sleepTimerRemainingController.add(diff);
      }
    });
  }

  void setSleepTimerEndAtTrack() {
    final remaining = (_player.duration ?? Duration.zero) - _player.position;
    if (remaining > Duration.zero) {
      setSleepTimer(remaining);
    }
  }

  // --- Persistent Like & Collections Support ---
  bool isSongLiked(String id) => HiveService.getLikedSongs().containsKey(id);

  bool isCurrentSongLiked() {
    final song = currentSong;
    if (song == null) return false;
    return isSongLiked(song.id);
  }

  Future<void> toggleLikeSong(Song song) async {
    await HiveService.toggleLikeSong(song);
  }

  Future<void> toggleLikeCurrentSong() async {
    final song = currentSong;
    if (song != null) {
      await toggleLikeSong(song);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();
}