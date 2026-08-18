import 'package:eschool/utils/system/labelKeys.dart';

// ignore: avoid_classes_with_only_static_members
class ErrorMessageKeysAndCode {
  static const String defaultErrorMessageKey = "defaultErrorMessage";
  static const String noInternetKey = "noInternet";
  static const String internetServerErrorKey = "internetServerError";
  static const String invalidLogInCredentialsKey = "invalidLogInCredentials";
  static const String unauthenticatedAccessKey = "unauthenticatedAccess";

  static const String assignmentAlreadySubmittedKey =
      "assignmentAlreadySubmitted";

  static String invalidUserDetailsKey = "invalidUserDetails";

  static String invalidPasswordKey = "invalidPassword";

  static String canNotSendResetPasswordRequestKey =
      "canNotSendResetPasswordRequest";

  static String examOnlineAttendedKey = "examOnlineAttended";

  static String examOnlineNotStartedYetKey = "examOnlineNotStartedYet";

  static String noOnlineExamReportFoundKey = "noOnlineExamReportFound";
  static String inactiveChildKey = "inactiveChild";
  static String inactiveAccountKey = "inactiveAccount";
  static String tooManyAttempsKey = "tooManyAttemps";
  static String failedDeleteAssigmentKey = "failedDeleteAssigment";
  static String notAllowedInDemoVersionKey =
      "This is not allowed in the Demo Version.";

  //These are ui side error codes
  static const String internetServerErrorCode = "500";
  static const String fileNotFoundErrorCode = "404";
  static const String tooManyAttemps = "429";
  static const String permissionNotGivenCode = "300";
  static const String noInternetCode = "301";
  static const String defaultErrorMessageCode = "302";
  static const String noOnlineExamReportFoundCode = "303";
  static const String unauthenticatedErrorCode = "401";
  static const String notAllowedInDemoVersionCode = "112";
  static const String inactiveChildCode = "115";
  static const String inactiveAccountCode = "116";
  static const String failedDeleteAssigment = "103";

  //Visit here to watch error message keys and codes
  static String getErrorMessageKeyFromCode(String errorCode,
      {String source = ""}) {
    //
    if (errorCode == "101") {
      return invalidLogInCredentialsKey;
    }
    if (errorCode == "104") {
      return assignmentAlreadySubmittedKey;
    }

    if (errorCode == "107") {
      return invalidUserDetailsKey;
    }

    if (errorCode == "108") {
      return canNotSendResetPasswordRequestKey;
    }

    if (errorCode == "109") {
      return invalidPasswordKey;
    }

    if (errorCode == "105") {
      return examOnlineAttendedKey;
    }
    if (errorCode == "106") {
      return examOnlineNotStartedYetKey;
    }
    if (errorCode == tooManyAttemps) {
      return tooManyAttempsKey;
    }
    if (errorCode == "103") {
      print(source);
      if (source == "tugas") {
        return failedDeleteAssigmentKey;
      } else if (source == "ujian") {
        return pleaseAnswerAllQuestionsKey;
      }
    }
    if (errorCode == notAllowedInDemoVersionCode) {
      return notAllowedInDemoVersionKey;
    }
    if (errorCode == noOnlineExamReportFoundCode) {
      return noOnlineExamReportFoundKey;
    }
    if (errorCode == permissionNotGivenCode) {
      return permissionsNotGivenKey;
    }
    if (errorCode == noInternetCode) {
      return noInternetKey;
    }
    if (errorCode == internetServerErrorCode) {
      return internetServerErrorKey;
    }
    if (errorCode == fileNotFoundErrorCode) {
      return fileDownloadingFailedKey;
    }
    if (errorCode == defaultErrorMessageCode) {
      return defaultErrorMessageKey;
    }
    if (errorCode == inactiveChildCode) {
      return inactiveChildKey;
    }
    if (errorCode == inactiveAccountCode) {
      return inactiveAccountKey;
    }

    if (errorCode == unauthenticatedErrorCode) {
      return unauthenticatedAccessKey;
    } else {
      return defaultErrorMessageKey;
    }
  }
}

/// Utility class to convert technical errors to user-friendly Indonesian messages
///
/// This mapper provides improved UX by translating technical error messages
/// (exceptions, HTTP codes, network errors) into clear, actionable messages
/// that users can understand and act upon.
class ErrorMessageMapper {
  /// Converts technical error messages to user-friendly Indonesian messages
  ///
  /// Examples:
  /// - SocketException → "Koneksi internet bermasalah..."
  /// - 401 Unauthenticated → "Sesi Anda habis. Silakan login kembali."
  /// - Timeout → "Server tidak merespons..."
  static String getUserFriendlyMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    // Penugasan / Pengumpulan ulang
    if (errorStr.contains('already submitted') ||
        errorStr.contains('already submitted assignment') ||
        errorStr.contains('resubmission') ||
        errorStr.contains('re-submission') ||
        errorStr.contains('cannot submit') ||
        errorStr.contains('resubmit') ||
        errorStr.contains('limit reached')) {
      return 'Tugas sudah dikumpulkan dan tidak dapat dikirim ulang (batas pengumpulan ulang habis).';
    }

    // Network/Connection errors
    if (errorStr.contains('connection') ||
        errorStr.contains('network') ||
        errorStr.contains('socket')) {
      return 'Koneksi internet bermasalah. Periksa koneksi Anda dan coba lagi.';
    }

    // Timeout errors
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Server tidak merespons. Silakan coba beberapa saat lagi.';
    }

    // Authentication errors (401)
    if (errorStr.contains('unauthenticated') || errorStr.contains('401')) {
      return 'Sesi Anda habis. Silakan login kembali.';
    }

    // Forbidden errors (403)
    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return 'Anda tidak memiliki akses untuk melakukan aksi ini.';
    }

    // Not found errors (404)
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'Data tidak ditemukan. Hubungi admin sekolah.';
    }

    // Validation errors (422)
    if (errorStr.contains('422') || errorStr.contains('validation')) {
      return 'Data yang Anda kirim tidak valid. Periksa kembali data Anda.';
    }

    // Server errors (500)
    if (errorStr.contains('500') ||
        errorStr.contains('server error') ||
        errorStr.contains('internal server')) {
      return 'Server sedang bermasalah. Coba lagi nanti.';
    }

    // Service unavailable (503)
    if (errorStr.contains('503') || errorStr.contains('service unavailable')) {
      return 'Layanan sedang maintenance. Coba lagi nanti.';
    }

    // Default fallback
    return 'Terjadi kesalahan. Silakan coba lagi atau hubungi admin.';
  }
}
