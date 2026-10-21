import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The colours the designer's SVGs are drawn in. They only identify which
/// parts of an asset to repaint, and are never shown as they are.
class SvgSourceColors {
  const SvgSourceColors._();

  /// Brand-coloured parts of the illustrations.
  static const Color brand = Color(0xff22577A);

  /// The same, in the artwork that predates the illustrations.
  static const Color legacyBrand = Color(0xff29638A);

  /// Outline of the bottom navigation icons.
  static const Color navOutline = Color(0xff1A1C1D);

  /// Second tone of the two-tone artwork.
  static const Color accent = Color(0xff57CC99);
}

/// Repaints chosen colours of a multi-colour SVG and leaves the others as
/// drawn, which a [ColorFilter] can't do. A colour's own alpha is kept.
///
/// Compared by value, so flutter_svg caches one picture per asset and palette.
class SvgColorSwap extends ColorMapper {
  /// Source colour (alpha ignored) to the colour painted in its place.
  final Map<Color, Color> swaps;

  const SvgColorSwap(this.swaps);

  static int _rgb(Color color) => color.toARGB32() & 0x00ffffff;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    final rgb = _rgb(color);
    for (final swap in swaps.entries) {
      if (_rgb(swap.key) == rgb) {
        return swap.value.withValues(alpha: swap.value.a * color.a);
      }
    }
    return color;
  }

  @override
  bool operator ==(Object other) =>
      other is SvgColorSwap && mapEquals(other.swaps, swaps);

  @override
  int get hashCode => Object.hashAllUnordered(
        swaps.entries.map((swap) => Object.hash(swap.key, swap.value)),
      );
}
