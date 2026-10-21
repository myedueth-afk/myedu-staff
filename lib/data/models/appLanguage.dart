class AppLanguage {
  final String languageName;
  final String languageCode;

  /// Whether this language lays out right-to-left. Panel languages can use
  /// custom codes (e.g. "002") whose direction Flutter/GetX cannot infer, so
  /// the panel's explicit flag is carried along.
  final bool isRtl;

  /// Whether the panel marks this language as the default one (`status: 1`).
  /// The app starts in this language until the user picks another one — see
  /// [AppLocalizationCubit].
  final bool isDefault;

  /// Flag/icon shown next to the language name in the picker. May be a raster
  /// (jpg/png) or vector (svg) url, or null if the panel has none set.
  final String? imageUrl;

  const AppLanguage({
    required this.languageCode,
    required this.languageName,
    this.isRtl = false,
    this.isDefault = false,
    this.imageUrl,
  });

  factory AppLanguage.fromJson(Map<String, dynamic> json) {
    final languageCode =
        (json['code'] ?? json['language_code'] ?? json['languageCode'] ?? '')
            .toString()
            .trim();
    final languageName = (json['name'] ??
            json['language'] ??
            json['language_name'] ??
            json['languageName'] ??
            '')
        .toString()
        .trim();
    final imageUrl = (json['image'] ?? json['flag'] ?? json['image_url'] ?? '')
        .toString()
        .trim();
    return AppLanguage(
      languageCode: languageCode,
      languageName: languageName.isEmpty ? languageCode : languageName,
      isRtl: _parseBool(json['is_rtl'] ?? json['rtl'] ?? json['isRtl']),
      isDefault:
          _parseBool(json['status'] ?? json['is_default'] ?? json['isDefault']),
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
    );
  }

  /// The panel sends flags as 0/1 (get-languages) or bool (set-languages).
  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = value?.toString().toLowerCase();
    return normalized == "1" || normalized == "true";
  }

  Map<String, dynamic> toJson() => {
        "code": languageCode,
        "name": languageName,
        "is_rtl": isRtl ? 1 : 0,
        "status": isDefault ? 1 : 0,
        "image": imageUrl,
      };
}

extension AppLanguageList on List<AppLanguage> {
  /// The language the panel marks as default, or null when it marks none.
  /// Only the first one counts: the panel is expected to flag a single
  /// default, and a misconfigured list must still resolve deterministically.
  AppLanguage? get defaultLanguage {
    for (final language in this) {
      if (language.isDefault) {
        return language;
      }
    }
    return null;
  }

  AppLanguage? withCode(String languageCode) {
    for (final language in this) {
      if (language.languageCode == languageCode) {
        return language;
      }
    }
    return null;
  }
}
