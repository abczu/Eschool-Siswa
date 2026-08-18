import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:eschool/app/routes.dart';

class ApiException implements Exception {
  String errorMessage;

  ApiException(this.errorMessage);

  @override
  String toString() {
    return errorMessage;
  }
}

// ignore: avoid_classes_with_only_static_members
class Api {
  static final Dio _dio = _initDio();

  static Dio _initDio() {
    final dio = Dio();
    dio.interceptors.add(AuthInterceptor(dio));
    return dio;
  }

  /// Extracts a user-readable error message from a Dio response.
  /// Priority: response JSON 'message' field → status code fallback.
  static String _extractErrorMessage(Response? response, {String? fallbackCode}) {
    try {
      final data = response?.data;
      if (data is Map) {
        // Backend sekarang kirim {"success": false, "message": "..."}
        if (data.containsKey('message') && data['message'] != null) {
          return data['message'].toString();
        }
      }
    } catch (_) {}

    // Fallback berdasarkan HTTP Status Code sesuai standar baru backend
    final statusCode = response?.statusCode;
    if (statusCode == 400) return "Permintaan tidak valid (Bad Request)";
    if (statusCode == 401) return ErrorMessageKeysAndCode.unauthenticatedErrorCode;
    if (statusCode == 422) return "Data tidak valid atau kurang lengkap";
    if (statusCode == 429) return ErrorMessageKeysAndCode.tooManyAttemps;
    if (statusCode == 500 || statusCode == 503) return ErrorMessageKeysAndCode.internetServerErrorCode;
    if (statusCode == 404) return ErrorMessageKeysAndCode.fileNotFoundErrorCode;

    return fallbackCode ?? ErrorMessageKeysAndCode.defaultErrorMessageCode;
  }

  static Map<String, dynamic> headers() {
    final String jwtToken = AuthRepository().getJwtToken();
    final schoolCode = AuthRepository().schoolCode;

    if (kDebugMode) {
      print(
          "DEBUG headers(): jwtToken='${jwtToken.isNotEmpty ? 'HAS_VALUE(${jwtToken.substring(0, jwtToken.length.clamp(0, 20))}...)' : 'EMPTY'}', schoolCode='$schoolCode'");
    }

    return {
      "Authorization": "Bearer $jwtToken",
      "school-code": schoolCode,
      "X-School-Code": schoolCode,
      "Accept": "application/json",
    };
  }

  ///[General Apis]
  //Apis that will be use in both student and parent app
  //
  static String get logout => "${databaseUrl}logout";
  static String get registerDeviceToken => "${databaseUrl}devices/register";
  static String get settings => "${databaseUrl}settings";
  static String get holidays => "${databaseUrl}holidays";

  static String get changePassword => "${databaseUrl}change-password";
  static String get getSchoolGallery => "${databaseUrl}gallery";
  static String get getSchoolSessionYears => "${databaseUrl}session-years";
  static String get getUsers => "${databaseUrl}users";
  static String get getUserChatHistory => "${databaseUrl}users/chat/history";
  static String get chatMessages => "${databaseUrl}message";
  static String get readMessages => "${databaseUrl}message/read";
  static String get deleteMessages => "${databaseUrl}delete/message";

  //

  //
  ///[Student app apis]
  //
  static String get studentLogin => "${databaseUrl}student/login";
  static String get requestOtp => "${databaseUrl}auth/otp/request";
  static String get verifyOtp => "${databaseUrl}auth/otp/verify";
  static String get refresh => "${databaseUrl}auth/refresh";
  static String get studentProfile => "${databaseUrl}student/get-profile-data";
  static String get studentSubjects => "${databaseUrl}student/subjects";
  //get subjects of given class
  static String get classSubjects => "${databaseUrl}student/class-subjects";
  static String get studentTimeTable => "${databaseUrl}student/timetable";
  static String get studentExamList => "${databaseUrl}student/get-exam-list";
  static String get studentExamStatus =>
      "${databaseUrl}student/get-online-exam-status";

  static String get getSchoolSettingDetails =>
      "${databaseUrl}student/school-settings";

  static String get studentExamDetails =>
      "${databaseUrl}student/get-exam-details";
  static String get selectStudentElectiveSubjects =>
      "${databaseUrl}student/select-subjects";
  static String get getLessonsOfSubject => "${databaseUrl}student/lessons";
  static String get getstudyMaterialsOfTopic =>
      "${databaseUrl}student/lesson-topics";
  static String get getStudentAttendance => "${databaseUrl}student/attendance";
  static String get getAssignments => "${databaseUrl}student/assignments";
  static String get submitAssignment =>
      "${databaseUrl}student/submit-assignment";
  static String get generalAnnouncements =>
      "${databaseUrl}student/announcements";
  static String get guardianDetailsOfStudent =>
      "${databaseUrl}student/guradian-details";
  static String get deleteAssignment =>
      "${databaseUrl}student/delete-assignment-submission";

  static String get studentResults => "${databaseUrl}student/exam-marks";
  static String get requestResetPassword =>
      "${databaseUrl}student/forgot-password";

  static String get studentExamOnlineList =>
      "${databaseUrl}student/get-online-exam-list";
  static String get studentExamOnlineQuestions =>
      "${databaseUrl}student/get-online-exam-questions";
  static String get studentSubmitOnlineExamAnswers =>
      "${databaseUrl}student/submit-online-exam-answers";

  static String get studentOnlineExamResultList =>
      "${databaseUrl}student/get-online-exam-result-list";

  static String get studentOnlineExamResult =>
      "${databaseUrl}student/get-online-exam-result";

  static String get studentOnlineExamReport =>
      "${databaseUrl}student/get-online-exam-report";
  static String get studentAssignmentReport =>
      "${databaseUrl}student/get-assignments-report";

  static String get getStudentSliders => "${databaseUrl}student/sliders";

  // Fitur Tambahan E-School versi 1.3.3 Student - Galang
  static String get getSubjectAttendance =>
      "${databaseUrl}student/subject-attendance";

  static String get getSystemInformation => "${databaseUrl}/api/information";

  //
  ///[Parent app apis]
  //
  static String get subjectsByChildId => "${databaseUrl}parent/subjects";
  static String get parentLogin => "${databaseUrl}parent/login";

  //
  static String get childProfileDetails =>
      "${databaseUrl}parent/get-child-profile-data";
  static String get lessonsOfSubjectParent => "${databaseUrl}parent/lessons";
  static String get getstudyMaterialsOfTopicParent =>
      "${databaseUrl}parent/lesson-topics";
  static String get getAssignmentsParent => "${databaseUrl}parent/assignments";
  static String get getParentChildSchoolSettingDetails =>
      "${databaseUrl}parent/school-settings";
  static String get getStudentAttendanceParent =>
      "${databaseUrl}parent/attendance";
  static String get getStudentTimetableParent =>
      "${databaseUrl}parent/timetable";
  static String get getStudentExamListParent =>
      "${databaseUrl}parent/get-exam-list";
  static String get getStudentResultsParent =>
      "${databaseUrl}parent/exam-marks";
  static String get getStudentExamDetailsParent =>
      "${databaseUrl}parent/get-exam-details";
  static String get updateGuardianPhoto => "${databaseUrl}parent/profile";

  static String get generalAnnouncementsParent =>
      "${databaseUrl}parent/announcements";

  static String get getStudentTeachersParent => "${databaseUrl}parent/teachers";
  static String get forgotPassword => "${databaseUrl}forgot-password";

  static String get getStudentFeesDetailParent => "${databaseUrl}parent/fees";
  static String get addFeesTransaction =>
      "${databaseUrl}parent/add-fees-transaction";
  static String get failPaymentTransaction =>
      "${databaseUrl}parent/fail-payment-transaction";
  static String get storeFeesParent => "${databaseUrl}parent/store-fees";

  static String get getPaidFeesListParent =>
      "${databaseUrl}parent/fees-paid-list";
  static String get downloadFeesPaidReceiptParent =>
      "${databaseUrl}parent/fees-paid-receipt-pdf";

  static String get parentExamOnlineList =>
      "${databaseUrl}parent/get-online-exam-list";
  static String get parentOnlineExamResultList =>
      "${databaseUrl}parent/get-online-exam-result-list";
  static String get parentOnlineExamResult =>
      "${databaseUrl}parent/get-online-exam-result";
  static String get parentOnlineExamReport =>
      "${databaseUrl}parent/get-online-exam-report";
  static String get parentAssignmentReport =>
      "${databaseUrl}parent/get-assignments-report";

  static String get getFeesTransactions =>
      "${databaseUrl}parent/fees-transactions-list";

  static String get getParentSliders => "${databaseUrl}parent/sliders";

  static String get payChildCompulsoryFees =>
      "${databaseUrl}parent/fees/compulsory/pay";

  static String get payChildOptionalFees =>
      "${databaseUrl}parent/fees/optional/pay";
  static String get confirmPayment =>
      "${databaseUrl}parent/payment-confirmation";
  static String get getTransactions => "${databaseUrl}payment-transactions";
  static String get downloadFeeReceipt => "${databaseUrl}parent/fees/receipt";
  static String get downloadStudentResult =>
      "${databaseUrl}student-exan-result-pdf";

  // Payment submission endpoints - Updated to match API documentation
  static String get submitSinglePayment => "${databaseUrl}parent/fees/pay-bill";
  static String get submitBulkPayment =>
      "${databaseUrl}parent/fees/pay-bill-bulk";
  static String get submitInstallmentPayment =>
      "${databaseUrl}parent/fees/pay-installment";
  static String get verifyPaymentStatus =>
      "${databaseUrl}parent/fees/payment-status";

  // Xendit payment gateway endpoints (DEMO - will be implemented in backend)
  static String get createXenditInvoice =>
      "${databaseUrl}parent/fees/xendit/create";
  static String get getXenditStatus =>
      "${databaseUrl}parent/fees/xendit/status";

  // Fitur tambahan Eschool - Galang

  static String get getSubjectAttendanceParent =>
      "${databaseUrl}parent/subject-attendance";

  static String get parentApplyLeaves => "${databaseUrl}parent/apply-leaves";

  static String get parentGetLeaves => "${databaseUrl}parent/child-leaves";

  // Contact/Support endpoints
  static String get submitContact => "${databaseUrl}contact/submit";
  static String get getContacts => "${databaseUrl}contacts";
  static String get getContactDetails => "${databaseUrl}contacts";
  static String get getContactStats => "${databaseUrl}contacts/stats";

  // Extracurricular endpoints
  static String get getExtracurriculars =>
      "${databaseUrl}student/extracurricular/show";
  static String get getMyExtracurriculars => "${databaseUrl}student/my-eskul";
  static String get joinExtracurricular => "${databaseUrl}student/join-eskul";

  // static Future<Map<String, dynamic>> post({
  //   required Map<String, dynamic> body,
  //   required String url,
  //   required bool useAuthToken,
  //   Map<String, dynamic>? queryParameters,
  //   CancelToken? cancelToken,
  //   Function(int, int)? onSendProgress,
  //   Function(int, int)? onReceiveProgress,
  // }) async {
  //   try {
  //     final Dio dio = Dio();
  //     final FormData formData =
  //         FormData.fromMap(body, ListFormat.multiCompatible);
  //     if (kDebugMode) {
  //       print("API Called POST: $url with $body");
  //       print("Body Params: $body");
  //     }
  //     final response = await dio.post(
  //       url,
  //       data: formData,
  //       queryParameters: queryParameters,
  //       cancelToken: cancelToken,
  //       onReceiveProgress: onReceiveProgress,
  //       onSendProgress: onSendProgress,
  //       options: useAuthToken ? Options(headers: headers()) : null,
  //     );

  //     if (kDebugMode) {
  //       print("Response: ${response.data}");
  //     }
  //     if (response.data['error']) {
  //       throw ApiException(response.data['code'].toString());
  //     }
  //     return Map.from(response.data);
  //   } on DioException catch (e) {
  //     if (kDebugMode) {
  //       print(e.response?.data);
  //     }
  //     if (e.response?.statusCode == 503 || e.response?.statusCode == 500) {
  //       throw ApiException(ErrorMessageKeysAndCode.internetServerErrorCode);
  //     }
  //     throw ApiException(
  //       e.error is SocketException
  //           ? ErrorMessageKeysAndCode.noInternetCode
  //           : ErrorMessageKeysAndCode.defaultErrorMessageCode,
  //     );
  //   } on ApiException catch (e) {
  //     throw ApiException(e.errorMessage);
  //   } catch (e) {
  //     throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
  //   }
  // }

  // Update kode Eschool 1.3.3 ke 1.4.1 post - Galang
  static Future<Map<String, dynamic>> post({
    required dynamic
        body, // Ubah tipe dari Map<String, dynamic> menjadi dynamic
    required String url,
    required bool useAuthToken,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Function(int, int)? onSendProgress,
    Function(int, int)? onReceiveProgress,
  }) async {
    try {
      final dio = _dio;
      dynamic dataToSend;

      // Cek apakah body sudah berupa FormData
      if (body is FormData) {
        dataToSend = body;
      } else if (body is Map<String, dynamic>) {
        dataToSend = FormData.fromMap(body, ListFormat.multiCompatible);
      } else {
        throw ApiException("Invalid body type");
      }

      if (kDebugMode) {
        print("API Called POST: $url with $body");
        print("Body Params: $body");
      }

      final response = await dio.post(
        url,
        data: dataToSend,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
        options: useAuthToken ? Options(headers: headers()) : null,
      );

      if (kDebugMode) {
        print("Response: ${response.data}");
      }
      if (response.data['error'] == true) {
        throw ApiException(
          response.data['message']?.toString() ??
              response.data['code']?.toString() ??
              ErrorMessageKeysAndCode.defaultErrorMessageCode,
        );
      }
      return Map.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Url is $url");
        print(e.response?.data);
        print(e.response?.statusCode);
      }
      if (e.error is SocketException) {
        throw ApiException(ErrorMessageKeysAndCode.noInternetCode);
      }
      throw ApiException(_extractErrorMessage(e.response));
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static Future<Map<String, dynamic>> get({
    required String url,
    required bool useAuthToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final dio = _dio;

      if (kDebugMode) {
        print(url);
        print(queryParameters);
      }

      final response = await dio.get(
        url,
        queryParameters: queryParameters,
        options: useAuthToken ? Options(headers: headers()) : null,
      );

      if (response.data is Map &&
          response.data['error'] != null &&
          response.data['error']) {
        if (kDebugMode) {
          print("Url $url");
          print(response.data);
        }
        throw ApiException(
            response.data['message'] ?? response.data['code'].toString());
      }

      if (response.data is Map) {
        return Map.from(response.data);
      }
      return {"data": response.data};
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Url is $url");
        print(e.response?.data);
        print(e.response?.statusCode);
      }
      if (e.error is SocketException) {
        throw ApiException(ErrorMessageKeysAndCode.noInternetCode);
      }
      throw ApiException(_extractErrorMessage(e.response));
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage.toString());
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print(e.toString());
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

// import 'dart:io';  // pastikan ada ini di atas file untuk HttpHeaders

  static Future<void> download({
    required String url,
    required CancelToken cancelToken,
    required String savePath,
    required Function(double)
        updateDownloadedPercentage, // kirim 0..100 atau -1
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          followRedirects: true,
          // biar Authorization & header lain kepakai
          headers: {
            ...headers(),
            // nonaktifkan kompresi supaya Content-Length lebih sering muncul
            HttpHeaders.acceptEncodingHeader: 'identity',
          },
          // boleh baca body saat 4xx (supaya error mapping tetap dapat data)
          receiveDataWhenStatusError: true,
          validateStatus: (s) => (s ?? 0) < 500,
        ),
      );

      await dio.download(
        url,
        savePath,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            // aman: 0..100
            updateDownloadedPercentage((count / total) * 100.0);
          } else {
            // server tidak kirim total -> indeterminate
            updateDownloadedPercentage(-1);
          }
        },
      );
    } on DioException catch (e) {
      if (e.error is SocketException) {
        throw ApiException(ErrorMessageKeysAndCode.noInternetCode);
      }
      // Download: prioritaskan file-not-found untuk 404
      throw ApiException(_extractErrorMessage(
        e.response,
        fallbackCode: e.response?.statusCode == 404
            ? ErrorMessageKeysAndCode.fileNotFoundErrorCode
            : null,
      ));
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage);
    } catch (e) {
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  static String sanitizeFileName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      // ambil nama tanpa ekstensi terakhir
      final name = parts.sublist(0, parts.length - 1).join('.');
      final ext = parts.last.toLowerCase();
      return '$name.$ext'; // pastikan hanya satu ekstensi
    }
    return fileName;
  }
  // static Future<bool> checkAndRequestStoragePermission() async {
  //   if (Platform.isAndroid) {
  //     var status = await Permission.storage.status;
  //     if (!status.isGranted) {
  //       status = await Permission.storage.request();
  //       if (!status.isGranted) {
  //         return false;
  //       }
  //     }
  //   }
  //   return true;
  // }

  static Future<Map<String, dynamic>> delete({
    required String url,
    required bool useAuthToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final dio = _dio;

      if (kDebugMode) {
        print("API Called DELETE: $url");
        print("Query Params: $queryParameters");
      }

      final response = await dio.delete(
        url,
        queryParameters: queryParameters,
        options: useAuthToken ? Options(headers: headers()) : null,
      );

      if (response.data['error'] != null && response.data['error']) {
        if (kDebugMode) {
          print("Url $url");
          print(response.data);
        }
        throw ApiException(
            response.data['message'] ?? response.data['code'].toString());
      }

      return Map.from(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print("Url is $url");
        print(e.response?.data);
        print(e.response?.statusCode);
      }
      if (e.error is SocketException) {
        throw ApiException(ErrorMessageKeysAndCode.noInternetCode);
      }
      throw ApiException(_extractErrorMessage(e.response));
    } on ApiException catch (e) {
      throw ApiException(e.errorMessage.toString());
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      throw ApiException(ErrorMessageKeysAndCode.defaultErrorMessageKey);
    }
  }

  /// Mengambil data dokumen (PDF) dengan prioritas 'pdf_url' (Fase 2 Backend).
  /// Menggunakan [pdf_url] jika tersedia, atau fallback ke [pdf] base64.
  static Future<Uint8List> fetchDocumentBytes(Map<String, dynamic> data) async {
    // Prioritaskan URL karena lebih hemat memori
    if (data['pdf_url'] != null && data['pdf_url'].toString().isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[Api] Downloading document via URL: ${data['pdf_url']}');
      }
      final dio = _dio;
      final response = await dio.get<List<int>>(
        data['pdf_url'].toString(),
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    }

    // Fallback ke Base64 (Legacy)
    if (data['pdf'] != null && data['pdf'].toString().isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[Api] Loading document via Base64 (Legacy)');
      }
      return base64Decode(data['pdf'].toString());
    }

    throw ApiException("Konten dokumen tidak ditemukan dalam respons API.");
  }
}

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  Completer<String>? _refreshTokenCompleter;

  AuthInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      RequestOptions options = err.requestOptions;

      // Jika URL adalah refresh token atau logout, langsung bersihkan secara lokal dan ke login
      if (options.path.contains('/auth/refresh') || options.path.contains('/logout') || options.path.contains('logout')) {
        AuthRepository().setIsLogIn(false);
        AuthRepository().setJwtToken("");
        Get.offAllNamed(Routes.auth);
        return handler.next(err);
      }

      if (_refreshTokenCompleter != null) {
        // Refresh sedang berjalan, tunggu hingga selesai
        try {
          final newToken = await _refreshTokenCompleter!.future;
          options.headers["Authorization"] = "Bearer $newToken";
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }

      // Mulai proses refresh
      _refreshTokenCompleter = Completer<String>();
      try {
        final response = await Dio().post(
          "${databaseUrl}auth/refresh",
          options: Options(headers: {
            "Authorization": "Bearer ${AuthRepository().getJwtToken()}"
          }),
        );
        
        final newToken = response.data['data']['token'];
        await AuthRepository().setJwtToken(newToken);

        _refreshTokenCompleter!.complete(newToken);
        _refreshTokenCompleter = null;

        options.headers["Authorization"] = "Bearer $newToken";
        final retryResponse = await _dio.fetch(options);
        return handler.resolve(retryResponse);
      } catch (e) {
        _refreshTokenCompleter!.completeError(err);
        _refreshTokenCompleter = null;
        AuthRepository().signOutUser();
        Get.offAllNamed(Routes.auth);
      }
    }
    return handler.next(err);
  }
}
