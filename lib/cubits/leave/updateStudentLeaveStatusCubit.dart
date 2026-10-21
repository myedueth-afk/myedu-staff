import 'package:eschool_saas_staff/data/models/studentLeave.dart';
import 'package:eschool_saas_staff/data/repositories/studentLeaveRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class UpdateStudentLeaveStatusState {}

class UpdateStudentLeaveStatusInitial extends UpdateStudentLeaveStatusState {}

class UpdateStudentLeaveStatusInProgress extends UpdateStudentLeaveStatusState {}

class UpdateStudentLeaveStatusSuccess extends UpdateStudentLeaveStatusState {
  final StudentLeaveStatus updatedStatus;

  UpdateStudentLeaveStatusSuccess({required this.updatedStatus});
}

class UpdateStudentLeaveStatusFailure extends UpdateStudentLeaveStatusState {
  final String errorMessage;

  UpdateStudentLeaveStatusFailure(this.errorMessage);
}

/// Approves or rejects a student leave. An admin/principal may act on a request
/// a class teacher already decided — the backend treats the latest decision as
/// final, so this cubit does not restrict which transitions are allowed.
class UpdateStudentLeaveStatusCubit
    extends Cubit<UpdateStudentLeaveStatusState> {
  final StudentLeaveRepository _studentLeaveRepository =
      StudentLeaveRepository();

  UpdateStudentLeaveStatusCubit() : super(UpdateStudentLeaveStatusInitial());

  void updateStudentLeaveStatus({
    required int leaveId,
    required bool approveLeave,
    String? note,
  }) async {
    try {
      emit(UpdateStudentLeaveStatusInProgress());

      //// 1 -> Approved, 2 -> Rejected
      await _studentLeaveRepository.updateStudentLeaveStatus(
        leaveId: leaveId,
        status: approveLeave ? 1 : 2,
        note: note,
      );

      emit(
        UpdateStudentLeaveStatusSuccess(
          updatedStatus: approveLeave
              ? StudentLeaveStatus.approved
              : StudentLeaveStatus.rejected,
        ),
      );
    } catch (e) {
      emit(UpdateStudentLeaveStatusFailure(e.toString()));
    }
  }
}
