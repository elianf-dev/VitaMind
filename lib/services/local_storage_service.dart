import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_log_entry.dart';
import '../models/check_in_settings.dart';
import '../models/diagnosed_condition.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/privacy_security_settings.dart';
import '../models/symptom_entry.dart';
import '../models/wellness_goal.dart';
import 'encrypted_health_storage.dart';

class LocalStorageService {
  LocalStorageService(this._preferences, this._healthStorage);

  static const String _guestProfileId = 'guest';
  static const String _onboardingCompletedKey = 'vitamind.onboarding_completed';
  static const String _moodsKey = 'vitamind.mood_entries';
  static const String _symptomsKey = 'vitamind.symptom_entries';
  static const String _journalsKey = 'vitamind.journal_entries';
  static const String _checkInSettingsKey = 'vitamind.check_in_settings';
  static const String _diagnosedConditionsKey = 'vitamind.diagnosed_conditions';
  static const String _wellnessGoalsKey = 'vitamind.wellness_goals';
  static const String _privacySettingsKey = 'vitamind.privacy_settings';
  static const String _medicationsKey = 'vitamind.medications';
  static const String _commonSymptomsKey = 'vitamind.common_symptoms';
  static const String _healthLogEntriesKey = 'vitamind.health_log_entries';
  static const String _legacyAiHealthLogsKey = 'vitamind.ai_health_logs';

  final SharedPreferences _preferences;
  final HealthStorage _healthStorage;
  String _profileId = _guestProfileId;

  static Future<LocalStorageService> create() async {
    final preferences = await SharedPreferences.getInstance();
    final healthStorage = await EncryptedHealthStorage.create();
    return LocalStorageService(preferences, healthStorage);
  }

  void setProfileId(String? profileId) {
    final trimmedProfileId = profileId?.trim();
    _profileId = trimmedProfileId == null || trimmedProfileId.isEmpty
        ? _guestProfileId
        : trimmedProfileId;
  }

  Future<bool> loadOnboardingCompleted() async {
    return _getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> saveOnboardingCompleted(bool completed) async {
    // TODO: Store onboarding completion per Firebase user in Firestore later.
    await _preferences.setBool(_scopedKey(_onboardingCompletedKey), completed);
  }

  Future<List<MoodEntry>> loadMoodEntries() async {
    return _decodeModels(await _getHealthString(_moodsKey), MoodEntry.fromJson);
  }

  Future<void> saveMoodEntries(List<MoodEntry> entries) async {
    await _writeHealthString(
      _moodsKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> addMoodEntry(MoodEntry entry) async {
    final entries = await loadMoodEntries();
    entries.insert(0, entry);
    await saveMoodEntries(entries);
  }

  Future<List<SymptomEntry>> loadSymptomEntries() async {
    return _decodeModels(
      await _getHealthString(_symptomsKey),
      SymptomEntry.fromJson,
    );
  }

  Future<void> saveSymptomEntries(List<SymptomEntry> entries) async {
    await _writeHealthString(
      _symptomsKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> addSymptomEntry(SymptomEntry entry) async {
    final entries = await loadSymptomEntries();
    entries.insert(0, entry);
    await saveSymptomEntries(entries);
  }

  Future<List<JournalEntry>> loadJournalEntries() async {
    return _decodeModels(
      await _getHealthString(_journalsKey),
      JournalEntry.fromJson,
    );
  }

  Future<void> saveJournalEntries(List<JournalEntry> entries) async {
    await _writeHealthString(
      _journalsKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> addJournalEntry(JournalEntry entry) async {
    final entries = await loadJournalEntries();
    entries.insert(0, entry);
    await saveJournalEntries(entries);
  }

  Future<List<HealthLogEntry>> loadHealthLogEntries() async {
    return _decodeModels(
      await _getHealthString(_healthLogEntriesKey) ??
          await _getHealthString(_legacyAiHealthLogsKey),
      HealthLogEntry.fromJson,
    );
  }

  Future<void> saveHealthLogEntries(List<HealthLogEntry> logs) async {
    // TODO: Add optional cloud sync for user-approved health log history later.
    await _writeHealthString(
      _healthLogEntriesKey,
      jsonEncode(logs.map((log) => log.toJson()).toList()),
    );
  }

  Future<void> addHealthLogEntry(HealthLogEntry log) async {
    final logs = await loadHealthLogEntries();
    logs.insert(0, log);
    await saveHealthLogEntries(logs);
  }

  Future<CheckInSettings> loadCheckInSettings() async {
    final json = _getString(_checkInSettingsKey);
    if (json == null) {
      return CheckInSettings.defaults();
    }

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return CheckInSettings.fromJson(decoded);
    } on Object {
      return CheckInSettings.defaults();
    }
  }

  Future<void> saveCheckInSettings(CheckInSettings settings) async {
    await _preferences.setString(
      _scopedKey(_checkInSettingsKey),
      jsonEncode(settings.toJson()),
    );
  }

  Future<List<DiagnosedCondition>> loadDiagnosedConditions() async {
    return _decodeModels(
      await _getHealthString(_diagnosedConditionsKey),
      DiagnosedCondition.fromJson,
    );
  }

  Future<void> saveDiagnosedConditions(
    List<DiagnosedCondition> conditions,
  ) async {
    // TODO: Sync diagnosed conditions to users/{userId}/conditions in Firestore.
    await _writeHealthString(
      _diagnosedConditionsKey,
      jsonEncode(conditions.map((condition) => condition.toJson()).toList()),
    );
  }

  Future<List<WellnessGoal>> loadWellnessGoals() async {
    return _decodeModels(
      await _getHealthString(_wellnessGoalsKey),
      WellnessGoal.fromJson,
    );
  }

  Future<void> saveWellnessGoals(List<WellnessGoal> goals) async {
    // TODO: Sync wellness goals to users/{userId}/goals in Firestore.
    await _writeHealthString(
      _wellnessGoalsKey,
      jsonEncode(goals.map((goal) => goal.toJson()).toList()),
    );
  }

  Future<PrivacySecuritySettings> loadPrivacySettings() async {
    final json = _getString(_privacySettingsKey);
    if (json == null) {
      return PrivacySecuritySettings.defaults();
    }

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return PrivacySecuritySettings.fromJson(decoded);
    } on Object {
      return PrivacySecuritySettings.defaults();
    }
  }

  Future<void> savePrivacySettings(PrivacySecuritySettings settings) async {
    await _preferences.setString(
      _scopedKey(_privacySettingsKey),
      jsonEncode(settings.toJson()),
    );
  }

  Future<List<String>> loadMedications() async {
    return _decodeStringList(await _getHealthString(_medicationsKey));
  }

  Future<void> saveMedications(List<String> medications) async {
    // TODO: Sync prescriptions to Firestore only after adding explicit user consent controls.
    await _writeHealthString(_medicationsKey, jsonEncode(medications));
  }

  Future<List<String>> loadCommonSymptoms() async {
    return _decodeStringList(await _getHealthString(_commonSymptomsKey));
  }

  Future<void> saveCommonSymptoms(List<String> symptoms) async {
    // TODO: Sync common symptoms to Firestore after user profile syncing is added.
    await _writeHealthString(_commonSymptomsKey, jsonEncode(symptoms));
  }

  Future<void> clearLocalHealthData() async {
    await Future.wait([
      _removeScoped(_onboardingCompletedKey),
      _removeScoped(_checkInSettingsKey),
      _removeScoped(_privacySettingsKey),
      _removeHealthString(_moodsKey),
      _removeHealthString(_symptomsKey),
      _removeHealthString(_journalsKey),
      _removeHealthString(_diagnosedConditionsKey),
      _removeHealthString(_wellnessGoalsKey),
      _removeHealthString(_medicationsKey),
      _removeHealthString(_commonSymptomsKey),
      _removeHealthString(_healthLogEntriesKey),
      _removeHealthString(_legacyAiHealthLogsKey),
    ]);
  }

  String _scopedKey(String key) {
    return '$key.$_profileId';
  }

  String? _getString(String key) {
    return _preferences.getString(_scopedKey(key)) ??
        (_profileId == _guestProfileId ? _preferences.getString(key) : null);
  }

  bool? _getBool(String key) {
    return _preferences.getBool(_scopedKey(key)) ??
        (_profileId == _guestProfileId ? _preferences.getBool(key) : null);
  }

  Future<String?> _getHealthString(String key) async {
    final scopedKey = _scopedKey(key);
    final encryptedValue = _healthStorage.read(scopedKey);
    if (encryptedValue != null) {
      return encryptedValue;
    }

    final legacyValue = _getString(key);
    if (legacyValue == null) {
      return null;
    }

    await _healthStorage.write(scopedKey, legacyValue);
    await _removeScoped(key);
    return legacyValue;
  }

  Future<void> _writeHealthString(String key, String value) async {
    await _healthStorage.write(_scopedKey(key), value);
    await _removeScoped(key);
  }

  Future<void> _removeHealthString(String key) async {
    await _healthStorage.delete(_scopedKey(key));
    await _removeScoped(key);
  }

  Future<void> _removeScoped(String key) async {
    await _preferences.remove(_scopedKey(key));
    if (_profileId == _guestProfileId) {
      await _preferences.remove(key);
    }
  }

  List<Map<String, dynamic>> _decodeList(String? json) {
    if (json == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on Object {
      return [];
    }
  }

  List<T> _decodeModels<T>(
    String? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final models = <T>[];
    for (final item in _decodeList(json)) {
      try {
        models.add(fromJson(item));
      } on Object {
        // Keep valid records usable if an older or damaged record is malformed.
      }
    }
    return models;
  }

  List<String> _decodeStringList(String? json) {
    if (json == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    } on Object {
      return [];
    }
  }
}
