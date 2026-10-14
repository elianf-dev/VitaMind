import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/main.dart';
import 'package:vitamind/screens/support_screen.dart';
import 'package:vitamind/services/auth_service.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/firebase_bootstrap_service.dart';
import 'package:vitamind/services/firestore_service.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/services/notification_service.dart';
import 'package:vitamind/services/sync_coordinator.dart';
import 'package:vitamind/startup_gate.dart';

/// A storage factory that throws until [failuresLeft] reaches zero.
class _FlakyStorageFactory {
  _FlakyStorageFactory({required this.failuresLeft});

  int failuresLeft;
  int calls = 0;

  Future<LocalStorageService> call() async {
    calls++;
    if (failuresLeft > 0) {
      failuresLeft--;
      throw StateError('Keystore unavailable');
    }
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    return LocalStorageService(preferences, MemoryHealthStorage());
  }
}

Future<Widget> _launchTestApp(LocalStorageService storage) async {
  return VitaMindApp(
    authService: AuthService(firebaseAvailable: false),
    firestoreService: const FirestoreService(enabled: false),
    syncCoordinator: SyncCoordinator(),
    localStorageService: storage,
    notificationService: NotificationService(),
  );
}

Widget _gate(
  _FlakyStorageFactory factory, {
  Future<void> Function()? resetLocalData,
}) {
  return StartupGate(
    storageFactory: factory.call,
    resetLocalData: resetLocalData ?? () async {},
    launchApp: _launchTestApp,
  );
}

void main() {
  testWidgets(
    'a throwing storage factory shows the recovery screen, not a blank one',
    (tester) async {
      final factory = _FlakyStorageFactory(failuresLeft: 1);

      await tester.pumpWidget(_gate(factory));
      await tester.pumpAndSettle();

      expect(factory.calls, 1);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Reset local data on this device'), findsOneWidget);
      expect(find.text('Need help now'), findsOneWidget);
      expect(find.text('Continue as guest'), findsNothing);
    },
  );

  testWidgets('Try again calls the factory again and enters the app', (
    tester,
  ) async {
    final factory = _FlakyStorageFactory(failuresLeft: 1);

    await tester.pumpWidget(_gate(factory));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(factory.calls, 2);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('a second failure keeps the recovery screen with a note', (
    tester,
  ) async {
    final factory = _FlakyStorageFactory(failuresLeft: 2);

    await tester.pumpWidget(_gate(factory));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(factory.calls, 2);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('still couldn’t open'), findsOneWidget);
  });

  testWidgets('Reset asks for confirmation first, then resets and retries', (
    tester,
  ) async {
    final factory = _FlakyStorageFactory(failuresLeft: 1);
    var resetCalls = 0;

    await tester.pumpWidget(
      _gate(factory, resetLocalData: () async => resetCalls++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset local data on this device'));
    await tester.pumpAndSettle();

    // The dialog is up and nothing has been deleted yet.
    expect(resetCalls, 0);
    expect(find.text('Reset local data?'), findsOneWidget);
    expect(
      find.textContaining(
        'moods, symptoms and journal entries can be restored from the cloud',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('conditions, medications and goals'),
      findsOneWidget,
    );

    // Cancel leaves everything alone.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(resetCalls, 0);
    expect(factory.calls, 1);

    await tester.tap(find.text('Reset local data on this device'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(resetCalls, 1);
    expect(factory.calls, 2);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('a failing reset still retries startup', (tester) async {
    final factory = _FlakyStorageFactory(failuresLeft: 1);

    await tester.pumpWidget(
      _gate(factory, resetLocalData: () async => throw StateError('no key')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset local data on this device'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();

    expect(factory.calls, 2);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('Need help now opens the support screen', (tester) async {
    final factory = _FlakyStorageFactory(failuresLeft: 1);

    await tester.pumpWidget(_gate(factory));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Need help now'));
    await tester.pumpAndSettle();

    expect(find.byType(SupportScreen), findsOneWidget);
  });

  testWidgets('a failure after storage opens also shows the recovery screen', (
    tester,
  ) async {
    final factory = _FlakyStorageFactory(failuresLeft: 0);

    await tester.pumpWidget(
      StartupGate(
        storageFactory: factory.call,
        resetLocalData: () async {},
        launchApp: (_) async => throw StateError('auth init failed'),
      ),
    );
    await tester.pumpAndSettle();

    // SEC-S4-1 / QA-S4-1: storage opened fine, so no reset is offered and
    // the wording doesn't blame the device's data.
    expect(find.text('VitaMind couldn’t start'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Need help now'), findsOneWidget);
    expect(find.text('Reset local data on this device'), findsNothing);
    expect(find.textContaining('data saved on this device'), findsNothing);
    expect(find.textContaining('Android Settings'), findsNothing);
  });

  testWidgets('a storage failure offers reset and blames local data', (
    tester,
  ) async {
    final factory = _FlakyStorageFactory(failuresLeft: 1);

    await tester.pumpWidget(_gate(factory));
    await tester.pumpAndSettle();

    expect(find.text('VitaMind couldn’t open'), findsOneWidget);
    expect(find.textContaining('data saved on this device'), findsOneWidget);
    expect(find.textContaining('Trying again may fix it.'), findsOneWidget);
    expect(find.text('Reset local data on this device'), findsOneWidget);
  });

  testWidgets('a launch failure after a storage failure drops the reset', (
    tester,
  ) async {
    final factory = _FlakyStorageFactory(failuresLeft: 1);
    var launches = 0;

    await tester.pumpWidget(
      StartupGate(
        storageFactory: factory.call,
        resetLocalData: () async {},
        launchApp: (_) async {
          launches++;
          throw StateError('notifications failed');
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reset local data on this device'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(launches, 1);
    expect(find.text('VitaMind couldn’t start'), findsOneWidget);
    expect(find.text('Reset local data on this device'), findsNothing);
  });

  testWidgets('a repeated storage failure names the Android Settings way out', (
    tester,
  ) async {
    final factory = _FlakyStorageFactory(failuresLeft: 2);

    await tester.pumpWidget(_gate(factory));
    await tester.pumpAndSettle();
    expect(find.textContaining('Android Settings'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Settings → Apps → VitaMind → Storage'),
      findsOneWidget,
    );
  });

  testWidgets('the recovery title is a heading for TalkBack', (tester) async {
    final handle = tester.ensureSemantics();
    final factory = _FlakyStorageFactory(failuresLeft: 1);

    await tester.pumpWidget(_gate(factory));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('VitaMind couldn’t open')),
      matchesSemantics(label: 'VitaMind couldn’t open', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('the reset dialog reaches both buttons at 3x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final factory = _FlakyStorageFactory(failuresLeft: 1);
    var resetCalls = 0;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 690),
          textScaler: TextScaler.linear(3),
        ),
        child: _gate(factory, resetLocalData: () async => resetCalls++),
      ),
    );
    await tester.pumpAndSettle();

    final resetButton = find.widgetWithText(
      OutlinedButton,
      'Reset local data on this device',
    );
    Future<void> openDialog() async {
      // "Need help now" sits below the reset button, so scrolling to it
      // brings the whole button on screen (the list builds lazily).
      await tester.scrollUntilVisible(
        find.text('Need help now'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(resetButton);
      await tester.pumpAndSettle();
      await tester.tap(resetButton);
      await tester.pumpAndSettle();
      expect(find.text('Reset local data?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    // Both actions are reachable and tappable at 3x.
    await openDialog();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(resetCalls, 0);

    await openDialog();
    final confirm = find.widgetWithText(FilledButton, 'Reset');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(resetCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the first frame is released once, when content is ready', (
    tester,
  ) async {
    final factory = _FlakyStorageFactory(failuresLeft: 1);
    var readyCalls = 0;

    await tester.pumpWidget(
      StartupGate(
        storageFactory: factory.call,
        resetLocalData: () async {},
        launchApp: _launchTestApp,
        onFirstContent: () => readyCalls++,
      ),
    );
    await tester.pumpAndSettle();
    expect(readyCalls, 1);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(readyCalls, 1);
  });

  for (final scale in [2.0, 3.0]) {
    testWidgets('the recovery screen fits at ${scale}x text', (tester) async {
      tester.view.physicalSize = const Size(360, 690);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final factory = _FlakyStorageFactory(failuresLeft: 1);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 690),
            textScaler: TextScaler.linear(scale),
          ),
          child: _gate(factory),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Need help now'), 100);
      expect(find.text('Need help now'), findsOneWidget);
    });
  }

  test('a Firebase init failure falls back to guest-only', () async {
    final bootstrap = FirebaseBootstrapService(
      initializeApp: () async => throw StateError('no google-services'),
    );

    expect(await bootstrap.initialize(), isFalse);
    final auth = AuthService(firebaseAvailable: false);
    await auth.initialize();
    expect(auth.isLoggedIn, isFalse);
  });
}
