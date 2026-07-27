List<T> mergeEntriesById<T>({
  required Iterable<T> localEntries,
  required Iterable<T> cloudEntries,
  required String Function(T entry) idOf,
  required DateTime Function(T entry) createdAtOf,
}) {
  final entriesById = <String, T>{};

  for (final entry in localEntries) {
    entriesById[idOf(entry)] = entry;
  }
  for (final entry in cloudEntries) {
    entriesById[idOf(entry)] = entry;
  }

  final entries = entriesById.values.toList();
  entries.sort((a, b) => createdAtOf(b).compareTo(createdAtOf(a)));
  return entries;
}
