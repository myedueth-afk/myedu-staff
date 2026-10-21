import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceToday.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceUtils.dart';

/// A single scan as it was recorded.
class QrPunchEntry {
  final QrPunchType type;
  final String punchedAt;
  final int distance;

  const QrPunchEntry({
    required this.type,
    required this.punchedAt,
    required this.distance,
  });

  QrPunchEntry.fromJson(Map<String, dynamic> json)
      : type = QrPunchType.fromValue(json['type']?.toString()),
        punchedAt = (json['punched_at'] ?? "").toString(),
        distance = int.tryParse((json['distance'] ?? "").toString()) ?? 0;

  String get formattedTime => QrAttendanceUtils.formatTime(punchedAt);

  String get formattedDistance => QrAttendanceUtils.formatDistance(distance);
}

/// Answer of `GET /staff/qr-attendance/punches` — the raw scan log of one date.
///
/// Raw punch rows are deleted a month after the attendance date, so an older
/// date legitimately comes back empty. The finalized result in
/// `my-attendance` is the permanent record.
class QrPunchLog {
  final String date;
  final List<QrPunchEntry> punches;
  final List<QrAttendanceSession> sessions;

  /// Punch ins with no matching punch out.
  final List<String> openPunches;

  const QrPunchLog({
    required this.date,
    required this.punches,
    required this.sessions,
    required this.openPunches,
  });

  QrPunchLog.fromJson(Map<String, dynamic> json)
      : date = (json['date'] ?? "").toString(),
        punches = ((json['punches'] ?? []) as List)
            .map((punch) => QrPunchEntry.fromJson(Map.from(punch)))
            .toList(),
        sessions = ((json['sessions'] ?? []) as List)
            .map((session) => QrAttendanceSession.fromJson(Map.from(session)))
            .toList(),
        openPunches = ((json['open'] ?? []) as List)
            .map((punch) => punch.toString())
            .toList();

  bool get isEmpty => punches.isEmpty;

  String get formattedDate => QrAttendanceUtils.formatDate(date);
}
