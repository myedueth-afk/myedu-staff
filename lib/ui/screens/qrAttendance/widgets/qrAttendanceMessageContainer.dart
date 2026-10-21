import 'package:eschool_saas_staff/ui/widgets/customRoundedButton.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:flutter/material.dart';

/// Full width notice used for every state where scanning cannot continue:
/// the feature is off, no shift is assigned, the QR expired, the location is
/// unavailable, and so on.
///
/// The message is displayed exactly as received — the server has already
/// translated it — with an optional action underneath.
class QrAttendanceMessageContainer extends StatelessWidget {
  final IconData icon;
  final String message;

  /// Tone of the notice. Warnings keep the primary colour, blocking states use
  /// the error colour.
  final bool isBlocking;

  final String? actionTitleKey;
  final VoidCallback? onTapAction;

  const QrAttendanceMessageContainer({
    super.key,
    required this.icon,
    required this.message,
    this.isBlocking = false,
    this.actionTitleKey,
    this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isBlocking
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(appContentHorizontalPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextContainer(
                  textKey: message,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 20 / 13.5,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          if (actionTitleKey != null && onTapAction != null) ...[
            const SizedBox(height: 15),
            CustomRoundedButton(
              widthPercentage: 1,
              backgroundColor: accentColor.withValues(alpha: 0.1),
              buttonTitle: actionTitleKey,
              titleColor: accentColor,
              textSize: 14,
              height: 42,
              showBorder: false,
              onTap: onTapAction,
            ),
          ],
        ],
      ),
    );
  }
}
