import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';

class VitaMindPlusScreen extends StatelessWidget {
  const VitaMindPlusScreen({super.key});

  // TODO: Add real payments, entitlement checks, and account plan sync later.
  static const _plannedFeatures = [
    _PlusFeature(
      icon: Icons.psychology_alt_outlined,
      title: 'AI Health Explainer',
      description:
          'Optional AI explanations built on top of the current safe Health Log Explainer.',
    ),
    _PlusFeature(
      icon: Icons.calendar_month_outlined,
      title: 'AI weekly summaries',
      description:
          'Summaries of mood, symptoms, journal themes, goals, and questions to discuss.',
    ),
    _PlusFeature(
      icon: Icons.quiz_outlined,
      title: 'AI doctor-question drafts',
      description:
          'Optional questions generated from saved logs for users to review before appointments.',
    ),
    _PlusFeature(
      icon: Icons.query_stats_outlined,
      title: 'Advanced pattern detection',
      description:
          'More personalized pattern prompts across logs while avoiding diagnosis.',
    ),
    _PlusFeature(
      icon: Icons.medication_outlined,
      title: 'Medication plain-language summaries',
      description:
          'Future pharmacist-style summaries with safety guardrails and source references.',
    ),
    _PlusFeature(
      icon: Icons.picture_as_pdf_outlined,
      title: 'Exportable health reports',
      description:
          'Appointment-friendly reports users can review before talking with a clinician.',
    ),
    _PlusFeature(
      icon: Icons.cloud_sync_outlined,
      title: 'Cloud sync',
      description: 'A future opt-in way to keep data available across devices.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VitaMind Plus')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            const VitaMindPageHeader(
              title: 'VitaMind Plus',
              subtitle:
                  'The free MVP works without AI. Plus is a planned upgrade for optional AI and advanced reports later.',
            ),
            VitaMindCard(
              backgroundColor: AppColors.primaryMist,
              borderColor: AppColors.primarySoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Free plan active',
                          style: AppTextStyles.cardTitle(context),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Mood, symptoms, journaling, goals, reminders, source-supported explanations, and basic insights are included in the free MVP.',
                          style: AppTextStyles.cardBody(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final feature in _plannedFeatures)
              VitaMindCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(feature.icon, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.title,
                            style: AppTextStyles.cardTitle(context),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            feature.description,
                            style: AppTextStyles.cardBody(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.lock_outline, color: AppColors.mutedIcon),
                  ],
                ),
              ),
            const DisclaimerCard(
              text:
                  'Future AI features will still follow the same safety rule: This is not medical advice or a diagnosis.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlusFeature {
  const _PlusFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
