import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/auth/presentation/controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _routeAfterAuth() {
    final user = ref.read(authControllerProvider).user;
    if (user != null && user.hasCompletedOnboarding) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      _routeAfterAuth();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      _routeAfterAuth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                ClipOval(
                  child: Image.asset(
                    'assets/images/paatufy.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, color: Color(0xFF22C55E), size: 36),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Welcome back', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Log in to continue enjoying ad-free music.', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 28),

                if (authState.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(authState.errorMessage!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12))),
                      ],
                    ),
                  ),

                // Email
                Text('Email', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'your.email@example.com',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 18),

                // Password
                Text('Password', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.textSecondary),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: authState.isLoading ? null : _handleEmailLogin,
                    child: authState.isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : Text('Log In', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: AppTheme.divider)),
                  ],
                ),
                const SizedBox(height: 20),

                // Google Sign In
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: AppTheme.surface,
                    ),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.white),
                    label: Text('Continue with Google', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                  ),
                ),
                const SizedBox(height: 32),

                // Link to Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
                    GestureDetector(
                      onTap: () => context.go('/signup'),
                      child: Text('Sign Up', style: GoogleFonts.poppins(color: const Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}