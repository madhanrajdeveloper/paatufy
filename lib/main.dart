import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/data/audio_handler.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/search/data/jiosaavn_provider.dart';
import 'package:paatufy/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();

  final audioHandler = await AudioService.init(
    builder: () => PaatufyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.paatufy.audio',
      androidNotificationChannelName: 'Paatufy Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_stat_music',
    ),
  );

  final jioSaavnProvider = JioSaavnProvider(Dio());
  audioHandler.streamResolver = (song) => jioSaavnProvider.resolveSongStreamUrl(
        song.providerId,
        songTitle: song.title,
      );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const PaatufyApp(),
    ),
  );
}

class PaatufyApp extends StatelessWidget {
  const PaatufyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Paatufy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}