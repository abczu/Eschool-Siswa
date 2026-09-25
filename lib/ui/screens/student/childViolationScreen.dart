import 'package:eschool/cubits/student/downloadParentViolationCubit.dart';
import 'package:eschool/cubits/student/parentViolationCubit.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/data/repositories/student/violationRepository.dart';
import 'package:eschool/ui/widgets/student/childViolationContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

/// Layar sisi Orang Tua: "Pelanggaran Anak".
/// Dibuka dari menu detail anak dengan argumen [Student].
/// Mendukung deep-link notifikasi FCM via `childId` / `student_id`.
class ChildViolationScreen extends StatelessWidget {
  final Student student;

  const ChildViolationScreen({Key? key, required this.student})
      : super(key: key);

  static Widget routeInstance() {
    final args = Get.arguments;
    late final Student student;

    if (args is Student) {
      student = args;
    } else if (args is Map) {
      final map = Map<String, dynamic>.from(args);
      if (map['student'] is Student) {
        student = map['student'] as Student;
      } else if (map['student'] is Map) {
        student = Student.fromJson(
            Map<String, dynamic>.from(map['student'] as Map));
      } else {
        // Dari notifikasi FCM: student_id / childId + fallback Hive
        student = _resolveStudentFromNotification(map);
      }
    } else {
      student = Student.fromJson({});
    }

    return ChildViolationScreen(student: student);
  }

  /// Resolve [Student] dari payload notifikasi (parent).
  /// Prioritas: student_id bawaan payload > childId hasil enhance > anak pertama.
  static Student _resolveStudentFromNotification(
      Map<String, dynamic> map) {
    try {
      final rawId = map['student_id'] ??
          map['studentId'] ??
          map['childId'] ??
          map['child_id'];
      final targetId =
          rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

      // Coba cocokkan dengan daftar anak di argumen (jika ada)
      final childrenRaw = map['children'];
      if (childrenRaw is List && targetId != null) {
        for (final e in childrenRaw) {
          if (e is Student && e.id == targetId) return e;
          if (e is Map) {
            final m = Map<String, dynamic>.from(e);
            if (m['id'] == targetId) return Student.fromJson(m);
          }
        }
      }

      // Fallback: bangun Student minimal agar API tetap bisa dipanggil
      if (targetId != null) {
        return Student.fromJson({'id': targetId});
      }
    } catch (_) {}
    return Student.fromJson({});
  }

  @override
  Widget build(BuildContext context) {
    final displayName = student.getFullName();
    return MultiBlocProvider(
      providers: [
        BlocProvider<ParentViolationCubit>(
          create: (_) => ParentViolationCubit(ViolationRepository()),
        ),
        BlocProvider<DownloadParentViolationCubit>(
          create: (_) =>
              DownloadParentViolationCubit(ViolationRepository()),
        ),
      ],
      child: Scaffold(
        body: ChildViolationContainer(
          studentId: student.id ?? 0,
          studentName: displayName,
        ),
      ),
    );
  }
}
