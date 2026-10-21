import 'package:eschool_saas_staff/data/models/studentLeave.dart';
import 'package:eschool_saas_staff/data/repositories/studentLeaveRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class StudentLeavesState {}

class StudentLeavesInitial extends StudentLeavesState {}

class StudentLeavesFetchInProgress extends StudentLeavesState {}

class StudentLeavesFetchSuccess extends StudentLeavesState {
  final List<StudentLeave> leaves;

  StudentLeavesFetchSuccess({required this.leaves});
}

class StudentLeavesFetchFailure extends StudentLeavesState {
  final String errorMessage;

  StudentLeavesFetchFailure(this.errorMessage);
}

class StudentLeavesCubit extends Cubit<StudentLeavesState> {
  final StudentLeaveRepository _studentLeaveRepository =
      StudentLeaveRepository();

  StudentLeavesCubit() : super(StudentLeavesInitial());

  void getStudentLeaves({int? classSectionId}) async {
    try {
      emit(StudentLeavesFetchInProgress());

      final leaves = await _studentLeaveRepository.getStudentLeaves(
        classSectionId: classSectionId,
      );

      emit(StudentLeavesFetchSuccess(leaves: leaves));
    } catch (e) {
      emit(StudentLeavesFetchFailure(e.toString()));
    }
  }

  List<StudentLeave> leaves() {
    if (state is StudentLeavesFetchSuccess) {
      return (state as StudentLeavesFetchSuccess).leaves;
    }
    return [];
  }
}
