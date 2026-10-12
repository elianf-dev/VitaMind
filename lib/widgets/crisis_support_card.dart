import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/support_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'vita_mind_card.dart';

/// The 988 card pinned above explainer results when a log matched the crisis
/// phrase check. Shared by the explainer screen and the history detail sheet.
/// Keep it calm and factual: no claims that VitaMind contacts anyone or
/// monitors entries, and U.S. numbers only.
class CrisisSupportCard extends StatefulWidget {
  const CrisisSupportCard({
    super.key,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  static const String title = 'If you might be in crisis';
  static const String body =
      "If you may hurt yourself or someone else, call 911 or go to the nearest emergency room now. In the U.S. you can call or text 988, the Suicide & Crisis Lifeline, any time. VitaMind can't respond to emergencies.";
  static const String launchFailedMessage =
      "Couldn't open your phone app. You can call or text 988 directly, or dial 911 in an emergency.";

  final EdgeInsetsGeometry margin;

  @override
  State<CrisisSupportCard> createState() => _CrisisSupportCardState();
}

class _CrisisSupportCardState extends State<CrisisSupportCard> {
  bool _launchFailed = false;

  // Same launchUrl call as SupportScreen, but the failure message is shown
  // inside the card instead of in a SnackBar. In the history bottom sheet a
  // SnackBar lands on the screen's Scaffold, underneath the sheet, so it was
  // invisible (QA-A1-1). Inline text works the same on any screen or sheet
  // and doesn't time out.
  Future<void> _open(Uri uri) async {
    bool opened;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('Could not launch $uri: $error');
      opened = false;
    }
    if (!mounted) {
      return;
    }
    setState(() => _launchFailed = !opened);
  }

  @override
  Widget build(BuildContext context) {
    // The theme's buttons are full-width; these sit side by side in a Wrap.
    const minimumSize = Size(48, 48);

    return Semantics(
      key: const ValueKey('crisis-support-card'),
      container: true,
      liveRegion: true,
      child: VitaMindCard(
        margin: widget.margin,
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: AppColors.primaryMist,
        borderColor: AppColors.primarySoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CrisisSupportCard.title,
              style: AppTextStyles.cardTitle(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CrisisSupportCard.body,
              style: AppTextStyles.cardBody(context),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: minimumSize),
                  onPressed: () => _open(Uri(scheme: 'tel', path: '988')),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call 988'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: minimumSize,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: () => _open(Uri(scheme: 'sms', path: '988')),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Text 988'),
                ),
                TextButton(
                  style: TextButton.styleFrom(minimumSize: minimumSize),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(SupportScreen.routeName),
                  child: const Text('Need help now'),
                ),
              ],
            ),
            if (_launchFailed) ...[
              const SizedBox(height: AppSpacing.sm),
              // Its own live-region node, so TalkBack announces just this
              // message (like a SnackBar) instead of re-reading the card.
              Semantics(
                container: true,
                liveRegion: true,
                child: Text(
                  CrisisSupportCard.launchFailedMessage,
                  style: AppTextStyles.cardBody(
                    context,
                  )?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
