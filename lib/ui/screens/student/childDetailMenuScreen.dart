import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/data/models/academic/subject.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/systemModules.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ChildDetailMenuScreen extends StatefulWidget {
  final Student student;
  final List<Subject> subjectsForFilter;
  const ChildDetailMenuScreen({
    Key? key,
    required this.student,
    required this.subjectsForFilter,
  }) : super(key: key);

  @override
  ChildDetailMenuScreenState createState() => ChildDetailMenuScreenState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return ChildDetailMenuScreen(
      subjectsForFilter: arguments['subjectsForFilter'],
      student: arguments['student'],
    );
  }
}

class ChildDetailMenuScreenState extends State<ChildDetailMenuScreen> {
  List<MenuContainerDetails> _menuItems = [];
  final ValueNotifier<int> _hoveredIndex = ValueNotifier<int>(-1);

  // Soft red theme colors
  final Color primaryRed = const Color(0xFFE57373);
  final Color lightRed = const Color(0xFFFFCDD2);
  final Color darkRed = const Color(0xFFD32F2F);

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      setMenuItems();
    });
    super.initState();
  }

  @override
  void dispose() {
    _hoveredIndex.dispose();
    super.dispose();
  }

  void setMenuItems() {
    //Menu will have module Id attache to it same as student home bottm sheet
    _menuItems = [
      MenuContainerDetails(
        moduleId: assignmentManagementModuleId.toString(),
        route: Routes.childAssignments,
        arguments: {
          "childId": widget.student.id,
          "subjects": widget.subjectsForFilter
        },
        iconPath: Utils.getImagePath("assignment_icon_parent.svg"),
        title: Utils.getTranslatedLabel(assignmentsKey),
      ),
      MenuContainerDetails(
        moduleId: defaultModuleId.toString(),
        route: Routes.childTeachers,
        arguments: widget.student.id,
        iconPath: Utils.getImagePath("teachers_icon.svg"),
        title: Utils.getTranslatedLabel(teachersKey),
      ),
      MenuContainerDetails(
        moduleId: attendanceManagementModuleId.toString(),
        route: Routes.childAttendance,
        arguments: widget.student.id,
        iconPath: Utils.getImagePath("attendance_icon.svg"),
        title: Utils.getTranslatedLabel(attendanceKey),
      ),
      MenuContainerDetails(
        moduleId: timetableManagementModuleId.toString(),
        route: Routes.childTimeTable,
        arguments: widget.student.id,
        iconPath: Utils.getImagePath("timetable_icon.svg"),
        title: Utils.getTranslatedLabel(timeTableKey),
      ),
      MenuContainerDetails(
        moduleId: attendanceManagementModuleId.toString(),
        route: Routes.childSubjectAttendance,
        arguments: widget.student.id,
        iconPath: Utils.getImagePath("subject_attendance_icon.svg"),
        title: Utils.getTranslatedLabel(subjectAttendanceKey),
      ),
      MenuContainerDetails(
        moduleId: leavesManagementModuleId.toString(),
        route: Routes.childLeaves,
        arguments: widget.student,
        iconPath: Utils.getImagePath("leaves.svg"),
        title: Utils.getTranslatedLabel(myLeavesKey),
      ),
      MenuContainerDetails(
        moduleId: holidayManagementModuleId.toString(),
        route: Routes.holidays,
        arguments: widget.student.id,
        iconPath: Utils.getImagePath("holiday_icon.svg"),
        title: Utils.getTranslatedLabel(holidaysKey),
      ),
      MenuContainerDetails(
        moduleId: examManagementModuleId.toString(),
        route: Routes.exam,
        arguments: {
          "childId": widget.student.id,
          "subjects": widget.subjectsForFilter
        },
        iconPath: Utils.getImagePath("exam_icon.svg"),
        title: Utils.getTranslatedLabel(examsKey),
      ),
      MenuContainerDetails(
        moduleId: examManagementModuleId.toString(),
        route: Routes.childResults,
        arguments: {
          "childId": widget.student.id,
          "subjects": widget.subjectsForFilter
        },
        iconPath: Utils.getImagePath("result_icon.svg"),
        title: Utils.getTranslatedLabel(gradesKey),
      ),
      MenuContainerDetails(
        moduleId:
            "$assignmentManagementModuleId$moduleIdJoiner$examManagementModuleId",
        route: Routes.subjectWiseReport,
        arguments: {
          "childId": widget.student.id,
          "subjects": widget.subjectsForFilter
        },
        iconPath: Utils.getImagePath("reports_icon.svg"),
        title: Utils.getTranslatedLabel(reportsKey),
      ),
      MenuContainerDetails(
        moduleId: feesManagementModuleId.toString(),
        route: Routes.childFees,
        arguments: widget.student,
        iconPath: Utils.getImagePath("fees_icon.svg"),
        title: Utils.getTranslatedLabel(feesKey),
      ),
      MenuContainerDetails(
        moduleId: galleryManagementModuleId.toString(),
        route: Routes.schoolGallery,
        arguments: widget.student,
        iconPath: Utils.getImagePath("gallery.svg"),
        title: Utils.getTranslatedLabel(galleryKey),
      ),
      MenuContainerDetails(
        moduleId: defaultModuleId.toString(),
        route: Routes.childViolations,
        arguments: widget.student,
        iconPath: Utils.getImagePath("violation_icon.svg"),
        title: Utils.getTranslatedLabel(violationsKey),
      ),
    ];

    setState(() {});
  }

  Widget _buildAppBar(BuildContext context) {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarSmallerHeightPercentage,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                left: 10,
                top: -2,
                child: context.read<AuthCubit>().isParent()
                    ? const CustomBackButton()
                    : SizedBox(),
              ),
              Text(
                Utils.getTranslatedLabel(menuKey),
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
              ),
            ]),
      ),
    );
  }

  Widget _buildInformationAndMenu() {
    // Filter enabled modules first
    final enabledMenuItems = _menuItems
        .where((menuItem) => Utils.isModuleEnabled(
            context: context, moduleId: menuItem.moduleId))
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width * (0.05),
        right: MediaQuery.of(context).size.width * (0.05),
        bottom: 30,
        top: MediaQuery.of(context).size.height *
            Utils.appBarSmallerHeightPercentage,
      ),
      child: Column(
        children: [
          // Student info card at the top
          Animate(
            effects: [
              FadeEffect(duration: const Duration(milliseconds: 500)),
              SlideEffect(
                begin: const Offset(0, -0.1),
                end: const Offset(0, 0),
                duration: const Duration(milliseconds: 500),
              ),
            ],
          ),

          // Menu grid layout
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: enabledMenuItems.length,
            itemBuilder: (context, index) =>
                _buildMenuCard(enabledMenuItems[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(MenuContainerDetails menuItem, int index) {
    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 500 + (index * 100))),
        SlideEffect(
          begin: const Offset(0, 0.2),
          end: const Offset(0, 0),
          duration: Duration(milliseconds: 500 + (index * 100)),
        ),
      ],
      child: ValueListenableBuilder<int>(
        valueListenable: _hoveredIndex,
        builder: (context, hoveredIndex, _) {
          final isHovered = hoveredIndex == index;

          return MouseRegion(
            onEnter: (_) => _hoveredIndex.value = index,
            onExit: (_) => _hoveredIndex.value = -1,
            child: GestureDetector(
              onTap: () {
                Get.toNamed(menuItem.route, arguments: menuItem.arguments);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHovered
                      ? lightRed.withValues(alpha: 0.3)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: isHovered ? 2 : 0,
                    ),
                  ],
                  border: Border.all(
                    color: isHovered
                        ? primaryRed
                        : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    width: isHovered ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: isHovered ? 70 : 65, // Increased from 50/45
                      width: isHovered ? 70 : 65, // Increased from 50/45
                      padding: const EdgeInsets.all(12), // Adjusted padding
                      decoration: BoxDecoration(
                        color: lightRed.withValues(alpha: 0.5),
                        borderRadius:
                            BorderRadius.circular(18), // Increased radius
                      ),
                      child: SvgPicture.asset(
                        menuItem.iconPath,
                        // Explicitly set height and width for SVG
                        height: isHovered ? 46 : 41,
                        width: isHovered ? 46 : 41,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      menuItem.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: darkRed,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildInformationAndMenu(),
          _buildAppBar(context),
        ],
      ),
    );
  }
}

//class to maintain details required by each menu items
class MenuContainerDetails {
  String iconPath;
  String title;
  String route;
  String moduleId;
  Object? arguments;

  MenuContainerDetails({
    required this.iconPath,
    required this.title,
    required this.route,
    required this.moduleId,
    this.arguments,
  });
}
