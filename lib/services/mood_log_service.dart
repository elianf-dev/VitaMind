import 'package:flutter/foundation.dart';

import '../models/mood_entry.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';

/// Saves a mood entry locally, then to Firestore for signed-in users.
/// Returns false when the entry was kept locally but cloud sync failed.
Future<bool> recordMoodEntry({
  required MoodEntry entry,
  required AuthService authService,
  required FirestoreService firestoreService,
  required LocalStorageService localStorageService,
}) async {
  await localStorageService.addMoodEntry(entry);

  final userId = authService.userId;
  if (userId == null || !firestoreService.enabled) {
    return true;
  }

  try {
    await firestoreService.saveMoodEntry(userId, entry);
    return true;
  } on Object catch (error) {
    debugPrint('VitaMind: failed to save mood entry to cloud: $error');
    return false;
  }
}
