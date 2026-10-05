import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';

/// Zero-friction crisis and grounding support. Keep this screen free of
/// upsells, celebrations, and anything that asks the user to decide much.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const String routeName = '/support';

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open ${uri.scheme == 'https' ? 'the link' : 'your phone app'}. You can dial or text the number directly.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const VitaMindPageHeader(
              title: 'Need help now',
              subtitle:
                  'You deserve support. These options are free and available any time.',
            ),
            _SupportCard(
              title: 'In immediate danger?',
              body:
                  'Call emergency services, or go to the nearest emergency department.',
              actions: [
                _SupportAction(
                  icon: Icons.emergency_outlined,
                  label: 'Call 911',
                  primary: true,
                  onPressed: () =>
                      _open(context, Uri(scheme: 'tel', path: '911')),
                ),
              ],
            ),
            _SupportCard(
              title: '988 Suicide & Crisis Lifeline',
              body:
                  'Free, confidential support 24/7 in the U.S. You can call or text, even if you are not in crisis.',
              actions: [
                _SupportAction(
                  icon: Icons.call_outlined,
                  label: 'Call 988',
                  primary: true,
                  onPressed: () =>
                      _open(context, Uri(scheme: 'tel', path: '988')),
                ),
                _SupportAction(
                  icon: Icons.sms_outlined,
                  label: 'Text 988',
                  onPressed: () =>
                      _open(context, Uri(scheme: 'sms', path: '988')),
                ),
              ],
            ),
            _SupportCard(
              title: 'Outside the U.S.?',
              body: 'Find a free, verified helpline in your country.',
              actions: [
                _SupportAction(
                  icon: Icons.public,
                  label: 'Find a helpline',
                  onPressed: () =>
                      _open(context, Uri.parse('https://findahelpline.com/')),
                ),
              ],
            ),
            const _SupportCard(
              title: 'Ground yourself: 5-4-3-2-1',
              body:
                  'Slowly notice 5 things you can see, 4 you can feel, 3 you can hear, 2 you can smell, and 1 you can taste. Breathe out longer than you breathe in.',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'VitaMind cannot contact anyone for you or respond to emergencies.',
              style: AppTextStyles.meta(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final String body;
  final List<_SupportAction> actions;

  @override
  Widget build(BuildContext context) {
    return VitaMindCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle(context)),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppTextStyles.cardBody(context)),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    // The theme's buttons are full-width; these sit side by side in a Wrap.
    const minimumSize = Size(0, 48);
    if (primary) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: minimumSize),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: minimumSize,
        foregroundColor: AppColors.primary,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
