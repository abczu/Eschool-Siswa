import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/utils/system/imageCompress.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:path/path.dart' as p;
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';

/// Repository untuk update foto profil siswa sendiri.
///
/// Menggunakan endpoint umum backend:
/// `POST /api/update-profile` (multipart, key `image`, max 2MB).
/// Hanya mengirim foto — field identitas lain bersifat opsional di backend.
class StudentProfileRepository {
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
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<Student> updateStudentPhoto({
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ApiException('File gambar tidak ditemukan.');
      }

      final before = await file.length();
      if (kDebugMode) {
        print("Student photo original: ${_fmtBytes(before)} ($filePath)");
      }

      // Kompres agar aman di bawah batas 2MB backend.
      final File toUpload = await DartImagePreprocessor.processFile(
        file,
        maxBytes: 200 * 1024,
        maxDimension: 1080,
        flattenAlphaToWhite: true,
      );

      final after = await toUpload.length();
      if (kDebugMode) {
        debugPrint(
            '[STUDENT PHOTO] ${_fmtBytes(before)} → ${_fmtBytes(after)}');
      }

      final outExt = p.extension(toUpload.path).toLowerCase();
      final mediaType = _mediaTypeFor(outExt);

      final multipartFile = await MultipartFile.fromFile(
        toUpload.path,
        filename: p.basename(toUpload.path),
        contentType: mediaType,
      );

      final formData = FormData();
      formData.files.add(MapEntry('image', multipartFile));

      final result = await Api.post(
        url: Api.updateStudentProfile,
        body: formData,
        useAuthToken: true,
      );

      if (kDebugMode) {
        print("\nAPI Response (updateStudentProfile): $result");
      }

      if (result['error'] == true) {
        throw ApiException(
          result['message'] ?? ErrorMessageKeysAndCode.defaultErrorMessageCode,
        );
      }

      final data = (result['data'] is Map)
          ? Map<String, dynamic>.from(result['data'])
          : Map<String, dynamic>.from(result);

      // Backend mengembalikan user baru; Student.fromJson handle
      // fallback image dari `image` maupun `user.image`.
      return Student.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (kDebugMode) {
        print("\nError updateStudentPhoto: ${e.runtimeType} $e");
      }
      throw ApiException(e.toString());
    }
  }
}
