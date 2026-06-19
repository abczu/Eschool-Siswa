import 'dart:convert';

import 'package:eschool/app/GlobalAppLifecycleObserver.dart';
import 'package:eschool/app/app.dart';
import 'package:eschool/utils/academic/ExamSubmitSyncService.dart';
import 'package:eschool/utils/system/inAppBanner.dart';
import 'package:eschool/utils/system/logHelper.dart';
import 'package:eschool/utils/system/hiveBoxKeys.dart';
import 'package:eschool/utils/system/vibrationHelper.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///[V.1.4.1]
///
///
///
///
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print("Pesan background: ${message.notification?.title}");
// }

Future<void> main() async {
  timeago.setLocaleMessages('id', timeago.IdMessages());
  await initializeDateFormatting('id');
  Encoding.getByName('utf-8');

  await initializeApp();

  // Setup FCM notification listener
  await setupFCM();

  // pasang observer global
  GlobalAppLifecycleObserver.install();

  // cold start: coba sync jawaban yang tersimpan
  await ExamSubmitSyncService.syncIfCached();
}

// Setup FCM notification listener & permission
Future<void> setupFCM() async {
  // Init Firebase kalau belum (aman dari freeze karena dipanggil setelah runApp)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }

  // Izin notifikasi (Android 13+ & iOS)
  await FirebaseMessaging.instance.requestPermission();

  // --- DEBUG TOKEN ---
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('=========================================');
    debugPrint('📍 TOKEN HP SAYA (Copy ini):');
    debugPrint(token ?? 'Gagal ambil token');
    debugPrint('=========================================');
  } catch (e) {
    debugPrint('❌ Error ambil token: $e');
  }
  // ------------------

  // Foreground: tampilkan banner non-modal (tanpa context)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    logRemoteMessageAndroid(message, tag: 'FCM-OPENED');

    // ✅ CEK STATUS LOGIN: Hanya tampilkan notifikasi jika user sudah login
    try {
      final authBox = Hive.box(authBoxKey);
      final isLoggedIn = authBox.get(isLogInKey) ?? false;

      if (!isLoggedIn) {
        debugPrint('🚫 FCM: User belum login, notifikasi tidak ditampilkan');
        debugPrint(
            '📨 FCM: Notifikasi diterima: ${message.notification?.title}');
        return; // Skip tampilkan notifikasi
      }

      debugPrint('✅ FCM: User sudah login, tampilkan notifikasi');
    } catch (e) {
      debugPrint('⚠️ FCM: Error saat cek status login: $e');
      // Jika error, amankan dengan tidak tampilkan notifikasi
      return;
    }

    // Use VibrationHelper that respects user settings
    await VibrationHelper.notificationVibration();
    final type = (message.data['type'] ?? '')
        .toString(); // 'announcement' | 'izin' | 'tagihan' | 'tugas' | ...
    final title = (message.notification?.title ?? 'Notifikasi').toString();
    final body = (message.notification?.body ?? '').toString();

    print("typeeee" + type);
    // mapping type -> style
    final PushType style = mapPushType(type, status: message.data['status']);
    final String? route = mapPushRoute(type, payload: message.data);

    // ✅ tampilkan banner non-modal (tanpa BuildContext)
    showPushBanner(
      title: title,
      body: body,
      type: style,
      onTap: () {
        if (route != null) {
          // ✅ Enhance arguments dengan childId jika user adalah parent
          final enhancedArguments = _enhanceNotificationArguments(message.data);
          Get.toNamed(route, arguments: enhancedArguments);
        }
      },
    );

    // contoh: kalau perlu update state lokal berdasarkan type/id, lakukan di sini
  });
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationClick(message);
  });

  // Handle cold start (app benar2 dari mati)
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _handleNotificationClick(initialMessage);
  }
}

void _handleNotificationClick(RemoteMessage message) {
  logRemoteMessageAndroid(message, tag: 'FCM-CLICK');

  final type = (message.data['type'] ?? '').toString();
  final route = mapPushRoute(type, payload: message.data);

  // ✅ Tunggu sampai GetMaterialApp dan routes benar-benar siap
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Delay untuk memastikan routing sudah ter-register
    Future.delayed(const Duration(milliseconds: 500), () {
      // ✅ CEK STATUS LOGIN: Hanya navigasi jika user sudah login
      try {
        final authBox = Hive.box(authBoxKey);
        final isLoggedIn = authBox.get(isLogInKey) ?? false;

        if (!isLoggedIn) {
          debugPrint('🚫 FCM-CLICK: User belum login, navigasi dibatalkan');
          debugPrint(
              '📨 FCM-CLICK: Notifikasi: ${message.notification?.title}');

          // ✅ SIMPAN notifikasi untuk dibuka setelah login
          if (route != null) {
            final enhancedArguments =
                _enhanceNotificationArguments(message.data);
            authBox.put(pendingNotificationRouteKey, route);
            authBox.put(pendingNotificationArgumentsKey, enhancedArguments);
            debugPrint(
                '💾 FCM-CLICK: Notifikasi disimpan untuk dibuka setelah login');
            debugPrint(
                '💾 FCM-CLICK: Route: $route, Arguments: $enhancedArguments');
          }

          // Jangan navigasi ke route, biarkan user tetap di halaman login
          return;
        }

        debugPrint('✅ FCM-CLICK: User sudah login, lanjut navigasi ke: $route');
      } catch (e) {
        debugPrint('⚠️ FCM-CLICK: Error saat cek status login: $e');
        // Jika error, amankan dengan tidak navigasi
        return;
      }

      if (route != null) {
        // ✅ Enhance arguments dengan childId jika user adalah parent
        final enhancedArguments = _enhanceNotificationArguments(message.data);
        Get.toNamed(route, arguments: enhancedArguments);
      } else {
        showAnnouncementDialog(
            message.notification?.title, message.notification?.body);
      }
    });
  });
}

/// Enhance notification arguments dengan childId untuk parent
Map<String, dynamic> _enhanceNotificationArguments(Map<String, dynamic> data) {
  try {
    final authBox = Hive.box(authBoxKey);
    final isStudent = authBox.get(isStudentLogInKey) ?? false;

    // Jika student, return data as is
    if (isStudent) {
      debugPrint('📱 User adalah student, tidak perlu enhance');
      return data;
    }

    // Jika parent, inject childId dari active child
    debugPrint('👨‍👩‍👧 User adalah parent, inject childId...');

    // Ambil data children dari Hive
    final childrenData = authBox.get(childrenDataKey) ?? [];
    if (childrenData is List && childrenData.isNotEmpty) {
      // Ambil child pertama sebagai default (atau bisa ambil active child)
      final firstChild = childrenData.first;
      final childId = firstChild['id'];

      debugPrint('✅ ChildId ditemukan: $childId');

      // Return enhanced arguments dengan childId
      return {
        ...data,
        'childId': childId,
      };
    } else {
      debugPrint('⚠️ Parent tidak punya children data');
    }
  } catch (e) {
    debugPrint('⚠️ Error saat enhance arguments: $e');
  }

  // Fallback: return data as is
  return data;
}

int? _normalizeLeaveStatus(dynamic status) {
  // dukung int atau string
  if (status == null) return null;
  if (status is int) return status;

  final s = status.toString().trim().toLowerCase();
  switch (s) {
    case '1':
    case 'approved':
    case 'disetujui':
      return 1;
    case '2':
    case 'pending':
    case 'tertunda':
      return 2;
    case '3':
    case 'rejected':
    case 'ditolak':
      return 3;
    default:
      return null;
  }
}

PushType mapPushType(String? rawType, {dynamic status}) {
  // normalisasi: null → "", trim, lowercase, '-' -> '_'
  final key = (rawType ?? '').trim().toLowerCase().replaceAll('-', '_');

  return switch (key) {
    // Assignment / Tugas
    'assignment_created' || 'assignment_updated' || 'tugas' => PushType.info,

    // Pembayaran / Tagihan
    'payment_status_changed' => PushType.info,
    'tagihan' => PushType.warning,

    // Attendance
    'attendance_update' => PushType.info,
    'attendance_marked' => PushType.success,

    // Exam (luring)
    'exam_created' => PushType.info,
    'exam_result_published' => PushType.success,
    'exam_marks_updated' => PushType.info,

    // Online Exam
    'online_exam_created' => PushType.success,
    'online_exam_updated' => PushType.info,
    'online_exam_cancelled' => PushType.error,
    'online_exam_questions_ready' => PushType.success,
    'online_exam_corrected' => PushType.success,

    // Leave (perizinan)
    'leave_approved' => PushType.success,
    'leave_rejected' => PushType.error,
    // 'staff_leave_approved' => PushType.success,
    // 'staff_leave_rejected' => PushType.error,
    'leave_status' => switch (_normalizeLeaveStatus(status)) {
        1 => PushType.success, // disetujui
        2 => PushType.warning, // tertunda
        3 => PushType.error, // ditolak
        _ => PushType.info, // fallback aman (jangan warning)
      },

    // Lesson
    'lesson_created' || 'lesson_updated' => PushType.info,

    // Lesson Topic
    'topic_created' || 'topic_updated' => PushType.info,

    // Announcement
    'announcement_created' || 'announcement_updated' => PushType.info,

    // Promote / Transfer
    'student_promoted' => PushType.success,
    'student_transferred' => PushType.warning,

    // Default
    _ => PushType.success,
  };
}

/// Pemetaan rawType -> route GetX (string nama route)
String? mapPushRoute(String? rawType, {dynamic payload}) {
  final key = (rawType ?? '').trim().toLowerCase().replaceAll('-', '_');

  return switch (key) {
    // Assignment / Tugas
    'assignment_created' ||
    'assignment_updated' ||
    'assignment_new' ||
    'assignment_update' ||
    'tugas' =>
      '/childAssignments',

    // Pembayaran / Tagihan
    'payment_status_changed' || 'tagihan' => '/payment-history',

    // Attendance
    'attendance_update' || 'attendance_marked' => '/childAttendance',

    // Exam
    'exam_created' ||
    'exam_result_published' ||
    'exam_marks_updated' =>
      '/exam',

    // Online Exam - arahkan ke exam list (bukan exam taking screen)
    'online_exam_created' ||
    'online_exam_updated' ||
    'online_exam_questions_ready' ||
    'online_exam_corrected' ||
    'online_exam_cancelled' =>
      '/exam',

    // Leave
    'leave_approved' || 'leave_rejected' || 'leave_status' => '/childLeaves',

    // Lesson - arahkan ke home karena perlu Subject object lengkap
    'lesson_created' || 'lesson_updated' => '/',

    // Lesson Topic - arahkan ke home karena perlu Topic object lengkap
    'topic_created' || 'topic_updated' => '/',

    // Announcement
    'announcement_created' || 'announcement_updated' => '/noticeBoard',

    // Promote / Transfer
    'student_promoted' || 'student_transferred' => '/studentProfile',

    // Default
    _ => null, // biarkan null kalau tidak ada mapping
  };
}

// Fungsi untuk menampilkan dialog pengumuman
void showAnnouncementDialog(String? title, String? body) {
  // Pastikan context global tersedia, atau gunakan Get.dialog jika pakai GetX
  Get.dialog(
    AlertDialog(
      title: Text(title ?? 'Pengumuman'),
      content: Text(body ?? ''),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Tutup'),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}
