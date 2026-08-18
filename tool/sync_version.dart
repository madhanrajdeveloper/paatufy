import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// Enter your Firebase Project ID (from Firebase Console Settings)
const String firebaseProjectId = 'paatufy-15e40';

void main(List<String> args) async {
  // 1. Read version from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(r'^version:\s*([0-9\.]+)\+?(\d*)', multiLine: true).firstMatch(pubspecContent);

  if (versionMatch == null) {
    print('❌ Error: Could not parse version from pubspec.yaml.');
    exit(1);
  }

  final String version = versionMatch.group(1)!;
  final int buildNumber = int.tryParse(versionMatch.group(2) ?? '1') ?? 1;

  // 2. Read Release Notes
  final notesFile = File('release_notes.json');
  String releaseNotes = '• Performance enhancements and bug fixes.';

  if (notesFile.existsSync()) {
    final Map<String, dynamic> notesMap = jsonDecode(notesFile.readAsStringSync());
    if (notesMap.containsKey(version)) {
      releaseNotes = notesMap[version];
    }
  }

  // 3. Optional APK URL passed via CLI argument
  String? apkUrl;
  if (args.isNotEmpty) {
    apkUrl = args[0];
  }

  print('🚀 Syncing Paatufy v$version+$buildNumber to Firestore...');

  // 4. Update Firestore via REST API (document: app_config/version)
  final firestoreUrl = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/app_config/version',
  );

  final Map<String, dynamic> fields = {
    'latest_version': {'stringValue': version},
    'latest_build_number': {'integerValue': buildNumber.toString()},
    'release_notes': {'stringValue': releaseNotes},
    'updated_at': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
  };

  if (apkUrl != null && apkUrl.isNotEmpty) {
    fields['apk_url'] = {'stringValue': apkUrl};
  }

  final response = await http.patch(
    firestoreUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'fields': fields}),
  );

  if (response.statusCode == 200) {
    print('✅ Successfully updated Firestore database with version $version ($buildNumber)!');
  } else {
    print('❌ Failed to update Firestore: ${response.statusCode}');
    print(response.body);
  }
}