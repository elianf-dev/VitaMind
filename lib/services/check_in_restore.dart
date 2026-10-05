import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// Schedules the active profile's check-in reminders, preferring the
/// signed-in user's cloud copy. Call after the profile changes (app start,
/// login, guest entry) so reminders never carry over from another account.
Future<void> restoreCheckInsForActiveProfile({
  required AuthService authService,
  required FirestoreService firestoreService,
  required LocalStorageService localStorageService,
  required NotificationService notificationService,
}) async {
  var checkInSettings = await localStorageService.loadCheckInSettings();
  final userId = authService.userId;
  if (userId != null && firestoreService.enabled) {
    try {
      checkInSettings =
          await firestoreService.loadCheckInSettings(userId) ?? checkInSettings;
      await localStorageService.saveCheckInSettings(checkInSettings);
    } on Object catch (error) {
      debugPrint('VitaMind: failed to load cloud check-in settings: $error');
      // Keep the local schedule usable if Firestore is unreachable.
    }
  }

  if (await localStorageService.loadOnboardingCompleted()) {
    await notificationService.applyCheckInSettings(checkInSettings);
  } else {
    // Onboarding schedules reminders itself once this profile finishes it.
    await notificationService.cancelAllCheckIns();
  }
}
