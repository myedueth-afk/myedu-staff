import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceEnums.dart';
import 'package:eschool_saas_staff/data/models/qrAttendance/qrAttendanceUtils.dart';

/// Totals of the requested range.
class QrAttendanceSummary {
  final int present;
  final int halfDay;
  final int absent;
  final int holiday;
  final int workingMinutes;

  const QrAttendanceSummary({
    required this.present,
    required this.halfDay,
    required this.absent,
    required this.holiday,
    required this.workingMinutes,
  });

  QrAttendanceSummary.fromJson(Map<String, dynamic> json)
      : present = int.tryParse((json['present'] ?? "").toString()) ?? 0,
        halfDay = int.tryParse((json['half_day'] ?? "").toString()) ?? 0,
        absent = int.tryParse((json['absent'] ?? "").toString()) ?? 0,
        holiday = int.tryParse((json['holiday'] ?? "").toString()) ?? 0,
        workingMinutes =
            QrAttendanceUtils.parseWorkingMinutes(json['working_minutes']);

  String get formattedWorkingDuration =>
      QrAttendanceUtils.formatDuration(workingMinutes);
}

/// One finalized attendance day.
class QrAttendanceHistoryRow {
  final String date;
  final QrAttendanceDayType type;
  final int workingMinutes;
  final int completedSessions;

  /// A punch in that was never closed. Worth highlighting so the staff member
  /// knows to ask for a correction.
  final int incompleteSessions;

  final String shiftName;
  final QrAttendanceSource source;

  const QrAttendanceHistoryRow({
    required this.date,
    required this.type,
    required this.workingMinutes,
    required this.completedSessions,
    required this.incompleteSessions,
    required this.shiftName,
    required this.source,
  });

  QrAttendanceHistoryRow.fromJson(Map<String, dynamic> json)
      : date = (json['date'] ?? "").toString(),
        type = QrAttendanceDayType.fromValue(
            int.tryParse((json['type'] ?? "").toString())),
        workingMinutes =
            QrAttendanceUtils.parseWorkingMinutes(json['working_minutes']),
        completedSessions =
            int.tryParse((json['completed_sessions'] ?? "").toString()) ?? 0,
        incompleteSessions =
            int.tryParse((json['incomplete_sessions'] ?? "").toString()) ?? 0,
        shiftName = (json['shift_name'] ?? "").toString(),
        source = QrAttendanceSource.fromValue(json['source']?.toString());

  bool get hasIncompleteSession => incompleteSessions > 0;

  bool get isManuallyMarked => source == QrAttendanceSource.manual;

  String get formattedDate => QrAttendanceUtils.formatDate(date);

  String get formattedWorkingDuration =>
      QrAttendanceUtils.formatDuration(workingMinutes);

  /// Weekday of the row, used as the secondary line of the date column.
  String get weekDayLabel {
    final parsed = QrAttendanceUtils.parseServerDateTime(date);
    if (parsed == null) return "";
    return QrAttendanceUtils.weekDayLabelOf(parsed);
  }

  /// Day of month, used as the leading badge of the row.
  String get dayOfMonth {
    final parsed = QrAttendanceUtils.parseServerDateTime(date);
    if (parsed == null) return "";
    return parsed.day.toString().padLeft(2, '0');
  }
}

/// Answer of `GET /staff/qr-attendance/my-attendance` — the staff member's own
/// finalized history, kept permanently.
class QrAttendanceHistory {
  final String fromDate;
  final String toDate;
  final QrAttendanceSummary summary;
  final List<QrAttendanceHistoryRow> rows;

  const QrAttendanceHistory({
    required this.fromDate,
    required this.toDate,
    required this.summary,
    required this.rows,
  });

  QrAttendanceHistory.fromJson(Map<String, dynamic> json)
      : fromDate = (json['from_date'] ?? "").toString(),
        toDate = (json['to_date'] ?? "").toString(),
        summary =
            QrAttendanceSummary.fromJson(Map.from(json['summary'] ?? const {})),
        rows = ((json['rows'] ?? []) as List)
            .map((row) => QrAttendanceHistoryRow.fromJson(Map.from(row)))
            .toList();
}
