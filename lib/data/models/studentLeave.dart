import 'package:eschool_saas_staff/data/models/studyMaterial.dart';
import 'package:eschool_saas_staff/utils/utils.dart';

/// Status of a student leave request as stored by the backend.
/// 0 -> Pending, 1 -> Approved, 2 -> Rejected
enum StudentLeaveStatus { pending, approved, rejected }

StudentLeaveStatus getStudentLeaveStatus(int? status) {
  if (status == 1) {
    return StudentLeaveStatus.approved;
  }
  if (status == 2) {
    return StudentLeaveStatus.rejected;
  }

  return StudentLeaveStatus.pending;
}

/// One student leave request as reviewed by a class teacher or an
/// admin/principal. The same payload backs both the list and the details
/// screen, so everything the details screen shows is parsed here.
class StudentLeave {
  final int? id;
  final int? studentId;
  final String? studentName;
  final String? studentClass;
  final String? studentImage;

  final String? fromDate;
  final String? toDate;
  final String? reason;
  final int? status;
  final String? createdAt;
  final double? days;

  /// Who acted on the request and when. Only present once the request leaves
  /// [pending].
  final String? actionByName;
  final String? actionDate;

  /// Remark left by the reviewer. Rendered as the rejection reason callout
  /// when the request was rejected.
  final String? note;

  /// Number of `leave_detail` rows the backend sent — one per leave day.
  final int leaveDays;

  final List<StudyMaterial> attachments;

  StudentLeave({
    this.id,
    this.studentId,
    this.studentName,
    this.studentClass,
    this.studentImage,
    this.fromDate,
    this.toDate,
    this.reason,
    this.status,
    this.createdAt,
    this.days,
    this.actionByName,
    this.actionDate,
    this.note,
    this.leaveDays = 0,
    this.attachments = const [],
  });

  StudentLeave.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        studentId = _parseStudentId(json),
        studentName = _parseStudentName(json),
        studentClass = _parseStudentClass(json),
        studentImage = _parseStudentImage(json),
        //`org_*` are the ISO dates; `from_date`/`to_date` come back already
        //formatted for display (dd-MM-yyyy) and are only a fallback.
        fromDate =
            json['org_from_date'] as String? ?? json['from_date'] as String?,
        toDate = json['org_to_date'] as String? ?? json['to_date'] as String?,
        reason = json['reason'] as String?,
        status = int.tryParse((json['status'] ?? 0).toString()),
        createdAt = json['created_at'] as String?,
        days = double.tryParse(
            (json['total_days'] ?? json['days'] ?? '').toString()),
        actionByName = _parseActionByName(json),
        actionDate = json['action_date'] as String? ??
            json['approved_at'] as String? ??
            json['updated_at'] as String?,
        note = json['note'] as String? ?? json['remark'] as String?,
        leaveDays = ((json['leave_detail'] ?? []) as List).length,
        attachments = ((json['file'] ?? json['files'] ?? []) as List)
            .map((file) => StudyMaterial.fromJson(Map.from(file ?? {})))
            .toList();

  /// The student can arrive either nested under `student`/`child` or flattened
  /// onto the leave itself, so both shapes are accepted.
  static Map? _studentJson(Map<String, dynamic> json) {
    final student = json['student'] ?? json['child'] ?? json['user'];
    return student is Map ? student : null;
  }

  static String? _joinName(Map source) {
    final fullName = source['full_name'];
    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    final firstName = (source['first_name'] ?? '').toString().trim();
    final lastName = (source['last_name'] ?? '').toString().trim();
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? null : name;
  }

  /// The student record id, which sits under the user rather than on the leave.
  static int? _parseStudentId(Map<String, dynamic> json) {
    final student = _studentJson(json)?['student'];
    if (student is Map && student['id'] is int) {
      return student['id'] as int;
    }

    return json['student_id'] as int? ?? json['child_id'] as int?;
  }

  static String? _parseStudentName(Map<String, dynamic> json) {
    final student = _studentJson(json);
    if (student != null) {
      final name = _joinName(student);
      if (name != null) {
        return name;
      }
    }
    return _joinName(json);
  }

  /// The class sits under the student record nested in the user
  /// (`user.student.class_section`), but flatter shapes are accepted too.
  static String? _parseStudentClass(Map<String, dynamic> json) {
    final user = _studentJson(json);
    final student = user?['student'];

    final classSection = (student is Map ? student['class_section'] : null) ??
        user?['class_section'] ??
        json['class_section'] ??
        json['class'];

    if (classSection is Map) {
      final fullName = classSection['full_name'] ?? classSection['name'];
      if (fullName is String && fullName.trim().isNotEmpty) {
        return fullName.trim();
      }
    }

    if (classSection is String && classSection.trim().isNotEmpty) {
      return classSection.trim();
    }

    return null;
  }

  static String? _parseStudentImage(Map<String, dynamic> json) {
    final image = _studentJson(json)?['image'] ?? json['image'];
    return image is String && image.trim().isNotEmpty ? image : null;
  }

  static String? _parseActionByName(Map<String, dynamic> json) {
    final user = json['action_by'] ?? json['approved_by'] ?? json['staff'];

    if (user is Map) {
      return _joinName(user);
    }
    if (user is String && user.trim().isNotEmpty) {
      return user.trim();
    }

    return null;
  }

  StudentLeaveStatus get leaveStatus => getStudentLeaveStatus(status);

  bool get isPending => leaveStatus == StudentLeaveStatus.pending;

  bool get isApproved => leaveStatus == StudentLeaveStatus.approved;

  bool get isRejected => leaveStatus == StudentLeaveStatus.rejected;

  /// Days the leave spans. The backend sends one `leave_detail` row per day,
  /// which is the most reliable count; the date range is only used when that
  /// list is absent. Dates arrive as dd-MM-yyyy, so they go through
  /// [Utils.parseDateSafely] rather than [DateTime.parse].
  int get totalDays {
    if (days != null && days! > 0) {
      return days!.round();
    }

    if (leaveDays > 0) {
      return leaveDays;
    }

    final from = Utils.parseDateSafely(fromDate ?? '');
    final to = Utils.parseDateSafely(toDate ?? '');
    if (from == null || to == null) {
      return 0;
    }

    return to.difference(from).inDays + 1;
  }

  /// Backs the search field on the list screen.
  bool matchesSearchQuery(String query) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return true;
    }

    return (studentName ?? '').toLowerCase().contains(trimmedQuery) ||
        (studentClass ?? '').toLowerCase().contains(trimmedQuery) ||
        (reason ?? '').toLowerCase().contains(trimmedQuery);
  }
}
