import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:paatufy/core/services/firestore_service.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/models/user_model.dart';
import 'package:uuid/uuid.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<AuthState> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthController() : super(AuthState()) {
    checkInitialSession();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  String _generateSecureToken(String userId) {
    final payload = '$userId:${DateTime.now().millisecondsSinceEpoch}:${const Uuid().v4()}';
    final hmac = Hmac(sha256, utf8.encode('paatufy_secret_salt_2026'));
    final digest = hmac.convert(utf8.encode(payload));
    return base64Url.encode(utf8.encode('$payload.${digest.toString()}'));
  }

  Future<void> checkInitialSession() async {
    final token = HiveService.getAuthToken();
    final uid = HiveService.getCurrentUserId();

    if (token != null && uid != null && uid != 'guest') {
      UserModel? user = HiveService.getUserMeta(uid);

      try {
        final cloudUser = await FirestoreService.getUser(uid).timeout(const Duration(seconds: 4));
        if (cloudUser != null) {
          user = cloudUser;
          await HiveService.saveUserMeta(cloudUser);
        }
      } catch (_) {}

      if (user != null) {
        try {
          await FirestoreService.updateUserStatus(userId: user.id, status: 'online')
              .timeout(const Duration(seconds: 4));
        } catch (_) {}
        state = state.copyWith(user: user, isAuthenticated: true);
        return;
      }
    }
    state = state.copyWith(user: null, isAuthenticated: false);
  }

  Future<bool> completeOnboarding() async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(hasCompletedOnboarding: true);
      await HiveService.saveUserMeta(updatedUser);
      try {
        await FirestoreService.saveUser(updatedUser).timeout(const Duration(seconds: 4));
      } catch (_) {}
      state = state.copyWith(user: updatedUser);
      return true;
    }
    return false;
  }

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final normalizedEmail = email.trim().toLowerCase();

      var existingUser = HiveService.getUserByEmail(normalizedEmail);
      if (existingUser == null) {
        try {
          existingUser = await FirestoreService.getUserByEmail(normalizedEmail).timeout(const Duration(seconds: 4));
        } catch (_) {}
      }

      if (existingUser != null) {
        state = state.copyWith(isLoading: false, errorMessage: 'An account with this email already exists.');
        return false;
      }

      final userId = 'user_${const Uuid().v4().substring(0, 8)}';
      final newUser = UserModel(
        id: userId,
        name: name.trim(),
        email: normalizedEmail,
        authProvider: 'email',
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        hasCompletedOnboarding: false,
        status: 'online',
      );

      await HiveService.saveUserMeta(newUser);
      final token = _generateSecureToken(userId);
      await HiveService.saveAuthSession(userId: userId, token: token);

      try {
        await FirestoreService.saveUser(newUser).timeout(const Duration(seconds: 5));
      } catch (_) {}

      state = state.copyWith(isLoading: false, user: newUser, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final normalizedEmail = email.trim().toLowerCase();
      var user = HiveService.getUserByEmail(normalizedEmail);

      // Restore profile from Firestore if app was reinstalled
      if (user == null) {
        try {
          user = await FirestoreService.getUserByEmail(normalizedEmail).timeout(const Duration(seconds: 5));
        } catch (_) {}
      }

      if (user == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Account not found. Please sign up.');
        return false;
      }

      if (user.authProvider == 'google') {
        state = state.copyWith(isLoading: false, errorMessage: 'This account uses Google Sign-In.');
        return false;
      }

      final enteredHash = _hashPassword(password);
      if (user.passwordHash != enteredHash) {
        state = state.copyWith(isLoading: false, errorMessage: 'Invalid password.');
        return false;
      }

      user = user.copyWith(
        hasCompletedOnboarding: true,
        status: 'online',
        lastSeen: DateTime.now().millisecondsSinceEpoch,
      );

      await HiveService.saveUserMeta(user);
      final token = _generateSecureToken(user.id);
      await HiveService.saveAuthSession(userId: user.id, token: token);

      // Restore all Liked Songs, Playlists, and Saved Albums from Cloud
      await HiveService.syncFromCloud(user.id);

      try {
        await FirestoreService.saveUser(user).timeout(const Duration(seconds: 5));
      } catch (_) {}

      state = state.copyWith(isLoading: false, user: user, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final normalizedEmail = account.email.trim().toLowerCase();

      // 1. Check local Hive
      UserModel? user = HiveService.getUserByEmail(normalizedEmail);

      // 2. If clean install, check Cloud Firestore
      if (user == null) {
        try {
          user = await FirestoreService.getUserByEmail(normalizedEmail).timeout(const Duration(seconds: 5));
        } catch (_) {}
      }

      if (user != null) {
        user = user.copyWith(
          photoUrl: account.photoUrl ?? user.photoUrl,
          status: 'online',
          lastSeen: DateTime.now().millisecondsSinceEpoch,
          hasCompletedOnboarding: true,
        );
      } else {
        // Deterministic ID ensures persistent identity across reinstalls
        final userId = 'google_${account.id}';
        user = UserModel(
          id: userId,
          name: account.displayName ?? 'Google User',
          email: normalizedEmail,
          photoUrl: account.photoUrl,
          authProvider: 'google',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          hasCompletedOnboarding: false,
          status: 'online',
        );
      }

      await HiveService.saveUserMeta(user);
      final token = _generateSecureToken(user.id);
      await HiveService.saveAuthSession(userId: user.id, token: token);

      // Restore all Liked Songs, Playlists, and Saved Albums from Cloud
      await HiveService.syncFromCloud(user.id);

      try {
        await FirestoreService.saveUser(user).timeout(const Duration(seconds: 5));
      } catch (_) {}

      state = state.copyWith(isLoading: false, user: user, isAuthenticated: true);
      return true;
    } catch (e) {
      String message = e.toString();
      if (message.contains('ApiException: 10')) {
        message = 'Google Sign-In requires adding your SHA-1 key to Firebase Console.';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    }
  }

  Future<void> switchUser(UserModel user) async {
    final token = _generateSecureToken(user.id);
    await HiveService.saveAuthSession(userId: user.id, token: token);
    await HiveService.syncFromCloud(user.id);
    try {
      await FirestoreService.updateUserStatus(userId: user.id, status: 'online')
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
    state = state.copyWith(user: user, isAuthenticated: true);
  }

  Future<void> removeAccount(String userId) async {
    final isCurrentActive = state.user?.id == userId;

    try {
      await FirestoreService.deleteUserData(userId).timeout(const Duration(seconds: 5));
    } catch (_) {}

    await HiveService.deleteUserAccountAndData(userId);

    if (isCurrentActive) {
      final remainingUsers = HiveService.getAllUsers();
      if (remainingUsers.isNotEmpty) {
        await switchUser(remainingUsers.first);
      } else {
        await logout();
      }
    } else {
      state = state.copyWith();
    }
  }

  Future<void> logout() async {
    if (state.user != null) {
      try {
        await FirestoreService.updateUserStatus(userId: state.user!.id, status: 'offline')
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await HiveService.clearAuthSession();
    state = AuthState(isAuthenticated: false);
  }
}