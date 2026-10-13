/// Whole-word matching for the rule-based health-log explainer.
///
/// Substring checks such as `text.contains('ibs')` misfire on words like
/// "ribs", "Spain" or "breathtaking". Normalize the text once with
/// [normalizeForMatch], then check terms with [containsTerm], which only
/// matches whole words or whole phrases. There is no stemming: list plural
/// and other forms as separate terms. (architecture.md §11.14, Matching 1–2.)
///
/// The crisis check in `HealthLogExplainerService` deliberately does NOT use
/// this helper. It keeps substring matching, because a false positive there
/// costs far less than a miss.
library;

final RegExp _nonWordCharacters = RegExp(r"[^\p{L}\p{N}']+", unicode: true);

/// Lowercases [text], turns a curly apostrophe into a straight one, turns
/// hyphens, punctuation and whitespace runs into one space, and pads a single
/// space at both ends, so every word sits between two spaces.
String normalizeForMatch(String text) {
  final words = text
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(_nonWordCharacters, ' ')
      .trim();
  return words.isEmpty ? ' ' : ' $words ';
}

/// True when [term] (lowercase; a word or a phrase of words separated by
/// single spaces) appears as whole words in [normalized], which must come
/// from [normalizeForMatch].
bool containsTerm(String normalized, String term) =>
    normalized.contains(' $term ');

/// True when any of [terms] appears as whole words in [normalized].
bool containsAnyTerm(String normalized, Iterable<String> terms) =>
    terms.any((term) => containsTerm(normalized, term));
