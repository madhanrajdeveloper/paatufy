import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  // 1. Check for Service Account Key
  final serviceAccountFile = File('tool/service-account.json');
  if (!serviceAccountFile.existsSync()) {
    print('❌ Error: "tool/service-account.json" not found.');
    exit(1);
  }

  // 2. Parse Project ID and Service Account Credentials
  final serviceAccountData = jsonDecode(serviceAccountFile.readAsStringSync());
  final String projectId = serviceAccountData['project_id'];
  final credentials = ServiceAccountCredentials.fromJson(serviceAccountData);

  // 3. Read version from pubspec.yaml
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

  // 4. Read Release Notes
  final notesFile = File('release_notes.json');
  String releaseNotes = '• Performance improvements and bug fixes.';

  if (notesFile.existsSync()) {
    final Map<String, dynamic> notesMap = jsonDecode(notesFile.readAsStringSync());
    if (notesMap.containsKey(version)) {
      releaseNotes = notesMap[version];
    }
  }

  String? apkUrl;
  if (args.isNotEmpty && args[0].trim().isNotEmpty) {
    apkUrl = args[0].trim();
  }

  final scopes = ['https://www.googleapis.com/auth/datastore'];
  final authClient = await clientViaServiceAccount(credentials, scopes);

  // Build the field list and update masks dynamically
  final List<String> maskParams = [
    'updateMask.fieldPaths=latest_version',
    'updateMask.fieldPaths=latest_build_number',
    'updateMask.fieldPaths=release_notes',
    'updateMask.fieldPaths=updated_at',
  ];

  final Map<String, dynamic> fields = {
    'latest_version': {'stringValue': version},
    'latest_build_number': {'integerValue': buildNumber.toString()},
    'release_notes': {'stringValue': releaseNotes},
    'updated_at': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
  };

  if (apkUrl != null) {
    maskParams.add('updateMask.fieldPaths=apk_url');
    fields['apk_url'] = {'stringValue': apkUrl};
    print('🚀 Syncing Paatufy v$version+$buildNumber with APK URL to Firestore...');
  } else {
    print('🚀 Syncing Paatufy v$version+$buildNumber metadata (keeping existing APK URL) to Firestore...');
  }

  final firestoreUrl = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/app_config/version?${maskParams.join('&')}',
  );

  try {
    final response = await authClient.patch(
      firestoreUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': fields}),
    );

    if (response.statusCode == 200) {
      print('✅ Firestore updated successfully!');
    } else {
      print('❌ Failed to update Firestore: ${response.statusCode}');
      print(response.body);
    }
  } finally {
    authClient.close();
  }
}