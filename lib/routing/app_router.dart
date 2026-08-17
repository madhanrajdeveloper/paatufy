import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paatufy/features/auth/presentation/screens/login_screen.dart';
import 'package:paatufy/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:paatufy/features/auth/presentation/screens/signup_screen.dart';
import 'package:paatufy/features/home/presentation/screens/home_screen.dart';
import 'package:paatufy/features/library/presentation/screens/library_screen.dart';
import 'package:paatufy/features/player/presentation/widgets/mini_player.dart';
import 'package:paatufy/features/profile/presentation/screens/profile_screen.dart';
import 'package:paatufy/features/profile/presentation/screens/settings_screen.dart';
import 'package:paatufy/features/search/presentation/screens/search_screen.dart';
import 'package:paatufy/features/splash/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return Consumer(
          builder: (context, ref, _) {
            final auth = ref.watch(authControllerProvider);
            final currentUserId = auth.user?.id ?? HiveService.activeUserId;

            return KeyedSubtree(
              key: ValueKey('user_session_$currentUserId'),
              child: Scaffold(
                body: Stack(
                  children: [
                    child,
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: MiniPlayer(),
                    ),
                  ],
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: _calculateSelectedIndex(state.uri.toString()),
                  onTap: (index) {
                    switch (index) {
                      case 0:
                        context.go('/home');
                        break;
                      case 1:
                        context.go('/search');
                        break;
                      case 2:
                        context.go('/library');
                        break;
                    }
                  },
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
                    BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Library'),
                  ],
                ),
              ),
            );
          },
        );
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

int _calculateSelectedIndex(String location) {
  if (location.startsWith('/search')) return 1;
  if (location.startsWith('/library')) return 2;
  return 0;
}