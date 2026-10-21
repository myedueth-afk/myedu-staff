import 'dart:io';

import 'package:eschool_saas_staff/utils/appIllustrations.dart';
import 'package:eschool_saas_staff/utils/svgColorSwap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

// The icons and illustrations take the school's colours at runtime. An asset
// that is missing, fails to parse or paints a colour the theme does not
// replace only shows up as a blank or off-brand picture on a device, so every
// one is checked here.

const Color _schoolPrimary = Color(0xffC2185B);
const Color _schoolSecondary = Color(0xff101010);

/// Counts how often each source colour of [swap] was repainted.
class _RecordingSwap extends ColorMapper {
  final SvgColorSwap swap;
  final Map<Color, int> hits = {};

  _RecordingSwap(this.swap);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    final swapped = swap.substitute(id, elementName, attributeName, color);
    if (swapped != color) {
      final source = swap.swaps.keys.firstWhere(
        (key) => (key.toARGB32() & 0xffffff) == (color.toARGB32() & 0xffffff),
      );
      hits[source] = (hits[source] ?? 0) + 1;
    }
    return swapped;
  }
}

/// Colours an SVG paints with, leaving out clip shapes, which paint nothing.
Set<String> _paintedColors(String svg) {
  final visible = svg.replaceAll(RegExp(r'<clipPath[\s\S]*?</clipPath>'), '');
  return RegExp(r'''(?:fill|stroke|stop-color)="(#[0-9a-fA-F]{3,8})"''')
      .allMatches(visible)
      .map((match) => match.group(1)!.toUpperCase())
      .toSet();
}

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}'
        .toUpperCase();

Future<_RecordingSwap> _parse(
  WidgetTester tester,
  File file,
  Map<Color, Color> swaps,
) async {
  final recorder = _RecordingSwap(SvgColorSwap(swaps));
  final bytes = await tester.runAsync(
    () => SvgStringLoader(file.readAsStringSync(), colorMapper: recorder)
        .loadBytes(null),
  );
  expect(bytes!.lengthInBytes, greaterThan(0), reason: '${file.path} is empty');
  return recorder;
}

Iterable<String> _literals(RegExp pattern) => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .expand(
      (file) => pattern
          .allMatches(file.readAsStringSync())
          .map((match) => match.group(1)!),
    );

void main() {
  final illustrations = Directory('assets/illustrations')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.svg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  // The bottom navigation icons, as homeScreen.dart names them.
  final navIcons = _literals(
    RegExp(r'''(?:iconPath|selectedIconPath):\s*["']([\w\-]+\.svg)["']'''),
  ).toSet().map((name) => File('assets/images/$name')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('every image the app names is a bundled file', () {
    final images = _literals(
      RegExp(r'''["'](?:assets/images/)?([\w\-]+\.(?:svg|png))["']'''),
    ).toSet();

    expect(images, isNotEmpty);
    for (final name in images) {
      expect(File('assets/images/$name').existsSync(), isTrue,
          reason: 'assets/images/$name is missing');
    }
  });

  test('every illustration is in the registry, and the other way round', () {
    final registry = File('lib/utils/appIllustrations.dart').readAsStringSync();
    final registered = RegExp(r'"\$_dir/(\w+\.svg)"')
        .allMatches(registry)
        .map((match) => 'assets/illustrations/${match.group(1)}')
        .toSet();

    expect(registered, illustrations.map((file) => file.path).toSet());
    expect(File(AppIllustrations.noData).existsSync(), isTrue);
  });

  group('illustrations', () {
    for (final file in illustrations) {
      testWidgets('${file.uri.pathSegments.last} takes the primary colour',
          (tester) async {
        final recorder = await _parse(
          tester,
          file,
          {SvgSourceColors.brand: _schoolPrimary},
        );
        expect(recorder.hits[SvgSourceColors.brand], greaterThan(0),
            reason: '${file.path} has no brand-coloured part to repaint');
      });
    }

    testWidgets('the start-a-chat artwork has no colour left as drawn',
        (tester) async {
      final file = File('assets/images/new_chat_icon.svg');
      expect(
        _paintedColors(file.readAsStringSync()).difference({'#FFF'}),
        {_hex(SvgSourceColors.legacyBrand), _hex(SvgSourceColors.accent)},
      );
      await _parse(tester, file, {
        SvgSourceColors.legacyBrand: _schoolPrimary,
        SvgSourceColors.accent: _schoolPrimary,
      });
    });
  });

  group('bottom navigation icons', () {
    test('are all found', () => expect(navIcons, hasLength(10)));

    for (final file in navIcons) {
      final selected = file.path.endsWith('_active.svg');

      testWidgets('${file.uri.pathSegments.last} follows the theme',
          (tester) async {
        expect(
          _paintedColors(file.readAsStringSync()),
          {
            _hex(SvgSourceColors.navOutline),
            if (selected) _hex(SvgSourceColors.accent),
          },
          reason: '${file.path} paints a colour the app does not expect',
        );

        final recorder = await _parse(
          tester,
          file,
          {SvgSourceColors.navOutline: _schoolSecondary},
        );
        expect(recorder.hits[SvgSourceColors.navOutline], greaterThan(0));
      });
    }
  });

  group('SvgColorSwap', () {
    final swap = SvgColorSwap({SvgSourceColors.brand: _schoolPrimary});

    test('repaints the source colour and keeps its transparency', () {
      expect(
        swap.substitute(null, 'path', 'fill', SvgSourceColors.brand),
        _schoolPrimary,
      );
      final faded = swap.substitute(
        null,
        'path',
        'fill',
        SvgSourceColors.brand.withValues(alpha: 0.5),
      );
      expect(faded.a, closeTo(0.5, 0.01));
      expect(faded.toARGB32() & 0xffffff, _schoolPrimary.toARGB32() & 0xffffff);
    });

    test('leaves every other colour as drawn', () {
      const skin = Color(0xffFFAA9D);
      expect(swap.substitute(null, 'path', 'fill', skin), skin);
    });

    test('is equal by palette, so the picture cache is shared', () {
      final same = SvgColorSwap({SvgSourceColors.brand: _schoolPrimary});
      final other = SvgColorSwap({SvgSourceColors.brand: Colors.black});
      expect(same, swap);
      expect(same.hashCode, swap.hashCode);
      expect(other, isNot(swap));
    });
  });
}
