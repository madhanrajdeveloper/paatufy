import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paatufy/core/services/app_update_service.dart';
import 'package:paatufy/core/services/firestore_service.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/core/widgets/update_dialog.dart';
import 'package:paatufy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paatufy/models/user_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late String _streamingQuality;
  late bool _normalizeVolume;
  late bool _gaplessPlayback;
  late bool _streamOnWifiOnly;

  String _currentAppVersion = 'Loading...';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user ?? HiveService.getUserMeta(HiveService.activeUserId);
    _streamingQuality = user?.streamingQuality ?? 'High (320kbps)';
    _streamOnWifiOnly = user?.streamOnWifiOnly ?? false;
    _normalizeVolume = user?.normalizeVolume ?? true;
    _gaplessPlayback = user?.gaplessPlayback ?? true;

    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentAppVersion = 'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentAppVersion = 'Version 1.0.0';
        });
      }
    }
  }

  Future<void> _manualCheckForUpdate() async {
    if (_isCheckingUpdate) return;

    setState(() => _isCheckingUpdate = true);

    final updateInfo = await AppUpdateService.checkForUpdate();

    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    if (updateInfo != null && updateInfo.isUpdateAvailable) {
      UpdateDialog.show(context, updateInfo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You are on the latest version of Paatufy!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E242B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateSetting({
    String? streamingQuality,
    bool? streamOnWifiOnly,
    bool? gaplessPlayback,
    bool? normalizeVolume,
  }) async {
    final authState = ref.read(authControllerProvider);
    final user = authState.user ?? HiveService.getUserMeta(HiveService.activeUserId);

    if (user != null) {
      final updatedUser = user.copyWith(
        streamingQuality: streamingQuality ?? _streamingQuality,
        streamOnWifiOnly: streamOnWifiOnly ?? _streamOnWifiOnly,
        gaplessPlayback: gaplessPlayback ?? _gaplessPlayback,
        normalizeVolume: normalizeVolume ?? _normalizeVolume,
      );

      // Save locally in Hive
      await HiveService.saveUserMeta(updatedUser);

      // Background Firestore sync
      FirestoreService.saveUser(updatedUser).catchError((_) {});
    }
  }

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
              color: AppTheme.primary,
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
              onSelected: (val) {
                setState(() => _streamingQuality = val);
                _updateSetting(streamingQuality: val);
              },
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
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setState(() => _streamOnWifiOnly = val);
              _updateSetting(streamOnWifiOnly: val);
            },
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // Playback Settings
          Text(
            'Playback',
            style: GoogleFonts.poppins(
              color: AppTheme.primary,
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
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setState(() => _gaplessPlayback = val);
              _updateSetting(gaplessPlayback: val);
            },
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
            activeColor: AppTheme.primary,
            onChanged: (val) {
              setState(() => _normalizeVolume = val);
              _updateSetting(normalizeVolume: val);
            },
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // Storage & Cache
          Text(
            'Storage & Cache',
            style: GoogleFonts.poppins(
              color: AppTheme.primary,
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
              'Remove all stored recent queries across devices',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onTap: () async {
              await HiveService.clearRecentSearches();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Search history cleared everywhere', style: GoogleFonts.poppins()),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Clear Recently Played',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Reset the 6-hour playback shelf across devices',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.history_toggle_off_rounded, color: Colors.redAccent),
            onTap: () async {
              await HiveService.clearRecentlyPlayed();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Recently played cleared everywhere', style: GoogleFonts.poppins()),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // App Updates Section
          Text(
            'Updates',
            style: GoogleFonts.poppins(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Check for Updates',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Verify if a newer version of Paatufy is available',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: _isCheckingUpdate
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  )
                : const Icon(Icons.system_update_rounded, color: AppTheme.primary),
            onTap: _manualCheckForUpdate,
          ),
          const Divider(color: AppTheme.divider, height: 28),

          // Brand Logo & About Info
          Center(
            child: Column(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/paatufy-purple.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.music_note_rounded,
                      size: 40,
                      color: AppTheme.primary,
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
                          color: AppTheme.primary,
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
                  _currentAppVersion,
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