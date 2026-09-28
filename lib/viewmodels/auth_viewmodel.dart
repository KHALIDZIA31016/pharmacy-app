import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../core/constants/app_constants.dart';
import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/fcm_service.dart';

class SignupDraft {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String? profession;
  final String organization;
  final String specialty;
  final String practiceType;
  final String licenseNo;
  final int? experience;

  const SignupDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.profession,
    this.organization = '',
    this.specialty = '',
    this.practiceType = '',
    this.licenseNo = '',
    this.experience,
  });
}

class AuthViewModel extends ChangeNotifier {
  final AuthService _auth;
  final UserRepository _users;
  final FcmService _fcm;

  AuthViewModel(this._auth, this._users, this._fcm);

  AppUser? user;
  bool loading = false;
  String? error;

  /// Called when a push message arrives while the app is open.
  VoidCallback? onPushReceived;

  Future<bool> _guarded(Future<void> Function() body) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await body();
      return true;
    } on AuthFailure catch (e) {
      error = e.message;
      return false;
    } catch (e) {
      error = 'Something went wrong. Please try again.';
      debugPrint('Auth error: $e');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- session

  Future<AppUser?> restoreSession() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return user = await _resolveUser(fbUser);
  }

  Future<AppUser> _resolveUser(fb.User fbUser) async {
    final email = fbUser.email ?? '';
    var profile = await _users.getById(fbUser.uid);
    final isAdmin = AppConstants.adminEmails.contains(email.toLowerCase());
    if (profile == null || (isAdmin && !profile.isAdmin)) {
      // No local profile (admin's first login, or account created elsewhere).
      profile = AppUser(
        uid: fbUser.uid,
        name:
            fbUser.displayName ??
            (isAdmin ? 'Administrator' : email.split('@').first),
        email: email,
        role: isAdmin ? UserRole.admin : UserRole.user,
        profession: isAdmin ? null : Profession.doctor,
        createdAt: DateTime.now(),
      );
      await _users.save(profile);
    }
    _startPush(profile);
    return profile;
  }

  void _startPush(AppUser u) {
    if (!_auth.configured) return;
    _fcm
        .start(u, () => onPushReceived?.call())
        .catchError((Object e) => debugPrint('FCM start failed: $e'));
  }

  Future<void> logout() async {
    final u = user;
    if (u != null && _auth.configured) await _fcm.stop(u);
    await _auth.signOut();
    user = null;
    notifyListeners();
  }

  // ----------------------------------------------------------- login / signup

  Future<bool> login(String email, String password) => _guarded(() async {
    final fbUser = await _auth.signInWithEmail(email, password);
    user = await _resolveUser(fbUser);
  });

  /// Creates the Firebase Auth account, then the local profile.
  Future<bool> signUp(SignupDraft d) => _guarded(() async {
    if (AppConstants.adminEmails.contains(d.email.trim().toLowerCase())) {
      throw const AuthFailure('This email is reserved. Use a different one.');
    }
    final fbUser = await _auth.signUp(d.email, d.password, d.name);
    final profile = AppUser(
      uid: fbUser.uid,
      name: d.name,
      email: d.email.trim(),
      phone: d.phone,
      role: d.role,
      profession: d.profession,
      organization: d.organization,
      specialty: d.specialty,
      practiceType: d.practiceType,
      licenseNo: d.licenseNo,
      experience: d.experience,
      createdAt: DateTime.now(),
    );
    await _users.save(profile);
    user = profile;
    _startPush(profile);
  });

  Future<bool> sendResetEmail(String email) =>
      _guarded(() => _auth.sendPasswordResetEmail(email));

  // ---------------------------------------------------------------- profile

  /// Saves (or clears, when [path] is null) the supplier's signature image.
  Future<void> updateSignature(String? path) async {
    final updated = path == null
        ? user!.copyWith(removeSignature: true)
        : user!.copyWith(signaturePath: path);
    await _users.save(updated);
    user = updated;
    notifyListeners();
  }

  /// Sets (or clears, when [path] is null) the profile photo.
  Future<void> updatePhoto(String? path) async {
    final updated = path == null
        ? user!.copyWith(removePhoto: true)
        : user!.copyWith(photoPath: path);
    await _users.save(updated);
    user = updated;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String organization,
    required String address,
    required String about,
  }) async {
    final updated = user!.copyWith(
      name: name,
      phone: phone,
      organization: organization,
      address: address,
      about: about,
    );
    await _users.save(updated);
    user = updated;
    notifyListeners();
  }
}
