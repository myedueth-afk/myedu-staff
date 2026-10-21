import 'package:eschool_saas_staff/data/models/studentLeave.dart';
import 'package:eschool_saas_staff/utils/api.dart';

/// Student leave review, kept separate from [LeaveRepository], which covers the
/// staff member's own leaves.
class StudentLeaveRepository {
  Future<List<StudentLeave>> getStudentLeaves({int? classSectionId}) async {
    try {
      final result = await Api.get(
        url: Api.getStudentLeaves,
        useAuthToken: true,
        queryParameters: classSectionId == null
            ? {}
            : {"class_section_id": classSectionId},
      );

      return _parseLeaves(result['data'])
          .map((leave) => StudentLeave.fromJson(Map.from(leave ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// This endpoint paginates, so `data` is an envelope holding the rows under
  /// its own `data` key. A plain list is still accepted so the parsing does not
  /// break if the endpoint stops paginating.
  List _parseLeaves(dynamic data) {
    if (data is List) {
      return data;
    }
    if (data is Map) {
      return (data['data'] ?? []) as List;
    }
    return [];
  }

  /// [status] follows the backend contract: 1 approves, 2 rejects. [note] is
  /// the reviewer's remark, required in practice only when rejecting.
  Future<void> updateStudentLeaveStatus({
    required int leaveId,
    required int status,
    String? note,
  }) async {
    try {
      await Api.post(
        url: Api.updateStudentLeaveStatus,
        useAuthToken: true,
        body: {
          "leave_id": leaveId,
          "status": status,
          if (note != null && note.trim().isNotEmpty) "note": note.trim(),
        },
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
