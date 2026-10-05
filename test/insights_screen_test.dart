import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/models/journal_entry.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/models/symptom_entry.dart';
import 'package:vitamind/screens/insights_screen.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/local_storage_service.dart';

void main() {
  testWidgets('Insights shows calendar, trends, and an honest comparison', (
    tester,
  ) async {
    // Tall viewport so every lazily built section is laid out.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorageService(
      await SharedPreferences.getInstance(),
      MemoryHealthStorage(),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9);
    DateTime daysAgo(int days) =>
        DateTime(today.year, today.month, today.day - days, 9);

    await storage.saveMoodEntries([
      MoodEntry(
        id: 'm1',
        emoji: '😄',
        label: 'Happy',
        notes: 'private note',
        createdAt: today,
      ),
      MoodEntry(
        id: 'm2',
        emoji: '😟',
        label: 'Low',
        notes: '',
        createdAt: daysAgo(1),
      ),
    ]);
    await storage.saveSymptomEntries([
      SymptomEntry(
        id: 's1',
        symptom: 'Headache',
        severity: 6,
        duration: '',
        notes: '',
        createdAt: today,
      ),
      SymptomEntry(
        id: 's2',
        symptom: 'Headache',
        severity: 8,
        duration: '',
        notes: '',
        createdAt: daysAgo(2),
      ),
    ]);
    await storage.saveJournalEntries([
      JournalEntry(id: 'j1', text: 'note', createdAt: today),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: InsightsScreen(localStorageService: storage)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mood calendar'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'today, Very pleasant: Happy')),
      findsOneWidget,
    );
    // Today is preselected; its details list the check-in but never the note.
    expect(find.textContaining('😄 Happy'), findsOneWidget);
    expect(find.textContaining('private note'), findsNothing);

    expect(
      find.textContaining('Average: Neutral · 2 check-ins on 2 days'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Headache: logged on 2 of the last 30 days · highest 8/10',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Not enough logs to compare yet'),
      findsOneWidget,
    );
    expect(find.textContaining('tends to improve'), findsNothing);

    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Mood trend for the last 30 days')),
      findsOneWidget,
    );
  });
}
