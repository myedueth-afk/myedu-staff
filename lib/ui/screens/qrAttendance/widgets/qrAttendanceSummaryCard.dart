import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceHistory.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrAttendanceDayTypePill.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/material.dart';

/// Totals of the selected month: the day counts and the minutes actually
/// counted by the server.
class QrAttendanceSummaryCard extends StatelessWidget {
  final QrAttendanceSummary summary;

  const QrAttendanceSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(appContentHorizontalPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.tertiary),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SummaryCount(
                labelKey: presentKey,
                count: summary.present,
                dayType: QrAttendanceDayType.present,
              ),
              _SummaryCount(
                labelKey: halfDaysKey,
                count: summary.halfDay,
                dayType: QrAttendanceDayType.halfDay,
              ),
              _SummaryCount(
                labelKey: absentKey,
                count: summary.absent,
                dayType: QrAttendanceDayType.absent,
              ),
              _SummaryCount(
                labelKey: holidaysKey,
                count: summary.holiday,
                dayType: QrAttendanceDayType.holiday,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Divider(height: 1, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timelapse,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomTextContainer(
                  textKey: totalWorkingHoursKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                summary.formattedWorkingDuration,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One count of the summary row, tinted with its day type colour.
class _SummaryCount extends StatelessWidget {
  final String labelKey;
  final int count;
  final QrAttendanceDayType dayType;

  const _SummaryCount({
    required this.labelKey,
    required this.count,
    required this.dayType,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = QrAttendanceDayTypePill.colorOf(context, dayType);

    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          CustomTextContainer(
            textKey: labelKey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
