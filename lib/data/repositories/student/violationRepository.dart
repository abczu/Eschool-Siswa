import 'dart:convert';

import 'package:eschool/data/models/student/violation.dart';
import 'package:eschool/utils/system/api.dart';

class ViolationRepository {
  /// GET /api/student/violations/summary
  /// Header Authorization + school-code sudah otomatis via [Api.headers].
  Future<ViolationSummary> fetchViolationSummary() async {
    try {
      final result = await Api.get(
        url: Api.studentViolationSummary,
        useAuthToken: true,
      );
      return ViolationSummary.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// GET /api/parent/violations?child_id={student_id}
  /// Menampilkan total poin anak, riwayat pelanggaran, nama pemberi poin,
  /// dan status sanksi. Model respons sama dengan ringkasan siswa
  /// ([ViolationSummary]) sehingga UI bisa dipakai ulang.
  Future<ViolationSummary> fetchChildViolation({required int studentId}) async {
    try {
      final result = await Api.get(
        url: Api.parentViolations,
        useAuthToken: true,
        queryParameters: {"child_id": studentId},
      );
      return ViolationSummary.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// GET /api/parent/violations/download-pdf?child_id={student_id}
  /// Mengembalikan isi PDF sebagai base64 string (mendukung `pdf_url`
  /// maupun legacy `pdf` base64 via [Api.fetchDocumentBytes]).
  Future<String> downloadChildViolationPdf({required int studentId}) async {
    try {
      final result = await Api.get(
        url: Api.parentViolationsDownloadPdf,
        useAuthToken: true,
        queryParameters: {"child_id": studentId},
      );
      final data = result['data'];
      if (data != null && data is Map<String, dynamic>) {
        final bytes = await Api.fetchDocumentBytes(data);
        return base64Encode(bytes);
      }
      throw ApiException("Format data respons dari server tidak valid.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
