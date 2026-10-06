// Store-screenshot build: opens VitaMind on the dashboard with four weeks of
// realistic sample data, without touching anyone's real entries.
//
//   flutter run -t tool/screenshots/main.dart
//
// The sample data lives in its own local profile ("screenshots"), so guest
// data on the device stays as it was. Firebase and reminders stay off.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vitamind/data/mood_choices.dart';
import 'package:vitamind/main.dart';
import 'package:vitamind/models/journal_entry.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/models/symptom_entry.dart';
import 'package:vitamind/models/wellness_goal.dart';
import 'package:vitamind/services/auth_service.dart';
import 'package:vitamind/services/firestore_service.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await LocalStorageService.create();
  storage.setProfileId('screenshots');
  await _seed(storage);

  runApp(
    VitaMindApp(
      authService: AuthService(firebaseAvailable: false),
      firestoreService: const FirestoreService(enabled: false),
      localStorageService: storage,
      notificationService: NotificationService(),
      onboardingCompleted: true,
      guestSessionActive: true,
    ),
  );
}

Future<void> _seed(LocalStorageService storage) async {
  // Fixed seed so every run produces the same screenshots.
  final random = Random(7);
  final now = DateTime.now();
  DateTime at(int daysAgo, int hour, [int minute = 0]) =>
      DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
  MoodChoice mood(String label) =>
      moodChoices.firstWhere((choice) => choice.label == label);

  // Moods: gently improving over four weeks, with a few skipped days.
  const early = ['Okay', 'Anxious', 'Low', 'Calm', 'Okay', 'Anxious'];
  const late = ['Calm', 'Happy', 'Okay', 'Calm', 'Happy', 'Anxious'];
  const notes = {
    1: 'Long walk by the water after work.',
    3: 'Slept badly, felt foggy all morning.',
    6: 'Good call with my sister.',
    12: 'Deadline stress, but I got it done.',
  };
  final moods = <MoodEntry>[];
  for (var daysAgo = 27; daysAgo >= 0; daysAgo--) {
    if (daysAgo != 0 && random.nextDouble() < 0.2) {
      continue;
    }
    final pool = daysAgo > 13 ? early : late;
    final checkIns = random.nextDouble() < 0.3 ? 2 : 1;
    for (var i = 0; i < checkIns; i++) {
      final choice = mood(pool[random.nextInt(pool.length)]);
      moods.add(
        MoodEntry(
          id: 'shot-mood-$daysAgo-$i',
          emoji: choice.emoji,
          label: choice.label,
          notes: i == 0 ? notes[daysAgo] ?? '' : '',
          createdAt: at(daysAgo, i == 0 ? 9 : 20, random.nextInt(50)),
        ),
      );
    }
  }
  await storage.saveMoodEntries(moods);

  // Symptoms: tension headaches easing over the month, plus some fatigue.
  final symptoms = <SymptomEntry>[
    for (final (daysAgo, severity) in [
      (26, 7),
      (23, 6),
      (20, 7),
      (16, 5),
      (13, 5),
      (9, 4),
      (5, 3),
      (2, 3),
    ])
      SymptomEntry(
        id: 'shot-headache-$daysAgo',
        symptom: 'Headache',
        severity: severity,
        duration: severity > 5 ? 'Most of the afternoon' : 'About an hour',
        notes: severity > 5 ? 'Behind the eyes, worse after screens.' : '',
        createdAt: at(daysAgo, 15),
      ),
    for (final (daysAgo, severity) in [(18, 6), (11, 5), (4, 4)])
      SymptomEntry(
        id: 'shot-fatigue-$daysAgo',
        symptom: 'Fatigue',
        severity: severity,
        duration: 'All day',
        notes: '',
        createdAt: at(daysAgo, 18),
      ),
  ];
  await storage.saveSymptomEntries(symptoms);

  // Journal: short, everyday reflections on about a third of the days.
  const journal = {
    0: 'Noticed I feel calmer on days I get outside before noon. Trying to make that a habit.',
    2: 'Small win: cooked dinner instead of ordering in. Felt good to slow down.',
    5: 'Headaches are less frequent since I started taking screen breaks.',
    8: 'Rough start to the week, but talking it through helped.',
    12: 'Busy and a bit anxious. Writing it down makes it feel smaller.',
    15: 'Slept eight hours for the first time in a while.',
    19: 'Not much energy today. Being gentle with myself.',
    24: 'Starting to track how I feel. Curious what patterns show up.',
  };
  await storage.saveJournalEntries([
    for (final MapEntry(key: daysAgo, value: text) in journal.entries)
      JournalEntry(
        id: 'shot-journal-$daysAgo',
        text: text,
        createdAt: at(daysAgo, 21, 15),
      ),
  ]);

  await storage.saveWellnessGoals([
    WellnessGoal(
      id: 'shot-goal-walk',
      title: 'Walk outside for 20 minutes',
      category: 'Movement',
      targetFrequency: 'Daily',
      progress: 0.6,
      active: true,
      createdAt: at(20, 9),
    ),
    WellnessGoal(
      id: 'shot-goal-screens',
      title: 'Screen break every two hours',
      category: 'Rest',
      targetFrequency: 'Daily',
      progress: 0.4,
      active: true,
      createdAt: at(14, 9),
    ),
  ]);
}
