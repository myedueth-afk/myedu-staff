import 'package:eschool_saas_staff/utils/labelKeys.dart';

/// What a scan did, or will do next. Always decided by the server — the app
/// never derives it from its own state.
enum QrPunchType {
  punchIn("IN"),
  punchOut("OUT");

  final String value;

  const QrPunchType(this.value);

  static QrPunchType fromValue(String? value) {
    return value?.toUpperCase() == punchOut.value ? punchOut : punchIn;
  }

  bool get isPunchIn => this == QrPunchType.punchIn;
}

/// `data.error_code` of a refused request. The message that travels with it is
/// already translated by the server and is what gets displayed; this value only
/// decides how the screen behaves.
enum QrAttendanceErrorCode {
  /// Feature switched off for the school.
  qrDisabled("qr_disabled"),

  /// School hasn't finished the QR setup.
  notConfigured("not_configured"),

  /// Account isn't active teaching / non-teaching staff.
  staffNotEligible("staff_not_eligible"),

  /// No shift assigned to this staff member.
  shiftMissing("shift_missing"),

  /// Token unreadable, or belongs to another school.
  qrInvalid("qr_invalid"),

  /// Past the QR end date.
  qrExpired("qr_expired"),

  /// Code disabled by the administrator.
  qrInactive("qr_inactive"),

  /// Coordinates were missing from the request.
  locationUnavailable("location_unavailable"),

  /// Too far from the school point.
  outsideRadius("outside_radius"),

  /// Scanned after the school end time.
  dayClosed("day_closed"),

  /// Repeat scan inside the cooldown window.
  cooldown("cooldown");

  final String value;

  const QrAttendanceErrorCode(this.value);

  static QrAttendanceErrorCode? fromValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final code in QrAttendanceErrorCode.values) {
      if (code.value == value) return code;
    }
    return null;
  }

  /// Refusals that make scanning pointless until an administrator acts, so the
  /// screen hides the scan button instead of inviting a retry.
  bool get blocksScanning =>
      this == qrDisabled ||
      this == notConfigured ||
      this == staffNotEligible ||
      this == shiftMissing ||
      this == qrExpired ||
      this == qrInactive;
}

/// Finalized attendance of a day. `4` and `5` come from the older manual
/// attendance module — QR finalization only produces `0`–`3`, but a manually
/// corrected day can carry any of them.
enum QrAttendanceDayType {
  absent(0, absentKey),
  present(1, presentKey),
  halfDay(2, halfDayKey),
  holiday(3, holidayKey),
  firstHalfPresent(4, firstHalfPresentKey),
  secondHalfPresent(5, secondHalfPresentKey);

  final int value;
  final String labelKey;

  const QrAttendanceDayType(this.value, this.labelKey);

  static QrAttendanceDayType fromValue(int? value) {
    for (final type in QrAttendanceDayType.values) {
      if (type.value == value) return type;
    }
    return QrAttendanceDayType.absent;
  }
}

/// How a finalized day was produced.
enum QrAttendanceSource {
  qr("QR"),
  manual("MANUAL");

  final String value;

  const QrAttendanceSource(this.value);

  static QrAttendanceSource fromValue(String? value) {
    return value?.toUpperCase() == manual.value ? manual : qr;
  }
}
