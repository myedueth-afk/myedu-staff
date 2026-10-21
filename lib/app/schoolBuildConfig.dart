/// Build-time values set by the School Builder addon through `--dart-define`.
/// Each falls back to the stock value, so a plain `flutter run` is unchanged.
/// Runtime settings (feature flags, rewards, school details) do not belong here.
library;

class SchoolBuildConfig {
  const SchoolBuildConfig._();

  /// School id from schools.json; `default` for a build without the addon.
  static const String id = String.fromEnvironment(
    'SCHOOL_ID',
    defaultValue: 'default',
  );

  /// Human readable school name, e.g. for diagnostics and about screens.
  static const String name = String.fromEnvironment(
    'SCHOOL_NAME',
    defaultValue: 'MyEdu Staff',
  );

  /// The name shown under the launcher icon, mirrored from the native side.
  static const String appName = String.fromEnvironment(
    'SCHOOL_APP_NAME',
    defaultValue: 'MyEdu Staff',
  );

  /// Logo bundled for this build, staged into `assets/branding/` by the addon.
  static const String logoAsset = String.fromEnvironment(
    'SCHOOL_LOGO_ASSET',
    defaultValue: 'assets/images/appLogo.svg',
  );

  static bool get logoIsVector => logoAsset.toLowerCase().endsWith('.svg');

  /// Splash logo staged into `assets/branding/` by the addon; empty keeps the
  /// stock splash image and colour.
  static const String splashLogoAsset = String.fromEnvironment(
    'SCHOOL_SPLASH_LOGO_ASSET',
    defaultValue: '',
  );

  static bool get hasSplashLogo => splashLogoAsset.isNotEmpty;

  /// Width of the splash logo in logical pixels.
  static const int splashLogoWidth = int.fromEnvironment(
    'SCHOOL_SPLASH_LOGO_WIDTH',
    defaultValue: 160,
  );

  /// Splash background colour; used only together with [splashLogoAsset].
  static const int splashBackgroundValue = int.fromEnvironment(
    'SCHOOL_COLOR_SPLASH_BACKGROUND',
    defaultValue: 0xffFFFFFF,
  );

  /// The school code a school-specific build is locked to; empty otherwise.
  static const String schoolCode = String.fromEnvironment(
    'SCHOOL_CODE',
    defaultValue: '',
  );

  /// True when this build serves a single, pre-selected school, so the login
  /// screens have no school code field.
  static bool get hasFixedSchoolCode =>
      locksSchoolCode(appType: appType, schoolCode: schoolCode);

  /// The rule behind [hasFixedSchoolCode]: only a school-specific app is
  /// locked to its code. A general app is shared by many schools, so it asks
  /// every user for theirs, even if the build was given a code.
  static bool locksSchoolCode({
    required String appType,
    required String schoolCode,
  }) =>
      appType == appTypeSchoolSpecific && schoolCode.isNotEmpty;

  /// The locked code on a school-specific build, otherwise what the user typed.
  static String resolveSchoolCode(String typed) =>
      hasFixedSchoolCode ? schoolCode : typed.trim();

  /// Off for school builds unless `runtime.showDemoCredentials` is true.
  static const bool showDemoCredentials = bool.fromEnvironment(
    'SCHOOL_SHOW_DEMO_CREDENTIALS',
    defaultValue: false,
  );

  static const String appTypeGeneral = 'general';
  static const String appTypeSchoolSpecific = 'school-specific';

  /// Which kind of app this is, sent as the `App-Type` header on login and on
  /// the splash screen's settings request: [appTypeGeneral] without the addon,
  /// otherwise the school's `runtime.appType`.
  static const String appType = String.fromEnvironment(
    'SCHOOL_APP_TYPE',
    defaultValue: appTypeGeneral,
  );

  /// True when this binary was produced by the multi-school build system.
  static bool get isSchoolBuild => id != 'default';
}
