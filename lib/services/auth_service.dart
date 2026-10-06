import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  AuthService({required this.firebaseAvailable});

  final bool firebaseAvailable;

  StreamSubscription<User?>? _authSubscription;
  User? _user;

  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  Future<void> initialize() async {
    if (!firebaseAvailable) {
      return;
    }

    _user = FirebaseAuth.instance.currentUser;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    if (!firebaseAvailable) {
      return 'Firebase is not configured yet. Continue as Guest still works.';
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = credential.user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return _friendlyError(
        error,
        fallback: 'Unable to log in. Please try again.',
      );
    } on Object catch (error) {
      debugPrint('VitaMind: sign-in failed: $error');
      return 'Something went wrong. Please check your connection and try again.';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    if (!firebaseAvailable) {
      return 'Firebase is not configured yet. Continue as Guest still works.';
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      _user = credential.user;
      await _user?.sendEmailVerification();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return _friendlyError(
        error,
        fallback: 'Unable to create an account. Please try again.',
      );
    } on Object catch (error) {
      debugPrint('VitaMind: sign-up failed: $error');
      return 'Something went wrong. Please check your connection and try again.';
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    if (!firebaseAvailable) {
      return 'Firebase is not configured in this build.';
    }
    if (email.trim().isEmpty) {
      return 'Enter your email address first.';
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (error) {
      return _friendlyError(
        error,
        fallback: 'Unable to send a password reset email.',
      );
    } on Object catch (error) {
      debugPrint('VitaMind: password reset email failed: $error');
      return 'Something went wrong. Please check your connection and try again.';
    }
  }

  Future<String?> resendEmailVerification() async {
    if (_user == null) {
      return 'Log in before requesting a verification email.';
    }
    if (_user!.emailVerified) {
      return null;
    }

    try {
      await _user!.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (error) {
      return _friendlyError(
        error,
        fallback: 'Unable to send a verification email.',
      );
    } on Object catch (error) {
      debugPrint('VitaMind: resend verification email failed: $error');
      return 'Something went wrong. Please check your connection and try again.';
    }
  }

  /// Confirms the signed-in user's password. Firebase only allows sensitive
  /// actions like account deletion shortly after a sign-in, so this lets the
  /// user prove it's them without signing out and back in.
  Future<String?> reauthenticate(String password) async {
    final user = _user;
    final email = user?.email;
    if (user == null || email == null) {
      return 'No signed-in account was found.';
    }
    if (password.isEmpty) {
      return 'Enter your password.';
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return null;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        return 'That password is incorrect.';
      }
      return _friendlyError(
        error,
        fallback: 'Unable to confirm your password.',
      );
    } on Object catch (error) {
      debugPrint('VitaMind: reauthentication failed: $error');
      return 'Something went wrong. Please check your connection and try again.';
    }
  }

  Future<String?> deleteAccount() async {
    if (_user == null) {
      return 'No signed-in account was found.';
    }

    try {
      await _user!.delete();
      _user = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (error) {
      return _friendlyError(error, fallback: 'Unable to delete the account.');
    } on Object catch (error) {
      debugPrint('VitaMind: account deletion failed: $error');
      return 'Something went wrong. Please check your connection and try again.';
    }
  }

  Future<void> continueAsGuest() async {
    if (firebaseAvailable && isLoggedIn) {
      await FirebaseAuth.instance.signOut();
    }
    _user = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (firebaseAvailable && isLoggedIn) {
      await FirebaseAuth.instance.signOut();
    }
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String _friendlyError(
    FirebaseAuthException error, {
    required String fallback,
  }) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Use a password with at least 6 characters.';
      case 'network-request-failed':
        return 'VitaMind could not reach Firebase. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'requires-recent-login':
        return 'For security, log out and log back in before deleting your account.';
      default:
        return error.message ?? fallback;
    }
  }
}
