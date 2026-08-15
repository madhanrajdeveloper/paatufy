import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:paatufy/features/audio/data/audio_handler.dart';
import 'package:paatufy/models/song.dart';

final audioHandlerProvider = Provider<PaatufyAudioHandler>((ref) {
  throw UnimplementedError('AudioHandler must be initialized in main');
});

final currentSongProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem;
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});

final isPlayingProvider = Provider<bool>((ref) {
  final state = ref.watch(playbackStateProvider).value;
  return state?.playing ?? false;
});

final playerPositionStreamProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.positionStream;
});

final playerDurationStreamProvider = StreamProvider<Duration?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.durationStream;
});

final playerBufferedPositionStreamProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.bufferedPositionStream;
});

final shuffleStateProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.shuffleStream;
});

final loopModeStreamProvider = StreamProvider<LoopMode>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.player.loopModeStream;
});

final queueStreamProvider = StreamProvider<List<Song>>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.queueStream;
});

final sleepTimerRemainingProvider = StreamProvider<Duration?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.sleepTimerRemainingStream;
});