import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceToday.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceUtils.dart';

/// Answer of `GET /staff/qr-attendance/config`.
///
/// A disabled feature is **not** an error: the response still succeeds, carries
/// `enabled: false` and nothing else, and the already translated `message`
/// explains why. Everything else is only present when [enabled] is true.
class QrAttendanceConfig {
  final bool enabled;

  /// Message that came with the response. Only worth showing when the feature
  /// is disabled — the server has already translated it.
  final String message;

  final double? latitude;
  final double? longitude;

  /// Allowed distance in metres. A device exactly on the boundary is accepted.
  final int? radius;

  /// Minimum gap between two punches, enforced server-side.
  final int cooldownSeconds;

  final String schoolStartTime;
  final String schoolEndTime;

  /// `SHIFT_BASED` / `DAY_BASED`. Informational — the server does the maths.
  final String calculationMode;

  final QrAttendanceToday? today;

  const QrAttendanceConfig({
    required this.enabled,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.cooldownSeconds,
    required this.schoolStartTime,
    required this.schoolEndTime,
    required this.calculationMode,
    required this.today,
  });

  QrAttendanceConfig.fromJson({
    required Map<String, dynamic> json,
    required String apiMessage,
  })  : enabled = json['enabled'] == true,
        message = apiMessage,
        latitude = double.tryParse((json['latitude'] ?? "").toString()),
        longitude = double.tryParse((json['longitude'] ?? "").toString()),
        radius = int.tryParse((json['radius'] ?? "").toString()),
        cooldownSeconds =
            int.tryParse((json['cooldown_seconds'] ?? "").toString()) ??
                defaultCooldownSeconds,
        schoolStartTime = (json['school_start_time'] ?? "").toString(),
        schoolEndTime = (json['school_end_time'] ?? "").toString(),
        calculationMode = (json['calculation_mode'] ?? "").toString(),
        today = json['today'] == null
            ? null
            : QrAttendanceToday.fromJson(Map.from(json['today']));

  /// Used when the school has no cooldown configured.
  static const int defaultCooldownSeconds = 30;

  /// The scan button only makes sense once the feature is on, the school point
  /// is configured and a shift is assigned for the day.
  bool get canScan =>
      enabled && hasSchoolLocation && (today?.hasShift ?? false);

  bool get hasSchoolLocation =>
      latitude != null && longitude != null && radius != null;

  /// The allowed distance as it is shown to the staff member — `150 m`, or
  /// `2 km` for a school that spreads over a campus. Empty when unconfigured.
  String get formattedRadius =>
      radius == null ? "" : QrAttendanceUtils.formatDistance(radius!);

  /// `7:00 AM - 7:00 PM`, or empty when the school hours are not configured.
  String get formattedSchoolHours {
    final start = QrAttendanceUtils.formatClockTime(schoolStartTime);
    final end = QrAttendanceUtils.formatClockTime(schoolEndTime);
    if (start.isEmpty || end.isEmpty) return "";
    return "$start - $end";
  }

  /// Same config with a refreshed `today` block, so a punch can update the
  /// screen without re-reading the whole configuration.
  QrAttendanceConfig copyWithToday(QrAttendanceToday today) {
    return QrAttendanceConfig(
      enabled: enabled,
      message: message,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      cooldownSeconds: cooldownSeconds,
      schoolStartTime: schoolStartTime,
      schoolEndTime: schoolEndTime,
      calculationMode: calculationMode,
      today: today,
    );
  }
}
