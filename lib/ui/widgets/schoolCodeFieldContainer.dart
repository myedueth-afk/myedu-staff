import 'package:eschool_saas_staff/app/schoolBuildConfig.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextFieldContainer.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/material.dart';

/// School code input, rendered as nothing on a build locked to one school.
///
/// Read the value with [SchoolBuildConfig.resolveSchoolCode], not the controller.
class SchoolCodeFieldContainer extends StatelessWidget {
  const SchoolCodeFieldContainer({
    required this.textEditingController,
    this.prefixWidget,
    this.bottomPadding,
    Key? key,
  }) : super(key: key);

  final TextEditingController textEditingController;
  final Widget? prefixWidget;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    if (SchoolBuildConfig.hasFixedSchoolCode) {
      return const SizedBox.shrink();
    }

    return CustomTextFieldContainer(
      hideText: false,
      hintTextKey: schoolCodeKey,
      prefixWidget: prefixWidget,
      bottomPadding: bottomPadding,
      textEditingController: textEditingController,
    );
  }
}
