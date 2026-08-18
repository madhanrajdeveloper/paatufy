import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ota_update/ota_update.dart';
import 'package:paatufy/core/services/app_update_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';

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
  StreamSubscription<OtaEvent>? _otaSubscription;

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _statusText = 'Starting download...';
      _progress = 0.0;
    });

    _otaSubscription = AppUpdateService.downloadAndInstallApk(widget.updateInfo.apkUrl).listen(
      (OtaEvent event) {
        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            setState(() {
              final parsed = double.tryParse(event.value ?? '0') ?? 0;
              _progress = (parsed / 100).clamp(0.0, 1.0);
              _statusText = 'Downloading: ${parsed.toInt()}%';
            });
            break;
          case OtaStatus.INSTALLING:
            setState(() {
              _statusText = 'Launching installer...';
            });
            break;
          case OtaStatus.ALREADY_RUNNING_ERROR:
            setState(() {
              _statusText = 'Download already running.';
            });
            break;
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            setState(() {
              _isDownloading = false;
              _statusText = 'Storage permission denied.';
            });
            break;
          default:
            setState(() {
              _isDownloading = false;
              _statusText = 'Download failed. Please try again.';
            });
            break;
        }
      },
      onError: (_) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Failed to connect to update server.';
        });
      },
    );
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
                    color: const Color(0xFF22C55E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: Color(0xFF22C55E), size: 28),
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
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF22C55E), fontWeight: FontWeight.w600),
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
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
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
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isDownloading ? null : _startDownload,
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