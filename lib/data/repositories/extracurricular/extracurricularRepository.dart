import 'package:eschool/data/models/extracurricular/extracurricular.dart';
import 'package:eschool/data/models/extracurricular/joinExtracurricularResponse.dart';
import 'package:eschool/data/models/extracurricular/studentExtracurricular.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class ExtracurricularRepository {
  // Fetch all available extracurricular activities
  Future<Map<String, dynamic>> fetchExtracurriculars({
    int? offset,
    int? limit,
    String? sort,
    String? order,
    String? search,
  }) async {
    try {
      Map<String, dynamic> queryParameters = {};

      if (offset != null) queryParameters['offset'] = offset;
      if (limit != null) queryParameters['limit'] = limit;
      if (sort != null) queryParameters['sort'] = sort;
      if (order != null) queryParameters['order'] = order;
      if (search != null && search.isNotEmpty)
        queryParameters['search'] = search;

      final result = await Api.get(
        url: Api.getExtracurriculars,
        useAuthToken: true,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );


      // API menggunakan 'rows' bukan 'data'
      final extracurriculars = ((result['rows'] ?? []) as List)
          .map((e) => Extracurricular.fromJson(Map.from(e)))
          .toList();

      return {
        'extracurriculars': extracurriculars,
        'total': result['total'] ?? 0,
        'current_page': result['current_page'] ?? 1,
        'last_page': result['last_page'] ?? 1,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> joinExtracurricular({
    required int extracurricularId,
    required int studentId,
    required String nisn,
  }) async {
    try {
      final result = await Api.post(
        url: Api.joinExtracurricular,
        useAuthToken: true,
        body: {
          'estrakulikuler_id': extracurricularId,
          'student_id': studentId, // Berisi students.id (1310 untuk Yusuf)
          'nisn': nisn,
        },
      );

      if (kDebugMode) {
        print('DEBUG: API Result - $result');
      }

      JoinExtracurricularResponse? responseData;
      if (result['data'] != null) {
        try {
          responseData = JoinExtracurricularResponse.fromJson(result['data']);
          if (kDebugMode) {
            print('DEBUG: Response data parsed successfully - $responseData');
          }
        } catch (parseError) {
          if (kDebugMode) {
            print('DEBUG: Error parsing response data - $parseError');
            print('DEBUG: Raw data - ${result['data']}');
          }
          // Continue without responseData if parsing fails
        }
      }

      final response = {
        'success': result['success'] ?? false,
        'message': result['message'] ??
            'Pendaftaran ekstrakurikuler berhasil dikirim, menunggu persetujuan.',
        'data': responseData,
      };

      if (kDebugMode) {
        print('DEBUG: Final response - $response');
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Exception caught in joinExtracurricular - $e');
      }
      if (e is ApiException) {
        if (e.errorMessage.contains('302') ||
            e.errorMessage.toLowerCase().contains('redirected')) {
          return {
            'success': true,
            'message':
                'Pendaftaran ekstrakurikuler berhasil dikirim, menunggu persetujuan.',
            'data': null,
          };
        }
      }
      throw ApiException(e.toString());
    }
  }

  // Fetch my extracurricular activities (student's joined extracurriculars)
  Future<Map<String, dynamic>> fetchMyExtracurriculars({
    String? search,
  }) async {
    try {
      Map<String, dynamic>? queryParameters;

      if (search != null && search.isNotEmpty) {
        queryParameters = {'search': search};
      }

      final result = await Api.get(
        url: Api.getMyExtracurriculars,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      // Parse student extracurriculars from response
      final dataList = result['data'] ?? [];
      final studentExtracurriculars = (dataList as List)
          .map((e) => StudentExtracurricular.fromJson(Map.from(e)))
          .toList();

      return {
        'extracurriculars': studentExtracurriculars,
        'total': studentExtracurriculars.length,
        'current_page': 1,
        'last_page': 1,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // Fetch ALL student extracurricular statuses (including pending, approved, rejected)
  // This is used for checking button status in "All Extracurriculars" tab
  Future<Map<String, dynamic>> fetchAllMyExtracurricularStatuses() async {
    try {
      // Add parameter to get all statuses, not just approved ones
      final result = await Api.get(
        url: Api.getMyExtracurriculars,
        useAuthToken: true,
        queryParameters: {'include_all_status': true}, // Request all statuses
      );

      // Parse student extracurriculars from response
      final dataList = result['data'] ?? [];
      final studentExtracurriculars = (dataList as List)
          .map((e) => StudentExtracurricular.fromJson(Map.from(e)))
          .toList();

      return {
        'extracurriculars': studentExtracurriculars,
        'total': studentExtracurriculars.length,
        'current_page': 1,
        'last_page': 1,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
