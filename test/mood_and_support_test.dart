import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitamind/screens/home_screen.dart';
import 'package:vitamind/screens/mood_tracker_screen.dart';
import 'package:vitamind/screens/support_screen.dart';
import 'package:vitamind/services/auth_service.dart';
import 'package:vitamind/services/encrypted_health_storage.dart';
import 'package:vitamind/services/firestore_service.dart';
import 'package:vitamind/services/local_storage_service.dart';
import 'package:vitamind/services/notification_service.dart';
import 'package:vitamind/widgets/vita_mind_buttons.dart';

Future<LocalStorageService> _storage() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return LocalStorageService(preferences, MemoryHealthStorage());
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
    routes: {SupportScreen.routeName: (context) => const SupportScreen()},
  );
}

void main() {
  testWidgets('one tap on Home logs a mood and offers support for Low', (
    tester,
  ) async {
    final storage = await _storage();
    var moodLoggedCalls = 0;

    await tester.pumpWidget(
      _wrap(
        HomeScreen(
          onNavigate: (_) {},
          onMoodLogged: () => moodLoggedCalls++,
          authService: AuthService(firebaseAvailable: false),
          firestoreService: const FirestoreService(enabled: false),
          localStorageService: storage,
          notificationService: NotificationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Log mood: Low'));
    await tester.pumpAndSettle();

    final moods = await storage.loadMoodEntries();
    expect(moods.single.label, 'Low');
    expect(moodLoggedCalls, 1);
    expect(
      find.text('Thanks for checking in. Hard days count too.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(
      find.text('Thanks for checking in. Hard days count too.'),
      findsNothing,
    );
  });

  testWidgets('a pleasant quick mood does not show the support card', (
    tester,
  ) async {
    final storage = await _storage();

    await tester.pumpWidget(
      _wrap(
        HomeScreen(
          onNavigate: (_) {},
          authService: AuthService(firebaseAvailable: false),
          firestoreService: const FirestoreService(enabled: false),
          localStorageService: storage,
          notificationService: NotificationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Log mood: Happy'));
    await tester.pumpAndSettle();

    expect((await storage.loadMoodEntries()).single.label, 'Happy');
    expect(
      find.text('Thanks for checking in. Hard days count too.'),
      findsNothing,
    );
  });

  testWidgets('Mood screen has no preselected mood', (tester) async {
    final storage = await _storage();

    await tester.pumpWidget(
      _wrap(
        MoodTrackerScreen(
          authService: AuthService(firebaseAvailable: false),
          firestoreService: const FirestoreService(enabled: false),
          localStorageService: storage,
        ),
      ),
    );
    await tester.pumpAndSettle();

    VitaMindPrimaryButton saveButton() =>
        tester.widget(find.byType(VitaMindPrimaryButton));
    expect(saveButton().onPressed, isNull);

    await tester.tap(find.text('Calm'));
    await tester.pump();
    expect(saveButton().onPressed, isNotNull);
  });

  testWidgets('support screen offers 911, 988 call and text, and helplines', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SupportScreen()));

    expect(find.text('Call 911'), findsOneWidget);
    expect(find.text('Call 988'), findsOneWidget);
    expect(find.text('Text 988'), findsOneWidget);
    expect(find.text('Find a helpline'), findsOneWidget);
    expect(find.textContaining('VitaMind Plus'), findsNothing);
  });
}
