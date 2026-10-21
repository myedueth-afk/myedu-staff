import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceConfig.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceToday.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceUtils.dart';
import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';

/// Hero card of the QR attendance screen: whether the staff member is on duty,
/// how long they have worked today and which shift the day is measured against.
class QrTodayStatusCard extends StatelessWidget {
  final QrAttendanceConfig config;

  const QrTodayStatusCard({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final QrAttendanceToday? today = config.today;
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color successColor =
        Theme.of(context).extension<CustomColors>()?.successColor ??
            primaryColor;
    final bool onDuty = today?.onDuty ?? false;
    final Color statusColor = onDuty ? successColor : primaryColor;

    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(appContentHorizontalPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.tertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, today, statusColor, onDuty),
          const SizedBox(height: 18),
          _buildWorkedDuration(context, today),
          if (today?.openSession != null) ...[
            const SizedBox(height: 12),
            _buildOpenSessionNote(context, today!, successColor),
          ],
          const SizedBox(height: 18),
          Divider(height: 1, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(height: 15),
          _buildFooterDetails(context, today),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    QrAttendanceToday? today,
    Color statusColor,
    bool onDuty,
  ) {
    return Row(
      children: [
        Expanded(
          child: CustomTextContainer(
            textKey: QrAttendanceUtils.formatDate(today?.date),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              CustomTextContainer(
                textKey: onDuty ? onDutyKey : offDutyKey,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkedDuration(BuildContext context, QrAttendanceToday? today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextContainer(
          textKey: workedTodayKey,
          style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          today?.formattedWorkingDuration ??
              QrAttendanceUtils.formatDuration(0),
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 38 / 30,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOpenSessionNote(
    BuildContext context,
    QrAttendanceToday today,
    Color successColor,
  ) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_outline, size: 16, color: successColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${Utils.getTranslatedLabel(sessionInProgressKey)} • ${today.formattedOpenSessionTime}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterDetails(BuildContext context, QrAttendanceToday? today) {
    final String shiftName = today?.shift?.name ?? "";
    final String shiftRange = today?.shift?.formattedTimeRange ?? "";
    final String schoolHours = config.formattedSchoolHours;

    return Row(
      children: [
        Expanded(
          child: _DetailColumn(
            labelKey: shiftKey,
            value: shiftName.isEmpty ? "-" : shiftName,
            helperText: shiftRange,
          ),
        ),
        Container(
          width: 1,
          height: 34,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _DetailColumn(
              labelKey: schoolHoursKey,
              value: schoolHours.isEmpty ? "-" : schoolHours,
            ),
          ),
        ),
      ],
    );
  }
}

/// Label above a value, with an optional smaller helper line underneath.
class _DetailColumn extends StatelessWidget {
  final String labelKey;
  final String value;
  final String? helperText;

  const _DetailColumn({
    required this.labelKey,
    required this.value,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextContainer(
          textKey: labelKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            color: secondaryColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: secondaryColor,
          ),
        ),
        if ((helperText ?? "").isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            helperText!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: secondaryColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}
