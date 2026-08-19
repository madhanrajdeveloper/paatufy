import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/data/audio_handler.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/common/presentation/screens/offline_fallback_screen.dart';
import 'package:paatufy/features/search/data/jiosaavn_provider.dart';
import 'package:paatufy/routing/app_router.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Lock screen orientation strictly to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 2. Initialize Firebase Cloud Backend (Auth, Remote Config)
  await Firebase.initializeApp();

  // 3. Initialize Local Hive Storage (Local Playlists, Auth Session, History)
  await HiveService.init();

  // 4. Request notification permissions for Android 13+ media controls
  if (Platform.isAndroid) {
    await Permission.notification.request();
  }

  // 5. Initialize Background Audio Service & OS Media Notifications
  final PaatufyAudioHandler audioHandler = await AudioService.init<PaatufyAudioHandler>(
    builder: () => PaatufyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.paatufy.audio',
      androidNotificationChannelName: 'Paatufy Playback',
      androidNotificationChannelDescription: 'Music playback notification controls',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_stat_music',
      androidShowNotificationBadge: true,
    ),
  );

  // 6. Connect high-bitrate audio stream resolver
  final jioSaavnProvider = JioSaavnProvider(Dio());
  audioHandler.streamResolver = (song) => jioSaavnProvider.resolveSongStreamUrl(
        song.providerId,
        songTitle: song.title,
      );

  // 7. Start App wrapped with Riverpod ProviderScope
  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const PaatufyApp(),
    ),
  );
}

class PaatufyApp extends ConsumerWidget {
  const PaatufyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch real-time network connectivity state
    final connectivityAsync = ref.watch(connectivityProvider);

    return MaterialApp.router(
      title: 'Paatufy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Global theme from AppTheme
      routerConfig: appRouter,
      builder: (context, child) {
        // Render offline fallback screen when internet is completely disconnected
        return connectivityAsync.when(
          data: (results) {
            final isOffline = results.every((r) => r == ConnectivityResult.none);
            if (isOffline) {
              return const OfflineFallbackScreen();
            }
            return child ?? const SizedBox.shrink();
          },
          loading: () => child ?? const SizedBox.shrink(),
          error: (_, __) => child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}