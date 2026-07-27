import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/models/diagnosed_condition.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/services/auth_service.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/firestore_service.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/services/notification_service.dart';
import 'package:vitamind/main.dart';

void main() {
  testWidgets('VitaMind opens on the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final localStorageService = LocalStorageService(
      preferences,
      MemoryHealthStorage(),
    );

    await tester.pumpWidget(
      VitaMindApp(
        authService: AuthService(firebaseAvailable: false),
        firestoreService: const FirestoreService(enabled: false),
        localStorageService: localStorageService,
        notificationService: NotificationService(),
      ),
    );

    expect(find.text('VitaMind'), findsOneWidget);
    expect(
      find.text('Track your mood, symptoms, and wellness habits.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.self_improvement), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  test(
    'local health profile data is scoped by guest or signed-in user',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final localStorageService = LocalStorageService(
        preferences,
        MemoryHealthStorage(),
      );

      await localStorageService.saveDiagnosedConditions([
        DiagnosedCondition.create(name: 'Migraine'),
      ]);

      localStorageService.setProfileId('user-123');
      expect(await localStorageService.loadDiagnosedConditions(), isEmpty);

      await localStorageService.saveDiagnosedConditions([
        DiagnosedCondition.create(name: 'Anxiety'),
      ]);

      localStorageService.setProfileId(null);
      expect(
        (await localStorageService.loadDiagnosedConditions()).single.name,
        'Migraine',
      );

      localStorageService.setProfileId('user-123');
      expect(
        (await localStorageService.loadDiagnosedConditions()).single.name,
        'Anxiety',
      );
    },
  );

  test('legacy health JSON migrates out of shared preferences', () async {
    final condition = DiagnosedCondition(
      id: 'legacy-condition',
      name: 'Migraine',
      dateAdded: DateTime(2026, 1, 1),
    );
    SharedPreferences.setMockInitialValues({
      'vitamind.diagnosed_conditions': jsonEncode([condition.toJson()]),
    });
    final preferences = await SharedPreferences.getInstance();
    final localStorageService = LocalStorageService(
      preferences,
      MemoryHealthStorage(),
    );

    final conditions = await localStorageService.loadDiagnosedConditions();

    expect(conditions.single.name, 'Migraine');
    expect(preferences.containsKey('vitamind.diagnosed_conditions'), isFalse);
    expect(
      (await localStorageService.loadDiagnosedConditions()).single.id,
      'legacy-condition',
    );
  });

  test('malformed saved records do not hide valid health history', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final healthStorage = MemoryHealthStorage();
    final validMood = MoodEntry(
      id: 'valid',
      emoji: '🙂',
      label: 'Calm',
      notes: '',
      createdAt: DateTime(2026, 1, 1),
    );
    await healthStorage.write(
      'vitamind.mood_entries.guest',
      jsonEncode([
        validMood.toJson(),
        {'id': 'damaged', 'createdAt': 42},
      ]),
    );
    final localStorageService = LocalStorageService(preferences, healthStorage);

    final moods = await localStorageService.loadMoodEntries();

    expect(moods, hasLength(1));
    expect(moods.single.id, 'valid');
  });
}
