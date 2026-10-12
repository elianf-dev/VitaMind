import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/main.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/screens/profile_screen.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/services/notification_service.dart';
import 'package:vitamind/services/sync_coordinator.dart';

import 'support/counting_fakes.dart';

// Some screens keep a progress indicator spinning, so pumpAndSettle never
// returns; advance a fixed amount of time instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.text(tab).last);
  await _settle(tester);
}

void main() {
  testWidgets('signed-in session: each collection is read once, and a '
      'one-tap mood log does one write and zero reads', (tester) async {
    // Tall enough that Insights builds its mood trend card.
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService(
      await SharedPreferences.getInstance(),
      MemoryHealthStorage(),
    );
    storage.setProfileId('user-a');
    final auth = FakeSignedInAuth('user-a');
    final firestore = CountingFirestoreService();
    final sync = SyncCoordinator();

    await tester.pumpWidget(
      VitaMindApp(
        authService: auth,
        firestoreService: firestore,
        syncCoordinator: sync,
        localStorageService: storage,
        notificationService: NotificationService(),
        onboardingCompleted: true,
      ),
    );
    await _settle(tester);

    // Cold start: the shell builds every tab once.
    expect(firestore.readsOf('moods'), 1);
    expect(firestore.readsOf('journals'), 1);

    // Moving between tabs and reopening Symptoms does not read again.
    for (final tab in ['Mood', 'Journal', 'Insights', 'Home', 'Mood']) {
      await _openTab(tester, tab);
    }
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    for (var i = 0; i < 3; i++) {
      navigator.pushNamed('/symptoms');
      await _settle(tester);
      navigator.pop();
      await _settle(tester);
    }
    expect(firestore.readsOf('moods'), 1);
    expect(firestore.readsOf('journals'), 1);
    expect(firestore.readsOf('symptoms'), 1);

    // One-tap mood log from Home.
    await _openTab(tester, 'Home');
    firestore.resetCounts();
    await tester.tap(find.bySemanticsLabel('Log mood: Low'));
    await _settle(tester);

    expect(firestore.totalReads, 0);
    expect(firestore.writesOf('moods'), 1);
    expect(firestore.moods['user-a']!.single.label, 'Low');

    // The entry shows on the Mood tab and in Insights right away.
    await _openTab(tester, 'Mood');
    expect(find.text('Low'), findsWidgets);
    expect(find.text('Recent mood entries'), findsOneWidget);
    await _openTab(tester, 'Insights');
    expect(find.textContaining('1 check-in on 1 day'), findsOneWidget);
    expect(firestore.totalReads, 0);

    // Logging out clears this user's guard.
    expect(sync.hasSynced('user-a', SyncCollection.moods), isTrue);
    await _openTab(tester, 'Profile');
    await tester.scrollUntilVisible(find.text('Logout'), 200);
    await tester.tap(find.text('Logout'));
    // Logout first cancels reminders through a platform channel, which only
    // answers in real time.
    for (var i = 0; i < 50 && auth.uid != null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(auth.uid, isNull);
    await _settle(tester);
    expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
    expect(sync.hasSynced('user-a', SyncCollection.journals), isFalse);
  });

  testWidgets('SEC-S2-2: account deletion waits for a running sync before '
      'wiping the cloud, and nothing is re-uploaded', (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService(
      await SharedPreferences.getInstance(),
      MemoryHealthStorage(),
    );
    storage.setProfileId('user-a');
    await storage.saveMoodEntries([
      MoodEntry(
        id: 'a-local',
        emoji: '🙂',
        label: 'Good',
        notes: '',
        createdAt: DateTime(2026, 10, 1),
      ),
    ]);
    final auth = FakeSignedInAuth('user-a');
    final firestore = CountingFirestoreService();
    final sync = SyncCoordinator();
    final gate = Completer<void>();
    var deleteCalls = 0;
    firestore.onDeleteUserData = (_) => deleteCalls++;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            authService: auth,
            firestoreService: firestore,
            localStorageService: storage,
            notificationService: NotificationService(),
            syncCoordinator: sync,
          ),
        ),
      ),
    );
    await _settle(tester);

    // A slow first mood sync is still running (cloud empty, one local-only
    // entry, so it would backfill if it finished normally).
    firestore.readGate = gate.future;
    final pending = sync.loadMoodEntries(
      userId: 'user-a',
      firestoreService: firestore,
      localStorageService: storage,
    );
    await tester.pump();

    await tester.tap(find.text('Delete Account'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete Account'));
    await _settle(tester);
    expect(deleteCalls, 0, reason: 'waits for the running sync first');

    gate.complete();
    await pending;
    await _settle(tester);
    expect(deleteCalls, 1);
    expect(firestore.writesOf('moods'), 0, reason: 'no re-upload');
    expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
  });
}
