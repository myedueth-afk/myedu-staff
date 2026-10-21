import 'package:eschool_saas_staff/data/models/studentLeave.dart';
import 'package:eschool_saas_staff/ui/styles/colors.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/material.dart';

/// Tinted pill showing the status of a student leave request. Each status pairs
/// a light container with the matching solid text color from the design tokens.
class StudentLeaveStatusChip extends StatelessWidget {
  final StudentLeaveStatus status;

  const StudentLeaveStatusChip({super.key, required this.status});

  Color get _backgroundColor {
    switch (status) {
      case StudentLeaveStatus.approved:
        return leaveApprovedContainerColor;
      case StudentLeaveStatus.rejected:
        return leaveRejectedContainerColor;
      case StudentLeaveStatus.pending:
        return leavePendingContainerColor;
    }
  }

  Color get _foregroundColor {
    switch (status) {
      case StudentLeaveStatus.approved:
        return leaveApprovedColor;
      case StudentLeaveStatus.rejected:
        return leaveRejectedColor;
      case StudentLeaveStatus.pending:
        return leavePendingColor;
    }
  }

  String get _labelKey {
    switch (status) {
      case StudentLeaveStatus.approved:
        return approvedKey;
      case StudentLeaveStatus.rejected:
        return rejectedKey;
      case StudentLeaveStatus.pending:
        return pendingKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: CustomTextContainer(
        textKey: _labelKey,
        style: TextStyle(
          color: _foregroundColor,
          fontSize: 14.0,
          height: 20 / 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
