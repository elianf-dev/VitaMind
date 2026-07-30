import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseBootstrapService {
  const FirebaseBootstrapService();

  Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } on Object catch (error) {
      debugPrint('VitaMind: Firebase failed to initialize: $error');
      // Guest mode remains available when Firebase cannot initialize.
      return false;
    }
  }
}
