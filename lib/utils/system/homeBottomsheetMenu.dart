import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/systemModules.dart';
import 'package:eschool/utils/system/utils.dart';

class Menu {
  final String title;
  final String iconUrl;
  final String menuModuleId; //This is fixed

  Menu(
      {required this.iconUrl, required this.title, required this.menuModuleId});
}

//To add all more menu here

final List<Menu> homeBottomSheetMenu = [
  Menu(
      menuModuleId: attendanceManagementModuleId.toString(),
      iconUrl: Utils.getImagePath("attendance_icon.svg"),
      title: attendanceKey),
  // Menu(
  //     menuModuleId: attendanceManagementModuleId.toString(),
  //     iconUrl: Utils.getImagePath("notifikasi.svg"),
  //     title: "Notifikasi"),
  Menu(
    menuModuleId: timetableManagementModuleId.toString(),
    iconUrl: Utils.getImagePath("timetable_icon.svg"),
    title: timeTableKey,
  ),
  // Fitur baru Eschool - Galang
  Menu(
    menuModuleId: attendanceManagementModuleId.toString(),
    iconUrl: Utils.getImagePath("subject_attendance_icon.svg"),
    title: subjectAttendanceKey,
  ),
  Menu(
    menuModuleId: announcementManagementModuleId.toString(),
    iconUrl: Utils.getImagePath("noticeboard_icon.svg"),
    title: noticeBoardKey,
  ),
  Menu(
      menuModuleId: examManagementModuleId.toString(),
      iconUrl: Utils.getImagePath("exam_icon.svg"),
      title: examsKey),
  Menu(
      menuModuleId: examManagementModuleId.toString(),
      iconUrl: Utils.getImagePath("result_icon.svg"),
      title: gradesKey),

  Menu(
      menuModuleId:
          "$assignmentManagementModuleId$moduleIdJoiner$examManagementModuleId",
      iconUrl: Utils.getImagePath("reports_icon.svg"),
      title: reportsKey),
  Menu(
    menuModuleId: defaultModuleId.toString(),
    iconUrl: Utils.getImagePath("parent_icon.svg"),
    title: guardianDetailsKey,
  ),
  Menu(
      iconUrl: Utils.getImagePath("holiday_icon.svg"),
      title: holidaysKey,
      menuModuleId: holidayManagementModuleId.toString()),
  Menu(
      iconUrl: Utils.getImagePath("gallery.svg"),
      title: galleryKey,
      menuModuleId: galleryManagementModuleId.toString()),
  Menu(
      iconUrl: Utils.getImagePath("extracurricular_icon.svg"),
      title: extracurricularKey,
      menuModuleId: defaultModuleId.toString()),
  // Modul Pelanggaran Siswa - selalu tampil (read-only ringkasan siswa)
  Menu(
      iconUrl: Utils.getImagePath("violation_icon.svg"),
      title: violationsKey,
      menuModuleId: defaultModuleId.toString()),
  Menu(
      iconUrl: Utils.getImagePath("setting_icon.svg"),
      title: settingsKey,
      menuModuleId: defaultModuleId.toString()),
];
