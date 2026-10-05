class MoodChoice {
  const MoodChoice(this.emoji, this.label, {this.offerSupport = false});

  final String emoji;
  final String label;

  /// Whether logging this mood should gently surface support options.
  final bool offerSupport;
}

const List<MoodChoice> moodChoices = [
  MoodChoice('😄', 'Happy'),
  MoodChoice('🙂', 'Calm'),
  MoodChoice('😐', 'Okay'),
  MoodChoice('😟', 'Low', offerSupport: true),
  MoodChoice('😣', 'Anxious', offerSupport: true),
];
