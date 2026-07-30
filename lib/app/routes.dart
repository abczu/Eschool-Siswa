import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/ui/screens/payment/payment/paymentHistoryTabScreen.dart';
import 'package:eschool/utils/system/hiveBoxKeys.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:eschool/ui/screens/system/aboutUsScreen.dart';
import 'package:eschool/ui/screens/academic/assignment/assignmentScreen.dart';
import 'package:eschool/ui/screens/auth/authScreen.dart';
import 'package:eschool/ui/screens/auth/parentLoginScreen.dart';
import 'package:eschool/ui/screens/auth/studentLoginScreen.dart';
import 'package:eschool/ui/screens/system/changePassword.dart';
import 'package:eschool/ui/screens/academic/chapterDetails/chapterDetailsScreen.dart';
import 'package:eschool/ui/screens/chat/chatScreen.dart';
import 'package:eschool/ui/screens/chatContacts/chatContactsScreen.dart';
import 'package:eschool/ui/screens/chatContacts/newChatContactsScreen.dart';
import 'package:eschool/ui/screens/academic/childAssignmentsScreen.dart';
import 'package:eschool/ui/screens/student/childAttendanceScreen.dart';
import 'package:eschool/ui/screens/student/childDetailMenuScreen.dart';
import 'package:eschool/ui/screens/student/childDetailsScreen.dart';
import 'package:eschool/ui/screens/payment/childFeeDetails/childFeeDetailsScreen.dart';
import 'package:eschool/ui/screens/payment/childFeesScreen.dart';
import 'package:eschool/ui/screens/student/childLeavesScreen.dart';
import 'package:eschool/ui/screens/academic/childResultsScreen.dart';
import 'package:eschool/ui/screens/academic/childSubjectAttendanceScreen.dart';
import 'package:eschool/ui/screens/student/childTeachers.dart';
import 'package:eschool/ui/screens/academic/childTimeTableScreen.dart';
import 'package:eschool/ui/screens/payment/payment/confirmPaymentScreen.dart';
import 'package:eschool/ui/screens/system/contactUsScreen.dart';
import 'package:eschool/ui/screens/exam/examTimeTableScreen.dart';
import 'package:eschool/ui/screens/exam/onlineExam/examOnlineScreen.dart';
import 'package:eschool/ui/screens/exam/examScreen.dart';
import 'package:eschool/ui/screens/system/faqsScreen.dart';
import 'package:eschool/ui/screens/system/galleryDetailsScreen.dart';
import 'package:eschool/ui/screens/academic/SubjectAttendanceAtDayScreen.dart';
import 'package:eschool/ui/screens/system/galleryImagesScreen.dart';
import 'package:eschool/ui/screens/system/holidaysScreen.dart';
import 'package:eschool/ui/screens/home/homeScreen.dart';
import 'package:eschool/ui/screens/system/noticeBoardScreen.dart';
import 'package:eschool/ui/screens/system/notificationsScreen.dart';
import 'package:eschool/ui/screens/home/parentHomeScreen.dart';
import 'package:eschool/ui/screens/profile/parentProfileScreen.dart';
import 'package:eschool/ui/screens/system/playVideo/playVideoScreen.dart';
import 'package:eschool/ui/screens/system/privacyPolicyScreen.dart';
import 'package:eschool/ui/screens/academic/reports/reportSubjectsContainer.dart';
import 'package:eschool/ui/screens/academic/reports/subjectWiseDetailedReport.dart';
import 'package:eschool/ui/screens/academic/resultOnline/resultOnlineScreen.dart';
import 'package:eschool/ui/screens/academic/resultScreen.dart';
import 'package:eschool/ui/screens/system/schoolGalleryScreen.dart';
import 'package:eschool/ui/screens/academic/selectSubjectsScreen.dart';
import 'package:eschool/ui/screens/system/settingsScreen.dart';
import 'package:eschool/ui/screens/system/splashScreen.dart';
import 'package:eschool/ui/screens/profile/studentProfileScreen.dart';
import 'package:eschool/ui/screens/academic/subjectDetails/subjectDetailsScreen.dart';
import 'package:eschool/ui/screens/system/termsAndConditionScreen.dart';
import 'package:eschool/ui/screens/academic/topicDetailsScreen.dart';
import 'package:eschool/ui/screens/payment/transactionsScreen.dart';
import 'package:eschool/cubits/auth/changePasswordCubit.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/ui/screens/system/contactScreen.dart';
import 'package:eschool/ui/screens/system/contactDetailScreen.dart';
import 'package:eschool/ui/screens/system/submitContactScreen.dart';
import 'package:eschool/ui/screens/extracurricular/extracurricularDetailsScreen.dart';
import 'package:get/route_manager.dart';

// ignore: avoid_classes_with_only_static_members
class Routes {
  static const String splash = "/splash";
  static const String home = "/";

  static const String auth = "/auth";
  static const String parentLogin = "/parentLogin";
  static const String studentLogin = "/studentLogin";
  static const String studentProfile = "/studentProfile";
  static const String assignment = "/assignment";

  static const String exam = "/exam";

  static const String examTimeTable = "/examTimeTable";

  static const String subjectDetails = "/subjectDetails";

  static const String chapterDetails = "/chapterDetails";

  static const String aboutUs = "/aboutUs";
  static const String privacyPolicy = "/privacyPolicy";

  static const String contactUs = "/contactUs";
  static const String faqs = "/faqs";

  static const String termsAndCondition = "/termsAndCondition";

  static const String selectSubjects = "/selectSubjects";
  static const String result = "/result";
  static const String parentHome = "/parent";

  static const String parentChildDetails = "/parent/studentDetails";

  static const String parentMenu = "/parent/studentDetailsMenu";

  static const String topicDetails = "/topicDetails";

  static const String playVideo = "/playVideo";

  static const String childAssignments = "/childAssignments";

  static const String childAttendance = "/childAttendance";

  static const String childTimeTable = "/childTimeTable";

  static const String childResults = "/childResults";

  static const String childTeachers = "/childTeachers";
  static const String childFees = "/childFees";
  static const String settings = "/settings";
  static const String changePassword = "/changePassword";
  static const String parentProfile = "/parentProfile";
  static const String noticeBoard = "/noticeBoard";
  static const String holidays = "/holidays";
  static const String subjectWiseReport = "/reportSubjectsContainer";
  static const String subjectWiseDetailedReport = "/subjectWiseDetailedReport";
  static const String examOnline = "/examOnline";
  static const String resultOnline = "/resultOnline";
  static const String childFeeDetails = "/childFeeDetails";
  static const String confirmPayment = "/confirmPayment";
  static const String transactions = "/transactions";
  static const String schoolGallery = "/schoolGallery";
  static const String galleryDetails = "/galleryDetails";
  static const String subjectAttendanceAtDay = "/subjectAttendanceAtDay";
  static const String galleryImages = "/galleryImages";
  static const String notifications = "/notifications";
  static const String chatContacts = "/chatContacts";
  static const String newChatContacts = "/newChatContacts";
  static const String chat = "/chat";

  // Fitur Baru Eschool versi 1.3.3 - Galang
  static const String childSubjectAttendance = "/childSubjectAttendance";
  static const String childLeaves = "/childLeaves";

  // Contact/Support routes
  static const String contacts = "/contacts";
  static const String contactDetails = "/contact-details";
  static const String submitContact = "/submit-contact";
  static const String extracurricularDetails = "/extracurricular-details";

  static List<GetPage> getPages = [
    GetPage(name: splash, page: () => SplashScreen.routeInstance()),
    GetPage(name: home, page: () => HomeScreen.routeInstance()),
    GetPage(name: auth, page: () => AuthScreen.routeInstance()),
    GetPage(name: studentLogin, page: () => StudentLoginScreen.routeInstance()),
    GetPage(name: parentLogin, page: () => ParentLoginScreen.routeInstance()),
    GetPage(name: parentHome, page: () => ParentHomeScreen.routeInstance()),
    GetPage(
        name: studentProfile, page: () => StudentProfileScreen.routeInstance()),
    GetPage(name: assignment, page: () => AssignmentScreen.routeInstance()),
    GetPage(name: exam, page: () => ExamScreen.routeInstance()),
    GetPage(
        name: examTimeTable, page: () => ExamTimeTableScreen.routeInstance()),
    GetPage(
        name: subjectDetails, page: () => SubjectDetailsScreen.routeInstance()),
    GetPage(
        name: chapterDetails, page: () => ChapterDetailsScreen.routeInstance()),
    GetPage(name: aboutUs, page: () => AboutUsScreen.routeInstance()),
    GetPage(
        name: privacyPolicy, page: () => PrivacyPolicyScreen.routeInstance()),
    GetPage(
        name: termsAndCondition,
        page: () => TermsAndConditionScreen.routeInstance()),
    GetPage(name: contactUs, page: () => ContactUsScreen.routeInstance()),
    GetPage(name: faqs, page: () => FaqsScreen.routeInstance()),
    GetPage(name: result, page: () => ResultScreen.routeInstance()),
    GetPage(
        name: selectSubjects, page: () => SelectSubjectsScreen.routeInstance()),
    GetPage(
        name: parentChildDetails,
        page: () => ChildDetailsScreen.routeInstance()),
    GetPage(name: topicDetails, page: () => TopicDetailsScreen.routeInstance()),
    GetPage(name: playVideo, page: () => PlayVideoScreen.routeInstance()),
    GetPage(
        name: childAssignments,
        page: () => ChildAssignmentsScreen.routeInstance()),
    GetPage(
        name: childAttendance,
        page: () => ChildAttendanceScreen.routeInstance()),
    GetPage(
        name: childTimeTable, page: () => ChildTimeTableScreen.routeInstance()),
    GetPage(name: childResults, page: () => ChildResultsScreen.routeInstance()),
    GetPage(
        name: childTeachers, page: () => ChildTeachersScreen.routeInstance()),
    GetPage(name: settings, page: () => SettingsScreen.routeInstance()),
    GetPage(
        name: changePassword,
        page: () => BlocProvider<ChangePasswordCubit>(
              create: (_) => ChangePasswordCubit(AuthRepository()),
              child: const ChangePasswordScreen(),
            )),
    GetPage(
        name: parentProfile, page: () => ParentProfileScreen.routeInstance()),
    GetPage(name: noticeBoard, page: () => NoticeBoardScreen.routeInstance()),
    GetPage(name: holidays, page: () => HolidaysScreen.routeInstance()),
    GetPage(
        name: subjectWiseReport,
        page: () => ReportSubjectsContainer.routeInstance()),
    GetPage(
        name: subjectWiseDetailedReport,
        page: () => SubjectWiseDetailedReport.routeInstance()),
    GetPage(name: examOnline, page: () => ExamOnlineScreen.routeInstance()),
    GetPage(name: resultOnline, page: () => ResultOnlineScreen.routeInstance()),
    GetPage(
        name: parentMenu, page: () => ChildDetailMenuScreen.routeInstance()),
    GetPage(name: childFees, page: () => ChildFeesScreen.routeInstance()),
    GetPage(
        name: childFeeDetails,
        page: () => ChildFeeDetailsScreen.routeInstance()),
    GetPage(
        name: confirmPayment, page: () => ConfirmPaymentScreen.routeInstance()),
    GetPage(name: transactions, page: () => TransactionsScreen.routeInstance()),
    GetPage(
        name: schoolGallery, page: () => SchoolGalleryScreen.routeInstance()),
    GetPage(
        name: galleryDetails, page: () => GalleryDetailsScreen.routeInstance()),
    GetPage(
        name: subjectAttendanceAtDay,
        page: () => SubjectAttendanceAtDayScreen.routeInstance()),
    GetPage(
        name: galleryImages, page: () => GalleryImagesScreen.routeInstance()),
    GetPage(
        name: notifications, page: () => NotificationsScreen.routeInstance()),
    GetPage(name: chatContacts, page: () => ChatContactsScreen.routeInstance()),
    GetPage(name: chat, page: () => ChatScreen.routeInstance()),
    GetPage(
      name: newChatContacts,
      page: () => NewChatContactsScreen.routeInstance(),
    ),
    // Contact/Support routes
    GetPage(name: contacts, page: () => ContactScreen.routeInstance()),
    GetPage(
        name: contactDetails, page: () => ContactDetailScreen.routeInstance()),
    GetPage(
        name: submitContact, page: () => SubmitContactScreen.routeInstance()),
    GetPage(
        name: extracurricularDetails,
        page: () => ExtracurricularDetailsScreen.routeInstance()),

    // Fitur baru Eschool 1.3.3 - Galang
    GetPage(
      name: childSubjectAttendance,
      page: () => ChildSubjectAttendanceScreen.routeInstance(),
    ),
    GetPage(
      name: childLeaves,
      page: () => ChildLeavesScreen.routeInstance(Get.arguments),
    ),
    GetPage(
      name: '/payment-history',
      page: () {
        final args = Get.arguments;
        Student child;

        if (args is Student) {
          // Direct Student object
          child = args;
        } else if (args is Map<String, dynamic>) {
          // From notification or other sources with childId
          final childId = args['childId'];

          if (childId != null) {
            // Try to get Student from Hive
            final authBox = Hive.box(authBoxKey);
            final isStudent = authBox.get(isStudentLogInKey) ?? false;

            if (isStudent) {
              // For student login, use their own data
              final studentData = authBox.get(studentDetailsKey);
              child = Student.fromJson(
                  Map<String, dynamic>.from(studentData ?? {}));
            } else {
              // For parent login, get child from children list
              final childrenData = authBox.get(childrenDataKey) ?? [];

              if (childrenData is List && childrenData.isNotEmpty) {
                // Find the specific child by ID
                final targetId =
                    childId is int ? childId : int.tryParse(childId.toString());

                // Find matching child or use first child as fallback
                dynamic childData;
                try {
                  childData =
                      childrenData.firstWhere((c) => c['id'] == targetId);
                } catch (e) {
                  // If not found, use first child
                  childData = childrenData.first;
                }

                child = Student.fromJson(Map<String, dynamic>.from(childData));
              } else {
                child = Student.fromJson({});
              }
            }
          } else {
            // No childId, try to parse as Student JSON
            try {
              child = Student.fromJson(args);
            } catch (e) {
              child = Student.fromJson({});
            }
          }
        } else {
          child = Student.fromJson({});
        }

        return PaymentHistoryTabScreen.routeInstance(child: child);
      },
    ),
  ];
}
