import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceHistory.dart';
import 'package:eschool_saas_staff/data/repositories/qrAttendanceRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class QrAttendanceHistoryState {}

class QrAttendanceHistoryInitial extends QrAttendanceHistoryState {}

class QrAttendanceHistoryFetchInProgress extends QrAttendanceHistoryState {}

class QrAttendanceHistoryFetchSuccess extends QrAttendanceHistoryState {
  final QrAttendanceHistory history;

  QrAttendanceHistoryFetchSuccess(this.history);
}

class QrAttendanceHistoryFetchFailure extends QrAttendanceHistoryState {
  final String errorMessage;
  final QrAttendanceErrorCode? errorCode;

  QrAttendanceHistoryFetchFailure(this.errorMessage, {this.errorCode});
}

/// The staff member's own finalized attendance, read one month at a time.
class QrAttendanceHistoryCubit extends Cubit<QrAttendanceHistoryState> {
  final QrAttendanceRepository _qrAttendanceRepository =
      QrAttendanceRepository();

  QrAttendanceHistoryCubit() : super(QrAttendanceHistoryInitial());

  /// Reads the full month [month] belongs to. The API expects a range, and a
  /// month is the unit the rest of the app's attendance screens work in.
  Future<void> fetchMonth(DateTime month) async {
    emit(QrAttendanceHistoryFetchInProgress());
    try {
      final history = await _qrAttendanceRepository.getMyAttendance(
        fromDate: DateTime(month.year, month.month, 1),
        // Day zero of the next month is the last day of this one.
        toDate: DateTime(month.year, month.month + 1, 0),
      );
      if (isClosed) return;
      emit(QrAttendanceHistoryFetchSuccess(history));
    } on QrAttendanceException catch (e) {
      if (isClosed) return;
      emit(QrAttendanceHistoryFetchFailure(e.message, errorCode: e.errorCode));
    } catch (e) {
      if (isClosed) return;
      emit(QrAttendanceHistoryFetchFailure(e.toString()));
    }
  }
}
