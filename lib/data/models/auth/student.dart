import 'package:eschool/data/models/auth/childUserDetails.dart';
import 'package:eschool/data/models/academic/classSection.dart';
import 'package:eschool/data/models/auth/guardian.dart';
import 'package:eschool/data/models/system/school.dart';
import 'package:eschool/data/models/student/studentProfileExtraDetails.dart';

class Student {
  final int? id;
  final int? userId;
  final String? firstName;
  final String? lastName;
  final String? mobile;
  final String? gender;
  final String? image;
  final String? dob;
  final String? currentAddress;
  final String? permanentAddress;
  final int? status;
  final String? fcmId;
  final int? schoolId;
  final String? createdAt;
  final String? schoolName;
  final String? updatedAt;
  final String? schoolCode; // Add schoolCode field
  final String? token;
  final ClassSection? classSection;
  final Guardian? guardian;
  final School? school;
  final int? sessionYearId;
  final int? rollNumber;
  final String? admissionNo;
  final String? admissionDate;
  final List<StudentProfileExtraDetails>? studentProfileExtraDetails;
  final ChildUserDetails? childUserDetails;

  Student({
    this.id,
    this.firstName,
    this.userId,
    this.lastName,
    this.mobile,
    this.gender,
    this.image,
    this.dob,
    this.currentAddress,
    this.permanentAddress,
    this.status,
    this.fcmId,
    this.token,
    this.schoolCode,
    this.schoolId,
    this.createdAt,
    this.updatedAt,
    this.classSection,
    this.schoolName,
    this.guardian,
    this.school,
    this.admissionDate,
    this.admissionNo,
    this.rollNumber,
    this.sessionYearId,
    this.studentProfileExtraDetails,
    this.childUserDetails,
  }); // Add token to constructor

  static String? _processImage(String? url, String? updatedAt) {
    if (url == null || url.isEmpty) return url;
    if (updatedAt == null || updatedAt.isEmpty) return url;
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}v=${Uri.encodeComponent(updatedAt)}';
  }

  Student copyWith(
      {int? id,
      String? firstName,
      String? lastName,
      String? mobile,
      String? gender,
      String? schoolCode,
      String? schoolId,
      String? image,
      String? dob,
      String? currentAddress,
      String? permanentAddress,
      int? status,
      String? fcmId,
      String? createdAt,
      String? updatedAt,
      String? schoolName, // Add schoolName parameter
      ClassSection? classSection,
      Guardian? guardian,
      School? school,
      String? admissionNo,
      String? admissionDate,
      int? rollNumber,
      int? sessionYearId,
      int? userId,
      List<StudentProfileExtraDetails>? studentProfileExtraDetails,
      ChildUserDetails? childUserDetails,
      String? token}) {
    return Student(
        userId: userId ?? this.userId,
        id: id ?? this.id,
        childUserDetails: childUserDetails ?? this.childUserDetails,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        mobile: mobile ?? this.mobile,
        gender: gender ?? this.gender,
        image: image ?? this.image,
        dob: dob ?? this.dob,
        currentAddress: currentAddress ?? this.currentAddress,
        permanentAddress: permanentAddress ?? this.permanentAddress,
        status: status ?? this.status,
        fcmId: fcmId ?? this.fcmId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        schoolName: schoolName ?? this.schoolName, // Add schoolName to copyWith
        classSection: classSection ?? this.classSection,
        guardian: guardian ?? this.guardian,
        school: school ?? this.school,
        admissionDate: admissionDate ?? this.admissionDate,
        admissionNo: admissionNo ?? this.admissionNo,
        rollNumber: rollNumber ?? this.rollNumber,
        sessionYearId: sessionYearId ?? this.sessionYearId,
        studentProfileExtraDetails:
            studentProfileExtraDetails ?? this.studentProfileExtraDetails,
        schoolCode: schoolCode ?? this.schoolCode,
        token: token ?? this.token);
  }

  Student.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        childUserDetails =
            ChildUserDetails.fromJson(Map.from(json['user'] ?? {})),
        userId = json['user_id'] as int?,
        firstName =
            (json['first_name'] ?? json['user']?['first_name']) as String?,
        lastName = (json['last_name'] ?? json['user']?['last_name']) as String?,
        mobile = (json['mobile'] ?? json['user']?['mobile']) as String?,
        gender = (json['gender'] ?? json['user']?['gender']) as String?,
        image = _processImage((json['image'] ?? json['user']?['image']) as String?, (json['updated_at'] ?? json['user']?['updated_at']) as String?),
        // Extract schoolCode from multiple possible sources in priority order
        schoolCode = json['school_code'] as String? ??
            json['user']?['school']?['code'] as String? ??
            json['school']?['code'] as String?,
        token = json['token'] as String?, // Extract token from JSON
        dob = (json['dob'] ?? json['user']?['dob']) as String?,
        currentAddress = (json['current_address'] ??
            json['user']?['current_address']) as String?,
        permanentAddress = (json['permanent_address'] ??
            json['user']?['permanent_address']) as String?,
        status = int.parse(
            (json['status'] ?? json['user']?['status'] ?? 0).toString()),
        fcmId = (json['fcm_id'] ?? json['user']?['fcm_id']) as String?,
        schoolId = (json['school_id'] ?? json['user']?['school_id']) as int?,
        createdAt =
            (json['created_at'] ?? json['user']?['created_at']) as String?,
        classSection =
            ClassSection.fromJson(Map.from(json['class_section'] ?? {})),
        guardian = Guardian.fromJson(Map.from(json['guardian'] ?? {})),
        school = School.fromJson(Map.from(json['school'] ?? {})),
        schoolName = json['school_name'] as String? ??
            json['user']?['school']?['name'] as String?,
        sessionYearId = json['session_year_id'] as int?,
        rollNumber = json['roll_number'] as int?,
        admissionDate = json['admission_date'] as String?,
        admissionNo = json['admission_no'] as String?,
        studentProfileExtraDetails = ((json['extra_details'] ?? []) as List)
            .map((details) =>
                StudentProfileExtraDetails.fromJson(Map.from(details ?? {})))
            .toList(),
        updatedAt = json['updated_at'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'mobile': mobile,
        'gender': gender,
        'image': image,
        'dob': dob,
        'current_address': currentAddress,
        'permanent_address': permanentAddress,
        'status': status,
        'fcm_id': fcmId,
        'school_id': schoolId,
        'school_code': schoolCode,
        'school_name': schoolName, // Add schoolName to JSON output
        'created_at': createdAt,
        'updated_at': updatedAt,
        'class_section': classSection?.toJson(),
        'guardian': guardian?.toJson(),
        'school': school?.toJson(),
        'session_year_id': sessionYearId,
        'roll_number': rollNumber,
        'admission_date': admissionDate,
        'admission_no': admissionNo,
        'user_id': userId,
        'extra_details':
            studentProfileExtraDetails?.map((e) => e.toJson()).toList(),
        'user': childUserDetails?.toJson(),
        'token': token,
      };

  String getFullName() {
    return "$firstName";
  }
  // String getFullName() {
  //   return "$firstName $lastName";
  // }

  @override
  String toString() {
    return '$firstName - ${classSection?.classDetails?.name}${classSection?.section?.name}';
  }
  // String toString() {
  //   return '$firstName $lastName - ${classSection?.classDetails?.name}${classSection?.section?.name}';
  // }
}
