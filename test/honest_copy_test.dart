import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/main.dart';
import 'package:vitamind/screens/onboarding/diagnosed_illnesses_screen.dart';
import 'package:vitamind/screens/onboarding/onboarding_summary_screen.dart';
import 'package:vitamind/screens/privacy_security_settings_screen.dart';
import 'package:vitamind/screens/profile_screen.dart';
import 'package:vitamind/screens/wellness_goals_screen.dart';
import 'package:vitamind/services/auth_service.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/firestore_service.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/services/notification_service.dart';
import 'package:vitamind/services/sync_coordinator.dart';

const _localOnlyNote = 'Stored on this device only.';
const _guestWarning =
    "Used VitaMind as a guest? Those entries stay on this device and won't move to your new account.";

Future<LocalStorageService> _storage() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorageService(
    await SharedPreferences.getInstance(),
    MemoryHealthStorage(),
  );
}

// A tall phone so list content below the fold is built.
void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 8000);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

// Some screens keep a progress indicator spinning, so pumpAndSettle never
// returns; advance a fixed amount of time instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(home: screen));
  await _settle(tester);
}

void _expectNoAiOrPlusWording() {
  expect(find.textContaining(RegExp(r'\bAI\b')), findsNothing);
  expect(find.textContaining('Plus'), findsNothing);
}

void main() {
  testWidgets(
    'Profile, Privacy & Security and onboarding summary have no AI or Plus wording',
    (tester) async {
      _useTallView(tester);
      final storage = await _storage();
      final notifications = NotificationService();

      await _pumpScreen(
        tester,
        ProfileScreen(
          authService: AuthService(firebaseAvailable: false),
          firestoreService: const FirestoreService(enabled: false),
          syncCoordinator: SyncCoordinator(),
          localStorageService: storage,
          notificationService: notifications,
        ),
      );
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(
        find.text('Local data controls and privacy policy'),
        findsOneWidget,
      );
      expect(find.text('Future AI Consent'), findsNothing);
      expect(find.text('VitaMind Plus'), findsNothing);
      expect(find.text('Plan'), findsNothing);
      _expectNoAiOrPlusWording();

      await _pumpScreen(
        tester,
        PrivacySecuritySettingsScreen(
          localStorageService: storage,
          notificationService: notifications,
        ),
      );
      expect(find.text('Gentle daily check-ins'), findsOneWidget);
      expect(find.text('Consent to future AI features'), findsNothing);
      _expectNoAiOrPlusWording();

      await _pumpScreen(
        tester,
        OnboardingSummaryScreen(
          localStorageService: storage,
          notificationService: notifications,
        ),
      );
      expect(find.text('Check-ins'), findsOneWidget);
      _expectNoAiOrPlusWording();
    },
  );

  testWidgets(
    'conditions and goals note local-only storage, and sign-up warns guests',
    (tester) async {
      _useTallView(tester);
      final storage = await _storage();

      await _pumpScreen(
        tester,
        DiagnosedIllnessesScreen(localStorageService: storage),
      );
      expect(find.text(_localOnlyNote), findsOneWidget);

      await _pumpScreen(
        tester,
        WellnessGoalsScreen(localStorageService: storage),
      );
      expect(find.text(_localOnlyNote), findsOneWidget);

      await tester.pumpWidget(
        VitaMindApp(
          authService: AuthService(firebaseAvailable: false),
          firestoreService: const FirestoreService(enabled: false),
          syncCoordinator: SyncCoordinator(),
          localStorageService: storage,
          notificationService: NotificationService(),
        ),
      );
      await _settle(tester);
      expect(find.text(_guestWarning), findsNothing);

      await tester.tap(find.text('Sign up'));
      await _settle(tester);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text(_guestWarning), findsOneWidget);

      await tester.tap(find.text('Back'));
      await _settle(tester);
      await tester.tap(find.text('Log in'));
      await _settle(tester);
      expect(find.text(_guestWarning), findsNothing);
    },
  );
}
