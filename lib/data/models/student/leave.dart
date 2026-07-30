import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class LeaveDetail {
  final int id;
  final int? leaveId;
  final String date;
  final String type;
  final int schoolId;
  final String? fileName;
  final String? fileUrl;
  final String? fileExtension;
  final String? typeDetail;
  final bool isFile;

  LeaveDetail({
    required this.id,
    required this.leaveId,
    required this.date,
    required this.type,
    required this.schoolId,
    this.fileName,
    this.fileUrl,
    this.fileExtension,
    this.typeDetail,
    this.isFile = false,
  });

  factory LeaveDetail.fromJson(Map<String, dynamic> json,
      {bool isFile = false}) {
    print("Parsing LeaveDetail ID: ${json['id']}");
    print("Parsing LeaveDetail leaveId: ${json['leave_id']}");
    print("Parsing LeaveDetail date: ${json['date']}");
    print(json);

    final actualIsFile = isFile ||
        json['file_name'] != null ||
        json['file_url'] != null ||
        json['file'] != null ||
        json['attachment'] != null;

    final fileUrlVal = json['file_url']?.toString() ??
        (json['file'] != null && json['file'].toString().contains('/')
            ? json['file'].toString()
            : null) ??
        json['attachment']?.toString();

    final fileNameVal = json['file_name']?.toString() ??
        (json['file'] != null && !json['file'].toString().contains('/')
            ? json['file'].toString()
            : null) ??
        (fileUrlVal != null ? fileUrlVal.split('/').last.split('?').first : null);

    return LeaveDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      leaveId: int.tryParse(json['leave_id'].toString()) ?? 0,
      date: json['date'] ?? '',
      type: json['type'] ?? '',
      schoolId: int.tryParse(json['school_id'].toString()) ?? 0,
      isFile: actualIsFile,
      fileName: fileNameVal,
      fileUrl: fileUrlVal,
      fileExtension: (json['file_extension']?.toString() ??
          (() {
            final name = (fileNameVal ?? fileUrlVal ?? '').toString();
            if (name.contains('.')) {
              return name.split('.').last.split('?').first.toLowerCase();
            }
            return null;
          })()),
      typeDetail: json['type_detail']?.toString(),
    );
  }

  String get formattedDate {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing date $date: $e");
      }
      return date; // Return original date string if parsing fails
    }
  }
}

class Leave {
  final int id;
  final int userId;
  final String reason;
  final String type;
  final String fromDate;
  final String toDate;
  final int status;
  final int schoolId;
  final int leaveMasterId;
  final String rejectReason;
  final String createdAt;
  final String updatedAt;
  final List<LeaveDetail> leaveDetail;
  final List<LeaveDetail> fileDetail;

  Leave({
    required this.id,
    required this.userId,
    required this.reason,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.schoolId,
    required this.rejectReason,
    required this.leaveMasterId,
    required this.createdAt,
    required this.updatedAt,
    required this.leaveDetail,
    required this.fileDetail,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    print("Parsing Leave ID: ${json['id']}");
    print("Raw JSON for Leave: $json");
    print(json);

    final rawLeaveDetails = json['leave_details'] ?? json['leave_detail'];
    final leaveDetails = (rawLeaveDetails as List?)?.map((detail) {
          print("Parsing leave detail: $detail");
          return LeaveDetail.fromJson(Map<String, dynamic>.from(detail));
        }).toList() ??
        [];

    // Robust: cek key 'file' dan 'files', serta handle nested/flat list maupun single map object
    final rawFileData = json['file'] ?? json['files'] ?? json['file_details'] ?? json['file_detail'];
    print("DEBUG Leave.fromJson - rawFileData: $rawFileData (type: ${rawFileData?.runtimeType})");
    List<LeaveDetail> fileDetails = [];
    if (rawFileData != null) {
      if (rawFileData is List && rawFileData.isNotEmpty) {
        List targetList;
        if (rawFileData[0] is List) {
          // Nested list: [[file1, file2]]
          targetList = rawFileData[0] as List;
        } else {
          // Flat list: [file1, file2]
          targetList = rawFileData;
        }
        fileDetails = targetList.map((file) {
          print("Parsing file detail element: $file");
          if (file is Map) {
            return LeaveDetail.fromJson(Map<String, dynamic>.from(file),
                isFile: true);
          } else if (file is String && file.isNotEmpty) {
            final fileName = file.split('/').last.split('?').first;
            return LeaveDetail(
              id: int.tryParse(json['id'].toString()) ?? 0,
              leaveId: int.tryParse(json['id'].toString()) ?? 0,
              date: json['from_date'] ?? json['created_at'] ?? '',
              type: json['type'] ?? '',
              schoolId: int.tryParse(json['school_id'].toString()) ?? 0,
              isFile: true,
              fileName: fileName,
              fileUrl: file,
              fileExtension: (() {
                if (fileName.contains('.')) {
                  return fileName.split('.').last.toLowerCase();
                }
                return null;
              })(),
            );
          } else {
            return LeaveDetail(
              id: 0,
              leaveId: 0,
              date: '',
              type: '',
              schoolId: 0,
            );
          }
        }).where((detail) => detail.id != 0 || detail.fileUrl != null).toList();
      } else if (rawFileData is Map) {
        print("Parsing file detail from Map: $rawFileData");
        fileDetails = [
          LeaveDetail.fromJson(Map<String, dynamic>.from(rawFileData),
              isFile: true)
        ];
      } else if (rawFileData is String && rawFileData.isNotEmpty) {
        print("Parsing file detail from String: $rawFileData");
        final fileName = rawFileData.split('/').last.split('?').first;
        fileDetails = [
          LeaveDetail(
            id: int.tryParse(json['id'].toString()) ?? 0,
            leaveId: int.tryParse(json['id'].toString()) ?? 0,
            date: json['from_date'] ?? json['created_at'] ?? '',
            type: json['type'] ?? '',
            schoolId: int.tryParse(json['school_id'].toString()) ?? 0,
            isFile: true,
            fileName: fileName,
            fileUrl: rawFileData,
            fileExtension: (() {
              if (fileName.contains('.')) {
                return fileName.split('.').last.toLowerCase();
              }
              return null;
            })(),
          )
        ];
      }
    }

    // Fallback jika root Leave object memiliki file_name atau file_url secara langsung
    if (fileDetails.isEmpty && (json['file_name'] != null || json['file_url'] != null || json['file'] is String)) {
      final fileVal = json['file_url'] ?? json['file'] ?? '';
      if (fileVal.toString().isNotEmpty) {
        final fileName = json['file_name']?.toString() ?? fileVal.toString().split('/').last.split('?').first;
        fileDetails = [
          LeaveDetail(
            id: int.tryParse(json['id'].toString()) ?? 0,
            leaveId: int.tryParse(json['id'].toString()) ?? 0,
            date: json['from_date'] ?? json['created_at'] ?? '',
            type: json['type'] ?? '',
            schoolId: int.tryParse(json['school_id'].toString()) ?? 0,
            isFile: true,
            fileName: fileName,
            fileUrl: fileVal.toString(),
            fileExtension: (() {
              if (fileName.contains('.')) {
                return fileName.split('.').last.toLowerCase();
              }
              return null;
            })(),
          )
        ];
      }
    }

    return Leave(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      reason: json['reason'] ?? '',
      type: json['type'] ?? '',
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      rejectReason: json['rejection_reason'] ?? '',
      status: int.tryParse(json['status'].toString()) ?? 0,
      schoolId: int.tryParse(json['school_id'].toString()) ?? 0,
      leaveMasterId: int.tryParse(json['leave_master_id'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      leaveDetail: leaveDetails,
      fileDetail: fileDetails,
    );
  }
}
