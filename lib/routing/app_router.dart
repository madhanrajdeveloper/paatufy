import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paatufy/features/home/presentation/screens/home_screen.dart';
import 'package:paatufy/features/library/presentation/screens/library_screen.dart';
import 'package:paatufy/features/player/presentation/widgets/mini_player.dart';
import 'package:paatufy/features/search/presentation/screens/search_screen.dart';
import 'package:paatufy/features/splash/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return Consumer(
          builder: (context, ref, _) {
            return Scaffold(
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Expanded(child: child),
                    const MiniPlayer(),
                  ],
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _calculateSelectedIndex(state.uri.toString()),
                onTap: (index) {
                  switch (index) {
                    case 0:
                      ref.read(searchQueryProvider.notifier).state = '';
                      context.go('/home');
                      break;
                    case 1:
                      context.go('/search');
                      break;
                    case 2:
                      ref.read(searchQueryProvider.notifier).state = '';
                      context.go('/library');
                      break;
                  }
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
                  BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Library'),
                ],
              ),
            );
          },
        );
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
        GoRoute(path: '/library', builder: (context, state) => const LibraryScreen()),
      ],
    ),
  ],
);

int _calculateSelectedIndex(String location) {
  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/search')) return 1;
  if (location.startsWith('/library')) return 2;
  return 0;
}