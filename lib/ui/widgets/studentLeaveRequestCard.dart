import 'package:eschool_saas_staff/data/models/studentLeave.dart';
import 'package:eschool_saas_staff/ui/styles/colors.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/studentLeaveStatusChip.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';

/// Header shared by the leave list card and the details screen: student avatar,
/// name, class and the current status chip.
class StudentLeaveHeader extends StatelessWidget {
  final StudentLeave leave;

  const StudentLeaveHeader({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 32.0,
          width: 32.0,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            shape: BoxShape.circle,
            image: (leave.studentImage ?? "").isEmpty
                ? null
                : DecorationImage(
                    image: NetworkImage(leave.studentImage!),
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextContainer(
                textKey: leave.studentName ?? "-",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14.0,
                  height: 20 / 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if ((leave.studentClass ?? "").isNotEmpty) ...[
                const SizedBox(height: 4.0),
                CustomTextContainer(
                  textKey: leave.studentClass!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: labelColor,
                    fontSize: 12.0,
                    height: 16 / 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        StudentLeaveStatusChip(status: leave.leaveStatus),
      ],
    );
  }
}

/// Boxed date range plus day count, shown on both the card and the details
/// screen.
class StudentLeaveDurationBox extends StatelessWidget {
  final StudentLeave leave;

  const StudentLeaveDurationBox({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 9.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: Theme.of(context).colorScheme.tertiary),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextContainer(
            textKey: Utils.formatLeaveDateRange(
              fromDate: leave.fromDate,
              toDate: leave.toDate,
            ),
            style: const TextStyle(
              color: Color(0xff212121),
              fontSize: 14.0,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          CustomTextContainer(
            textKey:
                "${leave.totalDays} ${Utils.getTranslatedLabel(leave.totalDays == 1 ? dayKey : daysKey)}",
            style: const TextStyle(
              color: labelColor,
              fontSize: 12.0,
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Caption label above a value, e.g. "Reason".
class StudentLeaveFieldLabel extends StatelessWidget {
  final String labelKey;

  const StudentLeaveFieldLabel({super.key, required this.labelKey});

  @override
  Widget build(BuildContext context) {
    return CustomTextContainer(
      textKey: labelKey,
      style: const TextStyle(
        color: captionColor,
        fontSize: 12.0,
        height: 16 / 12,
        letterSpacing: 0.4,
      ),
    );
  }
}

/// One student leave request on the review list.
class StudentLeaveRequestCard extends StatelessWidget {
  final StudentLeave leave;
  final VoidCallback onTap;

  const StudentLeaveRequestCard({
    super.key,
    required this.leave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudentLeaveHeader(leave: leave),
            Divider(
              height: 25.0,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            StudentLeaveDurationBox(leave: leave),
            const SizedBox(height: 12.0),
            StudentLeaveFieldLabel(labelKey: reasonKey),
            const SizedBox(height: 4.0),
            CustomTextContainer(
              textKey: (leave.reason ?? "").trim().isEmpty
                  ? "-"
                  : leave.reason!.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff212121),
                fontSize: 14.0,
                height: 20 / 14,
                letterSpacing: 0.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
