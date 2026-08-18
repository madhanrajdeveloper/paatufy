import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String minSupportedVersion;
  final String apkUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final bool isUpdateAvailable;

  AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minSupportedVersion,
    required this.apkUrl,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.isUpdateAvailable,
  });

  factory AppUpdateInfo.fromFirestore(Map<String, dynamic> map, String currentVersion, int currentBuild) {
    final latestVer = map['latest_version'] as String? ?? currentVersion;
    final latestBuild = (map['latest_build_number'] is int) 
        ? map['latest_build_number'] as int 
        : int.tryParse(map['latest_build_number']?.toString() ?? '') ?? currentBuild;
    final minVer = map['min_supported_version'] as String? ?? currentVersion;
    final force = map['force_update'] as bool? ?? false;
    final url = map['apk_url'] as String? ?? '';

    final int versionDiff = _compareVersions(latestVer, currentVersion);
    final bool hasNewerVersion = (versionDiff > 0 || latestBuild > currentBuild) && url.isNotEmpty;
    final bool isForce = force || _compareVersions(currentVersion, minVer) < 0;

    debugPrint('🔍 [UpdateCheck] Local: v$currentVersion (Build $currentBuild) | Remote: v$latestVer (Build $latestBuild)');
    debugPrint('🔍 [UpdateCheck] APK URL: $url');
    debugPrint('🔍 [UpdateCheck] isUpdateAvailable: $hasNewerVersion');

    return AppUpdateInfo(
      latestVersion: latestVer,
      latestBuildNumber: latestBuild,
      minSupportedVersion: minVer,
      apkUrl: url,
      releaseNotes: map['release_notes'] as String? ?? 'Performance improvements and bug fixes.',
      forceUpdate: isForce,
      isUpdateAvailable: hasNewerVersion,
    );
  }

  static int _compareVersions(String v1, String v2) {
    final clean1 = v1.split('+').first.trim();
    final clean2 = v2.split('+').first.trim();

    final parts1 = clean1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = clean2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }
}

class AppUpdateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final doc = await _firestore.collection('app_config').doc('version').get();
      if (!doc.exists || doc.data() == null) {
        debugPrint('⚠️ [UpdateCheck] Firestore doc "app_config/version" does not exist.');
        return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 1;

      return AppUpdateInfo.fromFirestore(doc.data()!, currentVersion, currentBuild);
    } catch (e, stack) {
      debugPrint('❌ [UpdateCheck Error]: $e');
      debugPrint('$stack');
      return null;
    }
  }

  static Stream<OtaEvent> downloadAndInstallApk(String apkUrl) {
    return OtaUpdate().execute(
      apkUrl,
      destinationFilename: 'paatufy-update.apk',
    );
  }
}