import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String authProvider; // 'email' or 'google'
  final String passwordHash;
  final int createdAt;
  final String streamingQuality;
  final bool streamOnWifiOnly;
  final bool normalizeVolume;
  final bool gaplessPlayback;
  final bool hasCompletedOnboarding;
  final String status; // 'online', 'offline'
  final int lastSeen;
  final String? currentlyPlayingTitle;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.authProvider,
    this.passwordHash = '',
    required this.createdAt,
    this.streamingQuality = 'High (320kbps)',
    this.streamOnWifiOnly = false,
    this.normalizeVolume = true,
    this.gaplessPlayback = true,
    this.hasCompletedOnboarding = false,
    this.status = 'online',
    int? lastSeen,
    this.currentlyPlayingTitle,
  }) : lastSeen = lastSeen ?? DateTime.now().millisecondsSinceEpoch;

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? streamingQuality,
    bool? streamOnWifiOnly,
    bool? normalizeVolume,
    bool? gaplessPlayback,
    bool? hasCompletedOnboarding,
    String? status,
    int? lastSeen,
    String? currentlyPlayingTitle,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider,
      passwordHash: passwordHash,
      createdAt: createdAt,
      streamingQuality: streamingQuality ?? this.streamingQuality,
      streamOnWifiOnly: streamOnWifiOnly ?? this.streamOnWifiOnly,
      normalizeVolume: normalizeVolume ?? this.normalizeVolume,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      currentlyPlayingTitle: currentlyPlayingTitle ?? this.currentlyPlayingTitle,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'authProvider': authProvider,
        'passwordHash': passwordHash,
        'createdAt': createdAt,
        'streamingQuality': streamingQuality,
        'streamOnWifiOnly': streamOnWifiOnly,
        'normalizeVolume': normalizeVolume,
        'gaplessPlayback': gaplessPlayback,
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'status': status,
        'lastSeen': lastSeen,
        'currentlyPlayingTitle': currentlyPlayingTitle,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] ?? '',
        name: map['name'] ?? 'User',
        email: map['email'] ?? '',
        photoUrl: map['photoUrl'],
        authProvider: map['authProvider'] ?? 'email',
        passwordHash: map['passwordHash'] ?? '',
        createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
        streamingQuality: map['streamingQuality'] ?? 'High (320kbps)',
        streamOnWifiOnly: map['streamOnWifiOnly'] ?? false,
        normalizeVolume: map['normalizeVolume'] ?? true,
        gaplessPlayback: map['gaplessPlayback'] ?? true,
        hasCompletedOnboarding: map['hasCompletedOnboarding'] ?? false,
        status: map['status'] ?? 'offline',
        lastSeen: map['lastSeen'] ?? DateTime.now().millisecondsSinceEpoch,
        currentlyPlayingTitle: map['currentlyPlayingTitle'],
      );

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel.fromMap({...data, 'id': doc.id});
  }

  String toJson() => jsonEncode(toMap());
  factory UserModel.fromJson(String source) => UserModel.fromMap(jsonDecode(source));
}