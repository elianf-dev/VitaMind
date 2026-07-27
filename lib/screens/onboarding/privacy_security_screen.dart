import 'package:flutter/material.dart';

import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../privacy_security_settings_screen.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({
    super.key,
    required this.localStorageService,
    required this.notificationService,
  });

  final LocalStorageService localStorageService;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return PrivacySecuritySettingsScreen(
      localStorageService: localStorageService,
      notificationService: notificationService,
      isOnboarding: true,
    );
  }
}
