import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_backdrop.dart';
import 'support_screen.dart';

/// Standalone app shown by `StartupGate` when startup fails. It has only
/// the theme and the support route, since nothing else is available yet.
class StartupRecoveryApp extends StatelessWidget {
  const StartupRecoveryApp({
    super.key,
    required this.busy,
    required this.storageFailed,
    required this.failedBefore,
    required this.onTryAgain,
    required this.onReset,
  });

  final bool busy;
  final bool storageFailed;
  final bool failedBefore;
  final VoidCallback onTryAgain;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitaMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) => AppBackdrop(child: child!),
      home: StartupRecoveryScreen(
        busy: busy,
        storageFailed: storageFailed,
        failedBefore: failedBefore,
        onTryAgain: onTryAgain,
        onReset: onReset,
      ),
      routes: {SupportScreen.routeName: (context) => const SupportScreen()},
    );
  }
}

/// Two variants (SEC-S4-1 / QA-S4-1):
/// - [storageFailed]: the encrypted local store couldn't be opened, so the
///   reset (and, after a repeat failure, the Android Settings way out) is
///   offered.
/// - otherwise: something after storage failed; local data isn't the
///   problem, so only Try again and Need help now are shown.
class StartupRecoveryScreen extends StatelessWidget {
  const StartupRecoveryScreen({
    super.key,
    required this.busy,
    required this.storageFailed,
    required this.failedBefore,
    required this.onTryAgain,
    required this.onReset,
  });

  final bool busy;
  final bool storageFailed;
  final bool failedBefore;
  final VoidCallback onTryAgain;
  final VoidCallback onReset;

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.overlay(context),
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Reset local data?'),
        content: const Text(
          'This deletes the VitaMind data stored on this device. If you’re signed in, your moods, symptoms and journal entries can be restored from the cloud. Local-only data (conditions, medications and goals), guest entries and saved explainer results will be lost. This can’t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            // Same destructive style as the other delete dialogs (DES-L2-2).
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = storageFailed
        ? 'VitaMind couldn’t open'
        : 'VitaMind couldn’t start';
    final body = storageFailed
        ? 'Something went wrong while opening the data saved on this device. Trying again may fix it.'
        : 'Something went wrong while starting. Trying again may fix it.';
    final repeatNote = storageFailed
        ? 'VitaMind still couldn’t open. You can try again, or reset the data on this device.'
        : 'VitaMind still couldn’t start. You can try again, or come back a little later.';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.pageBottom,
          ),
          children: [
            // DES-S4-10: announced as a heading by TalkBack.
            Semantics(
              header: true,
              child: Text(title, style: AppTextStyles.pageTitle(context)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(body, style: AppTextStyles.supportiveBody(context)),
            if (failedBefore) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                liveRegion: true,
                child: Text(repeatNote, style: AppTextStyles.cardBody(context)),
              ),
              if (storageFailed) ...[
                const SizedBox(height: AppSpacing.sm),
                // QA-S4-3: the last-resort way out, outside the app.
                Text(
                  'If it keeps happening, you can also clear VitaMind’s storage in Android Settings → Apps → VitaMind → Storage.',
                  style: AppTextStyles.cardBody(context),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: busy ? null : onTryAgain,
              child: const Text('Try again'),
            ),
            if (storageFailed) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: busy ? null : () => _confirmReset(context),
                child: const Text(
                  'Reset local data on this device',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (busy) ...[
              const SizedBox(height: AppSpacing.lg),
              const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Opening VitaMind',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Align(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(SupportScreen.routeName),
                child: const Text('Need help now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
