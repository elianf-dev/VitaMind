# Publishing VitaMind on Google Play: Requirements Report
*Generated: 2026-10-05 | Sources: 16 | Confidence: High on Google's own rules, Medium where only third-party sources were found (flagged)*

## Executive Summary
Getting a new app onto Google Play has two hard gates and several forms to fill in.

1. **A developer account.** Personal accounts cost a one-time US$25 and need ID verification.
2. **A closed test, because this would be a new personal account.** You need 12 testers opted in continuously for 14 days before Google lets you apply for production. That is the longest step, so start it first.

The forms are the privacy policy, the Data safety form, the account deletion web link, the Health apps declaration, the content rating and the target audience.

On the technical side, VitaMind is already in good shape:
- It targets API 36, the current requirement.
- It has release signing.
- It uses inexact alarms, which need no special permission.
- It has in-app account deletion.

Four things are missing:
- A public privacy policy URL, plus a link to it inside the app.
- A web page where people can request account deletion.
- Google's exact "not a medical device" disclaimer in the store description.
- The 12-tester closed test.

## 1. The developer account
- **Fee:** US$25, one-time, paid by card ([Play Console Help: Get started](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en); [ConsoleMint](https://consolemint.com/google-play-console-price/)).
- **Personal vs organization:**
  - A personal account needs a government ID that matches your legal name, and sometimes a selfie check.
  - An organization account also needs a D-U-N-S number, which can take up to 30 days to get ([12TesterHive](https://12testerhive.com/blog/google-play-personal-vs-organization-developer-account); [TesterBee](https://testerbee.com/blog/google-play-developer-verification-2026)).
- **Android developer verification:** this is a separate, newer program that applies even to apps installed outside Play. Verification opened in March 2026. It becomes mandatory in Brazil, Indonesia, Singapore and Thailand from September 2026, and globally through 2027 ([Median](https://median.co/blog/android-developer-verification-2026); [Bitdefender](https://www.bitdefender.com/en-us/blog/hotforsecurity/google-developer-verification-sideloaded-apps); [Slashdot](https://tech.slashdot.org/story/25/08/25/1716213/google-to-require-identity-verification-for-all-android-app-developers-by-2027)). *I didn't read Google's own page on this. It's mainly relevant to apps distributed outside Play.*

## 2. The closed-test gate for new personal accounts
Official wording ([Play Console Help: App testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)):
- **Who it applies to:** "personal developer accounts created after November 13, 2023".
- **The rule:** "At least 12 testers must be opted in to your closed test when you apply for production access, and they must have been opted in continuously for the preceding 14 days."
- **Opting out resets the clock:** "Testers who opt in, test for fewer than 14 days, and then opt out do not count… the 14 days must be consecutive."
- **After the test:** you answer a 3-part questionnaire about how the test went, your audience and the app's value, and what you changed based on feedback. The review "usually takes seven days or less."
- The minimum dropped from 20 testers to 12 on December 11, 2024 ([PrimeTestLab](https://primetestlab.com/blog/google-play-changed-20-to-12-testers)).
- **Unverified:** a third-party site says that since 2026 Google also checks that testers genuinely used the app ([TestersCommunity](https://www.testerscommunity.com/google-play-closed-testing)). Google's page only says to give testers instructions and encourage broad use. Plan for real use anyway.

**Realistic timeline:** account approval, then about 14 days or more of testing, then up to 7 days or more of production review. That's roughly 3–4 weeks minimum.

## 3. Technical requirements
- **Target API:** since August 31, 2026, new apps and updates must target **Android 16 (API 36)**. Extensions only ran until November 1, 2026 ([Play Console Help: Target API](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)). ✅ VitaMind targets 36, which is the Flutter 3.47 default.
- **16 KB memory pages:** apps targeting Android 15 or higher must support 16 KB page sizes. This has applied to submissions since November 1, 2025, and matters for native code ([Android Developers Blog](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html); [Median](https://median.co/blog/how-to-prepare-android-apps-google-play-16-kb-page-size-requirement)). *My inference: current Flutter builds should comply. Check the app bundle explorer in Play Console after the first upload to be sure, since plugins ship their own native libraries.*
- **Exact alarms:** `USE_EXACT_ALARM` is limited to alarm, timer and calendar apps and needs a declaration. `SCHEDULE_EXACT_ALARM` is denied by default on Android 14+ ([Play Console Help: Sensitive permissions](https://support.google.com/googleplay/android-developer/answer/16558241); [Android Developers](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)). ✅ VitaMind uses `inexactAllowWhileIdle` and only declares `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` and `VIBRATE`, so nothing needs declaring.

## 4. Health-app rules (VitaMind counts as a health app)
From [Play Console Help: Health Content and Services](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en):
- **Scope:** any app that "offers health-related features or information".
- **Health apps declaration:** a required form at Play Console → Policy → App content.
- **Disclaimer:** an app that isn't a medical device must say in its store description that it is "not a medical device and does not diagnose, treat, cure, or prevent any medical condition." It must also "remind users to consult a healthcare professional for medical advice, diagnosis, or treatment."
  - ⚠️ VitaMind's in-app card says "This is not medical advice or a diagnosis." That's fine in the app, but the store description needs Google's exact sentence.
- **Privacy policy:** it must be on an "active, publicly accessible and non-geofenced URL (no PDFs)" and also be linked inside the app.
- **Permissions:** don't request health permissions the core features don't need.
- **Reported 2026 changes (unverified):** a "Medical Device" badge for EU-certified apps, stricter Health Connect justifications, and disclaimers that must not be buried ([MyAppMonitor](https://myappmonitor.com/blog/google-play-health-apps-update-2026-requirements)). None of these affect VitaMind directly.
- **Gap:** the official page I read doesn't cover crisis or self-harm content. I couldn't confirm any specific rule for VitaMind's 988 support screen.

## 5. Privacy, the Data safety form and account deletion
- **Privacy policy:** every app needs one, linked both in Play Console and inside the app. It must describe all data access, collection, use and sharing, beyond what the Data safety form lists ([Play Console Help: User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)).
- **Account deletion** ([Play Console Help: Account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)): apps that let people create accounts need both of these.
  - An in-app deletion path. ✅ VitaMind has this on Profile.
  - A **web page** where people can request deletion. ❌ Missing. The page must:
    - load without errors;
    - feature the deletion request prominently;
    - use the app or developer name as it appears on the Play listing;
    - let users actually request deletion.
- Deletion must remove the account's data, explicitly including health data. Data kept for security, fraud or legal reasons must be disclosed.
- **Data safety form:** you must answer its data deletion questions and enter the web link there. Declare everything that syncs to Firebase (for example email and health entries). Guest data stays on the device, which also belongs in the privacy policy.

## 6. Other Play Console forms
These are standard App content items. I didn't read each official page, so treat this as a checklist rather than verified detail:
- **Content rating questionnaire.**
- **Target audience:** setting 18+ keeps the app out of Google's Families policy.
- **App access:** reviewers need a way in. Guest mode may be enough.
- **Store listing:** icon, feature graphic, screenshots and description.

## Key Takeaways
1. **Start the 12-tester, 14-day closed test as soon as the account exists.** It's the longest step and can't be sped up. Opting out resets a tester's clock.
2. **Before the closed test, publish two web pages:** a privacy policy and an account deletion request page. A simple page on GitHub Pages or your portfolio site works.
3. **Add a privacy policy link inside the app** (Profile or Privacy & Security). Put Google's exact disclaimer sentence in the store description.
4. **Fill in the Health apps declaration, Data safety, content rating and target audience forms.** Choose 18+.
5. **The technical side is already fine:** API 36, signing, inexact alarms. Just confirm 16 KB compliance in the bundle explorer after the first upload.

## Sources
1. [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en): official 12/14 rule *(read in full)*
2. [Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en): official, API 36 from Aug 31, 2026 *(read in full)*
3. [Health Content and Services](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en): official health app rules and disclaimer wording *(read in full)*
4. [Understanding account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en): official deletion rules *(read in full)*
5. [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en): official privacy policy rules
6. [Get started with Play Console](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en): official account setup and fee
7. [Permissions and APIs that access sensitive information](https://support.google.com/googleplay/android-developer/answer/16558241): official exact-alarm policy
8. [Schedule exact alarms are denied by default](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms): Android 14 behavior
9. [Prepare for the 16 KB page size requirement](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html): official blog
10. [Median: 16 KB guide](https://median.co/blog/how-to-prepare-android-apps-google-play-16-kb-page-size-requirement): Nov 1, 2025 date and tooling
11. [Median: Android developer verification 2026](https://median.co/blog/android-developer-verification-2026): verification timeline
12. [Bitdefender: verification for sideloaded apps](https://www.bitdefender.com/en-us/blog/hotforsecurity/google-developer-verification-sideloaded-apps): corroborates the timeline
13. [12TesterHive: personal vs organization accounts](https://12testerhive.com/blog/google-play-personal-vs-organization-developer-account): ID and D-U-N-S details
14. [PrimeTestLab: 20 to 12 testers](https://primetestlab.com/blog/google-play-changed-20-to-12-testers): date of the rule change
15. [TestersCommunity: closed testing guide](https://www.testerscommunity.com/google-play-closed-testing): engagement claim *(unverified)*
16. [MyAppMonitor: 2026 health app update](https://myappmonitor.com/blog/google-play-health-apps-update-2026-requirements): 2026 health changes *(single source, unverified)*

## Methodology
- Ran 8 web searches.
- Read 4 official Google help pages in full.
- Checked VitaMind's code for what it already covers: `android/app/build.gradle*`, `AndroidManifest.xml`, `notification_service.dart`, the profile screen, `disclaimer_card.dart`, and links throughout `lib/`.
- Firecrawl and Exa weren't configured, so I used the built-in web search and fetch.
- **Sub-questions covered:** account and fees; the closed-test gate; technical requirements; health-app policy; privacy and deletion.
- **Not verified:** crisis-content rules, store-listing asset sizes, and Google's own developer verification page.
