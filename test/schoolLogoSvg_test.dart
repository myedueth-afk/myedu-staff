import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

// A malformed SVG only shows up as a blank logo at runtime, so parse every
// enabled school's logo through flutter_svg here.

Map<String, String> _logosFromSchoolsJson() {
  final file = File('addon/config/schools.json');
  if (!file.existsSync()) return const {};

  final cfg = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final defaults = (cfg['defaults'] as Map<String, dynamic>?) ?? const {};
  final fallback =
      ((defaults['branding'] as Map<String, dynamic>?) ?? const {})['logo'];

  final out = <String, String>{};
  for (final raw in (cfg['schools'] as List<dynamic>)) {
    final school = raw as Map<String, dynamic>;
    if (school['enabled'] == false) continue;
    final branding = (school['branding'] as Map<String, dynamic>?) ?? const {};
    final logo = (branding['logo'] ?? fallback) as String?;
    if (logo != null && logo.toLowerCase().endsWith('.svg')) {
      out[school['id'] as String] = logo;
    }
  }
  return out;
}

void main() {
  final logos = _logosFromSchoolsJson();

  logos.forEach((school, path) {
    testWidgets('$school logo renders through flutter_svg', (tester) async {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SvgPicture.string(
              file.readAsStringSync(),
              width: 240,
              height: 240,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$path failed to parse');
      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });

  test('the wordmark uses no <text>, so no font is needed to draw it', () {
    for (final path in logos.values.where((p) => !p.contains('demo'))) {
      final svg = File(path).readAsStringSync();
      expect(svg.contains('<text'), isFalse, reason: '$path relies on a font');
    }
  });
}
