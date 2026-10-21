import 'package:eschool_saas_staff/data/models/studentDetails.dart';
import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/ui/widgets/customAttendanceToggleButton.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/material.dart';

class StudentAttendanceItemContainer extends StatefulWidget {
  final bool showStatusPicker;
  final bool isPresent;

  ///The school approved a leave for this student on this date. The row is
  ///highlighted and only present can be marked, for a student who turns up
  ///regardless.
  final bool isOnLeave;
  final StudentDetails studentDetails;
  final Function(StudentAttendanceStatus status)? onChangeAttendance;
  const StudentAttendanceItemContainer({
    super.key,
    required this.studentDetails,
    this.showStatusPicker = false,
    required this.isPresent,
    this.isOnLeave = false,
    this.onChangeAttendance,
  });
//
  @override
  State<StudentAttendanceItemContainer> createState() =>
      _StudentAttendanceItemContainerState();
}

class _StudentAttendanceItemContainerState
    extends State<StudentAttendanceItemContainer> {
  late StudentAttendanceStatus selectedValue = _statusFromApiData();

  StudentAttendanceStatus _statusFromApiData() {
    if (widget.isOnLeave) {
      return StudentAttendanceStatus.onLeave;
    }
    return widget.isPresent
        ? StudentAttendanceStatus.present
        : StudentAttendanceStatus.absent;
  }

  ///The leave styling follows what is picked rather than only what the API
  ///sent, so a student marked present stops reading as on leave right away.
  bool get _readsAsOnLeave =>
      selectedValue == StudentAttendanceStatus.onLeave;

  @override
  void didUpdateWidget(covariant StudentAttendanceItemContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    //another date, another class or a reload after submitting brings fresh
    //marks, and the row has to show those instead of the earlier pick
    if (oldWidget.isPresent != widget.isPresent ||
        oldWidget.isOnLeave != widget.isOnLeave) {
      selectedValue = _statusFromApiData();
    }
  }

  Widget _buildStatusPicker(BuildContext context) {
    return CustomAttendanceToggleButton(
      selectedStatus: selectedValue,
      //a student on an approved leave cannot be marked absent, and can always
      //be put back on leave after being marked present by mistake
      canMarkAbsent: !widget.isOnLeave,
      showOnLeaveOption: widget.isOnLeave,
      onStatusChanged: (status) {
        setState(() {
          selectedValue = status;
        });
        if (widget.onChangeAttendance != null) {
          widget.onChangeAttendance!(selectedValue);
        }
      },
      buttonWidth: 30.0,
      buttonHeight: 30.0,
    );
  }

  Widget _buildOnLeaveLabel({required double fontSize}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: onLeaveAttendanceColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: CustomTextContainer(
        textKey: onLeaveKey,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: onLeaveAttendanceColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Theme.of(context).colorScheme.tertiary);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 65,
      padding: EdgeInsets.symmetric(
          horizontal: appContentHorizontalPadding, vertical: 10),
      decoration: BoxDecoration(
          //the highlight that sets an on leave student apart from the rest
          //of the class, dropped as soon as they are marked present
          color: _readsAsOnLeave
              ? onLeaveAttendanceColor.withValues(alpha: 0.07)
              : null,
          border: Border(left: border, bottom: border, right: border)),
      child: LayoutBuilder(builder: (context, boxConstraints) {
        return Row(
          children: [
            SizedBox(
              width: boxConstraints.maxWidth * (0.175),
              child: CustomTextContainer(
                  textKey:
                      widget.studentDetails.student?.rollNumber?.toString() ??
                          "-"),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextContainer(
                    maxLines: _readsAsOnLeave ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    textKey: (widget.studentDetails.fullName ?? ""),
                    style: const TextStyle(
                        fontSize: 15.0, fontWeight: FontWeight.w600),
                  ),
                  //said once per row: beside the name while marking, and in
                  //the status column when the row is read only
                  if (_readsAsOnLeave && widget.showStatusPicker) ...[
                    const SizedBox(height: 3),
                    _buildOnLeaveLabel(fontSize: 11.0),
                  ],
                ],
              ),
            ),
            if (widget.showStatusPicker) ...[
              _buildStatusPicker(context),
            ] else if (widget.isOnLeave) ...[
              _buildOnLeaveLabel(fontSize: 12.0),
            ] else ...[
              Container(
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: widget.isPresent
                        ? Theme.of(context)
                            .extension<CustomColors>()!
                            .totalStaffOverviewBackgroundColor!
                            .withValues(alpha: 0.1)
                        : Theme.of(context)
                            .extension<CustomColors>()!
                            .totalStudentOverviewBackgroundColor!
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5)),
                child: CustomTextContainer(
                  textKey: widget.isPresent ? presentShortKey : absentShortKey,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: widget.isPresent
                        ? Theme.of(context)
                            .extension<CustomColors>()!
                            .totalStaffOverviewBackgroundColor
                        : Theme.of(context)
                            .extension<CustomColors>()!
                            .totalStudentOverviewBackgroundColor!,
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
