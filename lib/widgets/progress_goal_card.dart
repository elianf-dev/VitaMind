import 'package:flutter/material.dart';

import '../models/wellness_goal.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'vita_mind_card.dart';

class ProgressGoalCard extends StatelessWidget {
  const ProgressGoalCard({
    super.key,
    required this.goal,
    this.compact = false,
    this.onIncrement,
    this.onToggleActive,
    this.onDelete,
  });

  final WellnessGoal goal;
  final bool compact;
  final VoidCallback? onIncrement;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final progressPercent = (goal.progress * 100).round();
    final progressLabel = progressPercent == 0
        ? 'Not started'
        : '$progressPercent% complete';

    return VitaMindCard(
      margin: EdgeInsets.only(bottom: compact ? AppSpacing.sm : AppSpacing.md),
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Icon(
                  Icons.flag_outlined,
                  color: goal.active ? primary : AppColors.disabled,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: AppTextStyles.cardTitle(context)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      compact
                          ? goal.targetFrequency
                          : '${goal.category} • ${goal.targetFrequency}',
                      style: AppTextStyles.meta(context),
                    ),
                  ],
                ),
              ),
              if (onToggleActive != null)
                Switch(value: goal.active, onChanged: onToggleActive),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: compact ? 6 : 8,
              backgroundColor: const Color(0xFFEAF4EF),
              color: goal.active ? primary : AppColors.disabled,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(progressLabel, style: AppTextStyles.meta(context)),
              ),
              if (onIncrement != null)
                TextButton.icon(
                  onPressed: goal.active ? onIncrement : null,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(compact ? 'Progress' : 'Add progress'),
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Remove goal',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
