import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/symptom_entry.dart';
import '../utils/entry_merge.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';

enum SyncCollection { moods, symptoms, journals }

/// Remembers which `(uid, collection)` pairs have already done their full
/// cloud read in this app session, so opening a tab or logging an entry
/// doesn't re-read the whole Firestore collection.
///
/// A cold start still does one full read per collection (which also brings in
/// entries made on other devices). After that, screens render from local
/// storage, and writes go to local storage plus Firestore without a reload.
/// The guard lives in memory only; a failed sync is never marked done, so the
/// next load retries.
class SyncCoordinator {
  final Set<String> _synced = {};
  final Map<String, Future<void>> _inFlight = {};

  /// Bumped whenever a user's guard is cleared, so a sync that was already
  /// running for that user doesn't write into whoever is signed in next.
  int _epoch = 0;

  bool hasSynced(String userId, SyncCollection collection) {
    return _synced.contains(_key(userId, collection));
  }

  /// Forgets every collection for [userId]. Call on sign-out and account
  /// deletion.
  void clearUser(String userId) {
    _synced.removeWhere((key) => key.startsWith('$userId/'));
    _inFlight.removeWhere((key, _) => key.startsWith('$userId/'));
    _epoch++;
  }

  /// Clears [userId] like [clearUser], then waits for any sync that was
  /// already running for that user to stop. Call it before wiping the user's
  /// cloud data, so no backfill re-uploads entries after the wipe.
  ///
  /// The wait is capped at [timeout] so a sync stuck offline can't hang
  /// account deletion; a cleared sync makes no further writes either way.
  Future<void> clearUserAndSettle(
    String userId, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final running = [
      for (final entry in _inFlight.entries)
        if (entry.key.startsWith('$userId/')) entry.value,
    ];
    clearUser(userId);
    if (running.isEmpty) {
      return;
    }
    try {
      await Future.wait(running).timeout(timeout);
    } on TimeoutException {
      debugPrint('VitaMind: a sync was still running after $timeout');
    }
  }

  Future<List<MoodEntry>> loadMoodEntries({
    required String? userId,
    required FirestoreService firestoreService,
    required LocalStorageService localStorageService,
    ValueChanged<List<MoodEntry>>? onLocalLoaded,
  }) {
    return _load<MoodEntry>(
      userId: userId,
      collection: SyncCollection.moods,
      cloudEnabled: firestoreService.enabled,
      onLocalLoaded: onLocalLoaded,
      loadLocal: localStorageService.loadMoodEntries,
      saveLocal: localStorageService.saveMoodEntries,
      loadCloud: firestoreService.loadMoodEntries,
      saveCloud: firestoreService.saveMoodEntry,
      idOf: (entry) => entry.id,
      createdAtOf: (entry) => entry.createdAt,
    );
  }

  Future<List<JournalEntry>> loadJournalEntries({
    required String? userId,
    required FirestoreService firestoreService,
    required LocalStorageService localStorageService,
    ValueChanged<List<JournalEntry>>? onLocalLoaded,
  }) {
    return _load<JournalEntry>(
      userId: userId,
      collection: SyncCollection.journals,
      cloudEnabled: firestoreService.enabled,
      onLocalLoaded: onLocalLoaded,
      loadLocal: localStorageService.loadJournalEntries,
      saveLocal: localStorageService.saveJournalEntries,
      loadCloud: firestoreService.loadJournalEntries,
      saveCloud: firestoreService.saveJournalEntry,
      idOf: (entry) => entry.id,
      createdAtOf: (entry) => entry.createdAt,
    );
  }

  Future<List<SymptomEntry>> loadSymptomEntries({
    required String? userId,
    required FirestoreService firestoreService,
    required LocalStorageService localStorageService,
    ValueChanged<List<SymptomEntry>>? onLocalLoaded,
  }) {
    return _load<SymptomEntry>(
      userId: userId,
      collection: SyncCollection.symptoms,
      cloudEnabled: firestoreService.enabled,
      onLocalLoaded: onLocalLoaded,
      loadLocal: localStorageService.loadSymptomEntries,
      saveLocal: localStorageService.saveSymptomEntries,
      loadCloud: firestoreService.loadSymptomEntries,
      saveCloud: firestoreService.saveSymptomEntry,
      idOf: (entry) => entry.id,
      createdAtOf: (entry) => entry.createdAt,
    );
  }

  Future<List<T>> _load<T>({
    required String? userId,
    required SyncCollection collection,
    required bool cloudEnabled,
    required ValueChanged<List<T>>? onLocalLoaded,
    required Future<List<T>> Function() loadLocal,
    required Future<void> Function(List<T> entries) saveLocal,
    required Future<CloudRead<T>> Function(String userId) loadCloud,
    required Future<void> Function(String userId, T entry) saveCloud,
    required String Function(T entry) idOf,
    required DateTime Function(T entry) createdAtOf,
  }) async {
    // Captured before any await, so a sign-out during this load is noticed.
    final epoch = _epoch;
    final localEntries = await loadLocal();
    onLocalLoaded?.call(localEntries);

    if (userId == null || !cloudEnabled) {
      return localEntries;
    }

    final key = _key(userId, collection);
    if (_synced.contains(key)) {
      return localEntries;
    }

    final running = _inFlight[key];
    if (running != null) {
      await running;
      return epoch == _epoch ? loadLocal() : localEntries;
    }

    final done = Completer<void>();
    _inFlight[key] = done.future;
    // True once this user was cleared (sign-out or account deletion). After
    // that, local storage may belong to another profile and the cloud data
    // may be mid-wipe, so this sync must not write anywhere.
    bool cleared() => epoch != _epoch;
    var entries = localEntries;
    try {
      final cloud = await loadCloud(userId);
      if (cleared()) {
        return localEntries;
      }
      if (cloud.fromCache) {
        // Offline: the SDK answered from its cache. Keep showing local data
        // and leave the pair unsynced so the next load retries the server.
        debugPrint('VitaMind: ${collection.name} sync skipped (offline)');
        return localEntries;
      }

      // Re-read local storage so an entry saved while the cloud read was
      // running isn't overwritten by the merged list.
      final latestLocal = await loadLocal();
      if (cleared()) {
        return localEntries;
      }
      entries = mergeEntriesById(
        localEntries: latestLocal,
        cloudEntries: cloud.entries,
        idOf: idOf,
        createdAtOf: createdAtOf,
      );
      await saveLocal(entries);
      if (cleared()) {
        return entries;
      }

      final cloudIds = cloud.entries.map(idOf).toSet();
      await Future.wait(
        latestLocal
            .where((entry) => !cloudIds.contains(idOf(entry)))
            .map((entry) => saveCloud(userId, entry)),
      );

      if (!cleared()) {
        _synced.add(key);
      }
    } on Object catch (error) {
      debugPrint('VitaMind: failed to sync ${collection.name}: $error');
      // Keep the app usable from local data; the next load retries.
    } finally {
      if (identical(_inFlight[key], done.future)) {
        _inFlight.remove(key);
      }
      done.complete();
    }
    return entries;
  }

  String _key(String userId, SyncCollection collection) {
    return '$userId/${collection.name}';
  }
}
