import 'package:eschool_saas_staff/app/schoolBuildConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// The logo bundled for this build, which may be an SVG or a raster image.
class AppLogoImage extends StatelessWidget {
  const AppLogoImage({
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (SchoolBuildConfig.logoIsVector) {
      return SvgPicture.asset(
        SchoolBuildConfig.logoAsset,
        height: height,
        width: width,
        fit: fit,
      );
    }
    return Image.asset(
      SchoolBuildConfig.logoAsset,
      height: height,
      width: width,
      fit: fit,
    );
  }
}
