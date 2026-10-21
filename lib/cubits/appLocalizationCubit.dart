import 'package:eschool_saas_staff/app/appTranslation.dart';
import 'package:eschool_saas_staff/data/models/appLanguage.dart';
import 'package:eschool_saas_staff/data/repositories/localizationRepository.dart';
import 'package:eschool_saas_staff/data/repositories/settingsRepository.dart';
import 'package:eschool_saas_staff/utils/appLanguages.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class AppLocalizationState {
  /// Raw code of the active language (e.g. "zh-CN", "002"), unlike
  /// [Locale.languageCode] which drops the country part.
  final String languageCode;

  /// Languages offered by the panel; falls back to the bundled [appLanguages]
  /// list until the panel list has been fetched at least once.
  final List<AppLanguage> availableLanguages;

  /// True while the labels of a not-yet-cached language are being fetched
  /// during a language switch.
  final bool languageChangeInProgress;

  const AppLocalizationState({
    required this.languageCode,
    required this.availableLanguages,
    this.languageChangeInProgress = false,
  });

  /// Locale passed to [GetMaterialApp].
  Locale get language => Utils.getLocaleFromLanguageCode(languageCode);

  AppLocalizationState copyWith({
    String? languageCode,
    List<AppLanguage>? availableLanguages,
    bool? languageChangeInProgress,
  }) {
    return AppLocalizationState(
      languageCode: languageCode ?? this.languageCode,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      languageChangeInProgress:
          languageChangeInProgress ?? this.languageChangeInProgress,
    );
  }
}

/// Owns the language the app runs in.
///
/// The active language is resolved, in this order, from:
///   1. the language the user picked explicitly in the language sheet;
///   2. the panel default — the language flagged `status: 1` by
///      `get-languages`, which is what makes the default configurable from the
///      panel instead of being pinned in the build;
///   3. [AppTranslation.fallbackLanguageCode], the language bundled with the
///      build, used until the panel list has ever been fetched (first launch
///      while offline).
///
/// The panel list is cached, so a changed default survives a cold start and a
/// user who never picked a language follows the panel on the next sync.
class AppLocalizationCubit extends Cubit<AppLocalizationState> {
  final SettingsRepository _settingsRepository;
  final LocalizationRepository _localizationRepository =
      LocalizationRepository();

  AppLocalizationCubit(SettingsRepository settingsRepository)
      : _settingsRepository = settingsRepository,
        super(_initialState(settingsRepository));

  static AppLocalizationState _initialState(
      SettingsRepository settingsRepository) {
    final languages = _cachedOrBundledLanguages();
    final languageCode = resolveLanguageCode(
      selectedLanguageCode: settingsRepository.getSelectedLanguageCode(),
      availableLanguages: languages,
    );
    return AppLocalizationState(
      languageCode: languageCode,
      availableLanguages: _withLanguage(languages, languageCode),
    );
  }

  /// The language the app must run in. See the class docs for the order.
  @visibleForTesting
  static String resolveLanguageCode({
    required String? selectedLanguageCode,
    required List<AppLanguage> availableLanguages,
  }) {
    if (selectedLanguageCode != null) {
      return selectedLanguageCode;
    }
    final panelDefaultCode = availableLanguages.defaultLanguage?.languageCode;
    if (panelDefaultCode != null && panelDefaultCode.isNotEmpty) {
      return panelDefaultCode;
    }
    return AppTranslation.fallbackLanguageCode;
  }

  /// Cached panel languages when available, bundled list otherwise.
  static List<AppLanguage> _cachedOrBundledLanguages() {
    final cachedLanguages = LocalizationRepository().getCachedAppLanguages();
    return cachedLanguages.isEmpty ? _bundledLanguages() : cachedLanguages;
  }

  /// Offline fallback list: only the languages whose json file is actually
  /// bundled with this build. A build that ships a single `en.json` must not
  /// offer the other entries of [appLanguages] while the API is unreachable,
  /// because picking one of them cannot produce any labels.
  static List<AppLanguage> _bundledLanguages() {
    final bundled = appLanguages
        .where((language) =>
            AppTranslation.bundledLanguageCodes.contains(language.languageCode))
        .toList();
    if (bundled.isNotEmpty) {
      return bundled;
    }

    // Not even the fallback file parsed: still offer that language so the
    // picker is never empty and the app stays resettable.
    final fallbackLanguage =
        appLanguages.withCode(bundledFallbackLanguageCode) ??
            // Not listed in [appLanguages] either: show the raw code, the same
            // fallback AppLanguage.fromJson uses for unnamed panel languages.
            const AppLanguage(
              languageCode: bundledFallbackLanguageCode,
              languageName: bundledFallbackLanguageCode,
            );
    return [fallbackLanguage];
  }

  /// Keeps [languageCode] present in the picker list. The panel may stop
  /// offering a language the user had already selected (or never offer the
  /// bundled fallback at all), which would otherwise leave the picker with no
  /// row selected and no way back.
  static List<AppLanguage> _withLanguage(
      List<AppLanguage> languages, String languageCode) {
    if (languages.withCode(languageCode) != null) {
      return languages;
    }
    // Only re-add a language the app can actually render. Resurrecting one
    // with no labels left (its bundled json was dropped from the build, and
    // the panel no longer offers it) would show its name while every string
    // renders in the fallback language, and would suppress the reset below by
    // making the language look like it is still on offer.
    if (!AppTranslation.hasTranslationsFor(languageCode)) {
      return languages;
    }
    final bundledLanguage = appLanguages.withCode(languageCode);
    return bundledLanguage == null
        ? languages
        : [...languages, bundledLanguage];
  }

  /// Raw code of the current language (e.g. "zh-CN"), unlike
  /// [Locale.languageCode] which drops the country part.
  String get currentLanguageCode => state.languageCode;

  /// Locale GetX falls back to for keys the active language does not provide,
  /// passed to [GetMaterialApp]. Always a language bundled with the build —
  /// see [AppTranslation.fallbackLanguageCode].
  Locale get fallbackLocale =>
      Utils.getLocaleFromLanguageCode(AppTranslation.fallbackLanguageCode);

  /// Layout direction of the current language, passed to [GetMaterialApp].
  ///
  /// GetX only knows a fixed set of RTL language codes, so panel languages
  /// with custom codes (e.g. "002") rely on the panel's `is_rtl` flag; the
  /// union keeps real RTL codes (ar/ur) working even without that flag.
  TextDirection get textDirection {
    final panelSaysRtl =
        state.availableLanguages.withCode(currentLanguageCode)?.isRtl ?? false;
    return panelSaysRtl || rtlLanguages.contains(state.language.languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Display name of the current language, looked up in the available list.
  String get currentLanguageName {
    final code = currentLanguageCode;
    // Current language no longer offered by the panel (or bundled-only); fall
    // back to the bundled list, then to the raw code.
    return state.availableLanguages.withCode(code)?.languageName ??
        appLanguages.withCode(code)?.languageName ??
        code;
  }

  /// Refreshes the panel languages and the labels of the current language in
  /// the background. Failures are silent: the bundled language files and any
  /// previously cached labels keep the app fully working (e.g. offline).
  Future<void> syncRemoteLocalization() async {
    final directionBeforeSync = textDirection;
    final languageCodeBeforeSync = currentLanguageCode;

    try {
      final languages = await _localizationRepository.fetchAppLanguages();
      if (kDebugMode) {
        debugPrint(
            "Localization: ${languages.length} panel languages: ${languages.map((language) => language.languageCode).toList()}, default: ${languages.defaultLanguage?.languageCode}");
      }
      if (languages.isNotEmpty) {
        await _localizationRepository.cacheAppLanguages(languages);
        _applyLanguages(languages);
      }
    } catch (e) {
      // Keep cached/bundled language list.
      if (kDebugMode) {
        debugPrint("Localization: language list sync failed: $e");
      }
    }

    await _refreshLabels(currentLanguageCode);
    await _dropUnusableSelectedLanguage();

    // The refreshed list may flip the current language's rtl flag, and a
    // changed panel default moves the language outright.
    if (textDirection != directionBeforeSync ||
        currentLanguageCode != languageCodeBeforeSync) {
      Get.forceAppUpdate();
    }
  }

  /// Adopts the refreshed panel list, re-resolving the active language against
  /// it. A user who never picked a language follows the panel default, so
  /// changing that default on the panel moves the app on the next sync.
  void _applyLanguages(List<AppLanguage> languages) {
    final languageCode = resolveLanguageCode(
      selectedLanguageCode: _settingsRepository.getSelectedLanguageCode(),
      availableLanguages: languages,
    );
    if (languageCode != currentLanguageCode) {
      if (kDebugMode) {
        debugPrint(
            "Localization: following panel default '$languageCode' (was '$currentLanguageCode')");
      }
      Get.updateLocale(Utils.getLocaleFromLanguageCode(languageCode));
    }
    emit(state.copyWith(
      languageCode: languageCode,
      availableLanguages: _withLanguage(languages, languageCode),
    ));
  }

  /// Drops a stored language choice the app can no longer render, handing the
  /// app back to the panel default.
  ///
  /// Reached when the current language has no labels at all — no bundled json,
  /// nothing cached, and nothing returned by the API — *and* the panel does not
  /// offer it either. A language the panel still offers is kept as-is even with
  /// an empty label file; that case is covered by [fallbackLocale].
  Future<void> _dropUnusableSelectedLanguage() async {
    final code = currentLanguageCode;
    if (AppTranslation.hasTranslationsFor(code)) {
      return;
    }

    // Still offered by the panel (or the list could not be refreshed at all,
    // e.g. offline): keep the choice and render it through the fallback.
    if (state.availableLanguages.withCode(code) != null) {
      return;
    }

    await _settingsRepository.clearSelectedLanguageCode();
    final languageCode = resolveLanguageCode(
      selectedLanguageCode: null,
      availableLanguages: state.availableLanguages,
    );
    if (languageCode == code) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
          "Localization: no labels available for '$code', falling back to '$languageCode'");
    }

    Get.updateLocale(Utils.getLocaleFromLanguageCode(languageCode));
    emit(state.copyWith(
      languageCode: languageCode,
      availableLanguages: _withLanguage(state.availableLanguages, languageCode),
    ));
  }

  /// Fetches, caches and applies the labels of [languageCode].
  ///
  /// Never throws and never blocks a language switch: an unreachable API, or a
  /// language whose label file has not been uploaded on the panel (`file_name`
  /// comes back as `{}`), simply leaves the local labels untouched so the
  /// bundled files and the `fallbackLocale` keep supplying the text.
  Future<void> _refreshLabels(String languageCode) async {
    try {
      final labels =
          await _localizationRepository.fetchLabels(languageCode: languageCode);
      if (labels.isEmpty) {
        if (kDebugMode) {
          debugPrint(
              "Localization: no labels uploaded for '$languageCode', keeping local ones");
        }
        return;
      }

      await _localizationRepository.cacheLabels(
          languageCode: languageCode, labels: labels);
      final changed =
          AppTranslation.overlayRemoteLabels({languageCode: labels});
      if (kDebugMode) {
        debugPrint(
            "Localization: ${labels.length} labels fetched for '$languageCode' (changed: $changed)");
      }

      // Repaint labels that are already on screen.
      if (changed && languageCode == currentLanguageCode) {
        Get.forceAppUpdate();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Localization: labels fetch failed for '$languageCode': $e");
      }
    }
  }

  /// Switches the app language on an explicit user choice, and remembers it so
  /// the app stops following the panel default.
  ///
  /// Languages with local labels (bundled file or cached API labels) switch
  /// instantly and refresh their labels in the background. A language with no
  /// local labels yet has its labels fetched first, so the switch lands on
  /// translated text when the panel has a file for it.
  ///
  /// The switch always goes through. If the panel has no labels for the
  /// language — or the fetch fails — the app falls back to the bundled labels
  /// through GetX's `fallbackLocale` instead of refusing to switch.
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode == currentLanguageCode) {
      return;
    }

    if (AppTranslation.hasTranslationsFor(languageCode)) {
      _refreshLabels(languageCode);
    } else {
      emit(state.copyWith(languageChangeInProgress: true));
      await _refreshLabels(languageCode);
    }

    await _settingsRepository.setSelectedLanguageCode(languageCode);
    Get.updateLocale(Utils.getLocaleFromLanguageCode(languageCode));
    emit(state.copyWith(
      languageCode: languageCode,
      languageChangeInProgress: false,
    ));
  }
}
