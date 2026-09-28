import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_constants.dart';

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}

/// Thin wrapper over Firebase Auth (email + password).
class AuthService {
  /// Flipped by main() once Firebase.initializeApp succeeds.
  bool configured = false;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => configured ? _auth.currentUser : null;

  Future<T> _run<T>(Future<T> Function() body) async {
    if (!configured) {
      throw const AuthFailure(
        'Firebase is not configured yet. Add google-services.json (see README).',
      );
    }
    try {
      return await body();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  Future<User> signInWithEmail(String email, String password) => _run(() async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      // First admin login: create the admin account with the known credentials.
      final missing =
          e.code == 'user-not-found' || e.code == 'invalid-credential';
      final isAdminLogin =
          AppConstants.adminEmails.contains(email.trim().toLowerCase()) &&
          password == AppConstants.adminBootstrapPassword;
      if (!missing || !isAdminLogin) rethrow;
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await cred.user!.updateDisplayName('Administrator');
        return cred.user!;
      } on FirebaseAuthException {
        throw e; // account exists with a different password
      }
    }
  });

  /// Creates the Firebase Auth account (visible in Console > Authentication).
  Future<User> signUp(String email, String password, String name) =>
      _run(() async {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await cred.user!.updateDisplayName(name);
        return cred.user!;
      });

  Future<void> sendPasswordResetEmail(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> signOut() async {
    if (configured) await _auth.signOut();
  }

  String _message(FirebaseAuthException e) => switch (e.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Incorrect email or password.',
    'invalid-email' => 'That email address is not valid.',
    'user-disabled' => 'This account has been disabled.',
    'email-already-in-use' =>
      'An account with this email already exists. Please log in.',
    'weak-password' => 'Password is too weak (use 6+ characters).',
    'operation-not-allowed' =>
      'Email/Password sign-in is not enabled in Firebase Console.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'No internet connection.',
    _ => e.message ?? 'Authentication failed (${e.code}).',
  };
}
