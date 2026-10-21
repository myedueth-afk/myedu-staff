import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceUtils.dart';

/// A completed punch in -> punch out pair.
class QrAttendanceSession {
  final String punchInAt;
  final String punchOutAt;

  const QrAttendanceSession({
    required this.punchInAt,
    required this.punchOutAt,
  });

  QrAttendanceSession.fromJson(Map<String, dynamic> json)
      : punchInAt = (json['in'] ?? "").toString(),
        punchOutAt = (json['out'] ?? "").toString();

  String get formattedPunchInTime => QrAttendanceUtils.formatTime(punchInAt);

  String get formattedPunchOutTime => QrAttendanceUtils.formatTime(punchOutAt);

  /// Minutes between the two punches, or 0 when either end is unparsable.
  int get durationInMinutes {
    final start = QrAttendanceUtils.parseServerDateTime(punchInAt);
    final end = QrAttendanceUtils.parseServerDateTime(punchOutAt);
    if (start == null || end == null) return 0;
    final minutes = end.difference(start).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  String get formattedDuration =>
      QrAttendanceUtils.formatDuration(durationInMinutes);
}

/// The shift the staff member is scheduled on for the attendance date.
class QrAttendanceShift {
  final int? id;
  final String name;
  final String startTime;
  final String endTime;
  final int fullDayMinutes;
  final int halfDayMinutes;

  const QrAttendanceShift({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.fullDayMinutes,
    required this.halfDayMinutes,
  });

  QrAttendanceShift.fromJson(Map<String, dynamic> json)
      : id = int.tryParse((json['id'] ?? "").toString()),
        name = (json['name'] ?? "").toString(),
        startTime = (json['start_time'] ?? "").toString(),
        endTime = (json['end_time'] ?? "").toString(),
        fullDayMinutes =
            int.tryParse((json['full_day_minutes'] ?? "").toString()) ?? 0,
        halfDayMinutes =
            int.tryParse((json['half_day_minutes'] ?? "").toString()) ?? 0;

  /// `7:00 AM - 1:00 PM`
  String get formattedTimeRange {
    final start = QrAttendanceUtils.formatClockTime(startTime);
    final end = QrAttendanceUtils.formatClockTime(endTime);
    if (start.isEmpty || end.isEmpty) return "";
    return "$start - $end";
  }
}

/// Live state of the current attendance date: what the next scan will do, the
/// sessions closed so far and the minutes counted.
class QrAttendanceToday {
  final String date;
  final QrAttendanceShift? shift;
  final bool onDuty;
  final QrPunchType nextAction;
  final int workingMinutes;
  final List<QrAttendanceSession> sessions;

  /// A punch in that has no matching punch out yet. Null when the last punch
  /// closed a session.
  final String? openSession;

  const QrAttendanceToday({
    required this.date,
    required this.shift,
    required this.onDuty,
    required this.nextAction,
    required this.workingMinutes,
    required this.sessions,
    required this.openSession,
  });

  QrAttendanceToday.fromJson(Map<String, dynamic> json)
      : date = (json['date'] ?? "").toString(),
        shift = json['shift'] == null
            ? null
            : QrAttendanceShift.fromJson(Map.from(json['shift'])),
        onDuty = json['on_duty'] == true,
        nextAction = QrPunchType.fromValue(json['next_action']?.toString()),
        workingMinutes =
            QrAttendanceUtils.parseWorkingMinutes(json['working_minutes']),
        sessions = ((json['sessions'] ?? []) as List)
            .map((session) => QrAttendanceSession.fromJson(Map.from(session)))
            .toList(),
        openSession = (json['open_session']?.toString() ?? "").isEmpty
            ? null
            : json['open_session'].toString();

  /// Punching is refused by the server when no shift is assigned, so the scan
  /// button is hidden in that case.
  bool get hasShift => shift != null;

  String get formattedWorkingDuration =>
      QrAttendanceUtils.formatDuration(workingMinutes);

  String get formattedOpenSessionTime =>
      QrAttendanceUtils.formatTime(openSession);

  bool get hasAnyActivity => sessions.isNotEmpty || openSession != null;
}
