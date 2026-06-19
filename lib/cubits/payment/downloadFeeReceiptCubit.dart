import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:eschool/data/repositories/payment/feeRepository.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

abstract class DownloadFeeReceiptState {}

class DownloadFeeReceiptInitial extends DownloadFeeReceiptState {}

class DownloadFeeReceiptInProgress extends DownloadFeeReceiptState {}

class DownloadFeeReceiptSuccess extends DownloadFeeReceiptState {
  final String downloadedFilePath;

  DownloadFeeReceiptSuccess({required this.downloadedFilePath});
}

class DownloadFeeReceiptFailure extends DownloadFeeReceiptState {
  final String errorMessage;

  DownloadFeeReceiptFailure(this.errorMessage);
}

class DownloadFeeReceiptCubit extends Cubit<DownloadFeeReceiptState> {
  final FeeRepository _feeRepository;

  DownloadFeeReceiptCubit(this._feeRepository)
      : super(DownloadFeeReceiptInitial());

  void downloadFeeReceipt({required int childId, required int feeId}) async {
    try {
      emit(DownloadFeeReceiptInProgress());

      String filePath = "";
      final path = (await getApplicationDocumentsDirectory()).path;
      filePath = "$path/Fees-Receipts/${childId}-${feeId}.pdf";

      final File file = File(filePath);

      final receiptBytes =
          await _feeRepository.getFeeReceipt(childId: childId, feeId: feeId);

      if (receiptBytes.isEmpty) {
        emit(DownloadFeeReceiptFailure("Struk tidak ditemukan di server."));
        return;
      }

      // Validasi: Apakah ini benar-benar file PDF?
      // PDF signature: %PDF- (dalam bytes: 0x25, 0x50, 0x44, 0x46, 0x2d)
      if (receiptBytes.length < 5 ||
          receiptBytes[0] != 0x25 ||
          receiptBytes[1] != 0x50 ||
          receiptBytes[2] != 0x44 ||
          receiptBytes[3] != 0x46) {
        emit(DownloadFeeReceiptFailure(
            "Format berkas tidak valid atau korup. Silakan hubungi admin."));
        return;
      }

      await file.create(recursive: true);
      await file.writeAsBytes(receiptBytes);
      emit(DownloadFeeReceiptSuccess(downloadedFilePath: filePath));
    } catch (e) {
      emit(DownloadFeeReceiptFailure(
          ErrorMessageMapper.getUserFriendlyMessage(e)));
    }
  }

  void downloadFeeReceiptFromHistoryIds(
      {required int childId, required List<String> paymentHistoryIds}) async {
    try {
      emit(DownloadFeeReceiptInProgress());

      final path = (await getApplicationDocumentsDirectory()).path;
      final String fileName =
          "struk_${childId}_${paymentHistoryIds.join('_')}.pdf";
      final String filePath = "$path/Fees-Receipts/$fileName";

      final File file = File(filePath);

      final receiptBytes = await _feeRepository.getFeeReceiptFromHistoryIds(
          childId: childId, paymentHistoryIds: paymentHistoryIds);

      if (receiptBytes.isEmpty) {
        emit(DownloadFeeReceiptFailure("Struk tidak ditemukan di server."));
        return;
      }

      // Validasi signature PDF
      if (receiptBytes.length < 5 ||
          receiptBytes[0] != 0x25 ||
          receiptBytes[1] != 0x50 ||
          receiptBytes[2] != 0x44 ||
          receiptBytes[3] != 0x46) {
        emit(DownloadFeeReceiptFailure(
            "Format kuitansi tidak valid dari server (Bukan PDF)."));
        return;
      }

      await file.create(recursive: true);
      await file.writeAsBytes(receiptBytes);

      emit(DownloadFeeReceiptSuccess(downloadedFilePath: filePath));
    } catch (e) {
      emit(DownloadFeeReceiptFailure(
          ErrorMessageMapper.getUserFriendlyMessage(e)));
    }
  }
}
