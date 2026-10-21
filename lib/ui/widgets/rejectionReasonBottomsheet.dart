import 'package:eschool_saas_staff/ui/widgets/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/customRoundedButton.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Collects the reviewer's remark before a leave is rejected. Returns the
/// entered reason through [Get.back], so the caller stays in charge of the
/// actual status update.
class RejectionReasonBottomsheet extends StatefulWidget {
  const RejectionReasonBottomsheet({super.key});

  @override
  State<RejectionReasonBottomsheet> createState() =>
      _RejectionReasonBottomsheetState();
}

class _RejectionReasonBottomsheetState
    extends State<RejectionReasonBottomsheet> {
  final TextEditingController _reasonTextEditingController =
      TextEditingController();

  @override
  void dispose() {
    _reasonTextEditingController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonTextEditingController.text.trim();

    if (reason.isEmpty) {
      Utils.showSnackBar(
        context: context,
        message: Utils.getTranslatedLabel(pleaseEnterRejectionReasonKey),
      );
      return;
    }

    Get.back(result: reason);
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
      titleLabelKey: rejectionReasonKey,
      child: Padding(
        //uniform inset keeps the field clear of the title divider above it.
        //No keyboard inset here: CustomBottomsheet notes the sheet route
        //already applies viewInsets.bottom, so adding it again double counts.
        padding: EdgeInsets.all(appContentHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border:
                    Border.all(color: Theme.of(context).colorScheme.tertiary),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                controller: _reasonTextEditingController,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14.0,
                  height: 20 / 14,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  //the padding lives on the field rather than the container so
                  //the whole box stays tappable and the first line is not
                  //pinned to the top edge
                  contentPadding: const EdgeInsets.all(16.0),
                  hintText:
                      Utils.getTranslatedLabel(enterRejectionReasonKey),
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.5),
                    fontSize: 14.0,
                    height: 20 / 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            CustomRoundedButton(
              onTap: _submit,
              height: 48.0,
              widthPercentage: 1.0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              buttonTitle: submitKey,
              showBorder: false,
              radius: 8.0,
            ),
          ],
        ),
      ),
    );
  }
}
