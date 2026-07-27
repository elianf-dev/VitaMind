class PrivacySecuritySettings {
  const PrivacySecuritySettings({
    required this.appLockEnabled,
    required this.biometricUnlockEnabled,
    required this.hideSensitiveHealthDetails,
    required this.aiHealthConsent,
  });

  factory PrivacySecuritySettings.defaults() {
    return const PrivacySecuritySettings(
      appLockEnabled: false,
      biometricUnlockEnabled: false,
      hideSensitiveHealthDetails: false,
      aiHealthConsent: false,
    );
  }

  factory PrivacySecuritySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySecuritySettings(
      appLockEnabled: json['appLockEnabled'] as bool? ?? false,
      biometricUnlockEnabled: json['biometricUnlockEnabled'] as bool? ?? false,
      hideSensitiveHealthDetails:
          json['hideSensitiveHealthDetails'] as bool? ?? false,
      aiHealthConsent: json['aiHealthConsent'] as bool? ?? false,
    );
  }

  final bool appLockEnabled;
  final bool biometricUnlockEnabled;
  final bool hideSensitiveHealthDetails;
  final bool aiHealthConsent;

  PrivacySecuritySettings copyWith({
    bool? appLockEnabled,
    bool? biometricUnlockEnabled,
    bool? hideSensitiveHealthDetails,
    bool? aiHealthConsent,
  }) {
    return PrivacySecuritySettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      hideSensitiveHealthDetails:
          hideSensitiveHealthDetails ?? this.hideSensitiveHealthDetails,
      aiHealthConsent: aiHealthConsent ?? this.aiHealthConsent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appLockEnabled': appLockEnabled,
      'biometricUnlockEnabled': biometricUnlockEnabled,
      'hideSensitiveHealthDetails': hideSensitiveHealthDetails,
      'aiHealthConsent': aiHealthConsent,
    };
  }
}
