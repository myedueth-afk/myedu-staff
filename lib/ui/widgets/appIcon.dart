import 'package:eschool_saas_staff/utils/svgColorSwap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A single-colour SVG icon painted in the theme's primary colour, so it
/// follows the colour a school is built with. Pass [color] where the icon sits
/// on a coloured surface and needs the contrasting colour.
class AppIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;
  final BoxFit fit;

  const AppIcon(
    this.assetPath, {
    super.key,
    this.size,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).colorScheme.primary,
        BlendMode.srcIn,
      ),
    );
  }
}

/// The rounded tile a menu icon sits on: a tint of the icon's colour.
BoxDecoration appIconTileDecoration(Color iconColor) {
  return BoxDecoration(
    color: iconColor.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
  );
}

/// A two-tone bottom navigation icon: the outline takes the theme's secondary
/// colour, and the selected icon keeps the accent fill it is drawn with.
class BottomNavIcon extends StatelessWidget {
  final String assetPath;

  const BottomNavIcon(this.assetPath, {super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture(
      SvgAssetLoader(
        assetPath,
        colorMapper: SvgColorSwap({
          SvgSourceColors.navOutline: Theme.of(context).colorScheme.secondary,
        }),
      ),
    );
  }
}

/// A multi-colour illustration whose brand-coloured parts follow the theme's
/// primary colour; skin, hair and the other colours stay as drawn. A second
/// brand tone becomes a lighter primary, so two-tone artwork stays two-tone.
class AppIllustration extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppIllustration(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  static const double _secondToneOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SvgPicture(
      SvgAssetLoader(
        assetPath,
        colorMapper: SvgColorSwap({
          SvgSourceColors.brand: primary,
          SvgSourceColors.legacyBrand: primary,
          SvgSourceColors.accent: primary.withValues(alpha: _secondToneOpacity),
        }),
      ),
      width: width,
      height: height,
      fit: fit,
    );
  }
}
