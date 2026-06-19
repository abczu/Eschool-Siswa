import 'package:dio/dio.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/system/api.dart'; // For ApiException
import 'package:flutter/foundation.dart';
import 'dart:io';

/// API utility specifically for JSON requests
/// This is a separate utility from api.dart to avoid modifying existing code
/// Use this for APIs that require Content-Type: application/json
///
/// Note: ErrorMessageMapper is now in errorMessageKeysAndCodes.dart
class ApiJson {
  // Private constructor to prevent instantiation
  ApiJson._();

  /// Extracts a user-readable error message from a Dio response.
  /// Priority: response JSON 'message' field → status code fallback.
  static String _extractErrorMessage(Response? response, {String? fallbackCode}) {
    try {
      final data = response?.data;
      if (data is Map) {
        if (data.containsKey('message') && data['message'] != null) {
          return data['message'].toString();
        }
        if (data.containsKey('code') && data['code'] != null) {
          return data['code'].toString();
        }
      }
    } catch (_) {}

    final statusCode = response?.statusCode;
    if (statusCode == 401) return ErrorMessageKeysAndCode.unauthenticatedErrorCode;
    if (statusCode == 429) return ErrorMessageKeysAndCode.tooManyAttemps;
    if (statusCode == 500 || statusCode == 503) return ErrorMessageKeysAndCode.internetServerErrorCode;
    if (statusCode == 404) return ErrorMessageKeysAndCode.fileNotFoundErrorCode;

    return fallbackCode ?? ErrorMessageKeysAndCode.defaultErrorMessageCode;
  }

  // Singleton Dio instance with timeout configuration
  // Bug-safety: Reuse instance for better performance
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 15), // Connection timeout
      receiveTimeout: Duration(seconds: 15), // Response timeout
      sendTimeout: Duration(seconds: 15), // Send timeout
    ),
  );

  /// Get headers with Authorization and school_code
  /// Same as Api.headers() but explicitly includes Content-Type: application/json
  static Map<String, dynamic> headers() {
    final String jwtToken = AuthRepository().getJwtToken();
    final schoolCode = AuthRepository().schoolCode;

    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════');
      print('🔍 [DEBUG] ApiJson Headers Validation');
      print('═══════════════════════════════════════════════════════');

      // Token validation
      print('🔑 FULL TOKEN: $jwtToken');
      print('📏 TOKEN LENGTH: ${jwtToken.length}');
      print('✅ TOKEN EXISTS: ${jwtToken.isNotEmpty}');
      print(
          '✅ TOKEN FORMAT: ${jwtToken.contains('|') ? 'Valid (has pipe)' : 'Invalid (no pipe)'}');

      // School code validation
      print('🏫 SCHOOL CODE: $schoolCode');
      print('📏 SCHOOL CODE LENGTH: ${schoolCode.length}');
      print('✅ SCHOOL CODE EXISTS: ${schoolCode.isNotEmpty}');

      // Header preview
      print('───────────────────────────────────────────────────────');
      print('📤 HEADERS BEING SENT:');
      print('   Authorization: Bearer $jwtToken');
      print('   school-code: $schoolCode');
      print('   Content-Type: application/json');
      print('   Accept: application/json');
      print('═══════════════════════════════════════════════════════');
    }

    return {
      "Authorization": "Bearer $jwtToken",
      "school-code":
          schoolCode, // Use dash to avoid Nginx stripping underscore headers
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  /// POST request with JSON body (not FormData)
  /// Use this for payment confirmation and other APIs requiring JSON
  static Future<Map<String, dynamic>> post({
    required Map<String, dynamic> body,
    required String url,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      // Performance: Use singleton Dio instance
      if (kDebugMode) {
        print('📤 ApiJson POST: $url');
        print('Body: $body');
        print('Headers: ${headers()}');
      }

      final response = await _dio.post(
        url,
        data: body, // Send as JSON, not FormData
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(headers: headers()),
      );

      if (kDebugMode) {
        print('📥 Response Status: ${response.statusCode}');
        print('Response Data: ${response.data}');
      }

      // Check if response has error field
      if (response.data is Map && response.data['error'] == true) {
        throw ApiException(response.data['message'] ??
            response.data['code']?.toString() ??
            'Unknown error');
      }

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ ApiJson Error:');
        print('URL: $url');
        print('Status Code: ${e.response?.statusCode}');
        print('Response: ${e.response?.data}');
      }

      if (e.error is SocketException) {
        throw ApiException(ErrorMessageKeysAndCode.noInternetCode);
      }
      throw ApiException(_extractErrorMessage(e.response));
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  /// GET request with proper headers
  static Future<Map<String, dynamic>> get({
    required String url,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      // Performance: Use singleton Dio instance
      if (kDebugMode) {
        print('📤 ApiJson GET: $url');
        print('Headers: ${headers()}');
      }

      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(headers: headers()),
      );

      if (kDebugMode) {
        print('📥 Response Status: ${response.statusCode}');
        print('Response Data: ${response.data}');
      }

      if (response.data is Map && response.data['error'] == true) {
        throw ApiException(response.data['message'] ??
            response.data['code']?.toString() ??
            'Unknown error');
      }

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ ApiJson Error:');
        print('URL: $url');
        print('Status Code: ${e.response?.statusCode}');
        print('Response: ${e.response?.data}');
      }

      if (e.error is SocketException) {
        throw ApiException(ErrorMessageKeysAndCode.noInternetCode);
      }
      throw ApiException(_extractErrorMessage(e.response));
    } on ApiException {
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }
}
