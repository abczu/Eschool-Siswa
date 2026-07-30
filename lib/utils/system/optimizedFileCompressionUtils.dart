import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

/// Optimized file compression utility with memory management
/// Uses isolates for heavy processing to prevent UI blocking
class OptimizedFileCompressionUtils {
  /// Supported image formats
  static const List<String> _supportedImageFormats = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.bmp',
    '.gif',
    '.tiff'
  ];

  /// Compress file with progress callback and memory optimization
  static Future<File> compressFile({
    required File file,
    double maxSizeInMB = 0.5, // Default target 500KB
    int? customQuality,
    bool forceCompress = true,
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Checking file...');

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final fileSize = await file.length();
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();

      if (kDebugMode) {
        print('🔧 [OPTIMIZED COMPRESSION] Processing: $fileName');
        print('   📊 Original size: ${formatFileSize(fileSize)}');
        print('   🎯 Target: ${maxSizeInMB.toStringAsFixed(2)} MB');
      }

      // Check if it's an image
      if (!_supportedImageFormats.contains(fileExtension)) {
        if (kDebugMode) {
          print('   ⚠️  Not an image file, skipping compression');
        }
        return file;
      }

      // For very large files, use isolate to prevent main thread blocking
      final maxSizeInBytes = (maxSizeInMB * 1024 * 1024).toInt();

      // Skip only if very small and not forced
      if (!forceCompress && fileSize < 100 * 1024) {
        if (kDebugMode) {
          print('   ⏭️  File very small, skipping compression');
        }
        return file;
      }

      onProgress?.call('Starting compression...');

      // Use isolate for files larger than 2MB to prevent memory issues
      if (fileSize > 2 * 1024 * 1024) {
        return await _compressInIsolate(
            file, maxSizeInBytes, customQuality, onProgress);
      } else {
        return await _compressImageOptimized(
            file, maxSizeInBytes, customQuality, forceCompress, onProgress);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [COMPRESSION ERROR] $e');
      }
      onProgress?.call('Compression failed, using original file');
      return file; // Return original file on error
    }
  }

  /// Compress in isolate for heavy processing
  static Future<File> _compressInIsolate(File file, int maxSizeInBytes,
      int? customQuality, Function(String)? onProgress) async {
    try {
      onProgress?.call('Processing large file...');

      final receivePort = ReceivePort();

      final isolateData = {
        'filePath': file.path,
        'maxSizeInBytes': maxSizeInBytes,
        'customQuality': customQuality,
        'sendPort': receivePort.sendPort,
      };

      await Isolate.spawn(_compressInIsolateEntry, isolateData);

      final result = await receivePort.first;
      receivePort.close();

      onProgress?.call('Compression completed!');

      if (result['success'] == true) {
        return File(result['outputPath']);
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Isolate compression failed: $e');
      }
      onProgress?.call('Fallback to main thread...');
      return await _compressImageOptimized(
          file, maxSizeInBytes, customQuality, true, onProgress);
    }
  }

  /// Isolate entry point for compression
  static void _compressInIsolateEntry(Map<String, dynamic> isolateData) async {
    final SendPort sendPort = isolateData['sendPort'];

    try {
      final file = File(isolateData['filePath']);
      final maxSizeInBytes = isolateData['maxSizeInBytes'];
      final customQuality = isolateData['customQuality'];

      final result = await _compressImageOptimized(
          file, maxSizeInBytes, customQuality, true, null);

      sendPort.send({
        'success': true,
        'outputPath': result.path,
      });
    } catch (e) {
      sendPort.send({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// Optimized image compression with memory management
  static Future<File> _compressImageOptimized(
      File file,
      int maxSizeInBytes,
      int? customQuality,
      bool forceCompress,
      Function(String)? onProgress) async {
    try {
      onProgress?.call('Reading image data...');

      final fileSize = await file.length();
      final bytes = await file.readAsBytes();

      onProgress?.call('Decoding image...');
      final image = img.decodeImage(bytes);

      if (image == null) {
        if (kDebugMode) {
          print('   ❌ Failed to decode image');
        }
        return file;
      }

      if (kDebugMode) {
        print('   🖼️  Original dimensions: ${image.width}x${image.height}');
      }

      onProgress?.call('Calculating optimal settings...');

      // Start with aggressive settings for target 500KB
      int quality = customQuality ?? 85;
      int targetWidth = image.width;
      int targetHeight = image.height;

      // For target 500KB, be more aggressive
      if (maxSizeInBytes <= 512 * 1024) {
        // 500KB target
        // Calculate aggressive reduction
        double sizeFactor = (maxSizeInBytes / fileSize).clamp(0.1, 0.8);
        double dimensionFactor =
            sizeFactor * 1.2; // Slightly more aggressive on dimensions

        final int minWidth = image.width < 800 ? image.width : 800;
        final int minHeight = image.height < 600 ? image.height : 600;

        targetWidth =
            (image.width * dimensionFactor).round().clamp(minWidth, image.width);
        targetHeight =
            (image.height * dimensionFactor).round().clamp(minHeight, image.height);

        // Lower quality for smaller target
        quality = customQuality ?? 80;
      } else {
        // Standard reduction for larger targets
        if (fileSize > maxSizeInBytes) {
          double reductionFactor = (maxSizeInBytes / fileSize).clamp(0.4, 0.9);
          targetWidth = (image.width * reductionFactor).round();
          targetHeight = (image.height * reductionFactor).round();
        }
      }

      onProgress?.call('Resizing image...');

      // Resize image if needed with memory-efficient resizing
      img.Image finalImage = image;
      if (targetWidth != image.width || targetHeight != image.height) {
        finalImage = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear, // Faster than cubic
        );

        // Clear original image from memory
        image.clear();
      }

      onProgress?.call('Compressing and saving...');

      // Generate output path
      final fileName = path.basenameWithoutExtension(file.path);
      final directory = path.dirname(file.path);
      final outputPath = path.join(directory, '${fileName}_compressed.jpg');

      // Iterative compression to hit target size
      File? compressedFile;
      int currentQuality = quality;
      int attempts = 0;
      const maxAttempts = 3;

      while (attempts < maxAttempts) {
        attempts++;

        if (kDebugMode) {
          print('   🧪 Attempt $attempts: Testing quality $currentQuality%');
        }

        // Compress with current settings
        final compressedBytes =
            img.encodeJpg(finalImage, quality: currentQuality);
        final tempFile = File(outputPath);
        await tempFile.writeAsBytes(compressedBytes);

        final compressedSize = compressedBytes.length;

        if (kDebugMode) {
          print('   📊 Result: ${formatFileSize(compressedSize)}');
        }

        // Check if we hit the target
        if (compressedSize <= maxSizeInBytes || attempts >= maxAttempts) {
          compressedFile = tempFile;

          final compressionRatio =
              ((fileSize - compressedSize) / fileSize * 100);

          if (kDebugMode) {
            print('   ✅ Compression successful!');
            print('   📊 Final size: ${formatFileSize(compressedSize)}');
            print('   📉 Reduction: ${compressionRatio.toStringAsFixed(1)}%');
            print('   🖼️  Final dimensions: ${targetWidth}x${targetHeight}');
            print('   🎨 Quality: $currentQuality%');
            if (compressedSize <= maxSizeInBytes) {
              print('   🎯 Target achieved!');
            }
          }
          break;
        }

        // Reduce quality for next attempt
        currentQuality = (currentQuality * 0.85).round().clamp(40, 95);
        if (kDebugMode) {
          print('   🔄 Too large, reducing quality to $currentQuality%');
        }
      }

      // Clear final image from memory
      finalImage.clear();

      onProgress?.call('Compression completed!');
      return compressedFile ?? file;
    } catch (e) {
      if (kDebugMode) {
        print('   ❌ Compression failed: $e');
      }
      onProgress?.call('Compression failed');
      return file;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if file type is supported for compression
  static bool isCompressionSupported(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return _supportedImageFormats.contains(extension);
  }

  /// Get file size in MB
  static Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Batch compress multiple files with progress
  static Future<List<File>> compressMultipleFiles({
    required List<File> files,
    double maxSizeInMB = 0.5,
    int? customQuality,
    bool forceCompress = true,
    Function(int current, int total, String fileName)? onProgress,
  }) async {
    List<File> compressedFiles = [];

    for (int i = 0; i < files.length; i++) {
      File file = files[i];
      try {
        onProgress?.call(i + 1, files.length, path.basename(file.path));

        final compressedFile = await compressFile(
          file: file,
          maxSizeInMB: maxSizeInMB,
          customQuality: customQuality,
          forceCompress: forceCompress,
          onProgress: (status) {
            // Individual file progress can be logged here if needed
          },
        );
        compressedFiles.add(compressedFile);
      } catch (e) {
        if (kDebugMode) {
          print('Error compressing file ${file.path}: $e');
        }
        compressedFiles.add(file); // Add original file if compression fails
      }
    }

    return compressedFiles;
  }
}
