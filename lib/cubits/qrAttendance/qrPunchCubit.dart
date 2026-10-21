import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrPunchResult.dart';
import 'package:eschool_saas_staff/data/repositories/qrAttendanceRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

abstract class QrPunchState {}

class QrPunchInitial extends QrPunchState {}

class QrPunchInProgress extends QrPunchState {}

class QrPunchSuccess extends QrPunchState {
  final QrPunchResult result;

  QrPunchSuccess(this.result);
}

class QrPunchFailure extends QrPunchState {
  final String errorMessage;

  /// Null for a transport failure, which is the only case where re-sending the
  /// very same request is safe and useful.
  final QrAttendanceErrorCode? errorCode;

  QrPunchFailure(this.errorMessage, {this.errorCode});

  bool get isRetryableRequest => errorCode == null;
}

/// Records a punch and keeps the retry contract of the API.
///
/// One UUID v4 is generated per *scan attempt* and reused for every retry of
/// that same attempt. A punch can be stored on the server while the response is
/// lost — bad signal at a school gate is ordinary — and without the shared UUID
/// the retry would turn a single punch in into an accidental in/out pair. When
/// the server recognises the UUID it returns the original punch with
/// `duplicate: true`, which is a success, not an error.
class QrPunchCubit extends Cubit<QrPunchState> {
  final QrAttendanceRepository _qrAttendanceRepository =
      QrAttendanceRepository();
  static const Uuid _uuidGenerator = Uuid();

  /// Payload of the scan in flight, kept so a lost response can be retried
  /// byte for byte.
  _QrPunchRequest? _lastRequest;

  QrPunchCubit() : super(QrPunchInitial());

  /// Sends a punch for a QR code the user just scanned. Always starts a new
  /// idempotency key — this is a deliberate new scan.
  Future<void> punch({
    required String qrToken,
    required double latitude,
    required double longitude,
  }) {
    _lastRequest = _QrPunchRequest(
      qrToken: qrToken,
      latitude: latitude,
      longitude: longitude,
      requestUuid: _uuidGenerator.v4(),
    );
    return _send();
  }

  /// Re-sends the request that just failed, with the same UUID, so at most one
  /// punch is ever recorded. Only meaningful after a transport failure.
  Future<void> retryLastPunch() {
    if (_lastRequest == null) return Future.value();
    return _send();
  }

  Future<void> _send() async {
    final request = _lastRequest;
    if (request == null) return;

    emit(QrPunchInProgress());
    try {
      final result = await _qrAttendanceRepository.punch(
        qrToken: request.qrToken,
        latitude: request.latitude,
        longitude: request.longitude,
        requestUuid: request.requestUuid,
      );
      if (isClosed) return;
      emit(QrPunchSuccess(result));
    } on QrAttendanceException catch (e) {
      if (isClosed) return;
      emit(QrPunchFailure(e.message, errorCode: e.errorCode));
    } catch (e) {
      if (isClosed) return;
      emit(QrPunchFailure(e.toString()));
    }
  }

  void resetState() {
    _lastRequest = null;
    emit(QrPunchInitial());
  }
}

/// One punch attempt, including the idempotency key that makes it safe to
/// re-send.
class _QrPunchRequest {
  final String qrToken;
  final double latitude;
  final double longitude;
  final String requestUuid;

  const _QrPunchRequest({
    required this.qrToken,
    required this.latitude,
    required this.longitude,
    required this.requestUuid,
  });
}
