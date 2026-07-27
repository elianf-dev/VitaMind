import 'package:flutter/material.dart';

class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF0E9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.self_improvement,
                color: Color(0xFF2F8F7B),
                size: 46,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Set up your wellness space',
              style: textTheme.displaySmall?.copyWith(
                color: const Color(0xFF173B35),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'A few gentle preferences help VitaMind personalize reminders, insights, and safe wellness explanations around what you already track.',
              style: textTheme.titleMedium?.copyWith(
                color: const Color(0xFF5E746D),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            const _IntroPoint(
              icon: Icons.health_and_safety_outlined,
              title: 'Diagnosed conditions',
              text:
                  'Add only conditions you already know about or want to track.',
            ),
            const _IntroPoint(
              icon: Icons.flag_outlined,
              title: 'Wellness goals',
              text:
                  'Choose small goals VitaMind can keep visible on your dashboard.',
            ),
            const _IntroPoint(
              icon: Icons.lock_outline,
              title: 'Privacy choices',
              text:
                  'Control local privacy choices and future AI consent placeholders.',
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pushReplacementNamed('/onboarding/conditions'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Start Onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPoint extends StatelessWidget {
  const _IntroPoint({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

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
                  text,
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
