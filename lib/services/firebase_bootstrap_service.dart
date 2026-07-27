import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseBootstrapService {
  const FirebaseBootstrapService();

  Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } on Object {
      // Guest mode remains available when Firebase cannot initialize.
      return false;
    }
  }
}
