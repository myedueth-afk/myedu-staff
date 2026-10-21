import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceConfig.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceToday.dart';
import 'package:eschool_saas_staff/data/repositories/qrAttendanceRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class QrAttendanceConfigState {}

class QrAttendanceConfigInitial extends QrAttendanceConfigState {}

class QrAttendanceConfigFetchInProgress extends QrAttendanceConfigState {}

class QrAttendanceConfigFetchSuccess extends QrAttendanceConfigState {
  final QrAttendanceConfig config;

  QrAttendanceConfigFetchSuccess(this.config);
}

class QrAttendanceConfigFetchFailure extends QrAttendanceConfigState {
  final String errorMessage;

  /// Set when the server refused on a business rule. Screens use it to decide
  /// whether offering a retry makes any sense.
  final QrAttendanceErrorCode? errorCode;

  QrAttendanceConfigFetchFailure(this.errorMessage, {this.errorCode});
}

/// Owns the QR attendance configuration and, with it, today's live status.
///
/// Today's block is deliberately kept here rather than in a cubit of its own:
/// the config already carries it, and a second copy would be one more thing to
/// keep in sync after every punch.
class QrAttendanceConfigCubit extends Cubit<QrAttendanceConfigState> {
  final QrAttendanceRepository _qrAttendanceRepository =
      QrAttendanceRepository();

  QrAttendanceConfigCubit() : super(QrAttendanceConfigInitial());

  QrAttendanceConfig? get config => state is QrAttendanceConfigFetchSuccess
      ? (state as QrAttendanceConfigFetchSuccess).config
      : null;

  Future<void> fetchConfig() async {
    emit(QrAttendanceConfigFetchInProgress());
    try {
      emit(QrAttendanceConfigFetchSuccess(
        await _qrAttendanceRepository.getConfig(),
      ));
    } on QrAttendanceException catch (e) {
      emit(QrAttendanceConfigFetchFailure(e.message, errorCode: e.errorCode));
    } catch (e) {
      emit(QrAttendanceConfigFetchFailure(e.toString()));
    }
  }

  /// Re-reads only today's block — after a punch, or on pull to refresh.
  ///
  /// Fails quietly: the configuration on screen stays valid, and the refreshed
  /// values were already returned by the punch itself.
  Future<void> refreshToday() async {
    final currentConfig = config;
    if (currentConfig == null) return;

    try {
      final today = await _qrAttendanceRepository.getToday();
      if (isClosed) return;
      emit(QrAttendanceConfigFetchSuccess(
        currentConfig.copyWithToday(today),
      ));
    } catch (_) {
      // Keep showing what is already on screen.
    }
  }

  /// Applies a locally known today's block, so the screen reflects a punch
  /// immediately without waiting for the network round trip.
  void applyToday(QrAttendanceToday today) {
    final currentConfig = config;
    if (currentConfig == null) return;
    emit(QrAttendanceConfigFetchSuccess(currentConfig.copyWithToday(today)));
  }
}
