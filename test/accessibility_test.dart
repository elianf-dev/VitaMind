import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/main.dart';
import 'package:vitamind/models/journal_entry.dart';
import 'package:vitamind/models/mood_entry.dart';
import 'package:vitamind/models/symptom_entry.dart';
import 'package:vitamind/screens/support_screen.dart';
import 'package:vitamind/services/auth_service.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/firestore_service.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/services/notification_service.dart';
import 'package:vitamind/widgets/insights/daily_line_chart.dart';

Future<LocalStorageService> _seededStorage() async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorageService(
    await SharedPreferences.getInstance(),
    MemoryHealthStorage(),
  );
  final now = DateTime.now();
  await storage.saveMoodEntries([
    MoodEntry(id: 'm1', emoji: '😄', label: 'Happy', notes: '', createdAt: now),
  ]);
  await storage.saveSymptomEntries([
    SymptomEntry(
      id: 's1',
      symptom: 'Headache',
      severity: 6,
      duration: '',
      notes: '',
      createdAt: now,
    ),
  ]);
  await storage.saveJournalEntries([
    JournalEntry(id: 'j1', text: 'note', createdAt: now),
  ]);
  return storage;
}

/// Pumps the signed-in dashboard on a typical phone (411 x 914 dp), or a
/// taller one so content below the fold is built.
Future<void> _pumpDashboard(WidgetTester tester, {bool tall = false}) async {
  tester.view.physicalSize = Size(1080, tall ? 6000 : 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    VitaMindApp(
      authService: AuthService(firebaseAvailable: false),
      firestoreService: const FirestoreService(enabled: false),
      localStorageService: await _seededStorage(),
      notificationService: NotificationService(),
      onboardingCompleted: true,
      guestSessionActive: true,
    ),
  );
  await _settle(tester);
}

// Some screens keep a progress indicator spinning, so pumpAndSettle never
// returns; advance a fixed amount of time instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.text(tab).last);
  await _settle(tester);
}

// The chart's per-day reading, for example "Oct 5: Very pleasant".
final _dayReadout = RegExp(r'^[A-Z][a-z]{2} \d{1,2}: Very pleasant$');

const _tabs = ['Home', 'Mood', 'Journal', 'Insights', 'Profile'];

void main() {
  for (final tab in _tabs) {
    testWidgets('$tab tab meets tap target, label, and contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpDashboard(tester);
      await _openTab(tester, tab);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  testWidgets('custom mood buttons and calendar days are screen-reader '
      'actionable', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpDashboard(tester);

    // Home quick mood: one node with label and tap, no emoji name.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Log mood: Low')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(find.bySemanticsLabel('Add goal'), findsWidgets);

    await _openTab(tester, 'Mood');
    expect(
      tester.getSemantics(find.bySemanticsLabel('Anxious')),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        hasSelectedState: true,
        isSelected: false,
      ),
    );
    expect(find.bySemanticsLabel(RegExp('😣')), findsNothing);

    await _openTab(tester, 'Insights');
    final today = find.bySemanticsLabel(RegExp(r'today, Very pleasant'));
    expect(
      tester.getSemantics(today),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Previous month')),
      isSemantics(isButton: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('calendar days are reachable and selectable by keyboard', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _openTab(tester, 'Insights');

    // Focus a past day without a check-in (as Tab would), then press Enter.
    final firstDay = find.bySemanticsLabel(RegExp(r', no check-in$')).first;
    final dayNumber = find.descendant(
      of: firstDay,
      matching: find.byType(Text),
    );
    final focusNode = Focus.of(tester.element(dayNumber));
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.textContaining('· No check-in'), findsOneWidget);
  });

  testWidgets('every tab lays out with high contrast, reduced motion, bold '
      'text, and 2x text size', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(
          highContrast: true,
          disableAnimations: true,
          boldText: true,
        );
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await _pumpDashboard(tester);
    for (final tab in _tabs) {
      await _openTab(tester, tab);
      // Overflow and other layout errors fail the test on their own.
      expect(tester.takeException(), isNull, reason: tab);
    }

    // High contrast swaps glass for opaque surfaces, so nothing blurs.
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('trend chart steps through days by screen reader and keyboard', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpDashboard(tester, tall: true);
    await _openTab(tester, 'Insights');

    final chart = find.bySemanticsLabel(RegExp('^Mood trend for the last'));
    expect(
      tester.getSemantics(chart),
      isSemantics(hasIncreaseAction: true, hasDecreaseAction: true),
    );

    // TalkBack "adjust down" reads the most recent logged day.
    tester.semantics.performAction(
      find.semantics.byLabel(RegExp('^Mood trend for the last')),
      SemanticsAction.decrease,
    );
    await tester.pump();
    expect(find.textContaining(_dayReadout), findsOneWidget);

    // Keyboard: focus the chart, then arrow keys move the reading.
    final chartFocus = Focus.of(
      tester.element(
        find
            .descendant(
              of: find.byType(DailyLineChart).first,
              matching: find.byType(CustomPaint),
            )
            .first,
      ),
    );
    chartFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    // Only one day has data, so the reading stays on it rather than moving
    // to an empty day.
    expect(find.textContaining(_dayReadout), findsOneWidget);
    handle.dispose();
  });

  testWidgets('screens open without a transition when reduce motion is on', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await _pumpDashboard(tester);

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/support');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    // A normal transition starts the new page offset or faded; here it is
    // already in its final position on the first frame.
    final transitions = find.ancestor(
      of: find.byType(SupportScreen),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is FadeTransition ||
            widget is SlideTransition ||
            widget is ScaleTransition,
      ),
    );
    for (final element in transitions.evaluate()) {
      final widget = element.widget;
      if (widget is FadeTransition) {
        expect(widget.opacity.value, 1);
      }
    }
    expect(tester.getTopLeft(find.byType(SupportScreen)), Offset.zero);
  });

  testWidgets('bottom sheets appear without sliding when reduce motion is on', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await _pumpDashboard(tester);
    await _openTab(tester, 'Journal');

    // Opening a saved entry shows it in a bottom sheet.
    await tester.tap(find.text('note').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final firstFrame = tester.getTopLeft(find.byType(BottomSheet));
    await _settle(tester);
    expect(tester.getTopLeft(find.byType(BottomSheet)), firstFrame);
  });

  for (final largeText in [false, true]) {
    testWidgets('secondary screens meet guidelines'
        '${largeText ? ' at 2x text with high contrast' : ''}', (tester) async {
      if (largeText) {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(
              highContrast: true,
              disableAnimations: true,
              boldText: true,
            );
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
      }
      final handle = tester.ensureSemantics();
      await _pumpDashboard(tester);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );

      for (final route in _secondaryRoutes) {
        navigator.pushNamed(route);
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: route);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        if (!largeText) {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        navigator.pop();
        await _settle(tester);
      }
      handle.dispose();
    });
  }
}

const _secondaryRoutes = [
  '/',
  '/onboarding',
  '/symptoms',
  '/health-log-explainer',
  '/health-log-history',
  '/diagnosed-conditions',
  '/wellness-goals',
  '/privacy-security',
  '/vitamind-plus',
  '/support',
];
