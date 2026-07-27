import 'package:flutter/material.dart';

import '../models/wellness_goal.dart';
import 'progress_goal_card.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
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
    return ProgressGoalCard(
      goal: goal,
      compact: compact,
      onIncrement: onIncrement,
      onToggleActive: onToggleActive,
      onDelete: onDelete,
    );
  }
}
