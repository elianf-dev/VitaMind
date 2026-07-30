import 'package:flutter/material.dart';

import '../models/check_in_settings.dart';
import '../models/privacy_security_settings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_section_header.dart';
import '../widgets/vita_mind_buttons.dart';
import '../widgets/vita_mind_card.dart';
import '../widgets/vita_mind_page_header.dart';
import '../widgets/vita_mind_settings_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.localStorageService,
    required this.notificationService,
  });

  final AuthService authService;
  final FirestoreService firestoreService;
  final LocalStorageService localStorageService;
  final NotificationService notificationService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  CheckInSettings _checkInSettings = CheckInSettings.defaults();
  PrivacySecuritySettings _privacySettings = PrivacySecuritySettings.defaults();
  bool _loadingSettings = true;
  bool _savingNotificationSettings = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = widget.authService.userId;
    final localSettings = await widget.localStorageService
        .loadCheckInSettings();
    final privacySettings = await widget.localStorageService
        .loadPrivacySettings();
    var settings = localSettings;

    if (userId != null && widget.firestoreService.enabled) {
      try {
        settings =
            await widget.firestoreService.loadCheckInSettings(userId) ??
            localSettings;
        await widget.localStorageService.saveCheckInSettings(settings);
      } on Object catch (error) {
        debugPrint('VitaMind: failed to load cloud check-in settings: $error');
        settings = localSettings;
      }
    }

    await widget.notificationService.applyCheckInSettings(settings);

    if (!mounted) {
      return;
    }

    setState(() {
      _checkInSettings = settings;
      _privacySettings = privacySettings;
      _loadingSettings = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await widget.authService.signOut();
    widget.localStorageService.setProfileId(null);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _resendVerificationEmail() async {
    final error = await widget.authService.resendEmailVerification();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Verification email sent. Check your inbox.'),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final userId = widget.authService.userId;
    if (userId == null) {
      return;
    }
    if (!widget.authService.canDeleteAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'For security, log out and log back in before deleting your account.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete VitaMind account?'),
        content: const Text(
          'This permanently deletes your VitaMind account, its mood, symptom, journal, and reminder data in Firebase, and this profile’s data on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    if (!widget.authService.canDeleteAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your secure deletion session expired. Log out and back in, then try again.',
          ),
        ),
      );
      return;
    }

    // Firestore rules only allow this user to delete users/{userId} while
    // still authenticated, so cloud data must be wiped before the Firebase
    // Auth account (which signs the user out). If deleteAccount fails after
    // this, the cloud wipe is not silently lost: the user is told exactly
    // what happened so a retry is safe (deleteUserData is idempotent).
    try {
      await widget.firestoreService.deleteUserData(userId);
    } on Object catch (error) {
      debugPrint('VitaMind: failed to delete cloud data for $userId: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not reach the server to delete your cloud data. Check your connection and try again.',
          ),
        ),
      );
      return;
    }

    final error = await widget.authService.deleteAccount();
    if (error != null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your cloud data was deleted, but the account itself could not be removed: $error Please try again.',
          ),
        ),
      );
      return;
    }

    await widget.localStorageService.clearLocalHealthData();
    await widget.notificationService.cancelAllCheckIns();
    widget.localStorageService.setProfileId(null);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _updateCheckInSettings(CheckInSettings settings) async {
    setState(() {
      _checkInSettings = settings;
      _savingNotificationSettings = true;
    });

    await widget.localStorageService.saveCheckInSettings(settings);

    final userId = widget.authService.userId;
    if (userId != null && widget.firestoreService.enabled) {
      try {
        await widget.firestoreService.saveCheckInSettings(userId, settings);
      } on Object catch (error) {
        debugPrint('VitaMind: failed to sync check-in settings: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Saved locally. Cloud sync is unavailable right now.',
              ),
            ),
          );
        }
      }
    }

    await widget.notificationService.applyCheckInSettings(settings);

    if (!mounted) {
      return;
    }

    setState(() => _savingNotificationSettings = false);
  }

  Future<void> _pickCheckInTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _checkInSettings.time,
      helpText: 'Choose check-in time',
    );

    if (selectedTime == null) {
      return;
    }

    await _updateCheckInSettings(_checkInSettings.copyWith(time: selectedTime));
  }

  Future<void> _sendTestNotification() async {
    final shown = await widget.notificationService.showTestCheckIn();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shown
              ? 'Test notification sent.'
              : 'Notifications are unavailable or permission was not granted.',
        ),
      ),
    );
  }

  Future<void> _openSettingsRoute(String routeName) async {
    await Navigator.of(context).pushNamed(routeName);
    await _loadSettings();
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'VitaMind',
      applicationVersion: '1.0.0',
      children: const [
        Text(
          'VitaMind is a wellness companion for mood, symptom, journal, goals, reminders, and source-supported health explanations.',
        ),
        SizedBox(height: AppSpacing.md),
        Text('This is not medical advice or a diagnosis.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = widget.authService.userEmail;

    return SafeArea(
      child: ListView(
        padding: AppSpacing.tabPage,
        children: [
          const VitaMindPageHeader(title: 'Profile'),
          const AppSectionHeader(title: 'Account'),
          VitaMindCard(
            padding: AppSpacing.cardLarge,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEmail ?? 'Guest User',
                        style: AppTextStyles.sectionTitle(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        userEmail == null ? 'Guest mode' : 'VitaMind account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      if (userEmail != null &&
                          !widget.authService.isEmailVerified) ...[
                        const SizedBox(height: AppSpacing.xs),
                        TextButton(
                          onPressed: _resendVerificationEmail,
                          child: const Text('Verify email'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const AppSectionHeader(title: 'Health Profile'),
          VitaMindSettingsTile(
            icon: Icons.health_and_safety_outlined,
            title: 'Diagnosed Conditions',
            subtitle: 'Known conditions, medications, and common symptoms',
            onTap: () => _openSettingsRoute('/diagnosed-conditions'),
          ),
          VitaMindSettingsTile(
            icon: Icons.favorite_border,
            title: 'Wellness Goals',
            subtitle: 'Create goals and update progress',
            onTap: () => _openSettingsRoute('/wellness-goals'),
          ),
          const AppSectionHeader(title: 'Preferences'),
          VitaMindCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                if (_loadingSettings) ...[
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: AppSpacing.md),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gentle check-in'),
                  subtitle: const Text(
                    'One calm reminder for mood, journal, symptoms, or goals.',
                  ),
                  value: _checkInSettings.enabled,
                  onChanged: _loadingSettings
                      ? null
                      : (value) {
                          _updateCheckInSettings(
                            _checkInSettings.copyWith(enabled: value),
                          );
                        },
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: _checkInSettings.enabled,
                  leading: Icon(
                    Icons.schedule_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Check-in time'),
                  subtitle: Text(_checkInSettings.time.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _checkInSettings.enabled && !_loadingSettings
                      ? _pickCheckInTime
                      : null,
                ),
                DropdownButtonFormField<CheckInFrequency>(
                  key: ValueKey(_checkInSettings.frequency.name),
                  initialValue: _checkInSettings.frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: [
                    for (final frequency in CheckInFrequency.values)
                      DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency.label),
                      ),
                  ],
                  onChanged: _checkInSettings.enabled && !_loadingSettings
                      ? (frequency) {
                          if (frequency == null) {
                            return;
                          }
                          _updateCheckInSettings(
                            _checkInSettings.copyWith(frequency: frequency),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                VitaMindSecondaryButton(
                  onPressed: _loadingSettings ? null : _sendTestNotification,
                  icon: Icons.notifications_outlined,
                  label: 'Send Test Notification',
                ),
                if (_savingNotificationSettings) ...[
                  const SizedBox(height: AppSpacing.md),
                  const LinearProgressIndicator(minHeight: 3),
                ],
              ],
            ),
          ),
          VitaMindSettingsTile(
            icon: Icons.lock_outline,
            title: 'Privacy & Security',
            subtitle: 'Future AI consent and local data controls',
            onTap: () => _openSettingsRoute('/privacy-security'),
          ),
          VitaMindSettingsTile(
            icon: _privacySettings.aiHealthConsent
                ? Icons.psychology_alt
                : Icons.psychology_alt_outlined,
            title: 'Future AI Consent',
            subtitle: _privacySettings.aiHealthConsent
                ? 'On for future VitaMind Plus AI features.'
                : 'Off. Free Health Log Explainer still works.',
            onTap: () => _openSettingsRoute('/privacy-security'),
          ),
          const AppSectionHeader(title: 'Plan'),
          VitaMindSettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: 'VitaMind Plus',
            subtitle: 'Planned AI summaries, reports, and cloud sync',
            onTap: () => _openSettingsRoute('/vitamind-plus'),
          ),
          const AppSectionHeader(title: 'App'),
          VitaMindSettingsTile(
            icon: Icons.history_outlined,
            title: 'Health Log History',
            subtitle: 'Review previous health explainer logs',
            onTap: () => _openSettingsRoute('/health-log-history'),
          ),
          VitaMindSettingsTile(
            icon: Icons.info_outline,
            title: 'About VitaMind',
            subtitle: 'Version, purpose, and safety note',
            onTap: _showAbout,
          ),
          const SizedBox(height: AppSpacing.md),
          VitaMindSecondaryButton(
            onPressed: () => _logout(context),
            icon: Icons.logout,
            label: 'Logout',
          ),
          if (userEmail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: _confirmDeleteAccount,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Delete Account'),
            ),
          ],
        ],
      ),
    );
  }
}
