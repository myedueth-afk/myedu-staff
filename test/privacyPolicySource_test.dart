import 'package:eschool_saas_staff/app/schoolBuildConfig.dart';
import 'package:eschool_saas_staff/data/repositories/settingsRepository.dart';
import 'package:eschool_saas_staff/utils/api.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records which settings source was read, without going near the network.
class _RecordingSettingsRepository extends SettingsRepository {
  final List<String> calls = [];

  @override
  Future<String> getSetting(String type, {required bool isUserLoggedIn}) async {
    final call = isUserLoggedIn ? 'school:$type' : 'settings:$type';
    calls.add(call);
    return call;
  }

  @override
  Future<String> getPublicSchoolSetting(
    String type, {
    required String schoolCode,
  }) async {
    final call = 'public:$schoolCode:$type';
    calls.add(call);
    return call;
  }
}

/// Which source is read before login depends on how the binary was compiled,
/// so this file is run twice:
///
///   flutter test test/privacyPolicySource_test.dart
///   flutter test test/privacyPolicySource_test.dart --dart-define=SCHOOL_CODE=<any code>
///
/// Each group asserts only the mode it applies to, so both runs are green.
void main() {
  late _RecordingSettingsRepository repository;

  setUp(() => repository = _RecordingSettingsRepository());

  test('the header name is the one the backend reads', () {
    expect(Api.schoolCodeHeader, 'school-code');
  });

  test('a signed-out request naming a school carries only its code', () {
    expect(
      Api.requestHeaders(useAuthToken: false, schoolCode: 'tony2026629'),
      {Api.schoolCodeHeader: 'tony2026629'},
    );
  });

  test('signed in, the school\'s policy is read with the user\'s token',
      () async {
    await repository.getPrivacyPolicy(isUserLoggedIn: true);

    expect(repository.calls, ['school:privacy_policy']);
  });

  group('generic build (no SCHOOL_CODE)', () {
    if (SchoolBuildConfig.hasFixedSchoolCode) return;

    test('before login, the super admin\'s staff policy is shown', () async {
      await repository.getPrivacyPolicy(isUserLoggedIn: false);

      expect(repository.calls, ['settings:teacher_staff_privacy_policy']);
    });
  });

  group('school build (any SCHOOL_CODE)', () {
    if (!SchoolBuildConfig.hasFixedSchoolCode) return;

    test('before login, the school\'s policy is read by its code alone',
        () async {
      await repository.getPrivacyPolicy(isUserLoggedIn: false);

      expect(repository.calls, [
        'public:${SchoolBuildConfig.schoolCode}:privacy_policy',
      ]);
    });
  });
}
