import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceToday.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceUtils.dart';

/// Answer of `POST /staff/qr-attendance/punch` — what the server actually
/// recorded. The app never decides between IN and OUT itself.
class QrPunchResult {
  /// What this scan did, as decided by the server.
  final QrPunchType punchType;

  /// `Y-m-d H:i:s` in the school's timezone.
  final String punchedAt;

  /// Metres from the school point at the moment of the punch.
  final int distance;

  /// What the next scan will do.
  final QrPunchType nextAction;

  final int workingMinutes;
  final List<QrAttendanceSession> sessions;

  /// True when this `request_uuid` had already been recorded — the original
  /// punch is returned and nothing new was created. Still a success.
  final bool duplicate;

  /// Message that came with the response, already translated by the server.
  final String message;

  const QrPunchResult({
    required this.punchType,
    required this.punchedAt,
    required this.distance,
    required this.nextAction,
    required this.workingMinutes,
    required this.sessions,
    required this.duplicate,
    required this.message,
  });

  QrPunchResult.fromJson({
    required Map<String, dynamic> json,
    required String apiMessage,
  })  : punchType = QrPunchType.fromValue(json['punch_type']?.toString()),
        punchedAt = (json['punched_at'] ?? "").toString(),
        distance = int.tryParse((json['distance'] ?? "").toString()) ?? 0,
        nextAction = QrPunchType.fromValue(json['next_action']?.toString()),
        workingMinutes =
            QrAttendanceUtils.parseWorkingMinutes(json['working_minutes']),
        sessions = ((json['sessions'] ?? []) as List)
            .map((session) => QrAttendanceSession.fromJson(Map.from(session)))
            .toList(),
        duplicate = json['duplicate'] == true,
        message = apiMessage;

  String get formattedPunchTime => QrAttendanceUtils.formatTime(punchedAt);

  String get formattedDistance => QrAttendanceUtils.formatDistance(distance);

  String get formattedWorkingDuration =>
      QrAttendanceUtils.formatDuration(workingMinutes);

  /// Duration of the session this punch just closed. Only meaningful for an
  /// OUT punch; null when nothing was closed.
  String? get closedSessionDuration {
    if (punchType.isPunchIn || sessions.isEmpty) return null;
    return sessions.last.formattedDuration;
  }
}
