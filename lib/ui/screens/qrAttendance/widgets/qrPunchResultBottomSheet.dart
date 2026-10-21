import 'package:eschool_saas_staff/data/models/qrAttendance/qrPunchResult.dart';
import 'package:eschool_saas_staff/ui/screens/staffTransportEnroll/selectTransport/widgets/successCheckAnimatedIcon.dart';
import 'package:eschool_saas_staff/ui/widgets/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/customRoundedButton.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Confirmation of a recorded punch.
///
/// A punch the server recognised as a repeat of the same request (`duplicate`)
/// is shown exactly like a fresh one: nothing was recorded twice, so telling
/// the user it was "already recorded" would read as a failure when it is not.
class QrPunchResultBottomSheet extends StatelessWidget {
  final QrPunchResult result;

  const QrPunchResultBottomSheet({super.key, required this.result});

  /// Opens the sheet for [result].
  static Future<void> show({
    required BuildContext context,
    required QrPunchResult result,
  }) {
    return Utils.showBottomSheet(
      context: context,
      child: QrPunchResultBottomSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
      titleLabelKey: result.punchType.isPunchIn ? punchInKey : punchOutKey,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: appContentHorizontalPadding,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SuccessCheckAnimatedIcon(size: 88),
            const SizedBox(height: 20),
            CustomTextContainer(
              textKey: Utils.getTranslatedLabel(result.punchType.isPunchIn
                      ? punchedInAtKey
                      : punchedOutAtKey)
                  .replaceAll('@time', result.formattedPunchTime),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextContainer(
              textKey: result.nextAction.isPunchIn
                  ? nextScanPunchesYouInKey
                  : nextScanPunchesYouOutKey,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            _buildStats(context),
            const SizedBox(height: 12),
            _buildDistanceNote(context),
            const SizedBox(height: 20),
            CustomRoundedButton(
              widthPercentage: 1,
              backgroundColor: Theme.of(context).colorScheme.primary,
              buttonTitle: doneKey,
              showBorder: false,
              height: 46,
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final String? closedSessionDuration = result.closedSessionDuration;

    return Column(
      children: [
        // Only a punch out closes a session, so this line is absent on a
        // punch in.
        if (closedSessionDuration != null) ...[
          CustomTextContainer(
            textKey: Utils.getTranslatedLabel(sessionClosedKey)
                .replaceAll('@duration', closedSessionDuration),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
        ],
        _StatTile(
          labelKey: workedTodayKey,
          value: result.formattedWorkingDuration,
        ),
      ],
    );
  }

  Widget _buildDistanceNote(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 15,
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: CustomTextContainer(
            textKey: Utils.getTranslatedLabel(youAreAtSchoolKey)
                .replaceAll('@distance', result.formattedDistance),
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// Label above a highlighted value, used for the punch summary figure.
class _StatTile extends StatelessWidget {
  final String labelKey;
  final String value;

  const _StatTile({required this.labelKey, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextContainer(
            textKey: labelKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
