import 'package:eschool/data/models/auth/guardian.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:eschool/utils/system/apiJson.dart';
import 'package:eschool/utils/system/hiveBoxKeys.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:eschool/data/local/pendingPaymentLocalDataSource.dart';
import 'package:intl/intl.dart';

class AuthRepository {
  // Kirim device token ke backend
  Future<String> GetDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('DEBUG: Device token FCM: $token');
      if (token != null && token.isNotEmpty) {
        return token;
      }
      return "";
    } catch (e) {
      debugPrint('ERROR sending device token: $e');
      return "";
    }
  }

  // Register device token ke backend (untuk sinkronisasi Tanpa login)
  Future<void> registerDeviceToken({required String fcmId}) async {
    try {
      // Pastikan user sudah login sebelum register token
      if (!getIsLogIn()) return;

      final body = {
        "fcm_id": fcmId,
        "platform":
            defaultTargetPlatform == TargetPlatform.iOS ? "ios" : "android"
      };

      debugPrint('DEBUG: Memperbarui token device ke backend...');
      // Mencoba mendaftarkan token melalui jalur profil siswa (lebih aman untuk akun Siswa)
      await Api.get(
        url: Api.studentProfile,
        useAuthToken: true,
        queryParameters: {
          "fcm_id": fcmId,
          "platform":
              defaultTargetPlatform == TargetPlatform.iOS ? "ios" : "android"
        },
      );
      debugPrint('✅ Token device berhasil didaftarkan ke backend');

      // Update FCM class section topic subscriptions
      await updateFCMClassSectionTopics();
    } catch (e) {
      debugPrint('❌ Gagal mendaftarkan token device: $e');
    }
  }

  // Update FCM class section subscriptions based on user role (Student/Parent)
  Future<void> updateFCMClassSectionTopics() async {
    try {
      if (!getIsLogIn()) {
        debugPrint("🔔 FCM Topic: User tidak login, lewati update topic");
        return;
      }

      final authBox = Hive.box(authBoxKey);
      final isStudent = getIsStudentLogIn();

      // Get target class section IDs based on logged-in student or parent children
      final List<int> targetIds = [];
      if (isStudent) {
        final student = getStudentDetails();
        final classSectionId = student.classSection?.id;
        if (classSectionId != null) {
          targetIds.add(classSectionId);
        }
      } else {
        final children = getChildrenData();
        for (final child in children) {
          final classSectionId = child.classSection?.id;
          if (classSectionId != null && !targetIds.contains(classSectionId)) {
            targetIds.add(classSectionId);
          }
        }
      }

      // Read current subscribed ids from hive
      final List<int> currentSubscribedIds = List<int>.from(
          authBox.get(subscribedClassSectionIdsKey, defaultValue: []));

      debugPrint("🔔 FCM Topic: Mengupdate Class Section Topics...");
      debugPrint("   - Subscribed saat ini: $currentSubscribedIds");
      debugPrint("   - Target subskripsi: $targetIds");

      // 1. Unsubscribe from invalid/old topics
      for (final id in currentSubscribedIds) {
        if (!targetIds.contains(id)) {
          final topicName = "class_section_$id";
          debugPrint("   - Unsubscribe dari topic: $topicName");
          await FirebaseMessaging.instance.unsubscribeFromTopic(topicName);
        }
      }

      // 2. Subscribe to new topics
      for (final id in targetIds) {
        if (!currentSubscribedIds.contains(id)) {
          final topicName = "class_section_$id";
          debugPrint("   - Subscribe ke topic: $topicName");
          await FirebaseMessaging.instance.subscribeToTopic(topicName);
        }
      }

      // 3. Save new state to Hive
      await authBox.put(subscribedClassSectionIdsKey, targetIds);
      debugPrint("✅ FCM Topic: Pembaruan topic subskripsi selesai.");
    } catch (e) {
      debugPrint("❌ FCM Topic: Gagal memperbarui topic class section: $e");
    }
  }

  //LocalDataSource
  bool getIsLogIn() {
    return Hive.box(authBoxKey).get(isLogInKey) ?? false;
  }

  Future<void> setIsLogIn(bool value) async {
    return Hive.box(authBoxKey).put(isLogInKey, value);
  }

  static bool getIsStudentLogIn() {
    return Hive.box(authBoxKey).get(isStudentLogInKey) ?? false;
  }

  Future<void> setIsStudentLogIn(bool value) async {
    return Hive.box(authBoxKey).put(isStudentLogInKey, value);
  }

  static Student getStudentDetails() {
    return Student.fromJson(
      Map.from(Hive.box(authBoxKey).get(studentDetailsKey) ?? {}),
    );
  }

  Future<void> setStudentDetails(Student student) async {
    return Hive.box(authBoxKey).put(studentDetailsKey, student.toJson());
  }

  static Guardian getParentDetails() {
    return Guardian.fromJson(
      Map.from(Hive.box(authBoxKey).get(parentDetailsKey) ?? {}),
    );
  }

  Future<void> setParentDetails(Guardian parent) async {
    return Hive.box(authBoxKey).put(parentDetailsKey, parent.toJson());
  }

  // Children data persistence methods
  static List<Student> getChildrenData() {
    try {
      final childrenList = Hive.box(authBoxKey).get(childrenDataKey) ?? [];
      debugPrint("DEBUG getChildrenData: Raw data from Hive: $childrenList");
      debugPrint(
          "DEBUG getChildrenData: Raw data type: ${childrenList.runtimeType}");
      debugPrint(
          "DEBUG getChildrenData: Raw data length: ${(childrenList as List).length}");

      final children = (childrenList).map((child) {
        debugPrint("DEBUG getChildrenData: Processing child: $child");
        final student = Student.fromJson(Map.from(child));
        debugPrint(
            "DEBUG getChildrenData: Parsed student - name: ${student.getFullName()}, token: '${student.token}', schoolCode: '${student.schoolCode}', school.code: '${student.school?.code}'");
        return student;
      }).toList();

      debugPrint(
          "DEBUG getChildrenData: Final children count: ${children.length}");
      return children;
    } catch (e) {
      debugPrint("DEBUG getChildrenData: Error loading children: $e");
      return [];
    }
  }

  Future<void> setChildrenData(List<Student> children) async {
    try {
      debugPrint("DEBUG setChildrenData: Saving ${children.length} children");
      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        debugPrint(
            "DEBUG setChildrenData: Child $i - name: ${child.getFullName()}, token: '${child.token}', schoolCode: '${child.schoolCode}', school.code: '${child.school?.code}'");
        debugPrint("DEBUG setChildrenData: Child $i JSON: ${child.toJson()}");
      }

      final childrenJson = children.map((child) => child.toJson()).toList();
      debugPrint("DEBUG setChildrenData: Final JSON to save: $childrenJson");

      await Hive.box(authBoxKey).put(childrenDataKey, childrenJson);
      debugPrint("DEBUG setChildrenData: Data saved successfully");

      // Verify save by reading back
      final savedData = Hive.box(authBoxKey).get(childrenDataKey);
      debugPrint("DEBUG setChildrenData: Verification read: $savedData");
    } catch (e) {
      debugPrint("DEBUG setChildrenData: Error saving children: $e");
    }
  }

  String getJwtToken() {
    return Hive.box(authBoxKey).get(jwtTokenKey) ?? "";
  }

  Future<void> setJwtToken(String value) async {
    return Hive.box(authBoxKey).put(jwtTokenKey, value);
  }

  String getParentJwtToken() {
    return Hive.box(authBoxKey).get(parentJwtTokenKey) ?? "";
  }

  Future<void> setParentJwtToken(String value) async {
    return Hive.box(authBoxKey).put(parentJwtTokenKey, value);
  }

  String get schoolCode =>
      Hive.box(authBoxKey).get(schoolCodeKey, defaultValue: "") as String;

  set schoolCode(String value) =>
      Hive.box(authBoxKey).put(schoolCodeKey, value);

// Remember Me methods for OTP login flow
  bool getRememberMe() {
    return Hive.box(authBoxKey).get("rememberMeOtp") ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    return Hive.box(authBoxKey).put("rememberMeOtp", value);
  }

  String getSavedIdentifier() {
    return Hive.box(authBoxKey).get("savedIdentifierOtp") ?? "";
  }

  Future<void> setSavedIdentifier(String value) async {
    return Hive.box(authBoxKey).put("savedIdentifierOtp", value);
  }

  Future<void> clearOtpCredentials() async {
    await setRememberMe(false);
    await setSavedIdentifier("");
  }

// Remember Me methods for Student
  bool getRememberMeStudent() {
    return Hive.box(authBoxKey).get(rememberMeStudentKey) ?? false;
  }

  Future<void> setRememberMeStudent(bool value) async {
    return Hive.box(authBoxKey).put(rememberMeStudentKey, value);
  }

  String getSavedGrNumber() {
    return Hive.box(authBoxKey).get(savedGrNumberKey) ?? "";
  }

  Future<void> setSavedGrNumber(String value) async {
    return Hive.box(authBoxKey).put(savedGrNumberKey, value);
  }

  String getSavedSchoolCode() {
    return Hive.box(authBoxKey).get(savedSchoolCodeKey) ?? "";
  }

  Future<void> setSavedSchoolCode(String value) async {
    return Hive.box(authBoxKey).put(savedSchoolCodeKey, value);
  }

  String getSavedStudentPassword() {
    return Hive.box(authBoxKey).get(savedStudentPasswordKey) ?? "";
  }

  Future<void> setSavedStudentPassword(String value) async {
    return Hive.box(authBoxKey).put(savedStudentPasswordKey, value);
  }

  Future<void> clearStudentCredentials() async {
    await setRememberMeStudent(false);
    await setSavedGrNumber("");
    await setSavedSchoolCode("");
    await setSavedStudentPassword("");
  }

  // Remember Me methods for Parent
  bool getRememberMeParent() {
    return Hive.box(authBoxKey).get(rememberMeParentKey) ?? false;
  }

  Future<void> setRememberMeParent(bool value) async {
    return Hive.box(authBoxKey).put(rememberMeParentKey, value);
  }

  String getSavedEmail() {
    return Hive.box(authBoxKey).get(savedEmailKey) ?? "";
  }

  Future<void> setSavedEmail(String value) async {
    return Hive.box(authBoxKey).put(savedEmailKey, value);
  }

  String getSavedParentPassword() {
    return Hive.box(authBoxKey).get(savedParentPasswordKey) ?? "";
  }

  Future<void> setSavedParentPassword(String value) async {
    return Hive.box(authBoxKey).put(savedParentPasswordKey, value);
  }

  Future<void> clearParentCredentials() async {
    await setRememberMeParent(false);
    await setSavedEmail("");
    await setSavedParentPassword("");
  }

  Future<void> signOutUser() async {
    try {
      // ✅ 1. Ambil FCM token sebelum dihapus
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('🔑 FCM Token saat logout: $fcmToken');

      // ✅ 2. Unsubscribe dari all class section topics yang aktif
      final authBox = Hive.box(authBoxKey);
      try {
        final List<int> currentSubscribedIds = List<int>.from(
            authBox.get(subscribedClassSectionIdsKey, defaultValue: []));
        for (final id in currentSubscribedIds) {
          final topicName = "class_section_$id";
          debugPrint(
              '🗑️ FCM Topic: Unsubscribing dari topic: $topicName saat logout');
          await FirebaseMessaging.instance.unsubscribeFromTopic(topicName);
        }
        await authBox.delete(subscribedClassSectionIdsKey);
      } catch (e) {
        debugPrint('⚠️ Error saat unsubscribe topic FCM: $e');
      }

      // ✅ 3. Kirim request logout ke backend dengan FCM token
      // Backend akan unregister token ini dari database
      await Api.post(
          body: {'fcm_id': fcmToken ?? ''},
          url: Api.logout,
          useAuthToken: true);
      debugPrint('✅ Logout request berhasil dikirim ke backend');

      // ✅ 4. Hapus FCM token dari device
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('🗑️ FCM Token berhasil dihapus dari device');
    } catch (e) {
      debugPrint('⚠️ Error saat logout (tetap lanjut clear data lokal): $e');
      // Tetap lanjut clear data lokal meskipun error
    }

    // ✅ 4. Clear local data (ini tetap dijalankan meskipun ada error di atas)
    await setIsLogIn(false);
    await setJwtToken("");
    await setParentJwtToken("");
    await setStudentDetails(Student.fromJson({}));
    await setParentDetails(Guardian.fromJson({}));
    await setChildrenData([]); // Clear children data on logout
    schoolCode = ""; // Clear school code on logout
    await PendingPaymentLocalDataSource.clear(); // Clear pending payments on logout

    // ✅ 5. Clear pending notification (jika ada)
    final authBox = Hive.box(authBoxKey);
    authBox.delete(pendingNotificationRouteKey);
    authBox.delete(pendingNotificationArgumentsKey);
    debugPrint('🗑️ Pending notification berhasil dihapus');

    // ✅ 6. Remember Me credentials TETAP TERSIMPAN
    // Ini memungkinkan user untuk auto-fill credentials saat login lagi
    // TAPI tidak akan auto-login, user tetap harus tap tombol "Sign In"
    debugPrint(
        '✅ Data lokal berhasil dibersihkan (Remember Me credentials tetap tersimpan)');
  }

  //RemoteDataSource
  Future<Map<String, dynamic>> signInStudent({
    required String grNumber,
    required String schoolCode,
    required String password,
  }) async {
    try {
      final token = await GetDeviceToken();
      // Dual-key untuk backward-compatibility (backend fallback:
      // nisn <- nis <- gr_number <- admission_no; device_token <- fcm_id).
      // school_code wajib untuk multi-tenant resolve ke DB sekolah yang tepat.
      final body = {
        "nisn": grNumber,
        "gr_number": grNumber,
        "password": password,
        "school_code": schoolCode,
        "device_token": token,
        "fcm_id": token,
        "platform": "android",
      };

      debugPrint(body.toString());

      final result = await ApiJson.post(
        body: body,
        url: Api.studentLogin,
      );

      debugPrint("OK 0");
      final data = result['data'] as Map<String, dynamic>;
      debugPrint("OK 1");

      // Extrapolate school code if available in response, fallback to the schoolCode used to login
      String finalSchoolCode = schoolCode;
      if (data['school'] != null && data['school']['code'] != null) {
        finalSchoolCode = data['school']['code'];
      } else if (data['user'] != null &&
          data['user']['school'] != null &&
          data['user']['school']['code'] != null) {
        finalSchoolCode = data['user']['school']['code'];
      }

      final studentData = data['user'] as Map<String, dynamic>? ?? data;
      final student = Student.fromJson(studentData);

      // Token might be at the root of the response, or nested under data['user']
      final tokenResult = result['token'] ??
          data['token'] ??
          (data['user'] != null ? data['user']['token'] : null);
          
      if (tokenResult == null || tokenResult.toString().isEmpty) {
        debugPrint("ERROR: Backend did not return a token! Response: $result");
        throw ApiException("Gagal masuk: Backend tidak mengirimkan token keamanan.");
      }

      return {
        "jwtToken": tokenResult,
        "schoolCode": finalSchoolCode,
        "student": student
      };
    } catch (e) {
      debugPrint("!!!!");
      debugPrint(e.toString());
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> signInParent({
    required String email,
    required String password,
  }) async {
    try {
      final token = await GetDeviceToken();
      // Dual-key device_token + fcm_id untuk backward-compatibility.
      final body = {
        "password": password,
        "email": email,
        "device_token": token,
        "fcm_id": token,
        "platform": "android",
      };

      debugPrint("DEBUG signInParent: Sending request with body: $body");

      final result =
          await ApiJson.post(body: body, url: Api.parentLogin);

      debugPrint("DEBUG signInParent: Raw API response: $result");

      final parentData = result['data'] as Map<String, dynamic>;
      debugPrint("DEBUG signInParent: Parent data: $parentData");
      debugPrint(
          "DEBUG signInParent: Children from API: ${parentData['children']}");

      // Let's examine the exact structure of each child object
      final childrenList = parentData['children'] as List? ?? [];
      for (int i = 0; i < childrenList.length; i++) {
        final child = childrenList[i];
        debugPrint("DEBUG signInParent: Child $i full structure: $child");
        debugPrint("DEBUG signInParent: Child $i token: ${child['token']}");
        debugPrint(
            "DEBUG signInParent: Child $i school_code: ${child['school_code']}");
        debugPrint("DEBUG signInParent: Child $i user: ${child['user']}");
        debugPrint("DEBUG signInParent: Child $i school: ${child['school']}");
        if (child['user'] != null) {
          debugPrint(
              "DEBUG signInParent: Child $i user.school: ${child['user']['school']}");
        }
      }

      final children = (parentData['children'] as List? ?? []).map((child) {
        debugPrint("DEBUG signInParent: Processing child: $child");

        // Create a mutable map from child data
        final childMap = Map<String, dynamic>.from(child);

        // Get token and school_code from various possible locations
        final childToken = child['token'] as String?;
        final childSchoolCode = child['school_code'] as String? ??
            child['user']?['school']?['code'] as String? ??
            child['school']?['code'] as String?;

        debugPrint(
            "DEBUG signInParent: Child token: '$childToken', school code: '$childSchoolCode'");

        // Ensure token and school_code are properly set in child data
        childMap['token'] = childToken;
        childMap['school_code'] = childSchoolCode;

        // Also set the school code in the user.school.code path for compatibility
        if (childSchoolCode != null) {
          if (childMap['user'] == null) childMap['user'] = <String, dynamic>{};
          if (childMap['user']['school'] == null)
            childMap['user']['school'] = <String, dynamic>{};
          childMap['user']['school']['code'] = childSchoolCode;

          if (childMap['school'] == null)
            childMap['school'] = <String, dynamic>{};
          childMap['school']['code'] = childSchoolCode;
        }

        debugPrint(
            "DEBUG signInParent: Final child map schoolCode fields: school_code='${childMap['school_code']}', school.code='${childMap['school']?['code']}', user.school.code='${childMap['user']?['school']?['code']}'");

        final student = Student.fromJson(childMap);
        debugPrint(
            "DEBUG signInParent: Parsed student - name: ${student.getFullName()}, token: '${student.token}', schoolCode: '${student.schoolCode}', school.code: '${student.school?.code}'");

        return student;
      }).toList();

      final parent = Guardian.fromJson(Map.from(parentData));
      
      final parentToken = result['token']?.toString() ?? 
                          parentData['token']?.toString() ?? 
                          (parentData['user'] != null ? parentData['user']['token']?.toString() : null);

      if (parentToken != null && parentToken.isNotEmpty) {
        await setParentJwtToken(parentToken);
      }

      final result_map = {
        "jwtToken": parentToken ?? (children.isNotEmpty ? children.first.token ?? "" : ""),
        "schoolCode": children.isNotEmpty
            ? (children.first.schoolCode ?? children.first.school?.code ?? "")
            : "",
        "parent": parent,
        "children": children,
      };

      debugPrint(
          "DEBUG signInParent: Final result map: jwtToken='${result_map["jwtToken"]}', schoolCode='${result_map["schoolCode"]}', children count=${children.length}");

      return result_map;
    } catch (e) {
      debugPrint("DEBUG signInParent: Error occurred: $e");
      throw ApiException(e.toString());
    }
  }

  Future<void> requestOtp({
    required String identifier,
  }) async {
    try {
      final body = {
        "identifier": identifier,
      };
      await Api.post(
        body: body,
        url: Api.requestOtp,
        useAuthToken: false,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String otpCode,
  }) async {
    try {
      final token = await GetDeviceToken();
      final body = {
        "identifier": identifier,
        "otp_code": otpCode,
        "otp": otpCode,
        "code": otpCode,
        "otpCode": otpCode,
        "fcm_id": token,
      };
      final result = await Api.post(
        body: body,
        url: Api.verifyOtp,
        useAuthToken: false,
      );

      final data = result['data'] as Map<String, dynamic>;
      final tokenResult = result['token']?.toString() ?? 
                          data['token']?.toString() ?? 
                          result['data']?['token']?.toString() ??
                          (data['user'] != null ? data['user']['token']?.toString() : null);

      // Check roles and user_type for user type (student/parent)
      final roles = (data['roles'] ?? data['user']?['roles']) as List? ?? [];

      String userRole = '';
      if (roles.isNotEmpty) {
        final firstRole = roles[0];
        if (firstRole is Map) {
          userRole = (firstRole['name'] ?? firstRole['slug'] ?? '')
              .toString()
              .toLowerCase();
        } else {
          userRole = firstRole.toString().toLowerCase();
        }
      }

      final hasChildren = (data['children'] != null &&
              (data['children'] as List).isNotEmpty) ||
          (data['user']?['children'] != null &&
              (data['user']['children'] as List).isNotEmpty) ||
          (data['students'] != null && (data['students'] as List).isNotEmpty) ||
          (data['user']?['students'] != null &&
              (data['user']['students'] as List).isNotEmpty);

      final apiUserType =
          (data['user_type'] ?? data['user']?['user_type'] ?? '')
              .toString()
              .toLowerCase();

      debugPrint("DEBUG verifyOtp roles: $roles, parsedUserRole: '$userRole'");
      debugPrint(
          "DEBUG verifyOtp apiUserType: '$apiUserType', hasChildren: $hasChildren");

      final isParent = userRole == 'guardian' ||
          userRole == 'parent' ||
          apiUserType == 'guardian' ||
          apiUserType == 'parent' ||
          hasChildren;

      final isStudent = !isParent;
      final userType = isStudent ? 'student' : 'parent';

      debugPrint(
          "DEBUG verifyOtp final detected - isParent: $isParent, isStudent: $isStudent, userType: '$userType'");

      // Parse school details (supports Map or List)
      final schoolData = data['school'] ?? data['schools'];
      List<Map<String, dynamic>> schools = [];
      String schoolCode = '';
      if (schoolData is List) {
        schools = List<Map<String, dynamic>>.from(
            schoolData.map((e) => Map<String, dynamic>.from(e)));
        if (schools.isNotEmpty) {
          schoolCode = schools.first['code'] ?? '';
        }
      } else if (schoolData is Map) {
        schools = [Map<String, dynamic>.from(schoolData)];
        schoolCode = schoolData['code'] ?? '';
      }

      Student student = Student.fromJson({});
      Guardian parent = Guardian.fromJson({});
      List<Student> children = [];

      if (isParent) {
        final rawParent = Guardian.fromJson(Map.from(data['user'] ?? data));

        final childrenList = (data['user']?['children'] ??
                data['children'] ??
                data['user']?['students'] ??
                data['students']) as List? ??
            [];
        children = childrenList.map((child) {
          final childMap = Map<String, dynamic>.from(child);
          childMap['token'] = tokenResult;
          childMap['school_code'] = schoolCode;
          return Student.fromJson(childMap);
        }).toList();

        // Enforce parent to have the parsed children list in its model
        parent = rawParent.copyWith(children: children);
        if (tokenResult != null && tokenResult.isNotEmpty) {
          await setParentJwtToken(tokenResult);
        }
      } else {
        final studentData = data['user'] as Map<String, dynamic>? ?? data;
        student = Student.fromJson(studentData);
      }

      return {
        "jwtToken": tokenResult ?? "",
        "userType": userType,
        "schoolCode": schoolCode,
        "schools": schools,
        "student": student,
        "parent": parent,
        "children": children,
      };
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> resetPasswordRequest(
      {required String grNumber,
      required DateTime dob,
      required String schoolCode}) async {
    try {
      final body = {
        "gr_no": grNumber,
        "dob": DateFormat('yyyy-MM-dd').format(dob),
      };
      await Api.post(
        body: body,
        url: Api.requestResetPassword,
        useAuthToken: false,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newConfirmedPassword,
  }) async {
    try {
      final body = {
        "current_password": currentPassword,
        "new_password": newPassword,
        "new_password_confirmation": newConfirmedPassword
      };
      
      final isStudent = getIsStudentLogIn();
      final parentToken = getParentJwtToken();
      final customToken = (!isStudent && parentToken.isNotEmpty) ? parentToken : null;

      await Api.post(
        body: body,
        url: Api.changePassword,
        useAuthToken: true,
        customToken: customToken,
      );
    } catch (e) {
      debugPrint("Bapak Mulyono, Raja Tipu Tipu");
      debugPrint("Mobil ESEMKA hanyalah salah satu");
      debugPrint(e.toString());

      throw ApiException(e.toString());
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      final body = {"email": email};
      await Api.post(body: body, url: Api.forgotPassword, useAuthToken: false);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
