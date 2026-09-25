import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:eschool/data/repositories/exam/resultRepository.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

abstract class DownloadStudentResultState {}

class DownloadStudentResultInitial extends DownloadStudentResultState {}

class DownloadStudentResultInProgress extends DownloadStudentResultState {}

class DownloadStudentResultSuccess extends DownloadStudentResultState {
  final String downloadedFilePath;

  DownloadStudentResultSuccess({required this.downloadedFilePath});
}

class DownloadStudentResultFailure extends DownloadStudentResultState {
  final String errorMessage;

  DownloadStudentResultFailure(this.errorMessage);
}

class DownloadStudentResultCubit extends Cubit<DownloadStudentResultState> {
  final ResultRepository _resultRepository;

  DownloadStudentResultCubit(this._resultRepository)
      : super(DownloadStudentResultInitial());

  void downloadStudentResult({
    required int childId,
    required int examId,
    required bool useParentApi,
  }) async {
    try {
      emit(DownloadStudentResultInProgress());
      debugPrint("📥 [DownloadCubit] childId=$childId, examId=$examId, useParentApi=$useParentApi");

      final directory = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();

      final resultDir = Directory('${directory.path}/Results');
      if (!await resultDir.exists()) {
        await resultDir.create(recursive: true);
      }

      final filePath = '${resultDir.path}/$childId-$examId.pdf';
      final file = File(filePath);

      final receiptContent = await _resultRepository.downloadResult(
        studentId: childId,
        examId: examId,
        useParentApi: useParentApi,
      );

      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      await file.writeAsBytes(base64Decode(receiptContent));

      if (await file.exists()) {
        debugPrint("✅ [DownloadCubit] File successfully written to $filePath");
        emit(DownloadStudentResultSuccess(downloadedFilePath: filePath));
      } else {
        throw Exception("Gagal menyimpan berkas PDF.");
      }
    } catch (e) {
      debugPrint("❌ [DownloadCubit] Download result error: $e");
      String errorMsg = e.toString();
      if (errorMsg.startsWith("ApiException: ")) {
        errorMsg = errorMsg.replaceFirst("ApiException: ", "");
      }
      emit(DownloadStudentResultFailure(errorMsg));
    }
  }
}
