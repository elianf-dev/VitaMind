import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/data/app_links.dart';
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
const _firebaseNotice =
    'With an account, your moods, symptoms, journal entries and reminder settings are stored in Google Firebase so they sync.';
const _privacyPolicy = 'Privacy Policy';
const _chdPolicy = 'Consumer Health Data Privacy Policy';

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

  test('consumer health data policy link points at the hosted page', () {
    final uri = AppLinks.consumerHealthDataPolicy;
    expect(uri.scheme, 'https');
    expect(uri.host, 'elianf-dev.github.io');
    expect(uri.path, '/VitaMind/legal/consumer-health-data.html');
    expect(AppLinks.privacyPolicy.path, '/VitaMind/legal/privacy.html');
  });

  testWidgets(
    'Privacy & Security has a separate Consumer Health Data Privacy Policy tile',
    (tester) async {
      _useTallView(tester);
      final storage = await _storage();

      await _pumpScreen(
        tester,
        PrivacySecuritySettingsScreen(
          localStorageService: storage,
          notificationService: NotificationService(),
        ),
      );

      final privacyTile = find.ancestor(
        of: find.text(_privacyPolicy),
        matching: find.byType(ListTile),
      );
      final chdTile = find.ancestor(
        of: find.text(_chdPolicy),
        matching: find.byType(ListTile),
      );
      expect(privacyTile, findsOneWidget);
      expect(chdTile, findsOneWidget);
      expect(tester.widget(privacyTile), isNot(same(tester.widget(chdTile))));
      expect(
        find.text('How we handle health data under Washington law.'),
        findsOneWidget,
      );
      expect(tester.widget<ListTile>(chdTile).onTap, isNotNull);
      // The two tiles sit directly next to each other.
      final gap =
          tester.getRect(chdTile).top - tester.getRect(privacyTile).bottom;
      expect(gap, inInclusiveRange(0, 40));
    },
  );

  testWidgets(
    'Create account shows the Firebase notice and both policy links; Login does not',
    (tester) async {
      _useTallView(tester);
      final storage = await _storage();

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
      expect(find.text(_firebaseNotice), findsNothing);

      await tester.tap(find.text('Sign up'));
      await _settle(tester);
      expect(find.text(_firebaseNotice), findsOneWidget);
      final privacyLink = find.widgetWithText(TextButton, _privacyPolicy);
      final chdLink = find.widgetWithText(TextButton, _chdPolicy);
      expect(privacyLink, findsOneWidget);
      expect(chdLink, findsOneWidget);
      expect(tester.widget<TextButton>(privacyLink).onPressed, isNotNull);
      expect(tester.widget<TextButton>(chdLink).onPressed, isNotNull);

      // Below the guest warning, above the Email field.
      final warningY = tester.getTopLeft(find.text(_guestWarning)).dy;
      final noticeY = tester.getTopLeft(find.text(_firebaseNotice)).dy;
      final linkY = tester.getTopLeft(chdLink).dy;
      final emailY = tester
          .getTopLeft(find.widgetWithText(TextField, 'Email'))
          .dy;
      expect(noticeY, greaterThan(warningY));
      expect(linkY, greaterThan(noticeY));
      expect(emailY, greaterThan(linkY));

      await tester.tap(find.text('Back'));
      await _settle(tester);
      await tester.tap(find.text('Log in'));
      await _settle(tester);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.text(_firebaseNotice), findsNothing);
      expect(find.widgetWithText(TextButton, _privacyPolicy), findsNothing);
      expect(find.widgetWithText(TextButton, _chdPolicy), findsNothing);
    },
  );

  // QA-L1-1: a launcher that throws (for example ACTIVITY_NOT_FOUND) still
  // shows the "Could not open… Visit <url>" fallback.
  group('policy links when the launcher throws (L1 fix round 1)', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');

    void mockThrowingLauncher() {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launch') {
          throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
        }
        return false;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    }

    String fallback(String name, Uri url) => 'Could not open $name. Visit $url';

    testWidgets('sign-up links show the fallback', (tester) async {
      _useTallView(tester);
      mockThrowingLauncher();
      await tester.pumpWidget(
        VitaMindApp(
          authService: AuthService(firebaseAvailable: false),
          firestoreService: const FirestoreService(enabled: false),
          syncCoordinator: SyncCoordinator(),
          localStorageService: await _storage(),
          notificationService: NotificationService(),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Sign up'));
      await _settle(tester);

      await tester.tap(find.widgetWithText(TextButton, _privacyPolicy));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.text(fallback('the privacy policy', AppLinks.privacyPolicy)),
        findsOneWidget,
      );

      ScaffoldMessenger.of(
        tester.element(find.text('Create account')),
      ).removeCurrentSnackBar();
      await _settle(tester);
      await tester.tap(find.widgetWithText(TextButton, _chdPolicy));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          fallback(
            'the Consumer Health Data Privacy Policy',
            AppLinks.consumerHealthDataPolicy,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Privacy & Security policy tiles show the fallback', (
      tester,
    ) async {
      _useTallView(tester);
      mockThrowingLauncher();
      await _pumpScreen(
        tester,
        PrivacySecuritySettingsScreen(
          localStorageService: await _storage(),
          notificationService: NotificationService(),
        ),
      );

      await tester.tap(find.text(_chdPolicy));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          fallback(
            'the Consumer Health Data Privacy Policy',
            AppLinks.consumerHealthDataPolicy,
          ),
        ),
        findsOneWidget,
      );

      ScaffoldMessenger.of(
        tester.element(find.text(_chdPolicy)),
      ).removeCurrentSnackBar();
      await _settle(tester);
      await tester.tap(find.text(_privacyPolicy));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(
        find.text(fallback('the privacy policy', AppLinks.privacyPolicy)),
        findsOneWidget,
      );
    });
  });
}
