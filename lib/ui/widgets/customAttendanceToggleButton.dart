import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/utils.dart';
import 'package:flutter/material.dart';

class CustomAttendanceToggleButton extends StatelessWidget {
  final StudentAttendanceStatus selectedStatus;
  final Function(StudentAttendanceStatus status) onStatusChanged;
  final double buttonWidth;
  final double buttonHeight;

  ///False for a student the school approved a leave for. Their day is already
  ///accounted for, so absent is shown disabled and only present can be picked.
  final bool canMarkAbsent;

  ///Shows the leave option itself, so a teacher who marked an on leave student
  ///present by mistake can put the row back the way the school approved it.
  final bool showOnLeaveOption;

  const CustomAttendanceToggleButton({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.buttonWidth = 30.0,
    this.buttonHeight = 30.0,
    this.canMarkAbsent = true,
    this.showOnLeaveOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Present Button
        GestureDetector(
          onTap: () {
            onStatusChanged(StudentAttendanceStatus.present);
          },
          child: Container(
            width: buttonWidth,
            height: buttonHeight,
            decoration: BoxDecoration(
              color: selectedStatus == StudentAttendanceStatus.present
                  ? const Color(0xFF4CAF50) // Bright Green
                  : const Color(0xFF4CAF50)
                      .withValues(alpha: 0.2), // Light Green
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                Utils.getTranslatedLabel(presentShortKey),
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: selectedStatus == StudentAttendanceStatus.present
                      ? Colors.white
                      : const Color(0xFF4CAF50),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Absent Button
        GestureDetector(
          onTap: canMarkAbsent
              ? () {
                  onStatusChanged(StudentAttendanceStatus.absent);
                }
              : null,
          child: Opacity(
            opacity: canMarkAbsent ? 1.0 : 0.35,
            child: Container(
              width: buttonWidth,
              height: buttonHeight,
              decoration: BoxDecoration(
                color: selectedStatus == StudentAttendanceStatus.absent
                    ? const Color(0xFFF44336) // Bright Red
                    : const Color(0xFFF44336)
                        .withValues(alpha: 0.2), // Light Red
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text(
                  Utils.getTranslatedLabel(absentShortKey),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: selectedStatus == StudentAttendanceStatus.absent
                        ? Colors.white
                        : const Color(0xFFF44336),
                  ),
                ),
              ),
            ),
          ),
        ),

        // On Leave Button, only for a student with an approved leave
        if (showOnLeaveOption) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              onStatusChanged(StudentAttendanceStatus.onLeave);
            },
            child: Container(
              height: buttonHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selectedStatus == StudentAttendanceStatus.onLeave
                    ? onLeaveAttendanceColor // Bright Amber
                    : onLeaveAttendanceColor
                        .withValues(alpha: 0.2), // Light Amber
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                Utils.getTranslatedLabel(leaveKey),
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: selectedStatus == StudentAttendanceStatus.onLeave
                      ? Colors.white
                      : onLeaveAttendanceColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
