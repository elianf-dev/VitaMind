import 'package:flutter_test/flutter_test.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/utils/entry_merge.dart';

void main() {
  test('merges local and cloud entries by id in newest-first order', () {
    final older = MoodEntry(
      id: 'older',
      emoji: '🙂',
      label: 'Calm',
      notes: '',
      createdAt: DateTime(2026, 1, 1),
    );
    final newer = MoodEntry(
      id: 'newer',
      emoji: '😄',
      label: 'Happy',
      notes: '',
      createdAt: DateTime(2026, 1, 2),
    );
    final cloudVersion = MoodEntry(
      id: 'older',
      emoji: '🙂',
      label: 'Calm',
      notes: 'Synced note',
      createdAt: older.createdAt,
    );

    final entries = mergeEntriesById(
      localEntries: [older, newer],
      cloudEntries: [cloudVersion],
      idOf: (entry) => entry.id,
      createdAtOf: (entry) => entry.createdAt,
    );

    expect(entries.map((entry) => entry.id), ['newer', 'older']);
    expect(entries.last.notes, 'Synced note');
  });
}
