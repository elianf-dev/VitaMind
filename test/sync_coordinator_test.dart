import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/models/journal_entry.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/models/symptom_entry.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/firestore_service.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/services/sync_coordinator.dart';

import 'support/counting_fakes.dart';

/// Local storage that runs [onSecondMoodLoad] inside its second mood read,
/// which is the coordinator's re-read just before the merge.
class _HookedStorage extends LocalStorageService {
  _HookedStorage(super.preferences, super.healthStorage);

  int moodLoads = 0;
  void Function()? onSecondMoodLoad;

  @override
  Future<List<MoodEntry>> loadMoodEntries() {
    moodLoads++;
    if (moodLoads == 2) {
      onSecondMoodLoad?.call();
    }
    return super.loadMoodEntries();
  }
}

Future<LocalStorageService> _storage() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorageService(
    await SharedPreferences.getInstance(),
    MemoryHealthStorage(),
  );
}

MoodEntry _mood(String id, {int minutesAgo = 0}) => MoodEntry(
  id: id,
  emoji: '🙂',
  label: 'Good',
  notes: '',
  createdAt: DateTime(2026, 10, 1).subtract(Duration(minutes: minutesAgo)),
);

void main() {
  late LocalStorageService storage;
  late CountingFirestoreService firestore;
  late SyncCoordinator sync;

  setUp(() async {
    storage = await _storage();
    storage.setProfileId('user-a');
    firestore = CountingFirestoreService();
    sync = SyncCoordinator();
  });

  Future<List<MoodEntry>> loadMoods(String? uid) => sync.loadMoodEntries(
    userId: uid,
    firestoreService: firestore,
    localStorageService: storage,
  );

  test('repeated loads in a session query each collection once', () async {
    for (var i = 0; i < 4; i++) {
      await loadMoods('user-a');
      await sync.loadJournalEntries(
        userId: 'user-a',
        firestoreService: firestore,
        localStorageService: storage,
      );
      await sync.loadSymptomEntries(
        userId: 'user-a',
        firestoreService: firestore,
        localStorageService: storage,
      );
    }

    expect(firestore.readsOf('moods'), 1);
    expect(firestore.readsOf('journals'), 1);
    expect(firestore.readsOf('symptoms'), 1);
    expect(sync.hasSynced('user-a', SyncCollection.moods), isTrue);
  });

  test('concurrent loads of the same collection share one query', () async {
    await Future.wait([loadMoods('user-a'), loadMoods('user-a')]);
    expect(firestore.readsOf('moods'), 1);
  });

  test('the first load merges the cloud copy and backfills local-only '
      'entries; later loads come from local storage', () async {
    firestore.moods['user-a'] = [_mood('cloud-1', minutesAgo: 5)];
    await storage.saveMoodEntries([_mood('local-1')]);

    final first = await loadMoods('user-a');
    expect(first.map((e) => e.id), ['local-1', 'cloud-1']);
    expect(firestore.writesOf('moods'), 1, reason: 'backfill local-1');
    expect(
      firestore.moods['user-a']!.map((e) => e.id),
      containsAll(['cloud-1', 'local-1']),
    );

    // A write after the sync goes to local storage; the next load shows it
    // without another cloud read.
    await storage.addMoodEntry(_mood('new-1', minutesAgo: -5));
    final second = await loadMoods('user-a');
    expect(second.map((e) => e.id), ['new-1', 'local-1', 'cloud-1']);
    expect(firestore.readsOf('moods'), 1);
  });

  test('a failed sync is not marked done, so the next load retries', () async {
    firestore.throwOnRead = true;
    await storage.saveMoodEntries([_mood('local-1')]);

    final offline = await loadMoods('user-a');
    expect(offline.single.id, 'local-1', reason: 'works from local data');
    expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);

    firestore.throwOnRead = false;
    await loadMoods('user-a');
    expect(firestore.readsOf('moods'), 2);
    expect(sync.hasSynced('user-a', SyncCollection.moods), isTrue);

    await loadMoods('user-a');
    expect(firestore.readsOf('moods'), 2);
  });

  test('guests and a disabled Firestore never touch the cloud', () async {
    await loadMoods(null);
    await sync.loadMoodEntries(
      userId: 'user-a',
      firestoreService: const FirestoreService(enabled: false),
      localStorageService: storage,
    );
    expect(firestore.totalReads, 0);
    expect(firestore.writes, isEmpty);
  });

  test('guards are per uid and cleared on sign-out', () async {
    await loadMoods('user-a');
    expect(firestore.readsOf('moods'), 1);

    // A different user starts fresh and never sees user A's entries.
    sync.clearUser('user-a');
    storage.setProfileId('user-b');
    firestore.moods['user-a'] = [_mood('a-only')];
    final userB = await loadMoods('user-b');
    expect(firestore.readsOf('moods'), 2);
    expect(userB.map((e) => e.id), isNot(contains('a-only')));
    expect(firestore.moods['user-b'] ?? const [], isEmpty);

    // User A was cleared, so signing back in as A reads again.
    storage.setProfileId('user-a');
    expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
    await loadMoods('user-a');
    expect(firestore.readsOf('moods'), 3);
    expect(sync.hasSynced('user-b', SyncCollection.moods), isTrue);
  });

  test('a sync that finishes after its user was cleared writes nothing '
      'locally and is not marked done', () async {
    firestore.moods['user-a'] = [_mood('a-cloud')];
    final pending = loadMoods('user-a');
    sync.clearUser('user-a');
    storage.setProfileId('user-b');
    await pending;

    expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
    expect(await storage.loadMoodEntries(), isEmpty);
  });

  test('journal and symptom syncs use the same guard', () async {
    firestore.journals['user-a'] = [
      JournalEntry(id: 'j1', text: 'hi', createdAt: DateTime(2026, 10, 1)),
    ];
    firestore.symptoms['user-a'] = [
      SymptomEntry(
        id: 's1',
        symptom: 'Pain',
        severity: 3,
        duration: '',
        notes: '',
        createdAt: DateTime(2026, 10, 1),
      ),
    ];

    final journals = await sync.loadJournalEntries(
      userId: 'user-a',
      firestoreService: firestore,
      localStorageService: storage,
    );
    final symptoms = await sync.loadSymptomEntries(
      userId: 'user-a',
      firestoreService: firestore,
      localStorageService: storage,
    );
    expect(journals.single.id, 'j1');
    expect(symptoms.single.id, 's1');
    expect((await storage.loadJournalEntries()).single.id, 'j1');
    expect((await storage.loadSymptomEntries()).single.id, 's1');
  });

  test('QA-S2-1: an offline read served from the SDK cache is not a sync; '
      'local data shows and the next load retries', () async {
    firestore.moods['user-a'] = [_mood('from-device-b')];
    firestore.offlineCache = true;
    await storage.saveMoodEntries([_mood('local-1')]);

    final offline = await loadMoods('user-a');
    expect(offline.map((e) => e.id), ['local-1']);
    expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
    expect(firestore.writes, isEmpty, reason: 'no backfill while offline');

    // Back online: the next tab open reads the server and shows B's entry.
    firestore.offlineCache = false;
    final online = await loadMoods('user-a');
    expect(firestore.readsOf('moods'), 2);
    expect(online.map((e) => e.id), contains('from-device-b'));
    expect(sync.hasSynced('user-a', SyncCollection.moods), isTrue);
  });

  test('SEC-S2-1: a sign-out during the local re-read writes nothing into '
      'the next profile and uploads nothing', () async {
    SharedPreferences.setMockInitialValues({});
    final hooked = _HookedStorage(
      await SharedPreferences.getInstance(),
      MemoryHealthStorage(),
    );
    hooked.setProfileId('user-a');
    await hooked.saveMoodEntries([_mood('a-local')]);
    firestore.moods['user-a'] = [_mood('a-cloud', minutesAgo: 5)];
    hooked.onSecondMoodLoad = () {
      // What Logout does: clear the guard, then switch to the guest scope.
      sync.clearUser('user-a');
      hooked.setProfileId(null);
    };

    await sync.loadMoodEntries(
      userId: 'user-a',
      firestoreService: firestore,
      localStorageService: hooked,
    );

    expect(hooked.moodLoads, 2);
    expect(await hooked.loadMoodEntries(), isEmpty, reason: 'guest scope');
    expect(firestore.writes, isEmpty);
    expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
    hooked.setProfileId('user-a');
    expect((await hooked.loadMoodEntries()).map((e) => e.id), ['a-local']);
  });

  test('SEC-S2-2: clearUserAndSettle waits for a running sync, and that '
      'sync makes no backfill writes', () async {
    await storage.saveMoodEntries([_mood('a-local')]);
    final gate = Completer<void>();
    firestore.readGate = gate.future;

    final pending = loadMoods('user-a');
    await Future<void>.delayed(Duration.zero);
    expect(firestore.readsOf('moods'), 1);

    var settled = false;
    final settle = sync
        .clearUserAndSettle('user-a')
        .then((_) => settled = true);
    await Future<void>.delayed(Duration.zero);
    expect(settled, isFalse, reason: 'still waiting for the cloud read');

    // The cloud is empty (as after a wipe), which would normally backfill.
    gate.complete();
    await settle;
    await pending;
    expect(settled, isTrue);
    expect(firestore.writes, isEmpty);
    expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
  });

  test('clearUserAndSettle returns right away when nothing is running, and '
      'gives up waiting after its timeout', () async {
    await sync.clearUserAndSettle('user-a');

    firestore.readGate = Completer<void>().future; // never answers
    unawaited(loadMoods('user-a'));
    await Future<void>.delayed(Duration.zero);
    await sync.clearUserAndSettle(
      'user-a',
      timeout: const Duration(milliseconds: 20),
    );
    expect(sync.hasSynced('user-a', SyncCollection.moods), isFalse);
  });
}
