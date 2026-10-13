import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/sync_coordinator.dart';
import '../privacy_security_settings_screen.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({
    super.key,
    required this.authService,
    required this.syncCoordinator,
    required this.localStorageService,
    required this.notificationService,
    required this.firestoreService,
  });

  final AuthService authService;
  final SyncCoordinator syncCoordinator;
  final LocalStorageService localStorageService;
  final NotificationService notificationService;
  final FirestoreService firestoreService;

  @override
  Widget build(BuildContext context) {
    return PrivacySecuritySettingsScreen(
      authService: authService,
      syncCoordinator: syncCoordinator,
      localStorageService: localStorageService,
      notificationService: notificationService,
      firestoreService: firestoreService,
      isOnboarding: true,
    );
  }
}
