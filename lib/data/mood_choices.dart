class MoodChoice {
  const MoodChoice(
    this.emoji,
    this.label, {
    required this.score,
    this.offerSupport = false,
  });

  final String emoji;
  final String label;

  /// Pleasantness from -2 (very unpleasant) to 2 (very pleasant), used to
  /// chart mood over time.
  final int score;

  /// Whether logging this mood should gently surface support options.
  final bool offerSupport;
}

const List<MoodChoice> moodChoices = [
  MoodChoice('😄', 'Happy', score: 2),
  MoodChoice('🙂', 'Calm', score: 1),
  MoodChoice('😐', 'Okay', score: 0),
  MoodChoice('😣', 'Anxious', score: -1, offerSupport: true),
  MoodChoice('😟', 'Low', score: -2, offerSupport: true),
];

/// Pleasantness score for a saved mood label, or null for labels VitaMind no
/// longer offers (those entries are skipped in charts rather than guessed).
int? moodScoreForLabel(String label) {
  final normalized = label.trim().toLowerCase();
  for (final choice in moodChoices) {
    if (choice.label.toLowerCase() == normalized) {
      return choice.score;
    }
  }
  return null;
}
