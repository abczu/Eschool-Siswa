import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/auth/guardian.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/data/repositories/student/studentRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract class AuthState extends Equatable {}

class AuthInitial extends AuthState {
  @override
  List<Object?> get props => [];
}

class Unauthenticated extends AuthState {
  @override
  List<Object?> get props => [];
}

class Authenticated extends AuthState {
  final String jwtToken;
  final bool isStudent;
  final Student student;
  final Guardian parent;
  final String schoolCode;
  final List<Student> children;

  Authenticated({
    required this.jwtToken,
    required this.isStudent,
    required this.student,
    required this.parent,
    required this.schoolCode,
    this.children = const [],
  });

  @override
  List<Object?> get props => [
        jwtToken,
        isStudent,
        student,
        parent,
        schoolCode,
        children,
      ];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit(this.authRepository) : super(AuthInitial()) {
    _checkIsAuthenticated();
  }

  void _checkIsAuthenticated() {
    debugPrint("DEBUG: _checkIsAuthenticated called");
    debugPrint("DEBUG: getIsLogIn() = ${authRepository.getIsLogIn()}");

    if (authRepository.getIsLogIn()) {
      // Load children data from persistence storage
      final storedChildren = AuthRepository.getChildrenData();

      // --- Evict profile images from cache to ensure fresh image on app startup ---
      try {
        final isStudent = AuthRepository.getIsStudentLogIn();
        if (isStudent) {
          final student = AuthRepository.getStudentDetails();
          if (student.image != null && student.image!.isNotEmpty) {
            DefaultCacheManager().removeFile(student.image!);
          }
        } else {
          final parent = AuthRepository.getParentDetails();
          if (parent.image != null && parent.image!.isNotEmpty) {
            DefaultCacheManager().removeFile(parent.image!);
          }
          for (var child in storedChildren) {
            if (child.image != null && child.image!.isNotEmpty) {
              DefaultCacheManager().removeFile(child.image!);
            }
            if (child.childUserDetails?.image != null && child.childUserDetails!.image!.isNotEmpty) {
              DefaultCacheManager().removeFile(child.childUserDetails!.image!);
            }
          }
        }
      } catch (e) {
         debugPrint("Error evicting cache: $e");
      }
      // ----------------------------------------------------------------------

    debugPrint("DEBUG: storedChildren count = ${storedChildren.length}");

      // For parent login, get the current active child's token and school code
      String currentSchoolCode = authRepository.schoolCode;
      String currentJwtToken = authRepository.getJwtToken();
    debugPrint("DEBUG: currentSchoolCode from storage = '$currentSchoolCode'");
    debugPrint(
          "DEBUG: currentJwtToken from storage = '${currentJwtToken.isEmpty ? 'EMPTY' : 'HAS_VALUE'}'");

      Student currentStudent = Student.fromJson({});

      if (!AuthRepository.getIsStudentLogIn() && storedChildren.isNotEmpty) {
    debugPrint(
            "DEBUG: Processing parent login with ${storedChildren.length} children");

        // Find the active child based on stored token/schoolCode or use first child
        final activeChild = storedChildren.firstWhere(
          (child) =>
              child.token == currentJwtToken ||
              child.schoolCode == currentSchoolCode,
          orElse: () => storedChildren.first,
        );
    debugPrint(
            "DEBUG: activeChild = ${activeChild.getFullName()}, token=${activeChild.token?.isEmpty == true ? 'EMPTY' : 'HAS_VALUE'}, schoolCode=${activeChild.schoolCode}");

        // Update with active child's credentials if they exist
        if (activeChild.token != null && activeChild.token!.isNotEmpty) {
          currentJwtToken = activeChild.token!;
          authRepository.setJwtToken(currentJwtToken);
    debugPrint("DEBUG: Updated token to active child's token");
        } else {
    debugPrint("DEBUG: Active child has no token!");
        }

        if (activeChild.schoolCode != null &&
            activeChild.schoolCode!.isNotEmpty) {
          currentSchoolCode = activeChild.schoolCode!;
          authRepository.schoolCode = currentSchoolCode;
    debugPrint(
              "DEBUG: Updated schoolCode to active child's schoolCode: $currentSchoolCode");
        } else if (activeChild.school?.code != null &&
            activeChild.school!.code!.isNotEmpty) {
          currentSchoolCode = activeChild.school!.code!;
          authRepository.schoolCode = currentSchoolCode;
    debugPrint(
              "DEBUG: Updated schoolCode from school object: $currentSchoolCode");
        } else {
    debugPrint("DEBUG: Active child has no school code!");
        }

        currentStudent = activeChild;
      } else if (AuthRepository.getIsStudentLogIn()) {
    debugPrint("DEBUG: Processing student login");
        currentStudent = AuthRepository.getStudentDetails();
      } else {
    debugPrint("DEBUG: No children found or not parent login");
      }
    debugPrint(
          "DEBUG: Final values - schoolCode: '$currentSchoolCode', token: '${currentJwtToken.isEmpty ? 'EMPTY' : 'HAS_VALUE'}'");

      emit(
        Authenticated(
          schoolCode: currentSchoolCode,
          jwtToken: currentJwtToken,
          isStudent: AuthRepository.getIsStudentLogIn(),
          parent: AuthRepository.getIsStudentLogIn()
              ? Guardian.fromJson({})
              : AuthRepository.getParentDetails(),
          student: currentStudent,
          children: storedChildren, // Load children from storage
        ),
      );
    } else {
    debugPrint("DEBUG: User not logged in");
      emit(Unauthenticated());
    }
  }

  void authenticateUser({
    required String schoolCode,
    required String jwtToken,
    required bool isStudent,
    required Guardian parent,
    required Student student,
    List<Student> children = const [],
  }) {
    debugPrint(
        "DEBUG authenticateUser: schoolCode='$schoolCode', jwtToken='${jwtToken.isEmpty ? 'EMPTY' : 'HAS_VALUE'}', isStudent=$isStudent");
    debugPrint("DEBUG authenticateUser: children count=${children.length}");

    //
    authRepository.schoolCode = schoolCode;
    authRepository.setJwtToken(jwtToken);
    if (!isStudent) {
      authRepository.setParentJwtToken(jwtToken);
    }
    authRepository.setIsLogIn(true);
    authRepository.setIsStudentLogIn(isStudent);
    authRepository.setStudentDetails(student);
    authRepository.setParentDetails(parent);

    // Save children data to persistence storage
    if (children.isNotEmpty) {
    debugPrint("DEBUG authenticateUser: Saving children to persistence...");
      authRepository.setChildrenData(children);
    } else {
    debugPrint("DEBUG authenticateUser: No children to save");
    }

    //emit new state
    emit(
      Authenticated(
        schoolCode: schoolCode,
        jwtToken: jwtToken,
        isStudent: isStudent,
        student: student,
        parent: parent,
        children: children,
      ),
    );
    debugPrint("DEBUG authenticateUser: Authentication completed");
  }

  // Method to switch to a specific child session
  void switchToChildSession(Student child) {
    debugPrint(
        "DEBUG switchToChildSession: Switching to child ${child.getFullName()}");
    debugPrint(
        "DEBUG switchToChildSession: Child token='${child.token}', schoolCode='${child.schoolCode}', school.code='${child.school?.code}'");

    if (state is Authenticated) {
      final currentState = state as Authenticated;

      // Update the token and school code for the selected child
      // Use schoolCode field first, then fallback to school?.code
      final childSchoolCode = child.schoolCode ?? child.school?.code ?? '';
      final childToken = child.token ?? '';
    debugPrint(
          "DEBUG switchToChildSession: Setting token='$childToken', schoolCode='$childSchoolCode'");

      // Set the token and school code synchronously
      authRepository.setJwtToken(childToken);
      authRepository.schoolCode = childSchoolCode;

      // Also update the child object to ensure it has the latest data
      final updatedChild = child.copyWith(
        token: childToken,
        schoolCode: childSchoolCode,
      );

      // Update children list with the latest data
      final updatedChildren = currentState.children
          .map((c) => c.id == child.id ? updatedChild : c)
          .toList();

      // Save updated children data immediately
      authRepository.setChildrenData(updatedChildren);
    debugPrint(
          "DEBUG switchToChildSession: Verifying persistence - token='${authRepository.getJwtToken()}', schoolCode='${authRepository.schoolCode}'");

      emit(
        Authenticated(
          schoolCode: childSchoolCode,
          jwtToken: childToken,
          isStudent: false, // Parent viewing child data
          student: updatedChild,
          parent: currentState.parent,
          children: updatedChildren,
        ),
      );
    debugPrint("DEBUG switchToChildSession: Switch completed");
    }
  }

  Student getStudentDetails() {
    if (state is Authenticated) {
      return (state as Authenticated).student;
    }
    return Student.fromJson({});
  }

  Guardian getParentDetails() {
    if (state is Authenticated) {
      return (state as Authenticated).parent;
    }
    return Guardian.fromJson({});
  }

  bool isParent() {
    if (state is Authenticated) {
      return !(state as Authenticated).isStudent;
    }
    return false;
  }

  void signOut() {
    authRepository.signOutUser();
    emit(Unauthenticated());
  }

  void forceSignOut() {
    signOut();
  }

  int getUserId() {
    if (state is Authenticated) {
      if ((state as Authenticated).isStudent) {
        return (state as Authenticated).student.id!;
      } else {
        return (state as Authenticated).parent.id!;
      }
    }
    throw Exception("User is not authenticated");
  }

  // Get list of children for parent
  List<Student> getChildren() {
    if (state is Authenticated) {
      return (state as Authenticated).children;
    }
    return [];
  }

  // Get current selected child
  Student getCurrentChild() {
    if (state is Authenticated) {
      return (state as Authenticated).student;
    }
    return Student.fromJson({});
  }

  /// Update data parent yang baru (hasil dari API update profil)
  void updateParentProfile(Guardian updated) {
    if (state is! Authenticated) return;
    final s = state as Authenticated;
    debugPrint("UBAH PROFILE PARENT DI AUTH CUBIT");
    // merge semua field: gunakan copyWith
    final merged = s.parent.copyWith(
      id: updated.id,
      firstName: updated.firstName,
      lastName: updated.lastName,
      mobile: updated.mobile,
      email: updated.email,
      gender: updated.gender,
      image: updated.image,
      dob: updated.dob,
      currentAddress: updated.currentAddress,
      permanentAddress: updated.permanentAddress,
      occupation: updated.occupation,
      status: updated.status,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
      fullName: updated.fullName,
    );

    // simpan ke storage juga biar persisten
    authRepository.setParentDetails(merged);

    // emit ulang state Authenticated
    emit(Authenticated(
      jwtToken: s.jwtToken,
      isStudent: s.isStudent,
      student: s.student,
      parent: merged,
      schoolCode: s.schoolCode,
      children: s.children,
    ));
  }

  /// Refresh semua profile image dari cache (dipanggil saat terima notif profile_updated)
  Future<void> refreshProfileImage() async {
    if (state is! Authenticated) return;
    final s = state as Authenticated;

    // Coba ambil data terbaru dari server agar URL gambar yang baru didapat
    Student updatedStudent = s.student;
    Guardian updatedParent = s.parent;
    List<Student> updatedChildren = s.children;

    debugPrint("🔍 [REFRESH PROFILE] Awal - Parent Image: '${s.parent.image}'");

    try {
      if (s.isStudent) {
        final freshStudent = await StudentRepository().fetchStudentFullProfileDetails(useParentApi: false);
        updatedStudent = freshStudent;
      } else {
        // Fetch all children in parallel to save time
        final futures = s.children.map((child) async {
          try {
            final freshChild = await StudentRepository().fetchStudentFullProfileDetails(useParentApi: true, childId: child.id);
            
            final mergedChild = freshChild.copyWith(
              schoolName: freshChild.schoolName ?? child.schoolName,
              schoolCode: freshChild.schoolCode ?? child.schoolCode,
              token: freshChild.token ?? child.token,
              childUserDetails: (freshChild.childUserDetails?.id == null && child.childUserDetails != null)
                  ? child.childUserDetails!.copyWith(image: freshChild.image ?? child.childUserDetails!.image)
                  : freshChild.childUserDetails?.copyWith(image: freshChild.childUserDetails?.image ?? freshChild.image) ?? child.childUserDetails,
              guardian: freshChild.guardian?.id == null ? child.guardian : freshChild.guardian,
              school: freshChild.school?.id == null ? child.school : freshChild.school,
            );
            return mergedChild;
          } catch (e) {
            debugPrint("Failed to fetch profile for child ${child.id}: $e");
            return child; // Fallback to existing data if fetch fails
          }
        });

        final freshChildrenList = await Future.wait(futures);
        updatedChildren = freshChildrenList.toList();
        
        // Find if parent image needs update from any of the merged children
        for (var mergedChild in updatedChildren) {
          if (mergedChild.guardian != null && mergedChild.guardian!.id == s.parent.id) {
            if (mergedChild.guardian!.image != null && mergedChild.guardian!.image!.isNotEmpty) {
              updatedParent = updatedParent.copyWith(
                image: mergedChild.guardian!.image,
              );
              break;
            }
          }
        }

        // Update selected student if it exists
        updatedStudent = updatedChildren.firstWhere((c) => c.id == s.student.id, orElse: () => s.student);
      }
    } catch (e) {
      debugPrint("⚠️ Gagal mengambil data profil terbaru dari server, menggunakan fallback data lama: $e");
    }

    updatedParent = updatedParent.copyWith(
      children: updatedChildren,
    );

    debugPrint("🔍 [REFRESH PROFILE] Akhir - Parent Image: '${updatedParent.image}'");

    // Simpan ke persistence
    if (s.isStudent) {
      authRepository.setStudentDetails(updatedStudent);
    } else {
      authRepository.setParentDetails(updatedParent);
      authRepository.setChildrenData(updatedChildren);
    }

    emit(Authenticated(
      jwtToken: s.jwtToken,
      isStudent: s.isStudent,
      student: updatedStudent,
      parent: updatedParent,
      schoolCode: s.schoolCode,
      children: updatedChildren,
    ));
    debugPrint("✅ Profile image refreshed via FCM notification");
  }

  /// Khusus update foto (cache-buster biar tidak ketahan cache lama)
  void updateParentImage(String newUrl) {
    if (state is! Authenticated) return;
    final s = state as Authenticated;

    String busted = newUrl;
    try {
      final uri = Uri.parse(newUrl);
      final queryParams = Map<String, dynamic>.from(uri.queryParameters);
      queryParams['v'] = DateTime.now().millisecondsSinceEpoch.toString();
      busted = uri.replace(queryParameters: queryParams).toString();
    } catch (_) {}

    final merged = s.parent.copyWith(image: busted);

    authRepository.setParentDetails(merged);

    emit(Authenticated(
      jwtToken: s.jwtToken,
      isStudent: s.isStudent,
      student: s.student,
      parent: merged,
      schoolCode: s.schoolCode,
      children: s.children,
    ));
  }
}


