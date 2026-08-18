import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paatufy/core/theme/app_theme.dart';

/// Riverpod provider monitoring real-time connectivity status
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

class OfflineFallbackScreen extends StatefulWidget {
  final VoidCallback? onRetry;

  const OfflineFallbackScreen({super.key, this.onRetry});

  @override
  State<OfflineFallbackScreen> createState() => _OfflineFallbackScreenState();
}

class _OfflineFallbackScreenState extends State<OfflineFallbackScreen> {
  bool _isChecking = false;

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    final results = await Connectivity().checkConnectivity();
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isChecking = false);

    final isConnected = results.any((r) => r != ConnectivityResult.none);
    if (isConnected) {
      widget.onRetry?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still offline. Please check your Wi-Fi or mobile data.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Offline Icon Container
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 28),

                // Main Title
                Text(
                  'No Connection',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  'Connect to Wi-Fi or mobile cellular data to stream high-quality music on Paatufy.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, color: Colors.black),
                    label: Text(
                      _isChecking ? 'Checking...' : 'Try Again',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isChecking ? null : _checkConnection,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}