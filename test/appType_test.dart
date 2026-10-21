import 'package:eschool_saas_staff/app/schoolBuildConfig.dart';
import 'package:eschool_saas_staff/utils/api.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app type depends on how the binary was compiled, so this file is run twice:
///
///   flutter test test/appType_test.dart
///   flutter test test/appType_test.dart --dart-define=SCHOOL_APP_TYPE=school-specific
///
/// Each test asserts only the mode it applies to, so both runs are green.
void main() {
  const hasAppType = bool.hasEnvironment('SCHOOL_APP_TYPE');

  test('a build without the addon is the general app', () {
    if (hasAppType) return;
    expect(SchoolBuildConfig.appType, SchoolBuildConfig.appTypeGeneral);
  });

  test('a school build sends the app type it was built with', () {
    if (!hasAppType) return;
    expect(
      SchoolBuildConfig.appType,
      const String.fromEnvironment('SCHOOL_APP_TYPE'),
    );
  });

  test('the header name is the one the backend reads', () {
    expect(Api.appTypeHeader, 'App-Type');
  });

  test('a request that opts in carries only the App-Type header', () {
    expect(
      Api.requestHeaders(useAuthToken: false, sendAppType: true),
      {Api.appTypeHeader: SchoolBuildConfig.appType},
    );
  });

  test('any other signed-out request carries no headers at all', () {
    expect(Api.requestHeaders(useAuthToken: false), isNull);
  });
}
