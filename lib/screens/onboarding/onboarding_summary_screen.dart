import 'package:flutter/material.dart';

import '../../models/check_in_settings.dart';
import '../../models/diagnosed_condition.dart';
import '../../models/privacy_security_settings.dart';
import '../../models/wellness_goal.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';

class OnboardingSummaryScreen extends StatefulWidget {
  const OnboardingSummaryScreen({
    super.key,
    required this.localStorageService,
    required this.notificationService,
  });

  final LocalStorageService localStorageService;
  final NotificationService notificationService;

  @override
  State<OnboardingSummaryScreen> createState() =>
      _OnboardingSummaryScreenState();
}

class _OnboardingSummaryScreenState extends State<OnboardingSummaryScreen> {
  List<DiagnosedCondition> _conditions = [];
  List<WellnessGoal> _goals = [];
  PrivacySecuritySettings _privacySettings = PrivacySecuritySettings.defaults();
  CheckInSettings _checkInSettings = CheckInSettings.defaults();
  bool _loading = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final results = await Future.wait([
      widget.localStorageService.loadDiagnosedConditions(),
      widget.localStorageService.loadWellnessGoals(),
      widget.localStorageService.loadPrivacySettings(),
      widget.localStorageService.loadCheckInSettings(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _conditions = results[0] as List<DiagnosedCondition>;
      _goals = results[1] as List<WellnessGoal>;
      _privacySettings = results[2] as PrivacySecuritySettings;
      _checkInSettings = results[3] as CheckInSettings;
      _loading = false;
    });
  }

  Future<void> _finishOnboarding() async {
    setState(() => _finishing = true);

    await widget.localStorageService.saveOnboardingCompleted(true);
    await widget.notificationService.applyCheckInSettings(_checkInSettings);

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeGoals = _goals.where((goal) => goal.active).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding Summary')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Text(
                    'You are ready to begin',
                    style: textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF173B35),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'VitaMind will use these preferences to keep your dashboard, tips, and reminders more relevant.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF5E746D),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SummaryCard(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Diagnosed conditions',
                    value: _conditions.isEmpty
                        ? 'No diagnosed conditions added yet.'
                        : _conditions
                              .map((condition) => condition.name)
                              .join(', '),
                  ),
                  _SummaryCard(
                    icon: Icons.flag_outlined,
                    title: 'Active wellness goals',
                    value: activeGoals.isEmpty
                        ? 'No active goals yet.'
                        : activeGoals.map((goal) => goal.title).join(', '),
                  ),
                  _SummaryCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Check-ins',
                    value: _checkInSettings.enabled
                        ? '${_checkInSettings.frequency.label} at ${_formatTime(context, _checkInSettings)}'
                        : 'Daily check-ins are off.',
                  ),
                  _SummaryCard(
                    icon: Icons.psychology_alt_outlined,
                    title: 'Future AI consent',
                    value: _privacySettings.aiHealthConsent
                        ? 'Consent is on for future VitaMind Plus AI features.'
                        : 'Consent is off. The free Health Log Explainer still works.',
                  ),
                  const SizedBox(height: 10),
                  const _DisclaimerCard(),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _finishing ? null : _finishOnboarding,
                    icon: _finishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Finish Setup'),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatTime(BuildContext context, CheckInSettings settings) {
    return settings.time.format(context);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E8E2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF173B35),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5E746D),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAD8A8)),
      ),
      child: const Text(
        'This is not medical advice or a diagnosis.',
        style: TextStyle(color: Color(0xFF6E5A28), fontWeight: FontWeight.w800),
      ),
    );
  }
}
