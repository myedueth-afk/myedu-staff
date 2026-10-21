import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceHistory.dart';
import 'package:eschool_saas_staff/ui/screens/qrAttendance/widgets/qrAttendanceDayTypePill.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';

/// One finalized day of the history list.
///
/// A day whose punch in was never closed is called out: those minutes are not
/// counted and only an administrator can correct them.
class QrAttendanceHistoryRowCard extends StatelessWidget {
  final QrAttendanceHistoryRow row;
  final VoidCallback onTap;

  const QrAttendanceHistoryRowCard({
    super.key,
    required this.row,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color dayTypeColor =
        QrAttendanceDayTypePill.colorOf(context, row.type);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.tertiary),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildDateBadge(context, dayTypeColor),
                const SizedBox(width: 12),
                Expanded(child: _buildDetails(context, secondaryColor)),
                const SizedBox(width: 8),
                QrAttendanceDayTypePill(dayType: row.type),
              ],
            ),
            if (row.hasIncompleteSession) ...[
              const SizedBox(height: 10),
              _buildIncompleteSessionNote(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateBadge(BuildContext context, Color dayTypeColor) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: dayTypeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            row.dayOfMonth,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: dayTypeColor,
            ),
          ),
          Text(
            // Three letters keep every weekday inside the badge.
            row.weekDayLabel.length > 3
                ? row.weekDayLabel.substring(0, 3)
                : row.weekDayLabel,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: dayTypeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Color secondaryColor) {
    final List<String> details = [
      if (row.shiftName.isNotEmpty) row.shiftName,
      "${Utils.getTranslatedLabel(completedSessionsKey)}: ${row.completedSessions}",
      if (row.isManuallyMarked) Utils.getTranslatedLabel(manuallyMarkedKey),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timelapse, size: 14, color: secondaryColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                row.formattedWorkingDuration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          details.join(" • "),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            color: secondaryColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildIncompleteSessionNote(BuildContext context) {
    final Color errorColor = Theme.of(context).colorScheme.error;

    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14, color: errorColor),
          const SizedBox(width: 8),
          Expanded(
            child: CustomTextContainer(
              textKey: incompleteSessionNoteKey,
              style: TextStyle(
                fontSize: 11.5,
                height: 16 / 11.5,
                color: errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
