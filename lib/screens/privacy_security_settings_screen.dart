import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_links.dart';
import '../models/check_in_settings.dart';
import '../models/privacy_security_settings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/sync_coordinator.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/vita_mind_buttons.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';

class PrivacySecuritySettingsScreen extends StatefulWidget {
  const PrivacySecuritySettingsScreen({
    super.key,
    required this.authService,
    required this.syncCoordinator,
    required this.localStorageService,
    required this.notificationService,
    required this.firestoreService,
    this.isOnboarding = false,
  });

  final AuthService authService;
  final SyncCoordinator syncCoordinator;
  final LocalStorageService localStorageService;
  final NotificationService notificationService;
  final FirestoreService firestoreService;
  final bool isOnboarding;

  @override
  State<PrivacySecuritySettingsScreen> createState() =>
      _PrivacySecuritySettingsScreenState();
}

class _PrivacySecuritySettingsScreenState
    extends State<PrivacySecuritySettingsScreen> {
  PrivacySecuritySettings _settings = PrivacySecuritySettings.defaults();
  CheckInSettings _checkInSettings = CheckInSettings.defaults();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.localStorageService.loadPrivacySettings();
    final checkInSettings = await widget.localStorageService
        .loadCheckInSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      _settings = settings;
      _checkInSettings = checkInSettings;
      _loading = false;
    });
  }

  Future<void> _updateSettings(PrivacySecuritySettings settings) async {
    setState(() => _settings = settings);
    await widget.localStorageService.savePrivacySettings(settings);
  }

  Future<void> _updateCheckInSettings(CheckInSettings settings) async {
    setState(() => _checkInSettings = settings);
    await widget.localStorageService.saveCheckInSettings(settings);
    await widget.notificationService.applyCheckInSettings(settings);
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    await widget.localStorageService.savePrivacySettings(_settings);
    await widget.localStorageService.saveCheckInSettings(_checkInSettings);

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (widget.isOnboarding) {
      Navigator.of(context).pushReplacementNamed('/onboarding/summary');
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: AppMotion.overlay(context),
      builder: (context) => AlertDialog(
        // Long copy at large text sizes scrolls instead of clipping
        // (DES-L2-1).
        scrollable: true,
        title: const Text('Delete local VitaMind data?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This deletes all VitaMind moods, symptoms, journals, conditions, medications, goals, privacy choices and reminders on this device, for every profile used here, including guest entries. This can’t be undone, and you’ll see the welcome setup again.',
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Entries already synced to an account stay in the cloud and come back the next time you open VitaMind signed in. To remove those, delete the account.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            // Same destructive style as Delete Account (DES-L2-2).
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete From Device'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Stop a running sync for the signed-in user first, so it can't write
    // wiped entries back into the cleared store (SEC-L2-1). Never blocks.
    final userId = widget.authService.userId;
    if (userId != null) {
      try {
        await widget.syncCoordinator.clearUserAndSettle(userId);
      } on Object catch (error) {
        debugPrint('VitaMind: failed to settle sync before wipe: $error');
      }
    }

    // Every profile on the device, guest included (C-4, SEC-S1-02).
    await widget.localStorageService.clearAllLocalHealthData();
    await widget.notificationService.cancelAllCheckIns();
    // Any Firestore cache files too (C-3); a no-op cost for guests. A failure
    // never blocks the wipe.
    try {
      await widget.firestoreService.clearDeviceCache();
    } on Object catch (error) {
      debugPrint('VitaMind: Firestore cache clear failed: $error');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _settings = PrivacySecuritySettings.defaults();
      _checkInSettings = CheckInSettings.defaults();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('VitaMind data deleted from this device')),
    );
  }

  Future<void> _openPrivacyPolicy() =>
      _openPolicy(AppLinks.privacyPolicy, 'the privacy policy');

  Future<void> _openConsumerHealthDataPolicy() => _openPolicy(
    AppLinks.consumerHealthDataPolicy,
    'the Consumer Health Data Privacy Policy',
  );

  Future<void> _openPolicy(Uri url, String name) async {
    bool opened;
    try {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('Could not launch $url: $error');
      opened = false;
    }
    if (!opened && mounted) {
      _showPlaceholder('Could not open $name. Visit $url');
    }
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: AppSpacing.page,
                children: [
                  const VitaMindPageHeader(
                    title: 'Choose what feels comfortable',
                    subtitle:
                        'Health records on this device are encrypted. Signed-in mood, symptom, journal, and reminder data can also sync to Firebase.',
                  ),
                  const DisclaimerCard(),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsCard(
                    children: [
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.lock_outline),
                        title: Text('App lock'),
                        subtitle: _UnavailableSubtitle(
                          'Coming later. This control is unavailable until an unlock screen is implemented.',
                        ),
                      ),
                      const Divider(height: 18),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.fingerprint),
                        title: Text('Biometric unlock'),
                        subtitle: _UnavailableSubtitle(
                          'Coming later with Face ID, Touch ID, and Android biometrics.',
                        ),
                      ),
                      const Divider(height: 18),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hide diagnosed conditions on Home'),
                        subtitle: const Text(
                          'Show a private summary instead of condition names on the dashboard.',
                        ),
                        value: _settings.hideSensitiveHealthDetails,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(
                              hideSensitiveHealthDetails: value,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsCard(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Gentle daily check-ins'),
                        subtitle: const Text(
                          'Default is one calm reminder at 7:00 PM.',
                        ),
                        value: _checkInSettings.enabled,
                        onChanged: (value) {
                          _updateCheckInSettings(
                            _checkInSettings.copyWith(enabled: value),
                          );
                        },
                      ),
                      const Divider(height: 18),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.file_download_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Data export'),
                        subtitle: const _UnavailableSubtitle(
                          'Coming later. VitaMind does not currently create an export file.',
                        ),
                        onTap: () {
                          // TODO: Add a user-controlled encrypted health data export.
                          _showPlaceholder('Data export will be added later.');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SettingsCard(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.policy_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text('Privacy Policy'),
                        subtitle: const Text(
                          'What VitaMind stores, where, and how to delete it.',
                        ),
                        trailing: const Icon(
                          Icons.open_in_new,
                          semanticLabel: 'Opens in your browser',
                        ),
                        onTap: _openPrivacyPolicy,
                      ),
                      const Divider(height: 18),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.health_and_safety_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text(
                          'Consumer Health Data Privacy Policy',
                        ),
                        subtitle: const Text(
                          'How we handle health data under Washington law.',
                        ),
                        trailing: const Icon(
                          Icons.open_in_new,
                          semanticLabel: 'Opens in your browser',
                        ),
                        onTap: _openConsumerHealthDataPolicy,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  VitaMindSecondaryButton(
                    onPressed: _confirmDeleteLocalData,
                    icon: Icons.delete_outline,
                    label: 'Delete Data From This Device',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  VitaMindPrimaryButton(
                    onPressed: _continue,
                    loading: _saving,
                    icon: widget.isOnboarding
                        ? Icons.arrow_forward
                        : Icons.check,
                    label: widget.isOnboarding ? 'Continue' : 'Done',
                  ),
                ],
              ),
      ),
    );
  }
}

/// A tile subtitle with "Not available" on its own line, so the label wraps
/// with large text instead of filling the tile as a trailing widget did
/// (QA-L1-2). It keeps the ListTile trailing-text style it had before.
class _UnavailableSubtitle extends StatelessWidget {
  const _UnavailableSubtitle(this.description);

  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(description),
        const SizedBox(height: 4),
        Text(
          'Not available',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return VitaMindCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: children),
    );
  }
}
