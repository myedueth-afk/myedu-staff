import 'package:eschool_saas_staff/data/models/studentAttendance.dart';
import 'package:eschool_saas_staff/data/models/studentDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/studentAttendenceItemContainer.dart';
import 'package:eschool_saas_staff/utils/constants.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:flutter/material.dart';

class StudentAttendanceContainer extends StatefulWidget {
  final List<StudentAttendance> studentAttendances;
  final bool isForAddAttendance;
  final Function(
      List<({StudentAttendanceStatus status, int studentId})>
          attendanceStatuses)? onStatusChanged;
  const StudentAttendanceContainer(
      {super.key,
      required this.isForAddAttendance,
      required this.studentAttendances,
      this.onStatusChanged});

  @override
  State<StudentAttendanceContainer> createState() =>
      _StudentAttendanceContainerState();
}

class _StudentAttendanceContainerState
    extends State<StudentAttendanceContainer> {
  late List<StudentAttendanceStatus> allAttendanceStatuses =
      widget.studentAttendances.map(_initialStatusOf).toList();

  ///An approved leave arrives as its own attendance type and stays that way
  ///until the teacher marks the student present.
  StudentAttendanceStatus _initialStatusOf(StudentAttendance attendance) {
    if (attendance.isOnLeave()) {
      return StudentAttendanceStatus.onLeave;
    }
    return attendance.isPresent()
        ? StudentAttendanceStatus.present
        : StudentAttendanceStatus.absent;
  }

  @override
  void initState() {
    if (widget.onStatusChanged != null) {
      //passing initially filled values
      _notifyStatusChanged();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant StudentAttendanceContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    //the state object outlives the data it was built from: picking another
    //date or class, and reloading after a submit, all hand this widget a new
    //list while the old marks are still held here. They are rebuilt from the
    //API data so the screen never shows a previous date's marks.
    if (!_holdsSameData(oldWidget.studentAttendances)) {
      allAttendanceStatuses =
          widget.studentAttendances.map(_initialStatusOf).toList();
      if (widget.onStatusChanged != null) {
        _notifyStatusChanged();
      }
    }
  }

  bool _holdsSameData(List<StudentAttendance> previous) {
    if (previous.length != widget.studentAttendances.length) {
      return false;
    }
    for (var index = 0; index < previous.length; index++) {
      final old = previous[index];
      final current = widget.studentAttendances[index];
      if (old.studentDetails?.id != current.studentDetails?.id ||
          old.type != current.type) {
        return false;
      }
    }
    return true;
  }

  void _notifyStatusChanged() {
    widget.onStatusChanged!(
      List.generate(
        widget.studentAttendances.length,
        (index) {
          return (
            status: allAttendanceStatuses[index],
            studentId:
                widget.studentAttendances[index].studentDetails?.student?.userId ??
                    0
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(appContentHorizontalPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 45,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(5.0),
                    topLeft: Radius.circular(5.0)),
                color: Theme.of(context).colorScheme.tertiary),
            padding: EdgeInsets.symmetric(
                horizontal: appContentHorizontalPadding, vertical: 10),
            child: LayoutBuilder(builder: (context, boxConstraints) {
              const titleStyle =
                  TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600);
              return Row(
                children: [
                  SizedBox(
                    width: boxConstraints.maxWidth * (0.2),
                    child: const CustomTextContainer(
                      textKey: rollNoKey,
                      style: titleStyle,
                    ),
                  ),
                  SizedBox(
                    width: boxConstraints.maxWidth * (0.6),
                    child: const CustomTextContainer(
                      textKey: nameKey,
                      style: titleStyle,
                    ),
                  ),
                  SizedBox(
                    width: boxConstraints.maxWidth * (0.2),
                    child: const CustomTextContainer(
                      textKey: statusKey,
                      style: titleStyle,
                    ),
                  ),
                ],
              );
            }),
          ),
          ...List.generate(widget.studentAttendances.length, (index) {
            return StudentAttendanceItemContainer(
              //keyed on the student, so a row keeps its own marks when the
              //list is replaced rather than inheriting the row that sat at
              //this position before
              key: ValueKey(
                  widget.studentAttendances[index].studentDetails?.id ?? index),
              studentDetails: widget.studentAttendances[index].studentDetails ??
                  StudentDetails.fromJson({}),
              showStatusPicker: widget.isForAddAttendance,
              isPresent: widget.studentAttendances[index].isPresent(),
              isOnLeave: widget.studentAttendances[index].isOnLeave(),
              onChangeAttendance: (StudentAttendanceStatus status) {
                allAttendanceStatuses[index] = status;
                if (widget.onStatusChanged != null) {
                  _notifyStatusChanged();
                }
              },
            );
          }),
        ],
      ),
    );
  }
}
