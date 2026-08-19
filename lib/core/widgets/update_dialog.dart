import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paatufy/core/services/app_update_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (_) => PopScope(
        canPop: !updateInfo.forceUpdate,
        child: UpdateDialog(updateInfo: updateInfo),
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';

  Future<void> _startDownloadAndInstall() async {
    // 1. Verify "Install unknown apps" permission
    final status = await Permission.requestInstallPackages.status;
    if (!status.isGranted) {
      final req = await Permission.requestInstallPackages.request();
      if (!req.isGranted) {
        setState(() {
          _statusText = 'Please allow permission to install updates.';
        });
        await openAppSettings();
        return;
      }
    }

    setState(() {
      _isDownloading = true;
      _statusText = 'Starting download...';
      _progress = 0.0;
    });

    try {
      final filePath = await AppUpdateService.downloadApk(
        widget.updateInfo.apkUrl,
        (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _statusText = 'Downloading: ${(progress * 100).toInt()}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _statusText = 'Launching installer...';
        });
      }

      final success = await AppUpdateService.installApk(filePath);

      if (!success && mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Could not launch installer. Tap Update to retry.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Download failed. Check your internet connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;

    return Dialog(
      backgroundColor: const Color(0xFF1E242B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Available',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'v${info.latestVersion}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "What's New:",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 130),
              child: SingleChildScrollView(
                child: Text(
                  info.releaseNotes,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _statusText,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_statusText.isNotEmpty && !_isDownloading) ...[
              Center(
                child: Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.amberAccent),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (!info.forceUpdate && !_isDownloading)
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Later',
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (!info.forceUpdate && !_isDownloading) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isDownloading ? null : _startDownloadAndInstall,
                    child: Text(
                      _isDownloading ? 'Updating...' : 'Update Now',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}