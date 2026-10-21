import 'dart:convert';

import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceConfig.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceHistory.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceToday.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrPunchLog.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrPunchResult.dart';
import 'package:eschool_saas_staff/utils/api.dart';
import 'package:eschool_saas_staff/utils/labelKeys.dart';
import 'package:eschool_saas_staff/utils/unauthenticatedAccessManager.dart';
import 'package:intl/intl.dart';

/// A QR attendance request the server refused on a business rule.
///
/// [message] is already translated by the server and is what gets displayed;
/// [errorCode] is what the screens branch on. Validation failures (`code: 102`)
/// and transport errors carry no code and surface as a plain message.
class QrAttendanceException implements Exception {
  final String message;
  final QrAttendanceErrorCode? errorCode;

  const QrAttendanceException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

/// Data source of the QR staff attendance flow.
///
/// The endpoints answer with HTTP 200 even when they refuse, so the `error`
/// flag of the envelope decides, never the status code. That is why the raw
/// helpers of [Api] are used here: they keep the `data` object — and with it
/// `error_code` — instead of collapsing a refusal into a bare message.
class QrAttendanceRepository {
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  /// Feature state, school location and today's status.
  Future<QrAttendanceConfig> getConfig() async {
    final envelope = await _get(url: Api.getQrAttendanceConfig);
    return QrAttendanceConfig.fromJson(
      json: envelope.data,
      apiMessage: envelope.message,
    );
  }

  /// Today's sessions and next action. Cheaper than re-reading the config
  /// after a punch or on pull to refresh.
  Future<QrAttendanceToday> getToday() async {
    final envelope = await _get(url: Api.getQrAttendanceToday);
    return QrAttendanceToday.fromJson(envelope.data);
  }

  /// Records one punch. The server decides whether it is an IN or an OUT.
  ///
  /// [requestUuid] must stay the same across retries of the *same* scan so a
  /// response lost on a bad connection cannot turn one punch into two. The
  /// server then answers with the original punch and `duplicate: true`.
  Future<QrPunchResult> punch({
    required String qrToken,
    required double latitude,
    required double longitude,
    required String requestUuid,
  }) async {
    final envelope = await _post(
      url: Api.qrAttendancePunch,
      body: {
        "qr_token": qrToken,
        "latitude": latitude.toString(),
        "longitude": longitude.toString(),
        "request_uuid": requestUuid,
      },
    );
    return QrPunchResult.fromJson(
      json: envelope.data,
      apiMessage: envelope.message,
    );
  }

  /// Own finalized attendance history. Defaults to the current month
  /// server-side when no range is given.
  Future<QrAttendanceHistory> getMyAttendance({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final envelope = await _get(
      url: Api.getQrMyAttendance,
      queryParameters: {
        if (fromDate != null) "from_date": _apiDateFormat.format(fromDate),
        if (toDate != null) "to_date": _apiDateFormat.format(toDate),
      },
    );
    return QrAttendanceHistory.fromJson(envelope.data);
  }

  /// Raw scan log of one date. Defaults to today server-side.
  Future<QrPunchLog> getPunches({DateTime? date}) async {
    final envelope = await _get(
      url: Api.getQrAttendancePunches,
      queryParameters: {
        if (date != null) "date": _apiDateFormat.format(date),
      },
    );
    return QrPunchLog.fromJson(envelope.data);
  }

  /// GET with the error flag checked here instead of inside [Api], so the
  /// `data.error_code` of a refusal survives.
  Future<_QrAttendanceEnvelope> _get({
    required String url,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await Api.get(
        url: url,
        useAuthToken: true,
        queryParameters: queryParameters,
        skipErrorCheck: true,
      );
      return _QrAttendanceEnvelope.fromResponse(response);
    } on QrAttendanceException {
      rethrow;
    } on ApiException catch (e) {
      throw QrAttendanceException(e.errorMessage);
    } catch (e) {
      throw QrAttendanceException(e.toString());
    }
  }

  /// POST through [Api.postRaw], which returns the untouched body — the only
  /// way to read `data.error_code` off a refused punch.
  Future<_QrAttendanceEnvelope> _post({
    required String url,
    required Map<String, dynamic> body,
  }) async {
    try {
      final rawResponse = await Api.postRaw(
        url: url,
        body: body,
        useAuthToken: true,
      );

      if (rawResponse.trim().isEmpty) {
        throw const QrAttendanceException(defaultErrorMessageKey);
      }

      final decoded = jsonDecode(rawResponse);
      if (decoded is! Map) {
        throw const QrAttendanceException(defaultErrorMessageKey);
      }

      final envelope = Map<String, dynamic>.from(decoded);

      // `Api.postRaw` only sees the HTTP status, so an expired session
      // reported as a `code: 401` inside a 200 body is handled here, the same
      // way `Api.get` and `Api.post` handle it for every other endpoint.
      if (int.tryParse((envelope['code'] ?? "").toString()) == 401) {
        UnauthenticatedAccessManager().handleUnauthorizedAccess();
        throw const QrAttendanceException(defaultErrorMessageKey);
      }

      return _QrAttendanceEnvelope.fromResponse(envelope);
    } on QrAttendanceException {
      rethrow;
    } on ApiException catch (e) {
      throw QrAttendanceException(e.errorMessage);
    } on FormatException {
      throw const QrAttendanceException(defaultErrorMessageKey);
    } catch (e) {
      throw QrAttendanceException(e.toString());
    }
  }
}

/// The `{ error, message, data, code }` envelope every endpoint answers with.
class _QrAttendanceEnvelope {
  final String message;
  final Map<String, dynamic> data;

  const _QrAttendanceEnvelope({required this.message, required this.data});

  /// Throws a [QrAttendanceException] when the envelope reports a failure.
  /// Note that a *disabled* feature is a success with `enabled: false`, not an
  /// error — it must reach the caller untouched.
  factory _QrAttendanceEnvelope.fromResponse(Map<String, dynamic> response) {
    final message = (response['message'] ?? "").toString();
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : <String, dynamic>{};

    final hasError = response['error']?.toString().toLowerCase() == "true";
    if (hasError) {
      throw QrAttendanceException(
        message.isEmpty ? defaultErrorMessageKey : message,
        errorCode:
            QrAttendanceErrorCode.fromValue(data['error_code']?.toString()),
      );
    }

    return _QrAttendanceEnvelope(message: message, data: data);
  }
}
