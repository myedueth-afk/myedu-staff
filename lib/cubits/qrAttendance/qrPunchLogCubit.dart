import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrPunchLog.dart';
import 'package:eschool_saas_staff/data/repositories/qrAttendanceRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class QrPunchLogState {}

class QrPunchLogInitial extends QrPunchLogState {}

class QrPunchLogFetchInProgress extends QrPunchLogState {}

class QrPunchLogFetchSuccess extends QrPunchLogState {
  final QrPunchLog punchLog;

  QrPunchLogFetchSuccess(this.punchLog);
}

class QrPunchLogFetchFailure extends QrPunchLogState {
  final String errorMessage;
  final QrAttendanceErrorCode? errorCode;

  QrPunchLogFetchFailure(this.errorMessage, {this.errorCode});
}

/// Raw scan log of a single date.
///
/// Punch rows are purged a month after the attendance date, so an older date
/// answers with an empty log rather than an error — that is an empty state, not
/// a failure.
class QrPunchLogCubit extends Cubit<QrPunchLogState> {
  final QrAttendanceRepository _qrAttendanceRepository =
      QrAttendanceRepository();

  QrPunchLogCubit() : super(QrPunchLogInitial());

  Future<void> fetchPunches({DateTime? date}) async {
    emit(QrPunchLogFetchInProgress());
    try {
      final punchLog = await _qrAttendanceRepository.getPunches(date: date);
      if (isClosed) return;
      emit(QrPunchLogFetchSuccess(punchLog));
    } on QrAttendanceException catch (e) {
      if (isClosed) return;
      emit(QrPunchLogFetchFailure(e.message, errorCode: e.errorCode));
    } catch (e) {
      if (isClosed) return;
      emit(QrPunchLogFetchFailure(e.toString()));
    }
  }
}
