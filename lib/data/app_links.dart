/// VitaMind's public web pages, served by GitHub Pages from docs/legal.
class AppLinks {
  const AppLinks._();

  /// Google Play requires the privacy policy to be reachable inside the app.
  static final Uri privacyPolicy = Uri.parse(
    'https://elianf-dev.github.io/VitaMind/legal/privacy.html',
  );

  /// Washington's My Health My Data Act (RCW 19.373.020) wants a separate and
  /// distinct link to the consumer health data privacy policy.
  static final Uri consumerHealthDataPolicy = Uri.parse(
    'https://elianf-dev.github.io/VitaMind/legal/consumer-health-data.html',
  );
}
