import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/auth/presentation/controllers/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.music_note_rounded,
      'title': 'Unlimited Music,\nZero Ads',
      'desc': 'Stream trending Tamil & English hits with continuous playback and pure high fidelity audio.',
      'color': AppTheme.primary,
    },
    {
      'icon': Icons.download_rounded,
      'title': 'Import Any Spotify\nPlaylist Instantly',
      'desc': 'Paste your public Spotify playlist links and convert them into uninterrupted playlists in seconds.',
      'color': const Color(0xFF10B981),
    },
    {
      'icon': Icons.person_pin_rounded,
      'title': 'Your Personal Music\nSanctuary',
      'desc': 'Isolated custom playlists, liked songs, sleep timers, and multi-user profile switching.',
      'color': const Color(0xFF3B82F6),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await ref.read(authControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Top Bar with Skip Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/paatufy-purple.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Paatufy', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
                    ],
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text('Skip', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              // Page Slider
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (slide['color'] as Color).withOpacity(0.12),
                            boxShadow: [
                              BoxShadow(
                                color: (slide['color'] as Color).withOpacity(0.25),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(slide['icon'] as IconData, size: 72, color: slide['color'] as Color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, height: 1.25),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide['desc'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Indicators & Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final active = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    } else {
                      _finishOnboarding();
                    }
                  },
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Start Listening' : 'Next',
                    style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}