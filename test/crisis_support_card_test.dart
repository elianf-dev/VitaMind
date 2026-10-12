import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/models/health_log_entry.dart';
import 'package:vitamind/models/health_log_request.dart';
import 'package:vitamind/models/health_log_response.dart';
import 'package:vitamind/screens/health_log_explainer_screen.dart';
import 'package:vitamind/screens/health_log_history_screen.dart';
import 'package:vitamind/screens/support_screen.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/theme/app_theme.dart';
import 'package:vitamind/widgets/crisis_support_card.dart';

const _crisisSymptoms = 'Honestly I just want to die';
const _bannerText =
    'Free version: rule-based explanation with trusted source links.';

Future<LocalStorageService> _storage() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorageService(
    await SharedPreferences.getInstance(),
    MemoryHealthStorage(),
  );
}

void _setSurface(WidgetTester tester, Size logicalSize) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(tester.view.reset);
}

Widget _app({required Widget home, double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
    routes: {SupportScreen.routeName: (context) => const SupportScreen()},
  );
}

// The explainer waits 350 ms and a spinner keeps animating while it does,
// so advance fixed time instead of pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump();
}

Future<void> _explain(
  WidgetTester tester, {
  required String symptoms,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    _app(
      home: HealthLogExplainerScreen(localStorageService: await _storage()),
      textScale: textScale,
    ),
  );
  await _settle(tester);
  // At large text sizes most of the form starts below the built area.
  final symptomsField = find.widgetWithText(TextField, 'Symptoms');
  await _scrollTo(tester, symptomsField);
  await tester.enterText(symptomsField, symptoms);
  final explain = find.text('Explain Health Log');
  await _scrollTo(tester, explain);
  await tester.tap(explain);
  await _settle(tester);
}

/// Labels of every semantics node under [node], in TalkBack traversal order.
List<String> _labelsInTraversalOrder(SemanticsNode node) {
  final labels = <String>[];
  void visit(SemanticsNode current) {
    if (current.label.isNotEmpty) {
      labels.add(current.label);
    }
    for (final child in current.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      visit(child);
    }
  }

  visit(node);
  return labels;
}

int _indexOfLabel(List<String> labels, String text) =>
    labels.indexWhere((label) => label.contains(text));

HealthLogResponse _savedResponse({required bool crisis}) {
  return HealthLogResponse(
    summary: 'You logged Low mood with severity 6/10 for 2 days.',
    relatedTrackedConditions: const ['No diagnosed conditions are saved yet.'],
    wellnessTips: const ['Track sleep.'],
    copingStrategies: const ['Rest.'],
    medicationExplanation: 'No current medications were entered.',
    warningSigns: const ['Seek urgent care for severe chest pain.'],
    doctorQuestions: const ['What should I track?'],
    disclaimer: 'This is not medical advice or a diagnosis.',
    crisisDetected: crisis,
  );
}

Future<void> _openSavedEntry(
  WidgetTester tester, {
  required bool crisis,
}) async {
  final storage = await _storage();
  await storage.addHealthLogEntry(
    HealthLogEntry.create(
      request: const HealthLogRequest(
        symptoms: 'Low mood',
        severity: 6,
        duration: '2 days',
        medications: '',
        doctorNotes: '',
      ),
      response: _savedResponse(crisis: crisis),
    ),
  );
  await tester.pumpWidget(
    _app(home: HealthLogHistoryScreen(localStorageService: storage)),
  );
  await _settle(tester);
  await tester.tap(find.text('Low mood'));
  await _settle(tester);
}

void main() {
  group('Explainer screen', () {
    testWidgets('pins the crisis card above the banner and the summary', (
      tester,
    ) async {
      _setSurface(tester, const Size(411, 3200));
      await _explain(tester, symptoms: _crisisSymptoms);

      final card = find.byType(CrisisSupportCard);
      expect(card, findsOneWidget);
      final cardTop = tester.getTopLeft(card).dy;
      expect(cardTop, lessThan(tester.getTopLeft(find.text(_bannerText)).dy));
      expect(
        cardTop,
        lessThan(tester.getTopLeft(find.text('In plain language')).dy),
      );
      // The Warning signs card keeps 988 as a backup.
      expect(find.textContaining('call or text 988 to reach'), findsOneWidget);
    });

    testWidgets('TalkBack reaches the crisis card before the banner and the '
        'summary', (tester) async {
      final handle = tester.ensureSemantics();
      _setSurface(tester, const Size(411, 3200));
      await _explain(tester, symptoms: _crisisSymptoms);

      final labels = _labelsInTraversalOrder(
        tester.getSemantics(find.byType(ListView)),
      );
      final crisis = _indexOfLabel(labels, CrisisSupportCard.title);
      final banner = _indexOfLabel(labels, 'Free version: rule-based');
      final summary = _indexOfLabel(labels, 'In plain language');
      expect(crisis, isNonNegative);
      expect(banner, isNonNegative);
      expect(summary, isNonNegative);
      expect(crisis, lessThan(banner));
      expect(crisis, lessThan(summary));
      handle.dispose();
    });

    testWidgets('no crisis card for an ordinary log', (tester) async {
      _setSurface(tester, const Size(411, 3200));
      await _explain(tester, symptoms: 'Headache and nausea');

      expect(find.text('In plain language'), findsOneWidget);
      expect(find.byType(CrisisSupportCard), findsNothing);
      expect(find.text(CrisisSupportCard.title), findsNothing);
    });

    for (final scale in [2.0, 3.0]) {
      testWidgets('crisis card renders at text scale $scale on 360x690', (
        tester,
      ) async {
        _setSurface(tester, const Size(360, 690));
        // Record layout errors instead of failing on the first one. The
        // "In plain language" eyebrow row in the summary card below has a
        // pre-existing overflow at 2x (not part of A1), so this test fails
        // only on errors that come from the crisis card.
        final errors = <FlutterErrorDetails>[];
        final original = FlutterError.onError;
        FlutterError.onError = errors.add;
        try {
          await _explain(tester, symptoms: _crisisSymptoms, textScale: scale);

          final card = find.byType(CrisisSupportCard);
          await _scrollTo(tester, card);
          expect(card, findsOneWidget);
          final cardRect = tester.getRect(card);
          for (final label in ['Call 988', 'Text 988', 'Need help now']) {
            final button = find.text(label);
            await _scrollTo(tester, button);
            final buttonRect = tester.getRect(
              find.ancestor(
                of: button,
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              ),
            );
            final currentCard = tester.getRect(card);
            expect(buttonRect.left, greaterThanOrEqualTo(currentCard.left));
            expect(buttonRect.right, lessThanOrEqualTo(currentCard.right));
            expect(buttonRect.height, greaterThanOrEqualTo(48), reason: label);
          }
          expect(cardRect.width, lessThanOrEqualTo(360));
        } finally {
          FlutterError.onError = original;
        }
        final cardErrors = errors.where(
          (details) => details.toString().contains('crisis_support_card.dart'),
        );
        expect(cardErrors, isEmpty);
      });
    }

    testWidgets('tapping Need help now opens the support screen', (
      tester,
    ) async {
      _setSurface(tester, const Size(411, 3200));
      await _explain(tester, symptoms: _crisisSymptoms);

      await tester.tap(
        find.descendant(
          of: find.byType(CrisisSupportCard),
          matching: find.text('Need help now'),
        ),
      );
      await _settle(tester);

      expect(find.byType(SupportScreen), findsOneWidget);
    });
  });

  group('Crisis card on its own', () {
    for (final scale in [2.0, 3.0]) {
      testWidgets('has 48 dp actions and no overflow at text scale $scale', (
        tester,
      ) async {
        _setSurface(tester, const Size(360, 690));
        await tester.pumpWidget(
          _app(
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: const [CrisisSupportCard()],
              ),
            ),
            textScale: scale,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        for (final label in ['Call 988', 'Text 988', 'Need help now']) {
          final button = find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          );
          expect(button, findsOneWidget, reason: label);
          final size = tester.getSize(button);
          expect(size.height, greaterThanOrEqualTo(48), reason: label);
          expect(size.width, greaterThanOrEqualTo(48), reason: label);
        }
      });
    }
  });

  group('History detail sheet', () {
    testWidgets('shows the crisis card above What you entered', (tester) async {
      _setSurface(tester, const Size(411, 3200));
      await _openSavedEntry(tester, crisis: true);

      final card = find.byType(CrisisSupportCard);
      expect(card, findsOneWidget);
      expect(
        tester.getTopLeft(card).dy,
        lessThan(tester.getTopLeft(find.text('What you entered')).dy),
      );
    });

    testWidgets('no crisis card for a saved ordinary entry', (tester) async {
      _setSurface(tester, const Size(411, 3200));
      await _openSavedEntry(tester, crisis: false);

      expect(find.text('What you entered'), findsOneWidget);
      expect(find.byType(CrisisSupportCard), findsNothing);
    });
  });

  group('Call/Text launch failure (A1 fix round 1)', () {
    // url_launcher's default platform in tests talks over this channel.
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final launched = <String>[];

    void mockLauncher({bool throws = false}) {
      launched.clear();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'launch') {
          launched.add((call.arguments as Map)['url'] as String);
          if (throws) {
            throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
          }
          return false;
        }
        return false;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    }

    Finder failureMessage() => find.text(CrisisSupportCard.launchFailedMessage);

    void expectVisibleFailure(WidgetTester tester) {
      expect(failureMessage(), findsOneWidget);
      expect(CrisisSupportCard.launchFailedMessage, contains('988'));
      expect(CrisisSupportCard.launchFailedMessage, contains('911'));
      // It must be the topmost thing at its own position (not under a sheet).
      final center = tester.getCenter(failureMessage());
      final hit = tester.hitTestOnBinding(center);
      final textRender = tester.renderObject(failureMessage());
      expect(
        hit.path.any((entry) => identical(entry.target, textRender)),
        isTrue,
        reason: 'the failure message is covered by something else',
      );
      expect(
        tester.getSemantics(failureMessage()),
        isSemantics(
          isLiveRegion: true,
          label: CrisisSupportCard.launchFailedMessage,
        ),
      );
    }

    testWidgets('history sheet shows a visible, announced message when Call '
        '988 fails', (tester) async {
      final handle = tester.ensureSemantics();
      mockLauncher();
      _setSurface(tester, const Size(411, 3200));
      await _openSavedEntry(tester, crisis: true);
      expect(failureMessage(), findsNothing);

      await tester.tap(find.text('Call 988'));
      await _settle(tester);

      expect(launched, ['tel:988']);
      expectVisibleFailure(tester);
      handle.dispose();
    });

    testWidgets('history sheet shows the message when Text 988 throws', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      mockLauncher(throws: true);
      _setSurface(tester, const Size(411, 3200));
      await _openSavedEntry(tester, crisis: true);

      await tester.tap(find.text('Text 988'));
      await _settle(tester);

      expect(launched, ['sms:988']);
      expectVisibleFailure(tester);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('explainer screen shows a visible, announced message when '
        'Call 988 fails', (tester) async {
      final handle = tester.ensureSemantics();
      mockLauncher();
      _setSurface(tester, const Size(411, 3200));
      await _explain(tester, symptoms: _crisisSymptoms);

      await tester.tap(find.text('Call 988'));
      await _settle(tester);

      expect(launched, ['tel:988']);
      expectVisibleFailure(tester);
      handle.dispose();
    });

    testWidgets('failure message fits at text scale 3.0 on 360x690', (
      tester,
    ) async {
      mockLauncher();
      _setSurface(tester, const Size(360, 690));
      await tester.pumpWidget(
        _app(
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: const [CrisisSupportCard()],
            ),
          ),
          textScale: 3,
        ),
      );
      await tester.ensureVisible(find.text('Call 988'));
      await tester.pump();
      await tester.tap(find.text('Call 988'));
      await _settle(tester);
      await tester.ensureVisible(failureMessage());
      await tester.pump();

      expect(failureMessage(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
