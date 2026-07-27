# VitaMind

VitaMind is a Flutter wellness companion for tracking mood, symptoms,
diagnosed conditions, journals, wellness goals, reminders, and safe
source-supported health-log explanations.

## Features

- Email/password authentication and guest mode
- Guided onboarding and privacy preferences
- Mood, symptom, journal, condition, and wellness-goal tracking
- Deterministic insights and saved Health Log Explainer history
- Rule-based Health Log Explainer with trusted government and nonprofit sources
- Gentle local check-in notifications
- VitaMind Plus placeholder for future paid features
- Encrypted on-device storage for health records
- Per-user Firestore sync for logged-in mood, symptom, journal, and reminder data

## Run

Use Flutter 3.44.8 or a compatible stable release:

```sh
git clone https://github.com/elianf-dev/VitaMind.git
cd VitaMind
flutter pub get
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 flutter run -d macos
```

To see other targets:

```sh
flutter devices
flutter run -d <device-id>
```

Do not run `flutter create .` again: the platform projects already exist.

## Storage And Firebase

Guest health records are encrypted on the device with Hive CE. The encryption
key is kept in Keychain/secure storage. Small preferences such as onboarding
status and interface settings use `shared_preferences`.

Firebase is configured for project `vitamind-9d46b` and app identifier
`com.elianfigueroa.vitamind`. Logged-in users sync:

- `users/{userId}/moods`
- `users/{userId}/symptoms`
- `users/{userId}/journals`
- `users/{userId}/settings/notifications`

Firestore rules only allow an authenticated user to access their own
`users/{userId}` data. Device deletion does not delete cloud data; account
deletion removes the known Firestore collections before deleting the Firebase
account.

## Health Log Explainer

The free explainer is deterministic and source-supported. It does not call
OpenAI, Firebase Functions, or any other AI backend. The old experimental
Firebase AI function has been removed. TODO comments mark possible future
VitaMind Plus AI, payments, cloud sync expansion, and deeper trusted-source API
integrations.

## Build Compatibility

This project uses CocoaPods for Apple plugins because Firebase's newest Swift
package manifest requires a newer toolchain than Xcode 16.2. Firebase packages
are pinned to the April 2026 compatible set. After upgrading Xcode, revisit the
pins and `enable-swift-package-manager` in `pubspec.yaml`.

Local macOS Debug/Profile builds use the default Keychain and do not enable App
Sandbox so they can run without an Apple provisioning profile. Release builds
retain App Sandbox, Keychain entitlements, and Apple automatic signing. Before a
release build, sign in again under Xcode > Settings > Accounts so Xcode can
create the profile.

VitaMind does not diagnose, prescribe treatment, or replace a clinician.
Health explanation screens always include: "This is not medical advice or a
diagnosis."
