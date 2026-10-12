import 'package:vitamind/models/check_in_settings.dart';
import 'package:vitamind/models/journal_entry.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/models/symptom_entry.dart';
import 'package:vitamind/services/auth_service.dart';
import 'package:vitamind/services/firestore_service.dart';

/// An [AuthService] that reports a fixed signed-in user without Firebase.
class FakeSignedInAuth extends AuthService {
  FakeSignedInAuth(this.uid) : super(firebaseAvailable: false);

  String? uid;

  @override
  String? get userId => uid;

  @override
  bool get isLoggedIn => uid != null;

  @override
  String? get userEmail => uid == null ? null : '$uid@example.com';

  @override
  Future<String?> reauthenticate(String password) async => null;

  @override
  Future<String?> deleteAccount() async {
    uid = null;
    notifyListeners();
    return null;
  }

  @override
  Future<void> signOut() async {
    uid = null;
    notifyListeners();
  }
}

/// A [FirestoreService] backed by in-memory lists, per uid, that counts every
/// read and write so tests can assert on Firestore usage.
class CountingFirestoreService extends FirestoreService {
  CountingFirestoreService({
    this.throwOnRead = false,
    this.offlineCache = false,
  }) : super(enabled: true);

  bool throwOnRead;

  /// Models the real SDK offline: reads succeed but are served from cache.
  bool offlineCache;

  /// When set, collection reads wait for this before answering.
  Future<void>? readGate;

  /// Called at the start of [deleteUserData], for ordering checks.
  void Function(String userId)? onDeleteUserData;

  final Map<String, List<MoodEntry>> moods = {};
  final Map<String, List<SymptomEntry>> symptoms = {};
  final Map<String, List<JournalEntry>> journals = {};

  final Map<String, int> reads = {};
  final Map<String, int> writes = {};

  int readsOf(String collection) => reads[collection] ?? 0;
  int writesOf(String collection) => writes[collection] ?? 0;
  int get totalReads => reads.values.fold(0, (sum, count) => sum + count);

  void resetCounts() {
    reads.clear();
    writes.clear();
  }

  Future<CloudRead<T>> _read<T>(String collection, List<T>? stored) async {
    reads[collection] = readsOf(collection) + 1;
    final gate = readGate;
    if (gate != null) {
      await gate;
    }
    if (throwOnRead) {
      throw StateError('Firestore unavailable');
    }
    return CloudRead(List.of(stored ?? <T>[]), fromCache: offlineCache);
  }

  void _write(String collection) {
    writes[collection] = writesOf(collection) + 1;
  }

  @override
  Future<CloudRead<MoodEntry>> loadMoodEntries(String userId) {
    return _read('moods', moods[userId]);
  }

  @override
  Future<void> saveMoodEntry(String userId, MoodEntry entry) async {
    _write('moods');
    (moods[userId] ??= []).add(entry);
  }

  @override
  Future<CloudRead<SymptomEntry>> loadSymptomEntries(String userId) {
    return _read('symptoms', symptoms[userId]);
  }

  @override
  Future<void> saveSymptomEntry(String userId, SymptomEntry entry) async {
    _write('symptoms');
    (symptoms[userId] ??= []).add(entry);
  }

  @override
  Future<CloudRead<JournalEntry>> loadJournalEntries(String userId) {
    return _read('journals', journals[userId]);
  }

  @override
  Future<void> saveJournalEntry(String userId, JournalEntry entry) async {
    _write('journals');
    (journals[userId] ??= []).add(entry);
  }

  @override
  Future<CheckInSettings?> loadCheckInSettings(String userId) async {
    reads['settings'] = readsOf('settings') + 1;
    return null;
  }

  @override
  Future<void> saveCheckInSettings(
    String userId,
    CheckInSettings settings,
  ) async {
    _write('settings');
  }

  @override
  Future<void> deleteUserData(String userId) async {
    onDeleteUserData?.call(userId);
    moods.remove(userId);
    symptoms.remove(userId);
    journals.remove(userId);
  }
}
