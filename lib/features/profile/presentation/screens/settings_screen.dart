import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _streamingQuality = 'High (320kbps)';
  bool _normalizeVolume = true;
  bool _gaplessPlayback = true;
  bool _streamOnWifiOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Audio Quality
          Text(
            'Audio Quality',
            style: GoogleFonts.poppins(
              color: const Color(0xFF22C55E),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Streaming Quality',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              _streamingQuality,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              color: AppTheme.surfaceElevated,
              initialValue: _streamingQuality,
              onSelected: (val) => setState(() => _streamingQuality = val),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'Auto',
                  child: Text('Auto', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                ),
                PopupMenuItem(
                  value: 'Normal (160kbps)',
                  child: Text('Normal (160kbps)', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                ),
                PopupMenuItem(
                  value: 'High (320kbps)',
                  child: Text('High (320kbps)', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                ),
              ],
              child: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textPrimary, size: 28),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Stream only on Wi-Fi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            value: _streamOnWifiOnly,
            activeColor: const Color(0xFF22C55E),
            onChanged: (val) => setState(() => _streamOnWifiOnly = val),
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // Playback Settings
          Text(
            'Playback',
            style: GoogleFonts.poppins(
              color: const Color(0xFF22C55E),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Gapless Playback',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Seamless transitions between songs',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            value: _gaplessPlayback,
            activeColor: const Color(0xFF22C55E),
            onChanged: (val) => setState(() => _gaplessPlayback = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Normalize Volume',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Set the same volume level for all tracks',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            value: _normalizeVolume,
            activeColor: const Color(0xFF22C55E),
            onChanged: (val) => setState(() => _normalizeVolume = val),
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // Storage & Cache
          Text(
            'Storage & Cache',
            style: GoogleFonts.poppins(
              color: const Color(0xFF22C55E),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Clear Search History',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Remove all stored recent queries',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onTap: () {
              HiveService.getRecentSearches().clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Search history cleared', style: GoogleFonts.poppins()),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Clear Recently Played',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Reset the 6-hour playback shelf',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.history_toggle_off_rounded, color: Colors.redAccent),
            onTap: () {
              HiveService.getRecentlyPlayed().clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Recently played cleared', style: GoogleFonts.poppins()),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // Brand Logo & About Info
          Center(
            child: Column(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/paatufy.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.music_note_rounded,
                      size: 40,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Paatu',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                      TextSpan(
                        text: 'fy',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (Build 2026)',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}