import 'package:flutter/material.dart';

import '../models/wellness_goal.dart';
import '../services/local_storage_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_section_header.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/goal_card.dart';
import '../widgets/vita_mind_buttons.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';

class WellnessGoalsScreen extends StatefulWidget {
  const WellnessGoalsScreen({
    super.key,
    required this.localStorageService,
    this.isOnboarding = false,
  });

  final LocalStorageService localStorageService;
  final bool isOnboarding;

  @override
  State<WellnessGoalsScreen> createState() => _WellnessGoalsScreenState();
}

class _GoalTemplate {
  const _GoalTemplate(this.title, this.category);

  final String title;
  final String category;
}

class _WellnessGoalsScreenState extends State<WellnessGoalsScreen> {
  static const List<_GoalTemplate> _templates = [
    _GoalTemplate('Drink more water', 'Hydration'),
    _GoalTemplate('Improve sleep', 'Rest'),
    _GoalTemplate('Take medication on time', 'Care plan'),
    _GoalTemplate('Reduce stress', 'Stress'),
    _GoalTemplate('Journal daily', 'Reflection'),
    _GoalTemplate('Move/stretch more', 'Movement'),
    _GoalTemplate('Track symptoms daily', 'Tracking'),
  ];

  static const List<String> _frequencies = [
    'Daily',
    'Every Other Day',
    'Weekly',
  ];

  final TextEditingController _customGoalController = TextEditingController();
  final List<WellnessGoal> _goals = [];
  String _targetFrequency = 'Daily';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final goals = await widget.localStorageService.loadWellnessGoals();

    if (!mounted) {
      return;
    }

    setState(() {
      _goals
        ..clear()
        ..addAll(goals);
      _loading = false;
    });
  }

  bool _hasGoal(String title) {
    return _goals.any(
      (goal) => goal.title.toLowerCase() == title.toLowerCase(),
    );
  }

  Future<void> _saveGoals() async {
    await widget.localStorageService.saveWellnessGoals(_goals);
  }

  Future<void> _addTemplate(_GoalTemplate template) async {
    if (_hasGoal(template.title)) {
      return;
    }

    setState(() {
      _goals.add(
        WellnessGoal.create(
          title: template.title,
          category: template.category,
          targetFrequency: _targetFrequency,
        ),
      );
    });

    await _saveGoals();
  }

  Future<void> _addCustomGoal() async {
    final title = _customGoalController.text.trim();
    if (title.isEmpty || _hasGoal(title)) {
      return;
    }

    setState(() {
      _goals.add(
        WellnessGoal.create(
          title: title,
          category: 'Custom',
          targetFrequency: _targetFrequency,
        ),
      );
      _customGoalController.clear();
    });

    await _saveGoals();
  }

  Future<void> _updateGoal(WellnessGoal updatedGoal) async {
    setState(() {
      final index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
      if (index != -1) {
        _goals[index] = updatedGoal;
      }
    });

    await _saveGoals();
  }

  Future<void> _removeGoal(WellnessGoal goal) async {
    setState(() => _goals.removeWhere((item) => item.id == goal.id));
    await _saveGoals();
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    await _saveGoals();

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (widget.isOnboarding) {
      Navigator.of(context).pushReplacementNamed('/onboarding/privacy');
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness Goals')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: AppSpacing.page,
                children: [
                  const VitaMindPageHeader(
                    title: 'Choose goals to keep close',
                    subtitle:
                        'Start with a few goals that feel useful. You can change them any time.',
                  ),
                  VitaMindCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _targetFrequency,
                          decoration: const InputDecoration(
                            labelText: 'Frequency for new goals',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          items: [
                            for (final frequency in _frequencies)
                              DropdownMenuItem(
                                value: frequency,
                                child: Text(frequency),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _targetFrequency = value);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Templates',
                          style: AppTextStyles.cardTitle(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final template in _templates)
                              ActionChip(
                                avatar: _hasGoal(template.title)
                                    ? const Icon(Icons.check, size: 18)
                                    : const Icon(Icons.add, size: 18),
                                label: Text(template.title),
                                onPressed: _hasGoal(template.title)
                                    ? null
                                    : () => _addTemplate(template),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customGoalController,
                                decoration: const InputDecoration(
                                  labelText: 'Custom goal',
                                  hintText: 'Example: Take a quiet walk',
                                ),
                                onSubmitted: (_) => _addCustomGoal(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton.filled(
                              tooltip: 'Add goal',
                              onPressed: _addCustomGoal,
                              style: IconButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                              ),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const AppSectionHeader(title: 'Your goals'),
                  if (_goals.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.flag_outlined,
                      title: 'No goals yet',
                      body: 'Add one when you are ready.',
                    )
                  else
                    for (final goal in _goals)
                      GoalCard(
                        goal: goal,
                        onIncrement: () {
                          final progress = (goal.progress + 0.2)
                              .clamp(0, 1)
                              .toDouble();
                          _updateGoal(goal.copyWith(progress: progress));
                        },
                        onToggleActive: (active) {
                          _updateGoal(goal.copyWith(active: active));
                        },
                        onDelete: () => _removeGoal(goal),
                      ),
                  const SizedBox(height: AppSpacing.md),
                  VitaMindPrimaryButton(
                    onPressed: _continue,
                    loading: _saving,
                    icon: widget.isOnboarding
                        ? Icons.arrow_forward
                        : Icons.save_outlined,
                    label: widget.isOnboarding ? 'Continue' : 'Done',
                  ),
                ],
              ),
      ),
    );
  }
}
