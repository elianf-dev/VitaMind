import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../data/mood_choices.dart';
import '../models/check_in_settings.dart';
import '../models/diagnosed_condition.dart';
import '../models/mood_entry.dart';
import '../models/privacy_security_settings.dart';
import '../models/wellness_goal.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/mood_log_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_section_header.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/support_nudge_card.dart';
import 'support_screen.dart';
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
    this.onMoodLogged,
  });

  final ValueChanged<int> onNavigate;

  /// Called after a quick mood log so other tabs can refresh their history.
  final VoidCallback? onMoodLogged;
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
  bool _savingMood = false;
  bool _showSupportNudge = false;

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
      } on Object catch (error) {
        debugPrint('VitaMind: failed to sync check-in settings: $error');
        // Local settings remain the source of truth until cloud sync recovers.
      }
    }
    await widget.notificationService.applyCheckInSettings(settings);
  }

  Future<void> _logQuickMood(MoodChoice mood) async {
    setState(() {
      _savingMood = true;
      _showSupportNudge = mood.offerSupport;
    });

    final synced = await recordMoodEntry(
      entry: MoodEntry.create(emoji: mood.emoji, label: mood.label, notes: ''),
      authService: widget.authService,
      firestoreService: widget.firestoreService,
      localStorageService: widget.localStorageService,
    );
    widget.onMoodLogged?.call();

    if (!mounted) {
      return;
    }
    setState(() => _savingMood = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? '${mood.label} mood saved'
              : 'Mood saved locally. Cloud sync is unavailable.',
        ),
      ),
    );
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
                  _todayLabel(),
                  style: AppTextStyles.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${_greeting()}, friend.',
                  style: AppTextStyles.display(size: 26),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Start with one quick check-in.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
          const AppSectionHeader(
            title: 'How are you feeling today?',
            subtitle: 'Tap one to log it. Add notes anytime in Mood.',
          ),
          VitaMindCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                for (final mood in moodChoices)
                  Expanded(
                    child: _QuickMoodButton(
                      mood: mood,
                      onTap: _savingMood ? null : () => _logQuickMood(mood),
                    ),
                  ),
              ],
            ),
          ),
          if (_showSupportNudge)
            SupportNudgeCard(
              onDismiss: () => setState(() => _showSupportNudge = false),
            ),
          const SizedBox(height: AppSpacing.md),
          VitaMindActionCard(
            icon: LucideIcons.activity,
            title: 'Log symptoms',
            subtitle: 'Track what you feel and how severe it is.',
            accentColor: AppColors.blue,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.mutedIcon,
            ),
            onTap: () => Navigator.of(context).pushNamed('/symptoms'),
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
            icon: LucideIcons.pencil,
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
            icon: LucideIcons.bell,
            title: 'Gentle check-ins',
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
            icon: LucideIcons.square_check,
            title: 'Health Log Explainer',
            subtitle: 'Plain-language notes with trusted sources.',
            accentColor: AppColors.coral,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.mutedIcon,
            ),
            onTap: () =>
                Navigator.of(context).pushNamed('/health-log-explainer'),
          ),
          VitaMindActionCard(
            icon: LucideIcons.trending_up,
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
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(SupportScreen.routeName),
              icon: const Icon(Icons.favorite_outline),
              label: const Text('Need help now?'),
            ),
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

class _QuickMoodButton extends StatelessWidget {
  const _QuickMoodButton({required this.mood, required this.onTap});

  final MoodChoice mood;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Log mood: ${mood.label}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                mood.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.meta(
                  context,
                )?.copyWith(color: AppColors.bodyText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
