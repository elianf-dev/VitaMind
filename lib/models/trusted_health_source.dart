class TrustedHealthSource {
  const TrustedHealthSource({
    required this.title,
    required this.organization,
    required this.description,
    required this.url,
  });

  factory TrustedHealthSource.fromJson(Map<String, dynamic> json) {
    return TrustedHealthSource(
      title: json['title'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  final String title;
  final String organization;
  final String description;
  final String url;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'organization': organization,
      'description': description,
      'url': url,
    };
  }

  static TrustedHealthSource fromLegacyString(String value) {
    return TrustedHealthSource(
      title: value,
      organization: 'Trusted health source',
      description: 'Saved from an earlier VitaMind explanation.',
      url: '',
    );
  }
}
