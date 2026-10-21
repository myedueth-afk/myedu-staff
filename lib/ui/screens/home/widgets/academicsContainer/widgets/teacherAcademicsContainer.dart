import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/transport/vehicleAssignmentStatusCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/menusWithTitleContainer.dart';
import 'package:eschool_saas_staff/ui/screens/leaves/leavesScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/customMenuTile.dart';
import 'package:eschool_saas_staff/ui/widgets/transportNavigationTile.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/systemModulesAndPermissions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class TeacherAcademicsContainer extends StatefulWidget {
  const TeacherAcademicsContainer({super.key});

  @override
  State<TeacherAcademicsContainer> createState() =>
      _TeacherAcademicsContainerState();
}

class _TeacherAcademicsContainerState extends State<TeacherAcademicsContainer> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _fetchVehicleAssignmentStatus();
    });
  }

  void _fetchVehicleAssignmentStatus() {
    final authCubit = context.read<AuthCubit>();
    final userDetails = authCubit.getUserDetails();
    final userId = userDetails.id ?? 0;

    context.read<VehicleAssignmentStatusCubit>().fetchVehicleAssignmentStatus(
          userId: userId,
        );
  }

  /// The teacher may request leave for themselves.
  bool get _canApplyOwnLeave => context
      .read<StaffAllowedPermissionsAndModulesCubit>()
      .isModuleEnabled(moduleId: staffLeaveManagementModuleId.toString());

  /// The teacher may review the leave requests of the students of their class.
  /// Needs both the school's Student Leave Management module and the student
  /// leave list permission on their role, independently of the staff leave
  /// module covering their own leave.
  bool get _canReviewStudentLeave {
    final staffAllowedPermissionsAndModulesCubit =
        context.read<StaffAllowedPermissionsAndModulesCubit>();
    return staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
          moduleId: studentLeaveManagementModuleId.toString(),
        ) &&
        staffAllowedPermissionsAndModulesCubit.isPermissionGiven(
          permission: viewStudentLeavePermissionKey,
        );
  }

  @override
  Widget build(BuildContext context) {
    final StaffAllowedPermissionsAndModulesCubit
        staffAllowedPermissionsAndModulesCubit =
        context.read<StaffAllowedPermissionsAndModulesCubit>();
    return Column(
      children: [
        MenusWithTitleContainer(
          title: timetableKey,
          menus: [
            if (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
              moduleId: timetableManagementModuleId.toString(),
            ))
              CustomMenuTile(
                iconImageName: "timetable.svg",
                titleKey: myTimetableKey,
                onTap: () {
                  Get.toNamed(Routes.teacherMyTimetableScreen);
                },
              ),
            CustomMenuTile(
              iconImageName: "class_section.svg",
              titleKey: classSectionKey,
              onTap: () {
                Get.toNamed(Routes.teacherClassSectionScreen);
              },
            ),
            CustomMenuTile(
              iconImageName: "online_class.svg",
              titleKey: onlineClassKey,
              onTap: () {
                Get.toNamed(Routes.onlineClassesScreen);
              },
            ),
          ],
        ),
        if (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
          moduleId: attendanceManagementModuleId.toString(),
        ))
          MenusWithTitleContainer(
            title: attendanceKey,
            menus: [
              CustomMenuTile(
                iconImageName: "add_attendance.svg",
                titleKey: addAttendanceKey,
                onTap: () {
                  Get.toNamed(Routes.teacherAddAttendanceScreen);
                },
              ),
              CustomMenuTile(
                iconImageName: "view_attendance.svg",
                titleKey: viewAttendanceKey,
                onTap: () {
                  Get.toNamed(Routes.teacherViewAttendanceScreen);
                },
              ),
              CustomMenuTile(
                iconImageName: "my_attendance.svg",
                titleKey: myAttendanceKey,
                onTap: () {
                  Get.toNamed(Routes.teacherMyAttendanceScreen);
                },
              ),
              // The screen itself asks the API whether QR attendance is switched
              // on for the school and whether this staff member is eligible.
              CustomMenuTile(
                iconImageName: "qr_attendance.svg",
                titleKey: qrAttendanceKey,
                onTap: () {
                  Get.toNamed(Routes.qrAttendanceScreen);
                },
              ),
            ],
          ),
        if (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
          moduleId: lessonManagementModuleId.toString(),
        ))
          MenusWithTitleContainer(
            title: subjectLessonKey,
            menus: [
              CustomMenuTile(
                iconImageName: "manage_lesson.svg",
                titleKey: manageLessonKey,
                onTap: () {
                  Get.toNamed(Routes.teacherManageLessonScreen);
                },
              ),
              CustomMenuTile(
                iconImageName: "manage_topic.svg",
                titleKey: manageTopicKey,
                onTap: () {
                  Get.toNamed(Routes.teacherManageTopicScreen);
                },
              ),
            ],
          ),
        if (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
          moduleId: assignmentManagementModuleId.toString(),
        ))
          MenusWithTitleContainer(
            title: studentAssignmentKey,
            menus: [
              CustomMenuTile(
                iconImageName: "manage_assignment.svg",
                titleKey: manageAssignmentKey,
                onTap: () {
                  Get.toNamed(Routes.teacherManageAssignmentScreen);
                },
              ),
            ],
          ),
        staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
          moduleId: transportationModuleId.toString(),
        )
            ? MenusWithTitleContainer(
                title: transportationKey,
                menus: [const TransportNavigationTile()],
              )
            : const SizedBox(),
        // Messages section - only show if announcement module is enabled
        if (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
          moduleId: announcementManagementModuleId.toString(),
        ))
          MenusWithTitleContainer(
            title: messageKey,
            menus: [
              CustomMenuTile(
                iconImageName: "announcement.svg",
                titleKey: manageAnnouncementKey,
                onTap: () {
                  Get.toNamed(Routes.teacherManageAnnouncementScreen);
                },
              ),
            ],
          ),
        // Student Diary section - always visible without any condition
        MenusWithTitleContainer(
          title: studentDiaryKey,
          menus: [
            CustomMenuTile(
              iconImageName: "note_book.svg",
              titleKey: addStudentDiaryKey,
              onTap: () {
                Get.toNamed(Routes.studentDiarySelectionScreen);
              },
            ),
          ],
        ),

        if (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
          moduleId: examManagementModuleId.toString(),
        ))
          MenusWithTitleContainer(
            title: offlineExamKey,
            menus: [
              CustomMenuTile(
                iconImageName: "exam.svg",
                titleKey: examsKey,
                onTap: () {
                  Get.toNamed(Routes.examsScreen);
                },
              ),
              CustomMenuTile(
                iconImageName: "result.svg",
                titleKey: examResultKey,
                onTap: () {
                  Get.toNamed(Routes.teacherExamResultScreen);
                },
              ),
            ],
          ),
        MenusWithTitleContainer(
          title: myTaskKey,
          menus: [
            CustomMenuTile(
              iconImageName: "manage_task.svg",
              titleKey: manageTasksKey,
              onTap: () {
                Get.toNamed(Routes.myTasksScreen);
              },
            ),
          ],
        ),
        // The teacher's own leave and student leave review are gated
        // independently, so the Leave section appears when either applies.
        if (_canApplyOwnLeave || _canReviewStudentLeave)
          MenusWithTitleContainer(
            title: leaveKey,
            menus: [
              if (_canApplyOwnLeave) ...[
                CustomMenuTile(
                  iconImageName: "apply_leave.svg",
                  titleKey: applyLeaveKey,
                  onTap: () {
                    Get.toNamed(Routes.applyLeaveScreen);
                  },
                ),
                CustomMenuTile(
                  iconImageName: "my_leave.svg",
                  titleKey: myLeaveKey,
                  onTap: () {
                    Get.toNamed(
                      Routes.leavesScreen,
                      arguments: LeavesScreen.buildArguments(
                        showMyLeaves: true,
                      ),
                    );
                  },
                ),
              ],
              if (_canReviewStudentLeave)
                CustomMenuTile(
                  iconImageName: "student_attendance.svg",
                  titleKey: studentLeaveKey,
                  onTap: () {
                    Get.toNamed(Routes.studentLeaveScreen);
                  },
                ),
            ],
          ),
        if (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
          moduleId: attendanceManagementModuleId.toString(),
        ))
          MenusWithTitleContainer(
            title: payrollKey,
            menus: [
              CustomMenuTile(
                iconImageName: "payroll_slip.svg",
                titleKey: myPayrollSlipsKey,
                onTap: () {
                  Get.toNamed(Routes.myPayrollScreen);
                },
              ),
              CustomMenuTile(
                iconImageName: "allowances_and_deductions.svg",
                titleKey: allowancesAndDeductionsKey,
                onTap: () {
                  Get.toNamed(Routes.allowancesAndDeductionsScreen);
                },
              ),
            ],
          ),
      ],
    );
  }
}
