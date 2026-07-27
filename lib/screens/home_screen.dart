import 'package:flutter/material.dart';

import '../models/check_in_settings.dart';
import '../models/diagnosed_condition.dart';
import '../models/privacy_security_settings.dart';
import '../models/wellness_goal.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_section_header.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/vita_mind_action_card.dart';
import '../widgets/vita_mind_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.authService,
    required this.firestoreService,
    required this.localStorageService,
    required this.notificationService,
  });

  final ValueChanged<int> onNavigate;
  final AuthService authService;
  final FirestoreService firestoreService;
  final LocalStorageService localStorageService;
  final NotificationService notificationService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DiagnosedCondition> _conditions = [];
  List<WellnessGoal> _goals = [];
  CheckInSettings _checkInSettings = CheckInSettings.defaults();
  PrivacySecuritySettings _privacySettings = PrivacySecuritySettings.defaults();
  bool _loadingPersonalization = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final results = await Future.wait([
      widget.localStorageService.loadDiagnosedConditions(),
      widget.localStorageService.loadWellnessGoals(),
      widget.localStorageService.loadCheckInSettings(),
      widget.localStorageService.loadPrivacySettings(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _conditions = results[0] as List<DiagnosedCondition>;
      _goals = results[1] as List<WellnessGoal>;
      _checkInSettings = results[2] as CheckInSettings;
      _privacySettings = results[3] as PrivacySecuritySettings;
      _loadingPersonalization = false;
    });
  }

  Future<void> _toggleCheckIn(bool enabled) async {
    final settings = _checkInSettings.copyWith(enabled: enabled);
    setState(() => _checkInSettings = settings);
    await widget.localStorageService.saveCheckInSettings(settings);
    final userId = widget.authService.userId;
    if (userId != null && widget.firestoreService.enabled) {
      try {
        await widget.firestoreService.saveCheckInSettings(userId, settings);
      } on Object {
        // Local settings remain the source of truth until cloud sync recovers.
      }
    }
    await widget.notificationService.applyCheckInSettings(settings);
  }

  Future<void> _openAndRefresh(String routeName) async {
    await Navigator.of(context).pushNamed(routeName);
    await _loadDashboardData();
  }

  Future<void> _incrementGoal(WellnessGoal goal) async {
    final updatedGoal = goal.copyWith(
      progress: (goal.progress + 0.2).clamp(0, 1).toDouble(),
    );
    final updatedGoals = _goals
        .map((item) => item.id == goal.id ? updatedGoal : item)
        .toList();
    setState(() => _goals = updatedGoals);
    await widget.localStorageService.saveWellnessGoals(updatedGoals);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeGoals = _goals.where((goal) => goal.active).take(2).toList();
    final conditionSummary = _conditionSummary();

    return SafeArea(
      child: ListView(
        padding: AppSpacing.tabPage,
        children: [
          VitaMindCard(
            backgroundColor: AppColors.primaryMist,
            borderColor: AppColors.primarySoft,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, friend',
                  style: AppTextStyles.pageTitle(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _todayLabel(),
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Start with one quick check-in.',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const AppSectionHeader(title: 'How are you feeling today?'),
          Row(
            children: [
              Expanded(
                child: VitaMindActionCard(
                  compact: true,
                  icon: Icons.mood_outlined,
                  title: 'Log mood',
                  subtitle: 'Quick mood check',
                  accentColor: AppColors.primary,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.mutedIcon,
                  ),
                  onTap: () => widget.onNavigate(1),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: VitaMindActionCard(
                  compact: true,
                  icon: Icons.monitor_heart_outlined,
                  title: 'Log symptoms',
                  subtitle: 'Track severity',
                  accentColor: AppColors.blue,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.mutedIcon,
                  ),
                  onTap: () => Navigator.of(context).pushNamed('/symptoms'),
                ),
              ),
            ],
          ),
          AppSectionHeader(
            title: 'Current goals',
            actionLabel: _goals.isEmpty ? 'Add' : 'View all',
            onAction: () => _openAndRefresh('/wellness-goals'),
          ),
          if (_loadingPersonalization)
            const LinearProgressIndicator(minHeight: 3)
          else if (activeGoals.isEmpty)
            EmptyStateCard(
              icon: Icons.flag_outlined,
              title: 'No active goals yet',
              body: 'Add one small goal to keep it visible on your dashboard.',
              actionLabel: 'Add goal',
              onAction: () => _openAndRefresh('/wellness-goals'),
            )
          else
            for (final goal in activeGoals)
              GoalCard(
                goal: goal,
                compact: true,
                onIncrement: () => _incrementGoal(goal),
              ),
          const AppSectionHeader(title: 'Today'),
          VitaMindActionCard(
            icon: Icons.edit_note_outlined,
            title: 'Journal',
            subtitle: 'Write a thought, pattern, or small win.',
            accentColor: AppColors.purple,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.mutedIcon,
            ),
            onTap: () => widget.onNavigate(2),
          ),
          VitaMindActionCard(
            icon: Icons.notifications_active_outlined,
            title: 'Reminders',
            subtitle: _checkInSettings.enabled
                ? '${_checkInSettings.frequency.label} check-in at ${_checkInSettings.time.format(context)} for mood, journal, symptoms, or goals.'
                : 'Gentle check-ins are turned off.',
            accentColor: AppColors.warning,
            trailing: Switch(
              value: _checkInSettings.enabled,
              onChanged: _loadingPersonalization
                  ? null
                  : (value) => _toggleCheckIn(value),
            ),
          ),
          VitaMindActionCard(
            icon: Icons.fact_check_outlined,
            title: 'Health Log Explainer',
            subtitle: 'Rule-based tips with trusted source links.',
            accentColor: AppColors.primary,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.mutedIcon,
            ),
            onTap: () =>
                Navigator.of(context).pushNamed('/health-log-explainer'),
          ),
          VitaMindActionCard(
            icon: Icons.insights_outlined,
            title: 'Insights',
            subtitle: 'Review simple patterns from your local logs.',
            accentColor: AppColors.blue,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.mutedIcon,
            ),
            onTap: () => widget.onNavigate(3),
          ),
          VitaMindActionCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Diagnosed conditions',
            subtitle: conditionSummary,
            accentColor: AppColors.secondary,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.mutedIcon,
            ),
            onTap: () => _openAndRefresh('/diagnosed-conditions'),
          ),
        ],
      ),
    );
  }

  String _conditionSummary() {
    if (_privacySettings.hideSensitiveHealthDetails) {
      return _conditions.isEmpty
          ? 'No diagnosed conditions added yet.'
          : 'Tracking ${_conditions.length} condition${_conditions.length == 1 ? '' : 's'}.';
    }

    if (_conditions.isEmpty) {
      return 'No diagnosed conditions added yet.';
    }

    final names = _conditions
        .map((condition) => condition.name)
        .take(3)
        .join(', ');
    if (_conditions.length <= 3) {
      return 'Tracking: $names';
    }

    return 'Tracking: $names, and ${_conditions.length - 3} more';
  }
}
