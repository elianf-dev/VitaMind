import 'package:flutter_test/flutter_test.dart';
import 'package:vitamind/models/journal_entry.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/models/symptom_entry.dart';
import 'package:vitamind/utils/insight_math.dart';

MoodEntry mood(String label, DateTime at) => MoodEntry(
  id: '$label-$at',
  emoji: '',
  label: label,
  notes: '',
  createdAt: at,
);

SymptomEntry symptom(String name, int severity, DateTime at) => SymptomEntry(
  id: '$name-$at',
  symptom: name,
  severity: severity,
  duration: '',
  notes: '',
  createdAt: at,
);

JournalEntry journal(DateTime at) =>
    JournalEntry(id: 'j-$at', text: 'note', createdAt: at);

void main() {
  final today = DateTime(2026, 10, 5);
  DateTime daysAgo(int days, [int hour = 9]) =>
      DateTime(today.year, today.month, today.day - days, hour);

  test('mood bands follow the pleasantness thresholds', () {
    expect(MoodBand.forScore(2), MoodBand.veryPleasant);
    expect(MoodBand.forScore(0.5), MoodBand.pleasant);
    expect(MoodBand.forScore(0.4), MoodBand.neutral);
    expect(MoodBand.forScore(-0.5), MoodBand.unpleasant);
    expect(MoodBand.forScore(-1.5), MoodBand.veryUnpleasant);
  });

  test('moods group by day, average their scores, and skip unknown labels', () {
    final byDay = moodsByDay([
      mood('Happy', daysAgo(0, 8)),
      mood('Low', daysAgo(0, 20)),
      mood('Calm', daysAgo(1)),
      mood('Ecstatic', daysAgo(2)),
    ]);

    expect(byDay.keys, containsAll([daysAgo(0, 0), daysAgo(1, 0)]));
    expect(byDay.containsKey(daysAgo(2, 0)), isFalse);
    expect(byDay[daysAgo(0, 0)]!.average, 0); // (+2 + -2) / 2
    expect(byDay[daysAgo(0, 0)]!.entries.first.label, 'Happy');
  });

  test('daily series is oldest first with gaps for missing days', () {
    final byDay = moodsByDay([
      mood('Calm', daysAgo(0)),
      mood('Okay', daysAgo(2)),
    ]);

    expect(dailyMoodSeries(byDay, end: today, days: 4), [null, 0, null, 1]);
  });

  test('summaries average days, not individual check-ins', () {
    final byDay = moodsByDay([
      mood('Happy', daysAgo(0, 8)),
      mood('Happy', daysAgo(0, 12)),
      mood('Happy', daysAgo(0, 18)),
      mood('Low', daysAgo(1)),
    ]);

    final summary = summarizeMoods(
      byDay,
      start: daysAgo(6),
      endExclusive: daysAgo(-1),
    )!;
    expect(summary.average, 0); // (+2 + -2) / 2 days
    expect(summary.checkIns, 4);
    expect(summary.days, 2);
    expect(
      summarizeMoods(byDay, start: daysAgo(30), endExclusive: daysAgo(7)),
      isNull,
    );
  });

  test('top symptoms rank by frequency and ignore case and old logs', () {
    final entries = [
      symptom('Headache', 4, daysAgo(0)),
      symptom('headache ', 6, daysAgo(1)),
      symptom('Nausea', 3, daysAgo(2)),
      symptom('Fatigue', 5, daysAgo(40)),
      symptom('Fatigue', 5, daysAgo(41)),
      symptom('Fatigue', 5, daysAgo(42)),
    ];

    expect(topSymptoms(entries, since: daysAgo(29)), ['Headache', 'Nausea']);
  });

  test('symptom series keeps the highest severity per day', () {
    final entries = [
      symptom('Headache', 3, daysAgo(0, 8)),
      symptom('Headache', 7, daysAgo(0, 20)),
      symptom('Nausea', 9, daysAgo(1)),
    ];

    expect(
      dailySymptomSeries(entries, symptom: 'headache', end: today, days: 3),
      [null, null, 7],
    );
  });

  test('journal comparison needs 3 days on each side', () {
    final moods = [
      for (var day = 0; day < 6; day++)
        mood(day.isEven ? 'Happy' : 'Okay', daysAgo(day)),
    ];
    final byDay = moodsByDay(moods);
    final journals = [journal(daysAgo(0)), journal(daysAgo(2))];

    expect(
      compareMoodByJournal(byDay, journals, since: daysAgo(29)),
      isNull,
      reason: 'only 2 journaled days',
    );

    final comparison = compareMoodByJournal(byDay, [
      ...journals,
      journal(daysAgo(4)),
    ], since: daysAgo(29))!;
    expect(comparison.journaled.days, 3);
    expect(comparison.journaled.band, MoodBand.veryPleasant);
    expect(comparison.notJournaled.band, MoodBand.neutral);
  });
}
