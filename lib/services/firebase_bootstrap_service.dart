import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'firestore_service.dart';

class FirebaseBootstrapService {
  const FirebaseBootstrapService({this.initializeApp = _initializeDefaultApp});

  /// Starts the Firebase app. Injectable so tests can make it fail.
  final Future<void> Function() initializeApp;

  static Future<void> _initializeDefaultApp() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<bool> initialize() async {
    try {
      await initializeApp();
    } on Object catch (error) {
      debugPrint('VitaMind: Firebase failed to initialize: $error');
      // Guest mode remains available when Firebase cannot initialize.
      return false;
    }

    _turnOffFirestoreCache();
    await _clearOldFirestoreCache();
    return true;
  }

  /// No on-disk Firestore cache (C-3). This must run before any other
  /// Firestore call: the FlutterFire plugin fixes an instance's settings the
  /// first time it talks to the native SDK, including for clearPersistence.
  void _turnOffFirestoreCache() {
    try {
      FirebaseFirestore.instance.settings = FirestoreService.deviceSettings;
    } on Object catch (error) {
      debugPrint('VitaMind: could not turn off the Firestore cache: $error');
    }
  }

  /// Wipes cache files left by earlier builds, which had the cache on.
  /// Failure only logs: Firebase stays available.
  Future<void> _clearOldFirestoreCache() async {
    try {
      await FirebaseFirestore.instance.clearPersistence();
    } on Object catch (error) {
      debugPrint('VitaMind: could not clear the old Firestore cache: $error');
    }
  }
}
