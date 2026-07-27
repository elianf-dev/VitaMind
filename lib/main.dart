import 'package:flutter/material.dart';

import 'screens/health_log_explainer_screen.dart';
import 'screens/health_log_history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/mood_tracker_screen.dart';
import 'screens/onboarding/diagnosed_illnesses_screen.dart';
import 'screens/onboarding/onboarding_intro_screen.dart';
import 'screens/onboarding/onboarding_summary_screen.dart';
import 'screens/onboarding/privacy_security_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/privacy_security_settings_screen.dart';
import 'screens/symptom_tracker_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/wellness_goals_screen.dart';
import 'screens/vitamind_plus_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_bootstrap_service.dart';
import 'services/firestore_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_shadows.dart';
import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorageService = await LocalStorageService.create();
  final firebaseAvailable = await const FirebaseBootstrapService().initialize();
  final authService = AuthService(firebaseAvailable: firebaseAvailable);
  await authService.initialize();
  localStorageService.setProfileId(authService.userId);

  final firestoreService = FirestoreService(enabled: firebaseAvailable);
  final notificationService = NotificationService();
  await notificationService.initialize();
  final onboardingCompleted = await localStorageService
      .loadOnboardingCompleted();

  var checkInSettings = await localStorageService.loadCheckInSettings();
  final userId = authService.userId;
  if (userId != null && firestoreService.enabled) {
    try {
      checkInSettings =
          await firestoreService.loadCheckInSettings(userId) ?? checkInSettings;
      await localStorageService.saveCheckInSettings(checkInSettings);
    } on Object {
      // Keep the local schedule usable if Firestore is unreachable.
    }
  }
  if (onboardingCompleted) {
    await notificationService.applyCheckInSettings(checkInSettings);
  }

  runApp(
    VitaMindApp(
      authService: authService,
      firestoreService: firestoreService,
      localStorageService: localStorageService,
      notificationService: notificationService,
      onboardingCompleted: onboardingCompleted,
    ),
  );
}

class VitaMindApp extends StatelessWidget {
  const VitaMindApp({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.localStorageService,
    required this.notificationService,
    this.onboardingCompleted = false,
  });

  final AuthService authService;
  final FirestoreService firestoreService;
  final LocalStorageService localStorageService;
  final NotificationService notificationService;
  final bool onboardingCompleted;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitaMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: authService.isLoggedIn
          ? onboardingCompleted
                ? '/dashboard'
                : '/onboarding'
          : '/',
      routes: {
        '/': (context) => WelcomeScreen(
          authService: authService,
          localStorageService: localStorageService,
        ),
        '/onboarding': (context) => const OnboardingIntroScreen(),
        '/onboarding/conditions': (context) => DiagnosedIllnessesScreen(
          localStorageService: localStorageService,
          isOnboarding: true,
        ),
        '/onboarding/goals': (context) => WellnessGoalsScreen(
          localStorageService: localStorageService,
          isOnboarding: true,
        ),
        '/onboarding/privacy': (context) => PrivacySecurityScreen(
          localStorageService: localStorageService,
          notificationService: notificationService,
        ),
        '/onboarding/summary': (context) => OnboardingSummaryScreen(
          localStorageService: localStorageService,
          notificationService: notificationService,
        ),
        '/dashboard': (context) => VitaMindShell(
          authService: authService,
          firestoreService: firestoreService,
          localStorageService: localStorageService,
          notificationService: notificationService,
        ),
        '/symptoms': (context) => SymptomTrackerScreen(
          authService: authService,
          firestoreService: firestoreService,
          localStorageService: localStorageService,
        ),
        '/health-log-explainer': (context) =>
            HealthLogExplainerScreen(localStorageService: localStorageService),
        '/health-log-history': (context) =>
            HealthLogHistoryScreen(localStorageService: localStorageService),
        '/diagnosed-conditions': (context) =>
            DiagnosedIllnessesScreen(localStorageService: localStorageService),
        '/wellness-goals': (context) =>
            WellnessGoalsScreen(localStorageService: localStorageService),
        '/privacy-security': (context) => PrivacySecuritySettingsScreen(
          localStorageService: localStorageService,
          notificationService: notificationService,
        ),
        '/vitamind-plus': (context) => const VitaMindPlusScreen(),
      },
    );
  }
}

class VitaMindShell extends StatefulWidget {
  const VitaMindShell({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.localStorageService,
    required this.notificationService,
  });

  final AuthService authService;
  final FirestoreService firestoreService;
  final LocalStorageService localStorageService;
  final NotificationService notificationService;

  @override
  State<VitaMindShell> createState() => _VitaMindShellState();
}

class _VitaMindShellState extends State<VitaMindShell> {
  int _selectedIndex = 0;
  int _homeRefreshToken = 0;

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        key: ValueKey('home-$_homeRefreshToken'),
        onNavigate: _setSelectedIndex,
        authService: widget.authService,
        firestoreService: widget.firestoreService,
        localStorageService: widget.localStorageService,
        notificationService: widget.notificationService,
      ),
      MoodTrackerScreen(
        authService: widget.authService,
        firestoreService: widget.firestoreService,
        localStorageService: widget.localStorageService,
      ),
      JournalScreen(
        authService: widget.authService,
        firestoreService: widget.firestoreService,
        localStorageService: widget.localStorageService,
      ),
      InsightsScreen(localStorageService: widget.localStorageService),
      ProfileScreen(
        authService: widget.authService,
        firestoreService: widget.firestoreService,
        localStorageService: widget.localStorageService,
        notificationService: widget.notificationService,
      ),
    ];
  }

  void _setSelectedIndex(int index) {
    setState(() {
      if (index == 0 && _selectedIndex != 0) {
        _homeRefreshToken++;
      }
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _buildScreens()),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.raised(strength: 0.8),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _setSelectedIndex,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.mood_outlined),
                selectedIcon: Icon(Icons.mood),
                label: 'Mood',
              ),
              NavigationDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note),
                label: 'Journal',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Insights',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
