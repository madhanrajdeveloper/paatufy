import 'package:flutter/material.dart';
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
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Audio Quality
          const Text('Audio Quality', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Streaming Quality', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_streamingQuality, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            trailing: PopupMenuButton<String>(
              color: AppTheme.surfaceElevated,
              initialValue: _streamingQuality,
              onSelected: (val) => setState(() => _streamingQuality = val),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Auto', child: Text('Auto', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'Normal (160kbps)', child: Text('Normal (160kbps)', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'High (320kbps)', child: Text('High (320kbps)', style: TextStyle(color: Colors.white))),
              ],
              child: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textPrimary, size: 28),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Stream only on Wi-Fi', style: TextStyle(fontWeight: FontWeight.w600)),
            value: _streamOnWifiOnly,
            activeColor: const Color(0xFF22C55E),
            onChanged: (val) => setState(() => _streamOnWifiOnly = val),
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // Playback Settings
          const Text('Playback', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gapless Playback', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Seamless transitions between songs', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            value: _gaplessPlayback,
            activeColor: const Color(0xFF22C55E),
            onChanged: (val) => setState(() => _gaplessPlayback = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Normalize Volume', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Set the same volume level for all tracks', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            value: _normalizeVolume,
            activeColor: const Color(0xFF22C55E),
            onChanged: (val) => setState(() => _normalizeVolume = val),
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // Storage & Cache
          const Text('Storage & Cache', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Clear Search History', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Remove all stored recent queries', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onTap: () {
              HiveService.getRecentSearches().clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search history cleared'), duration: Duration(seconds: 1)),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Clear Recently Played', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Reset the 6-hour playback shelf', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            trailing: const Icon(Icons.history_toggle_off_rounded, color: Colors.redAccent),
            onTap: () {
              HiveService.getRecentlyPlayed().clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recently played cleared'), duration: Duration(seconds: 1)),
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
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Paatu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                      TextSpan(
                        text: 'fy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 1.0.0 (Build 2026)',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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