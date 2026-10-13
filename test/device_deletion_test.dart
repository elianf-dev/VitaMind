import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/models/check_in_settings.dart';
import 'package:vitamind/models/diagnosed_condition.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/models/privacy_security_settings.dart';
import 'package:vitamind/screens/privacy_security_settings_screen.dart';
import 'package:vitamind/screens/profile_screen.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/services/sync_coordinator.dart';
import 'package:vitamind/theme/app_colors.dart';

import 'support/counting_fakes.dart';

const _deviceDeleteCopy =
    'This deletes all VitaMind moods, symptoms, journals, conditions, '
    'medications, goals, privacy choices and reminders on this device, for '
    'every profile used here, including guest entries. This can’t be undone, '
    'and you’ll see the welcome setup again.';
const _deviceDeleteSyncedCopy =
    'Entries already synced to an account stay in the cloud and come back '
    'the next time you open VitaMind signed in. To remove those, delete the '
    'account.';

MoodEntry _mood(String id) => MoodEntry(
  id: id,
  emoji: '🙂',
  label: 'Good',
  notes: '',
  createdAt: DateTime(2026, 10, 1),
);

/// Saves moods, conditions, medications, common symptoms, onboarding,
/// privacy and check-in settings for the active profile of [storage].
Future<void> _seedProfile(LocalStorageService storage, String id) async {
  await storage.saveMoodEntries([_mood('mood-$id')]);
  await storage.saveDiagnosedConditions([
    DiagnosedCondition.create(name: 'Asthma'),
  ]);
  await storage.saveMedications(['Med $id']);
  await storage.saveCommonSymptoms(['Headache']);
  await storage.saveOnboardingCompleted(true);
  await storage.savePrivacySettings(
    PrivacySecuritySettings.defaults().copyWith(
      hideSensitiveHealthDetails: true,
    ),
  );
  await storage.saveCheckInSettings(
    CheckInSettings.defaults().copyWith(enabled: false),
  );
}

Future<void> _expectProfileEmpty(LocalStorageService storage) async {
  expect(await storage.loadMoodEntries(), isEmpty);
  expect(await storage.loadSymptomEntries(), isEmpty);
  expect(await storage.loadJournalEntries(), isEmpty);
  expect(await storage.loadDiagnosedConditions(), isEmpty);
  expect(await storage.loadMedications(), isEmpty);
  expect(await storage.loadCommonSymptoms(), isEmpty);
  expect(await storage.loadWellnessGoals(), isEmpty);
  expect(await storage.loadHealthLogEntries(), isEmpty);
  expect(await storage.loadOnboardingCompleted(), isFalse);
  expect(
    (await storage.loadPrivacySettings()).hideSensitiveHealthDetails,
    isFalse,
  );
  expect((await storage.loadCheckInSettings()).enabled, isTrue);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('LocalStorageService device wipe', () {
    test('clearAllLocalHealthData removes every profile, keeps the guest '
        'session flag and other apps\' keys', () async {
      SharedPreferences.setMockInitialValues({
        // Legacy unscoped guest keys from before profiles were scoped.
        'vitamind.mood_entries':
            '[{"id":"legacy","emoji":"🙂","label":"Good","notes":"",'
            '"createdAt":"2026-09-01T00:00:00.000"}]',
        'vitamind.ai_health_logs': '[]',
        'vitamind.onboarding_completed': true,
        // An unmigrated plain-preferences copy for another uid.
        'vitamind.journal_entries.user-c': '[]',
        'vitamind.guest_session': true,
        'other_app_key': 'keep me',
      });
      final preferences = await SharedPreferences.getInstance();
      final health = MemoryHealthStorage();
      final storage = LocalStorageService(preferences, health);

      for (final profile in ['user-a', 'user-b', null]) {
        storage.setProfileId(profile);
        await _seedProfile(storage, profile ?? 'guest');
      }
      expect(health.read('vitamind.mood_entries.user-a'), isNotNull);

      storage.setProfileId('user-a');
      await storage.clearAllLocalHealthData();

      expect(preferences.getKeys(), {
        'vitamind.guest_session',
        'other_app_key',
      });
      expect(preferences.getString('other_app_key'), 'keep me');
      for (final profile in ['user-a', 'user-b', 'user-c', null]) {
        storage.setProfileId(profile);
        await _expectProfileEmpty(storage);
      }
      for (final key in [
        'vitamind.mood_entries.user-a',
        'vitamind.mood_entries.user-b',
        'vitamind.mood_entries.guest',
        'vitamind.medications.guest',
      ]) {
        expect(health.read(key), isNull, reason: key);
      }
    });

    test(
      'clearLocalHealthData still clears only the current profile',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorageService(
          await SharedPreferences.getInstance(),
          MemoryHealthStorage(),
        );
        for (final profile in ['user-a', 'user-b', null]) {
          storage.setProfileId(profile);
          await _seedProfile(storage, profile ?? 'guest');
        }

        storage.setProfileId('user-a');
        await storage.clearLocalHealthData();

        await _expectProfileEmpty(storage);
        storage.setProfileId('user-b');
        expect((await storage.loadMoodEntries()).single.id, 'mood-user-b');
        expect(await storage.loadOnboardingCompleted(), isTrue);
        storage.setProfileId(null);
        expect((await storage.loadMoodEntries()).single.id, 'mood-guest');
        expect(await storage.loadMedications(), ['Med guest']);
      },
    );

    for (final throwing in [false, true]) {
      test(
        'SEC-L2-2: both wipes compact the encrypted store'
        '${throwing ? ', and a failing compact is only logged' : ''}',
        () async {
          SharedPreferences.setMockInitialValues({});
          final health = CountingHealthStorage()..throwOnCompact = throwing;
          final storage = LocalStorageService(
            await SharedPreferences.getInstance(),
            health,
          );
          storage.setProfileId('user-a');
          await _seedProfile(storage, 'user-a');

          await storage.clearLocalHealthData();
          expect(health.compactCalls, 1);
          await _expectProfileEmpty(storage);

          await _seedProfile(storage, 'user-a');
          await storage.clearAllLocalHealthData();
          expect(health.compactCalls, 2);
          await _expectProfileEmpty(storage);
        },
      );
    }

    test('MemoryHealthStorage.clear removes every value', () async {
      final health = MemoryHealthStorage();
      await health.write('a', '1');
      await health.write('b', '2');
      await health.clear();
      expect(health.read('a'), isNull);
      expect(health.read('b'), isNull);
    });
  });

  group('Delete Data From This Device', () {
    Future<(CountingLocalStorageService, CountingFirestoreService)> pump(
      WidgetTester tester, {
      bool throwOnCacheClear = false,
      String? signedInUid,
      SyncCoordinator? syncCoordinator,
      CountingFirestoreService? firestoreService,
      CountingLocalStorageService? localStorage,
    }) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final storage =
          localStorage ??
          await () async {
            SharedPreferences.setMockInitialValues({});
            final created = CountingLocalStorageService(
              await SharedPreferences.getInstance(),
              MemoryHealthStorage(),
            );
            created.setProfileId(signedInUid);
            await _seedProfile(created, signedInUid ?? 'guest');
            return created;
          }();
      final firestore = (firestoreService ?? CountingFirestoreService())
        ..throwOnClearDeviceCache = throwOnCacheClear;

      await tester.pumpWidget(
        MaterialApp(
          home: PrivacySecuritySettingsScreen(
            authService: FakeSignedInAuth(signedInUid),
            syncCoordinator: syncCoordinator ?? SyncCoordinator(),
            localStorageService: storage,
            notificationService: QuietNotificationService(),
            firestoreService: firestore,
          ),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Delete Data From This Device'));
      await _settle(tester);
      return (storage, firestore);
    }

    testWidgets('the dialog explains it wipes every profile on the device', (
      tester,
    ) async {
      final (storage, firestore) = await pump(tester);

      expect(find.text('Delete local VitaMind data?'), findsOneWidget);
      expect(find.text(_deviceDeleteCopy), findsOneWidget);
      expect(find.text(_deviceDeleteSyncedCopy), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await _settle(tester);
      expect(storage.clearAllCalls, 0);
      expect(firestore.clearDeviceCacheCalls, 0);
    });

    testWidgets('confirming wipes all profiles and the Firestore cache once', (
      tester,
    ) async {
      final (storage, firestore) = await pump(tester);

      await tester.tap(find.text('Delete From Device'));
      await _settle(tester);

      expect(storage.clearAllCalls, 1);
      expect(storage.clearProfileCalls, 0);
      expect(firestore.clearDeviceCacheCalls, 1);
      expect(await storage.loadMoodEntries(), isEmpty);
      expect(
        find.text('VitaMind data deleted from this device'),
        findsOneWidget,
      );
    });

    testWidgets('a failing cache clear still finishes the wipe', (
      tester,
    ) async {
      final (storage, firestore) = await pump(tester, throwOnCacheClear: true);

      await tester.tap(find.text('Delete From Device'));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(storage.clearAllCalls, 1);
      expect(firestore.clearDeviceCacheCalls, 1);
      expect(
        find.text('VitaMind data deleted from this device'),
        findsOneWidget,
      );
    });

    testWidgets('DES-L2-2: the confirm button uses the destructive color', (
      tester,
    ) async {
      await pump(tester);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete From Device'),
      );
      final style = button.style!;
      expect(style.backgroundColor!.resolve({}), AppColors.error);
      expect(style.foregroundColor!.resolve({}), Colors.white);
    });

    testWidgets('SEC-L2-1: a signed-in wipe waits for a running sync, which '
        'then writes nothing back', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = CountingLocalStorageService(
        await SharedPreferences.getInstance(),
        MemoryHealthStorage(),
      );
      storage.setProfileId('user-a');
      await storage.saveMoodEntries([_mood('a-local')]);
      final firestore = CountingFirestoreService();
      firestore.moods['user-a'] = [_mood('a-cloud')];
      final sync = SyncCoordinator();
      final gate = Completer<void>();

      // A slow first mood sync for user-a is still running.
      firestore.readGate = gate.future;
      final pending = sync.loadMoodEntries(
        userId: 'user-a',
        firestoreService: firestore,
        localStorageService: storage,
      );

      await pump(
        tester,
        signedInUid: 'user-a',
        syncCoordinator: sync,
        firestoreService: firestore,
        localStorage: storage,
      );
      await tester.tap(find.text('Delete From Device'));
      await _settle(tester);
      expect(storage.clearAllCalls, 0, reason: 'waits for the running sync');

      gate.complete();
      await pending;
      await _settle(tester);

      expect(storage.clearAllCalls, 1);
      expect(await storage.loadMoodEntries(), isEmpty, reason: 'no write-back');
      expect(firestore.writesOf('moods'), 0, reason: 'no backfill upload');
      expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
      expect(firestore.clearDeviceCacheCalls, 1);
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('DES-L2-1: at ${scale}x text on 360x690 the whole dialog '
          'scrolls and both buttons can be tapped', (tester) async {
        for (final button in ['Cancel', 'Delete From Device']) {
          tester.view.physicalSize = const Size(1080, 2070);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          SharedPreferences.setMockInitialValues({});
          final storage = CountingLocalStorageService(
            await SharedPreferences.getInstance(),
            MemoryHealthStorage(),
          );
          final firestore = CountingFirestoreService();

          await tester.pumpWidget(
            MaterialApp(
              home: PrivacySecuritySettingsScreen(
                authService: FakeSignedInAuth(null),
                syncCoordinator: SyncCoordinator(),
                localStorageService: storage,
                notificationService: QuietNotificationService(),
                firestoreService: firestore,
              ),
            ),
          );
          await _settle(tester);
          final openButton = find.text('Delete Data From This Device');
          await tester.scrollUntilVisible(
            openButton,
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(openButton);
          await tester.pump();
          await tester.tap(openButton);
          await _settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.byType(AlertDialog), findsOneWidget);

          final dialogScroll = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Scrollable),
          );

          // A paragraph can be taller than the dialog at large text, so
          // check its first and last lines: the point is inside the text
          // and a tap there lands in the dialog's scroll view (on screen,
          // not covered). Text only hit-tests on glyphs, so the scroll
          // view stands in for it.
          bool hits(Finder text, Offset point) {
            if (!tester.getRect(text).contains(point)) {
              return false;
            }
            final inScrollView = <Object>{};
            void collect(Element element) {
              final renderObject = element.renderObject;
              if (renderObject != null) {
                inScrollView.add(renderObject);
              }
              element.visitChildren(collect);
            }

            collect(dialogScroll.evaluate().single);
            return tester
                .hitTestOnBinding(point)
                .path
                .any((entry) => inScrollView.contains(entry.target));
          }

          expect(dialogScroll, findsOneWidget);
          final position = tester.state<ScrollableState>(dialogScroll).position;
          expect(
            position.maxScrollExtent,
            greaterThan(0),
            reason: 'the body is longer than the dialog at ${scale}x',
          );

          // The title scrolls with the body, so at 3x it can fill the view
          // at offset 0; bring the body's start to the top instead.
          final first = find.text(_deviceDeleteCopy);
          await tester.ensureVisible(first);
          await tester.pump();
          expect(
            hits(first, tester.getRect(first).topCenter + const Offset(0, 4)),
            isTrue,
            reason: 'start of the body is reachable',
          );

          final last = find.text(_deviceDeleteSyncedCopy);
          position.jumpTo(position.maxScrollExtent);
          await tester.pump();
          expect(
            hits(last, tester.getRect(last).bottomCenter + const Offset(0, -4)),
            isTrue,
            reason: 'the "delete the account." line is reachable',
          );
          expect(find.text(button).hitTestable(), findsOneWidget);

          await tester.tap(find.text(button));
          await _settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.byType(AlertDialog), findsNothing);
          final confirmed = button == 'Delete From Device';
          expect(storage.clearAllCalls, confirmed ? 1 : 0, reason: button);
        }
      });
    }
  });

  group('Profile clears the Firestore cache', () {
    Future<
      (
        CountingLocalStorageService,
        CountingFirestoreService,
        FakeSignedInAuth,
        SyncCoordinator,
      )
    >
    pump(WidgetTester tester, {bool throwOnCacheClear = false}) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final storage = CountingLocalStorageService(
        await SharedPreferences.getInstance(),
        MemoryHealthStorage(),
      );
      storage.setProfileId('user-a');
      final auth = FakeSignedInAuth('user-a');
      final firestore = CountingFirestoreService()
        ..throwOnClearDeviceCache = throwOnCacheClear;
      final sync = SyncCoordinator();

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/profile',
          routes: {
            '/': (context) => const Scaffold(body: Text('Welcome route')),
            '/profile': (context) => Scaffold(
              body: ProfileScreen(
                authService: auth,
                firestoreService: firestore,
                localStorageService: storage,
                notificationService: QuietNotificationService(),
                syncCoordinator: sync,
              ),
            ),
          },
        ),
      );
      await _settle(tester);
      return (storage, firestore, auth, sync);
    }

    Future<void> deleteAccount(WidgetTester tester) async {
      await tester.tap(find.text('Delete Account'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'secret');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete Account'));
      await _settle(tester);
    }

    for (final throwing in [false, true]) {
      final suffix = throwing ? ' even when the cache clear fails' : '';

      testWidgets('Logout clears the cache once and returns to /$suffix', (
        tester,
      ) async {
        final (_, firestore, auth, _) = await pump(
          tester,
          throwOnCacheClear: throwing,
        );

        await tester.tap(find.text('Logout'));
        await _settle(tester);

        expect(tester.takeException(), isNull);
        expect(auth.uid, isNull);
        expect(firestore.clearDeviceCacheCalls, 1);
        expect(find.text('Welcome route'), findsOneWidget);
      });

      testWidgets('account deletion clears the cache once, after the cloud '
          'wipe, and keeps the per-profile local clear$suffix', (tester) async {
        final (storage, firestore, auth, sync) = await pump(
          tester,
          throwOnCacheClear: throwing,
        );

        await deleteAccount(tester);

        expect(tester.takeException(), isNull);
        expect(auth.uid, isNull);
        expect(firestore.events, ['deleteUserData', 'clearDeviceCache']);
        expect(storage.clearProfileCalls, 1);
        expect(storage.clearAllCalls, 0, reason: 'deletion is per-account');
        expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
        expect(find.text('Welcome route'), findsOneWidget);
      });
    }
  });

  group('Privacy & Security at large text (QA-L1-2)', () {
    for (final scale in [2.0, 3.0]) {
      testWidgets('renders at ${scale}x text on a 360x690 phone', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1080, 2070);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          MaterialApp(
            home: PrivacySecuritySettingsScreen(
              authService: FakeSignedInAuth(null),
              syncCoordinator: SyncCoordinator(),
              localStorageService: LocalStorageService(
                await SharedPreferences.getInstance(),
                MemoryHealthStorage(),
              ),
              notificationService: QuietNotificationService(),
              firestoreService: CountingFirestoreService(),
            ),
          ),
        );
        await _settle(tester);
        expect(tester.takeException(), isNull);

        final list = find.byType(Scrollable).first;
        final seen = <String>{};
        for (var i = 0; i < 40; i++) {
          for (final title in [
            'App lock',
            'Biometric unlock',
            'Data export',
            'Consumer Health Data Privacy Policy',
          ]) {
            final tile = find.ancestor(
              of: find.text(title),
              matching: find.byType(ListTile),
            );
            if (tile.evaluate().isEmpty) {
              continue;
            }
            seen.add(title);
            if (title != 'Consumer Health Data Privacy Policy') {
              expect(
                find.descendant(
                  of: tile,
                  matching: find.textContaining('Not available'),
                ),
                findsOneWidget,
                reason: '$title still says Not available',
              );
            }
          }
          await tester.drag(list, const Offset(0, -250));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'scroll step $i');
        }
        expect(seen, {
          'App lock',
          'Biometric unlock',
          'Data export',
          'Consumer Health Data Privacy Policy',
        });
      });
    }

    testWidgets('unavailable tiles stay not tappable', (tester) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          home: PrivacySecuritySettingsScreen(
            authService: FakeSignedInAuth(null),
            syncCoordinator: SyncCoordinator(),
            localStorageService: LocalStorageService(
              await SharedPreferences.getInstance(),
              MemoryHealthStorage(),
            ),
            notificationService: QuietNotificationService(),
            firestoreService: CountingFirestoreService(),
          ),
        ),
      );
      await _settle(tester);
      for (final title in ['App lock', 'Biometric unlock']) {
        final tile = tester.widget<ListTile>(
          find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
        );
        expect(tile.onTap, isNull, reason: title);
      }
    });
  });
}
