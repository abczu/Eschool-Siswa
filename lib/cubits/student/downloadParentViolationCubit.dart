import 'dart:convert';
import 'dart:io';

import 'package:eschool/data/repositories/student/violationRepository.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

abstract class DownloadParentViolationState {}

class DownloadParentViolationInitial extends DownloadParentViolationState {}

class DownloadParentViolationInProgress
    extends DownloadParentViolationState {}

class DownloadParentViolationSuccess extends DownloadParentViolationState {
  final String downloadedFilePath;

  DownloadParentViolationSuccess({required this.downloadedFilePath});
}

class DownloadParentViolationFailure extends DownloadParentViolationState {
  final String errorMessage;

  DownloadParentViolationFailure(this.errorMessage);
}

/// Cubit untuk unduh PDF laporan pelanggaran anak:
/// GET /api/parent/violations/download-pdf?child_id={student_id}
class DownloadParentViolationCubit
    extends Cubit<DownloadParentViolationState> {
  final ViolationRepository _violationRepository;

  DownloadParentViolationCubit(this._violationRepository)
      : super(DownloadParentViolationInitial());

  Future<void> downloadReport({required int studentId}) async {
    try {
      emit(DownloadParentViolationInProgress());
      debugPrint(
          '📥 [DownloadParentViolation] studentId=$studentId');

      final directory = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();

      final reportDir = Directory('${directory.path}/Violations');
      if (!await reportDir.exists()) {
        await reportDir.create(recursive: true);
      }

      final filePath =
          '${reportDir.path}/pelanggaran-anak-$studentId.pdf';

      final base64Content = await _violationRepository
          .downloadChildViolationPdf(studentId: studentId);

      final file = File(filePath);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      await file.writeAsBytes(base64Decode(base64Content));

      if (await file.exists()) {
        debugPrint(
            '✅ [DownloadParentViolation] File tersimpan di $filePath');
        emit(DownloadParentViolationSuccess(
            downloadedFilePath: filePath));
      } else {
        throw Exception('Gagal menyimpan berkas PDF.');
      }
    } catch (e) {
      debugPrint('❌ [DownloadParentViolation] Error: $e');
      String errorMsg = e.toString();
      if (errorMsg.startsWith('ApiException: ')) {
        errorMsg = errorMsg.replaceFirst('ApiException: ', '');
      }
      if (errorMsg == ErrorMessageKeysAndCode.defaultErrorMessageCode ||
          errorMsg == ErrorMessageKeysAndCode.defaultErrorMessageKey) {
        errorMsg = ErrorMessageKeysAndCode.fileNotFoundErrorCode;
      }
      emit(DownloadParentViolationFailure(errorMsg));
    }
  }
}
