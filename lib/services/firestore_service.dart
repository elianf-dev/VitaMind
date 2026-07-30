import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/check_in_settings.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/symptom_entry.dart';

class FirestoreService {
  const FirestoreService({required this.enabled});

  final bool enabled;

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

  Future<List<MoodEntry>> loadMoodEntries(String userId) async {
    if (!enabled) {
      return [];
    }

    final snapshot = await _moods(
      userId,
    ).orderBy('createdAt', descending: true).get();
    return _decodeDocuments(
      snapshot.docs.map((document) => document.data()),
      MoodEntry.fromJson,
    );
  }

  Future<void> saveMoodEntry(String userId, MoodEntry entry) async {
    if (!enabled) {
      return;
    }

    await _moods(userId).doc(entry.id).set(entry.toJson());
  }

  Future<List<SymptomEntry>> loadSymptomEntries(String userId) async {
    if (!enabled) {
      return [];
    }

    final snapshot = await _symptoms(
      userId,
    ).orderBy('createdAt', descending: true).get();
    return _decodeDocuments(
      snapshot.docs.map((document) => document.data()),
      SymptomEntry.fromJson,
    );
  }

  Future<void> saveSymptomEntry(String userId, SymptomEntry entry) async {
    if (!enabled) {
      return;
    }

    await _symptoms(userId).doc(entry.id).set(entry.toJson());
  }

  Future<List<JournalEntry>> loadJournalEntries(String userId) async {
    if (!enabled) {
      return [];
    }

    final snapshot = await _journals(
      userId,
    ).orderBy('createdAt', descending: true).get();
    return _decodeDocuments(
      snapshot.docs.map((document) => document.data()),
      JournalEntry.fromJson,
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
