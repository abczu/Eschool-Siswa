import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eschool/data/models/auth/guardian.dart';
import 'package:eschool/utils/system/imageCompress.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:path/path.dart' as p;
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';

class GuardianProfileRepository {
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

  MediaType _mediaTypeFor(String ext) {
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
      case '.pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<Guardian> updateGuardianPhoto({
    required Guardian guardianData,
    required String filePath,
    required int childId,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('child_id', childId.toString()));

      // helper: tambah field hanya jika ada nilai
      void addIfPresent(String key, String? value) {
        if (value != null &&
            value.trim().isNotEmpty &&
            value.trim() != 'null') {
          formData.fields.add(MapEntry(key, value.trim()));
        }
      }

      if (kDebugMode) {
        print("Guardian ID: ${guardianData.id}");
        print("File Path  : $filePath");
      }

      // ====== Fields (opsional, kirim hanya yang ada) ======
      addIfPresent('first_name', guardianData.firstName);
      addIfPresent('last_name', guardianData.lastName);
      addIfPresent('email', guardianData.email);
      addIfPresent('mobile', guardianData.mobile);
      addIfPresent('current_address', guardianData.currentAddress);
      addIfPresent('permanent_address', guardianData.permanentAddress);
      addIfPresent('gender', guardianData.gender);
      addIfPresent('dob', guardianData.dob);
      addIfPresent('occupation', guardianData.occupation);

      // Kalau backend minta id, kirimkan juga (opsional)
      if (guardianData.id != null) {
        formData.fields
            .add(MapEntry('guardian_id', guardianData.id.toString()));
      }

      // ====== File ======
      // SINGLE FILE: kompres ke ~10 KB + logging + multipart
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('SKIP: file tidak ditemukan: $filePath');
      } else {
        final before = await file.length();
        final originalName = p.basename(file.path);

        // Kompres agresif ke ~10 KB
        final File toUpload = await DartImagePreprocessor.processFile(
          file,
          maxBytes: 50 * 1024, // 10 KB
          maxDimension: 1080, // mulai dari 720px, nanti turun jika perlu
          flattenAlphaToWhite: true, // penting agar bisa JPEG (lebih kecil)
        );

        final after = await toUpload.length();
        final saved = before - after > 0 ? before - after : 0;
        final pct = before > 0 ? (saved / before * 100) : 0.0;

        debugPrint(
            '[SINGLE] $originalName  |  ${_fmtBytes(before)} → ${_fmtBytes(after)} '
            '(hemat ${_fmtBytes(saved)} ~ ${pct.toStringAsFixed(1)}%)');

        final outExt = p.extension(toUpload.path).toLowerCase();
        final mediaType = _mediaTypeFor(outExt);

        final multipartFile = await MultipartFile.fromFile(
          toUpload.path,
          filename: p.basename(toUpload.path), // pakai nama dg ekstensi baru
          contentType: mediaType,
        );

        // ganti key 'image' jika server minta nama lain (mis. 'photo')
        formData.files.add(MapEntry('image', multipartFile));
      }

      // ====== Debug ======
      if (kDebugMode) {
        print("\nForm Data Fields:");
        for (var f in formData.fields) {
          print("${f.key}: ${f.value}");
        }
        print("\nForm Data Files:");
        for (var f in formData.files) {
          print("${f.key}: ${f.value.filename}");
        }
      }

      // ====== Request ======
      final result = await Api.post(
        url: Api.updateGuardianPhoto, // pastikan ada di utils/api.dart
        body: formData,
        useAuthToken: true,
      );

      if (kDebugMode) {
        print("\nAPI Response:");
        print("Status : ${result['error'] == true ? 'Error' : 'Success'}");
        print("Message: ${result['message'] ?? 'No message'}");
        print("Full   : $result");
      }

      if (result['error'] == true) {
        throw ApiException(
          result['message'] ?? ErrorMessageKeysAndCode.defaultErrorMessageCode,
        );
      }

      // Ambil URL gambar baru dari response (sesuaikan kunci)
      final data = (result['data'] ?? result);
      final String? imageUrl =
          (data['imageUrl'] ?? data['image_url'] ?? data['image']) as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        throw ApiException('URL gambar tidak ditemukan pada respons server.');
      }

      Guardian datareturns = Guardian.fromJson(data);

      return datareturns;
    } catch (e) {
      if (kDebugMode) {
        print("\nError Details:");
        print("Type   : ${e.runtimeType}");
        print("Message: ${e.toString()}");
      }
      throw ApiException(e.toString());
    }
  }
}
