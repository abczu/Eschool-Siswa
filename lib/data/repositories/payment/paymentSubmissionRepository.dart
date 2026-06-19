import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eschool/utils/system/imageCompress.dart';
import 'package:flutter/foundation.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class PaymentSubmissionRepository {
  // ====== Konfigurasi kompres global (target 10 KB) ======
  static const int _kTargetBytes = 10 * 1024; // 10 KB
  static const int _kStartMaxDim = 720; // mulai resize dari 720 px

  // Formatter ukuran untuk logging
  String _fmtBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(1)} ${units[unit]}';
  }

  MediaType _mediaTypeForExt(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.gif':
        return MediaType('image', 'gif');
      case '.bmp':
        return MediaType('image', 'bmp');
      case '.heic':
        return MediaType('image', 'heic');
      case '.tif':
      case '.tiff':
        return MediaType('image', 'tiff');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  /// Kompres bukti → ~10 KB + log + kembalikan MultipartFile siap upload
  Future<MultipartFile> _prepareCompressedProofMultipart(
    File proofFile, {
    String filenamePrefix = 'payment_proof_',
  }) async {
    if (!await proofFile.exists()) {
      throw ApiException(
          'File bukti pembayaran tidak ditemukan: ${proofFile.path}');
    }

    final before = await proofFile.length();

    final File compressed = await DartImagePreprocessor.processFile(
      proofFile,
      maxBytes: _kTargetBytes,
      maxDimension: _kStartMaxDim,
      flattenAlphaToWhite: true,
    );

    final after = await compressed.length();

    if (kDebugMode) {
      final name = p.basename(proofFile.path);
      final saved = before - after > 0 ? before - after : 0;
      final pct = before > 0 ? (saved / before * 100) : 0.0;
      debugPrint(
          '[Compress] $name | ${_fmtBytes(before)} → ${_fmtBytes(after)} '
          '(hemat ${_fmtBytes(saved)} ~ ${pct.toStringAsFixed(1)}%)');
    }

    final outExt = p.extension(compressed.path).toLowerCase();
    final mediaType = _mediaTypeForExt(outExt);
    final filename =
        '${filenamePrefix}${DateTime.now().millisecondsSinceEpoch}${outExt.isEmpty ? '.jpg' : outExt}';

    return MultipartFile.fromFile(
      compressed.path,
      filename: filename,
      contentType: mediaType,
    );
  }

  // ==========================
  //  Submit single payment
  // ==========================
  Future<Map<String, dynamic>> submitSinglePayment({
    required int childId,
    required int feesId,
    required double amount,
    required int paymentMethodId,
    required File proofFile,
  }) async {
    try {
      final proofMultipart = await _prepareCompressedProofMultipart(
        proofFile,
        filenamePrefix: 'payment_proof_',
      );

      final FormData formData = FormData.fromMap({
        'child_id': childId,
        'fees_id': feesId,
        'amount': amount.toStringAsFixed(2),
        'payment_method_id': paymentMethodId,
        'proof': proofMultipart,
      });

      final result = await Api.post(
        body: formData,
        url: Api.submitSinglePayment,
        useAuthToken: true,
      );

      return result;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // ==========================
  //  Submit bulk payment
  // ==========================
  Future<Map<String, dynamic>> submitBulkPayment({
    required int childId,
    required List<int> feesIds,
    required double amount,
    required int paymentMethodId,
    required File proofFile,
  }) async {
    try {
      final proofMultipart = await _prepareCompressedProofMultipart(
        proofFile,
        filenamePrefix: 'bulk_payment_proof_',
      );

      final FormData formData = FormData();

      // fields dasar
      formData.fields.add(MapEntry('child_id', childId.toString()));
      formData.fields
          .add(MapEntry('payment_method_id', paymentMethodId.toString()));
      formData.fields.add(MapEntry('amount', amount.toString()));

      // array fees_ids[] (Laravel/PHP style)
      for (final feeId in feesIds) {
        formData.fields.add(MapEntry('fees_ids[]', feeId.toString()));
      }

      // file proof
      formData.files.add(MapEntry('proof', proofMultipart));

      if (kDebugMode) {
        debugPrint('Sending bulk payment with fees_ids: $feesIds');
        debugPrint(
            'FormData fields: ${formData.fields.map((e) => '${e.key}=${e.value}').join('&')}');
      }

      final result = await Api.post(
        body: formData,
        url: Api.submitBulkPayment,
        useAuthToken: true,
      );

      return result;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // ==========================================
  //  Submit installment payment (custom amount)
  // ==========================================
  Future<Map<String, dynamic>> submitInstallmentPayment({
    required int childId,
    required int feeId,
    required double amount,
    required int paymentMethodId,
    required File proofFile,
  }) async {
    try {
      final proofMultipart = await _prepareCompressedProofMultipart(
        proofFile,
        filenamePrefix: 'installment_payment_proof_',
      );

      final FormData formData = FormData.fromMap({
        'child_id': childId,
        'fees_id': feeId, // sesuai API kamu
        'amount': amount, // biarkan numeric
        'payment_method_id': paymentMethodId,
        'proof': proofMultipart,
      });

      final result = await Api.post(
        body: formData,
        url: Api.submitSinglePayment,
        useAuthToken: true,
      );

      return result;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  // ==========================
  //  Verify payment status
  // ==========================
  Future<Map<String, dynamic>> verifyPaymentStatus({
    required String transactionId,
  }) async {
    try {
      final result = await Api.get(
        url: Api.verifyPaymentStatus,
        queryParameters: {
          'transaction_id': transactionId,
        },
        useAuthToken: true,
      );

      return result;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
