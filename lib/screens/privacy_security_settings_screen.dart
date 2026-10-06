import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_links.dart';
import '../models/check_in_settings.dart';
import '../models/privacy_security_settings.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/vita_mind_buttons.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';

class PrivacySecuritySettingsScreen extends StatefulWidget {
  const PrivacySecuritySettingsScreen({
    super.key,
    required this.localStorageService,
    required this.notificationService,
    this.isOnboarding = false,
  });

  final LocalStorageService localStorageService;
  final NotificationService notificationService;
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
        title: const Text('Delete local VitaMind data?'),
        content: const Text(
          'This clears this profile’s moods, symptoms, journals, diagnosed conditions, goals, privacy choices, and reminders from this device. Signed-in records already saved to Firebase are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete From Device'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await widget.localStorageService.clearLocalHealthData();
    await widget.notificationService.cancelAllCheckIns();

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

  Future<void> _openPrivacyPolicy() async {
    final opened = await launchUrl(
      AppLinks.privacyPolicy,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _showPlaceholder(
        'Could not open the privacy policy. Visit ${AppLinks.privacyPolicy}',
      );
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
                        subtitle: Text(
                          'Coming later. This control is unavailable until an unlock screen is implemented.',
                        ),
                        trailing: Text('Not available'),
                      ),
                      const Divider(height: 18),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.fingerprint),
                        title: Text('Biometric unlock'),
                        subtitle: Text(
                          'Coming later with Face ID, Touch ID, and Android biometrics.',
                        ),
                        trailing: Text('Not available'),
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
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Consent to future AI features'),
                        subtitle: const Text(
                          'Not needed for the free source-supported Health Log Explainer.',
                        ),
                        value: _settings.aiHealthConsent,
                        onChanged: (value) {
                          _updateSettings(
                            _settings.copyWith(aiHealthConsent: value),
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
                        subtitle: const Text(
                          'Coming later. VitaMind does not currently create an export file.',
                        ),
                        trailing: const Text('Not available'),
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
