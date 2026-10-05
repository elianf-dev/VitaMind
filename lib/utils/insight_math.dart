import '../data/mood_choices.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/symptom_entry.dart';

/// Five-step pleasantness scale used to color and describe mood days.
enum MoodBand {
  veryUnpleasant('Very unpleasant'),
  unpleasant('Unpleasant'),
  neutral('Neutral'),
  pleasant('Pleasant'),
  veryPleasant('Very pleasant');

  const MoodBand(this.label);

  final String label;

  static MoodBand forScore(double score) {
    if (score >= 1.5) {
      return MoodBand.veryPleasant;
    }
    if (score >= 0.5) {
      return MoodBand.pleasant;
    }
    if (score > -0.5) {
      return MoodBand.neutral;
    }
    if (score > -1.5) {
      return MoodBand.unpleasant;
    }
    return MoodBand.veryUnpleasant;
  }
}

/// Calendar day in local time with no time-of-day component.
DateTime dayOf(DateTime moment) {
  final local = moment.toLocal();
  return DateTime(local.year, local.month, local.day);
}

class DayMood {
  const DayMood({
    required this.day,
    required this.average,
    required this.entries,
  });

  final DateTime day;
  final double average;

  /// That day's scorable entries, oldest first.
  final List<MoodEntry> entries;

  MoodBand get band => MoodBand.forScore(average);
}

/// Groups scorable mood entries by local day and averages their scores.
Map<DateTime, DayMood> moodsByDay(Iterable<MoodEntry> entries) {
  final grouped = <DateTime, List<MoodEntry>>{};
  for (final entry in entries) {
    if (moodScoreForLabel(entry.label) == null) {
      continue;
    }
    grouped.putIfAbsent(dayOf(entry.createdAt), () => []).add(entry);
  }

  return grouped.map((day, dayEntries) {
    dayEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final total = dayEntries.fold<int>(
      0,
      (sum, entry) => sum + moodScoreForLabel(entry.label)!,
    );
    return MapEntry(
      day,
      DayMood(
        day: day,
        average: total / dayEntries.length,
        entries: dayEntries,
      ),
    );
  });
}

/// Daily average mood for the [days] days ending on [end] (inclusive),
/// oldest first. Days without a check-in are null so charts show a gap.
List<double?> dailyMoodSeries(
  Map<DateTime, DayMood> byDay, {
  required DateTime end,
  required int days,
}) {
  final last = dayOf(end);
  return List.generate(days, (index) {
    final day = DateTime(last.year, last.month, last.day - (days - 1 - index));
    return byDay[day]?.average;
  });
}

class MoodSummary {
  const MoodSummary({
    required this.average,
    required this.checkIns,
    required this.days,
  });

  final double average;
  final int checkIns;
  final int days;

  MoodBand get band => MoodBand.forScore(average);
}

/// Average of the daily averages from [start] up to (not including)
/// [endExclusive], so a day with many check-ins doesn't outweigh others.
MoodSummary? summarizeMoods(
  Map<DateTime, DayMood> byDay, {
  required DateTime start,
  required DateTime endExclusive,
}) {
  final first = dayOf(start);
  final stop = dayOf(endExclusive);
  final inRange = byDay.values
      .where((day) => !day.day.isBefore(first) && day.day.isBefore(stop))
      .toList();
  if (inRange.isEmpty) {
    return null;
  }

  final average =
      inRange.fold<double>(0, (sum, day) => sum + day.average) / inRange.length;
  final checkIns = inRange.fold<int>(0, (sum, day) => sum + day.entries.length);
  return MoodSummary(
    average: average,
    checkIns: checkIns,
    days: inRange.length,
  );
}

String _symptomKey(String symptom) => symptom.trim().toLowerCase();

/// The most frequently logged symptoms since [since], most frequent first,
/// using each symptom's most recent spelling for display.
List<String> topSymptoms(
  Iterable<SymptomEntry> entries, {
  required DateTime since,
  int limit = 3,
}) {
  final counts = <String, int>{};
  final latestName = <String, SymptomEntry>{};
  final first = dayOf(since);
  for (final entry in entries) {
    final key = _symptomKey(entry.symptom);
    if (key.isEmpty || dayOf(entry.createdAt).isBefore(first)) {
      continue;
    }
    counts[key] = (counts[key] ?? 0) + 1;
    final previous = latestName[key];
    if (previous == null || entry.createdAt.isAfter(previous.createdAt)) {
      latestName[key] = entry;
    }
  }

  final keys = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return keys
      .take(limit)
      .map((key) => latestName[key]!.symptom.trim())
      .toList();
}

/// Highest severity logged per day for [symptom] over the [days] days ending
/// on [end], oldest first. Days without that symptom are null.
List<double?> dailySymptomSeries(
  Iterable<SymptomEntry> entries, {
  required String symptom,
  required DateTime end,
  required int days,
}) {
  final key = _symptomKey(symptom);
  final maxByDay = <DateTime, int>{};
  for (final entry in entries) {
    if (_symptomKey(entry.symptom) != key) {
      continue;
    }
    final day = dayOf(entry.createdAt);
    final current = maxByDay[day];
    if (current == null || entry.severity > current) {
      maxByDay[day] = entry.severity;
    }
  }

  final last = dayOf(end);
  return List.generate(days, (index) {
    final day = DateTime(last.year, last.month, last.day - (days - 1 - index));
    return maxByDay[day]?.toDouble();
  });
}

class JournalMoodComparison {
  const JournalMoodComparison({
    required this.journaled,
    required this.notJournaled,
  });

  final MoodSummary journaled;
  final MoodSummary notJournaled;
}

/// Compares average mood on days with and without a journal entry since
/// [since]. Returns null unless each side has at least [minDaysEach] mood
/// days, so a single lucky day never reads as a pattern.
JournalMoodComparison? compareMoodByJournal(
  Map<DateTime, DayMood> byDay,
  Iterable<JournalEntry> journals, {
  required DateTime since,
  int minDaysEach = 3,
}) {
  final first = dayOf(since);
  final journalDays = journals.map((entry) => dayOf(entry.createdAt)).toSet();
  final withJournal = <DayMood>[];
  final withoutJournal = <DayMood>[];
  for (final day in byDay.values) {
    if (day.day.isBefore(first)) {
      continue;
    }
    (journalDays.contains(day.day) ? withJournal : withoutJournal).add(day);
  }

  if (withJournal.length < minDaysEach || withoutJournal.length < minDaysEach) {
    return null;
  }

  MoodSummary summarize(List<DayMood> days) {
    return MoodSummary(
      average:
          days.fold<double>(0, (sum, day) => sum + day.average) / days.length,
      checkIns: days.fold<int>(0, (sum, day) => sum + day.entries.length),
      days: days.length,
    );
  }

  return JournalMoodComparison(
    journaled: summarize(withJournal),
    notJournaled: summarize(withoutJournal),
  );
}
