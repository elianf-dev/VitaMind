import 'package:flutter_test/flutter_test.dart';
import 'package:vitamind/services/explainer/text_match.dart';

void main() {
  group('normalizeForMatch', () {
    test('lowercases and pads a space at both ends', () {
      expect(normalizeForMatch('Knee PAIN'), ' knee pain ');
    });

    test('turns a curly apostrophe into a straight one', () {
      expect(normalizeForMatch('I don’t know'), " i don't know ");
    });

    test('turns hyphens into spaces', () {
      expect(normalizeForMatch('self-harm'), ' self harm ');
      expect(normalizeForMatch('pre-diabetes'), ' pre diabetes ');
    });

    test('turns punctuation into spaces and collapses whitespace', () {
      expect(normalizeForMatch('pain, nausea.'), ' pain nausea ');
      expect(normalizeForMatch('  pain!!\n\tibs?  '), ' pain ibs ');
      expect(normalizeForMatch('(headache)/migraine'), ' headache migraine ');
    });

    test('an empty or blank string becomes a single space', () {
      expect(normalizeForMatch(''), ' ');
      expect(normalizeForMatch('   '), ' ');
    });
  });

  group('containsTerm', () {
    bool hit(String text, String term) =>
        containsTerm(normalizeForMatch(text), term);

    test('matches whole words and phrases', () {
      expect(hit('knee pain', 'pain'), isTrue);
      expect(hit('Pain', 'pain'), isTrue);
      expect(hit('pain, then nausea', 'pain'), isTrue);
      expect(hit('it was pain.', 'pain'), isTrue);
      expect(hit('I have IBS', 'ibs'), isTrue);
      expect(hit('short of breath', 'breath'), isTrue);
      expect(hit('sudden groin pain today', 'groin pain'), isTrue);
      expect(hit('self-harm', 'self harm'), isTrue);
    });

    test('does not match a term hidden inside another word', () {
      expect(hit('sore ribs', 'ibs'), isFalse);
      expect(hit('back from Spain', 'pain'), isFalse);
      expect(hit('painting all day', 'pain'), isFalse);
      expect(hit('breathtaking view', 'breath'), isFalse);
      expect(hit('headache', 'ache'), isFalse);
      expect(hit('today', 'day'), isFalse);
      expect(hit('since Monday', 'day'), isFalse);
    });

    test('containsAnyTerm is true when one term matches', () {
      final text = normalizeForMatch('pains in my legs');
      expect(containsAnyTerm(text, const ['pain', 'pains']), isTrue);
      expect(containsAnyTerm(text, const ['ache', 'aches']), isFalse);
    });
  });
}
