import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/check_in_settings.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/symptom_entry.dart';

/// The result of a full collection read. [fromCache] is true when the SDK
/// answered from its offline cache instead of the server, so the caller must
/// not treat the read as a completed sync.
class CloudRead<T> {
  const CloudRead(this.entries, {required this.fromCache});

  final List<T> entries;
  final bool fromCache;
}

class FirestoreService {
  const FirestoreService({required this.enabled});

  final bool enabled;

  /// The session sync reads must come from the server. With the default
  /// source the SDK returns its cache when offline, which would look like a
  /// successful sync and stop the retry. A server read throws instead (and
  /// still refreshes the cache).
  static const _serverOnly = GetOptions(source: Source.server);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _moods(String userId) {
    return _db.collection('users').doc(userId).collection('moods');
  }

  CollectionReference<Map<String, dynamic>> _symptoms(String userId) {
    return _db.collection('users').doc(userId).collection('symptoms');
  }

  CollectionReference<Map<String, dynamic>> _journals(String userId) {
    return _db.collection('users').doc(userId).collection('journals');
  }

  DocumentReference<Map<String, dynamic>> _notificationSettings(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notifications');
  }

  // TODO: Add Firestore collections for diagnosed conditions, wellness goals,
  // privacy settings, onboarding state, and account deletion workflows.

  Future<CloudRead<MoodEntry>> loadMoodEntries(String userId) async {
    if (!enabled) {
      return const CloudRead([], fromCache: false);
    }

    final snapshot = await _moods(
      userId,
    ).orderBy('createdAt', descending: true).get(_serverOnly);
    return CloudRead(
      _decodeDocuments(
        snapshot.docs.map((document) => document.data()),
        MoodEntry.fromJson,
      ),
      fromCache: snapshot.metadata.isFromCache,
    );
  }

  Future<void> saveMoodEntry(String userId, MoodEntry entry) async {
    if (!enabled) {
      return;
    }

    await _moods(userId).doc(entry.id).set(entry.toJson());
  }

  Future<CloudRead<SymptomEntry>> loadSymptomEntries(String userId) async {
    if (!enabled) {
      return const CloudRead([], fromCache: false);
    }

    final snapshot = await _symptoms(
      userId,
    ).orderBy('createdAt', descending: true).get(_serverOnly);
    return CloudRead(
      _decodeDocuments(
        snapshot.docs.map((document) => document.data()),
        SymptomEntry.fromJson,
      ),
      fromCache: snapshot.metadata.isFromCache,
    );
  }

  Future<void> saveSymptomEntry(String userId, SymptomEntry entry) async {
    if (!enabled) {
      return;
    }

    await _symptoms(userId).doc(entry.id).set(entry.toJson());
  }

  Future<CloudRead<JournalEntry>> loadJournalEntries(String userId) async {
    if (!enabled) {
      return const CloudRead([], fromCache: false);
    }

    final snapshot = await _journals(
      userId,
    ).orderBy('createdAt', descending: true).get(_serverOnly);
    return CloudRead(
      _decodeDocuments(
        snapshot.docs.map((document) => document.data()),
        JournalEntry.fromJson,
      ),
      fromCache: snapshot.metadata.isFromCache,
    );
  }

  Future<void> saveJournalEntry(String userId, JournalEntry entry) async {
    if (!enabled) {
      return;
    }

    await _journals(userId).doc(entry.id).set(entry.toJson());
  }

  Future<CheckInSettings?> loadCheckInSettings(String userId) async {
    if (!enabled) {
      return null;
    }

    final snapshot = await _notificationSettings(userId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return CheckInSettings.fromJson(data);
  }

  Future<void> saveCheckInSettings(
    String userId,
    CheckInSettings settings,
  ) async {
    if (!enabled) {
      return;
    }

    await _notificationSettings(userId).set(settings.toJson());
  }

  /// The Firestore cache settings for this app: no on-disk cache (C-3). Hive
  /// is the encrypted local store, and sync reads are server-only, so the
  /// SDK cache would only leave an unencrypted copy of entries on the phone.
  static const Settings deviceSettings = Settings(persistenceEnabled: false);

  /// Wipes any Firestore cache files on this device (C-3, SEC-S2-4). Called
  /// after Logout, account deletion and "Delete Data From This Device".
  ///
  /// `clearPersistence` only works on a stopped instance, so this terminates
  /// the instance first; the next Firestore call starts a new one. The
  /// settings are applied again before that next use. Never throws: a failed
  /// clear must not block logout, deletion or navigation.
  Future<void> clearDeviceCache() async {
    if (!enabled) {
      return;
    }

    try {
      await _db.terminate();
      await _db.clearPersistence();
    } on Object catch (error) {
      debugPrint(
        'VitaMind: failed to clear the Firestore device cache: $error',
      );
    }
    try {
      _db.settings = deviceSettings;
    } on Object catch (error) {
      debugPrint('VitaMind: failed to re-apply Firestore settings: $error');
    }
  }

  Future<void> deleteUserData(String userId) async {
    if (!enabled) {
      return;
    }

    final user = _db.collection('users').doc(userId);
    for (final collectionName in const [
      'moods',
      'symptoms',
      'journals',
      'settings',
    ]) {
      await _deleteCollection(user.collection(collectionName));
    }
    await user.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(400).get();
      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _db.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  List<T> _decodeDocuments<T>(
    Iterable<Map<String, dynamic>> documents,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final models = <T>[];
    for (final document in documents) {
      try {
        models.add(fromJson(document));
      } on Object catch (error) {
        debugPrint('VitaMind: dropped malformed cloud record: $error');
        // One malformed cloud record should not hide the user's valid history.
      }
    }
    return models;
  }
}
