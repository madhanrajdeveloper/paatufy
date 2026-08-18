import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/data/audio_handler.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/search/data/jiosaavn_provider.dart';
import 'package:paatufy/routing/app_router.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation strictly to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase Cloud Backend
  await Firebase.initializeApp();

  // Initialize Local Hive Storage & Restore Authenticated Session
  await HiveService.init();

  // Request Notification Permission for Android 13+
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }

  // Initialize Background Audio Service & Media Notifications
  final PaatufyAudioHandler audioHandler = await AudioService.init<PaatufyAudioHandler>(
    builder: () => PaatufyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.paatufy.audio',
      androidNotificationChannelName: 'Paatufy Playback',
      androidNotificationChannelDescription: 'Music playback notification controls',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true, // Satisfies the assert requirement
      androidNotificationIcon: 'drawable/ic_stat_music',
      androidShowNotificationBadge: true,
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