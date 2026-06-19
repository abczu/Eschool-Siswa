import 'dart:convert';
import 'package:eschool/data/models/exam/resultOnline.dart';
import 'package:eschool/data/models/exam/resultOnlineDetails.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class ResultRepository {
  Future<Map<String, dynamic>> getResultOnline({
    int? page,
    required int classSubjectId,
    required bool useParentApi,
    required int childId,
  }) async {
    try {
      final result = await Api.get(
        url: useParentApi
            ? Api.parentOnlineExamResultList
            : Api.studentOnlineExamResultList,
        useAuthToken: true,
        queryParameters: {
          if (classSubjectId != 0) 'class_subject_id': classSubjectId,
          if (page != 0) 'page': page ?? 1,
          if (useParentApi) 'child_id': childId,
        },
      );

      final resultRawList = result['data']['data'] as List;
      final resultList = resultRawList
          .map((e) => ResultOnline.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // print("data 1" + resultList.first.toString());
      // // Ambil status_ujian dari API untuk setiap online_exam_id
      // final updatedResultList =
      //     await Future.wait(resultList.map((result) async {
      //   final id = result.examId;
      //   try {
      //     final statusResponse = await Api.get(
      //       url: Api.studentExamStatus, // endpoint status exam
      //       useAuthToken: true,
      //       queryParameters: {
      //         if (id != 0) 'online_exam_id': id,
      //       },
      //     );

      //     final status = statusResponse['data']['status'] ?? 0;
      //     result.status_ujian = status;
      //   } catch (e) {
      //     // print('Gagal ambil status untuk exam ID $id: $e');
      //     result.status_ujian = 0; // fallback jika gagal
      //   } finally {
      //     return result;
      //   }
      // }));

      return {
        "results": resultList,
        "totalPage": result['data']['last_page'] as int,
        "currentPage": result['data']['current_page'] as int,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ResultOnlineDetails> getOnlineResultDetails({
    required int examId,
    required bool useParentApi,
    required int childId,
  }) async {
    try {
      final result = await Api.get(
        url: useParentApi
            ? Api.parentOnlineExamResult
            : Api.studentOnlineExamResult,
        useAuthToken: true,
        queryParameters: {
          if (examId != 0) 'online_exam_id': examId,
          if (useParentApi) 'child_id': childId,
        },
      );
      //debugging
      print("data details");
      print(result['data']);
      return ResultOnlineDetails.fromJson(result['data']);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<String> downloadResult(
      {required int examId, required int studentId}) async {
    try {
      final result = await Api.get(
          url: Api.downloadStudentResult,
          useAuthToken: true,
          queryParameters: {"exam_id": examId, "student_id": studentId});

      final bytes = await Api.fetchDocumentBytes(result['data']);
      return base64Encode(bytes); // Tetap kembalikan String biar tidak break UI, tapi proses downloadnya sudah benar.
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      throw ApiException(e.toString());
    }
  }
}
