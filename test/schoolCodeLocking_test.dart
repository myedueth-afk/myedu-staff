import 'package:eschool_saas_staff/app/schoolBuildConfig.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextFieldContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/schoolCodeFieldContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Behaviour differs by how the binary was compiled, so this file is run three
/// ways:
///
///   flutter test test/schoolCodeLocking_test.dart
///   flutter test test/schoolCodeLocking_test.dart --dart-define=SCHOOL_APP_TYPE=school-specific --dart-define=SCHOOL_CODE=<any code>
///   flutter test test/schoolCodeLocking_test.dart --dart-define=SCHOOL_APP_TYPE=general --dart-define=SCHOOL_CODE=<any code>
///
/// The first group holds for every build. Each of the other two asserts only
/// the mode it applies to, so all three runs are green.
void main() {
  final controller = TextEditingController();

  Widget host() => MaterialApp(
        home: Scaffold(
          body: SchoolCodeFieldContainer(textEditingController: controller),
        ),
      );

  group('which builds are locked to a school code', () {
    const general = SchoolBuildConfig.appTypeGeneral;
    const schoolSpecific = SchoolBuildConfig.appTypeSchoolSpecific;

    test('a school-specific app with a code is locked', () {
      expect(
        SchoolBuildConfig.locksSchoolCode(
            appType: schoolSpecific, schoolCode: 'SCH202412'),
        isTrue,
      );
    });

    test('a general app asks, even when it was given a code', () {
      expect(
        SchoolBuildConfig.locksSchoolCode(
            appType: general, schoolCode: 'SCH202412'),
        isFalse,
      );
      expect(
        SchoolBuildConfig.locksSchoolCode(appType: general, schoolCode: ''),
        isFalse,
      );
    });

    test('a school-specific app without a code has nothing to lock to', () {
      expect(
        SchoolBuildConfig.locksSchoolCode(
            appType: schoolSpecific, schoolCode: ''),
        isFalse,
      );
    });

    test('an app type the build does not know is not locked', () {
      expect(
        SchoolBuildConfig.locksSchoolCode(appType: '', schoolCode: 'SCH202412'),
        isFalse,
      );
    });

    test('this build follows the rule', () {
      expect(
        SchoolBuildConfig.hasFixedSchoolCode,
        SchoolBuildConfig.locksSchoolCode(
          appType: SchoolBuildConfig.appType,
          schoolCode: SchoolBuildConfig.schoolCode,
        ),
      );
    });
  });

  group('a build that asks for the school code', () {
    if (SchoolBuildConfig.hasFixedSchoolCode) return;

    test('is a general app, or has no code to lock to', () {
      expect(
        SchoolBuildConfig.appType == SchoolBuildConfig.appTypeGeneral ||
            SchoolBuildConfig.schoolCode.isEmpty,
        isTrue,
      );
    });

    test('the typed code is what gets sent', () {
      expect(SchoolBuildConfig.resolveSchoolCode('  SCH202412 '), 'SCH202412');
      expect(SchoolBuildConfig.resolveSchoolCode(''), '');
    });

    testWidgets('the school code field is shown', (tester) async {
      await tester.pumpWidget(host());
      expect(find.byType(CustomTextFieldContainer), findsOneWidget);
    });
  });

  group('a school-specific build with its code', () {
    if (!SchoolBuildConfig.hasFixedSchoolCode) return;

    // Asserted against the compiled-in value rather than a literal, so this
    // passes for whichever school the run was configured with.
    final baked = SchoolBuildConfig.schoolCode;

    test('the school is baked in', () {
      expect(SchoolBuildConfig.appType, SchoolBuildConfig.appTypeSchoolSpecific);
      expect(baked, isNotEmpty);
      expect(baked.trim(), baked, reason: 'code must not be padded');
    });

    test('typed input cannot override the built-in code', () {
      expect(SchoolBuildConfig.resolveSchoolCode('XYZ999'), baked);
      expect(SchoolBuildConfig.resolveSchoolCode(''), baked);
      expect(SchoolBuildConfig.resolveSchoolCode('  spaced  '), baked);
    });

    testWidgets('the school code field is gone entirely', (tester) async {
      await tester.pumpWidget(host());
      expect(find.byType(CustomTextFieldContainer), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
