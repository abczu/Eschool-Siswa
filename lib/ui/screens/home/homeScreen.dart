import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/system/appConfigurationCubit.dart';
import 'package:eschool/cubits/student/attendanceCubit.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/extracurricular/extracurricularCubit.dart';
import 'package:eschool/cubits/system/holidaysCubit.dart';
import 'package:eschool/cubits/extracurricular/joinExtracurricularCubit.dart';
import 'package:eschool/cubits/extracurricular/myExtracurricularCubit.dart';
import 'package:eschool/cubits/extracurricular/allMyExtracurricularStatusCubit.dart';
import 'package:eschool/cubits/exam/resultsCubit.dart';
import 'package:eschool/cubits/system/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/system/schoolGalleryCubit.dart';
import 'package:eschool/cubits/system/schoolSessionYearsCubit.dart';
import 'package:eschool/cubits/payment/pendingPaymentCheckCubit.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/data/repositories/payment/xenditRepository.dart';
import 'package:eschool/cubits/student/studentGuardianDetailsCubit.dart';
import 'package:eschool/cubits/student/subjectAttendanceCubit.dart';
import 'package:eschool/cubits/student/violationCubit.dart';
import 'package:eschool/data/repositories/student/violationRepository.dart';
import 'package:eschool/ui/widgets/student/violationContainer.dart';
import 'package:eschool/cubits/academic/timeTableCubit.dart';
import 'package:eschool/data/models/system/notificationDetails.dart';
import 'package:eschool/data/repositories/extracurricular/extracurricularRepository.dart';
import 'package:eschool/data/repositories/system/notificationRepository.dart';
import 'package:eschool/data/repositories/system/schoolRepository.dart';
import 'package:eschool/data/repositories/student/studentRepository.dart';
import 'package:eschool/data/repositories/system/systemInfoRepository.dart';
// import 'package:eschool/ui/screens/childSubjectAttendanceScreen.dart';
import 'package:eschool/ui/screens/home/cubits/assignmentsTabSelectionCubit.dart';
import 'package:eschool/ui/screens/home/widgets/bottomNavigationItemContainer.dart';
import 'package:eschool/ui/screens/home/widgets/examContainer.dart';
import 'package:eschool/ui/screens/home/widgets/homeContainer.dart';
import 'package:eschool/ui/screens/home/widgets/homeScreenDataLoadingContainer.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/profileHeaderShimmerLoadingContainer.dart';
import 'package:eschool/ui/screens/home/widgets/moreMenuBottomsheetContainer.dart';
import 'package:eschool/ui/screens/home/widgets/parentProfileContainer.dart';
import 'package:eschool/ui/screens/academic/reports/reportSubjectsContainer.dart';
import 'package:eschool/ui/widgets/system/NotificationHistoryContainer.dart';
import 'package:eschool/ui/widgets/system/appUnderMaintenanceContainer.dart';
import 'package:eschool/ui/widgets/academic/assignmentsContainer.dart';
import 'package:eschool/ui/widgets/student/attendanceContainer.dart';
import 'package:eschool/ui/widgets/system/customRoundedButton.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/extracurricular/extracurricularContainer.dart';
import 'package:eschool/ui/widgets/system/forceUpdateDialogContainer.dart';
import 'package:eschool/ui/widgets/system/holidaysContainer.dart';
import 'package:eschool/ui/widgets/academic/noticeBoardContainer.dart';
import 'package:eschool/ui/widgets/system/schoolGalleryWithSessionYearFilterContainer.dart';
import 'package:eschool/ui/widgets/system/settingsContainer.dart';
import 'package:eschool/ui/widgets/academic/subjectAttendanceContainer.dart';
import 'package:eschool/ui/widgets/academic/timetableContainer.dart';
import 'package:eschool/utils/academic/ExamSubmitSyncService.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/utils/system/homeBottomsheetMenu.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/systemModules.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
// Tambahan import untuk redesain

import '../../widgets/academic/resultsContainer.dart';

class HomeScreen extends StatefulWidget {
  static GlobalKey<HomeScreenState> homeScreenKey =
      GlobalKey<HomeScreenState>();
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();

  static Widget routeInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TimeTableCubit>(
          create: (_) => TimeTableCubit(StudentRepository()),
        ),
        BlocProvider<StudentGuardianDetailsCubit>(
          create: (_) => StudentGuardianDetailsCubit(StudentRepository()),
        ),
        BlocProvider<AttendanceCubit>(
          create: (context) => AttendanceCubit(StudentRepository()),
        ),
        BlocProvider<HolidaysCubit>(
          create: (context) => HolidaysCubit(SystemRepository()),
        ),
        BlocProvider<AssignmentsTabSelectionCubit>(
          create: (_) => AssignmentsTabSelectionCubit(),
        ),
        BlocProvider<ResultsCubit>(
          create: (_) => ResultsCubit(StudentRepository()),
        ),
        BlocProvider<SchoolGalleryCubit>(
          create: (_) => SchoolGalleryCubit(SchoolRepository()),
        ),
        // Safety Net Poin 2: Cubit untuk cek status invoice pending
        BlocProvider<PendingPaymentCheckCubit>(
          create: (_) => PendingPaymentCheckCubit(XenditRepository()),
        ),
      ],
      child: HomeScreen(
        key: homeScreenKey,
      ),
    );
  }
}

class HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _bottomNavAndTopProfileAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),
  );

  late final List<AnimationController> _bottomNavItemTitlesAnimationController =
      [];

  late final AnimationController _moreMenuBottomsheetAnimationController =
      AnimationController(
    vsync: this,
    duration: homeMenuBottomSheetAnimationDuration,
  );

  late final Animation<Offset> _moreMenuBottomsheetAnimation =
      Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
    CurvedAnimation(
      parent: _moreMenuBottomsheetAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  late final Animation<double> _moreMenuBackgroundContainerColorAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _moreMenuBottomsheetAnimationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ),
  );

  late int _currentSelectedBottomNavIndex = 0;

  //index of opened homeBottomsheet menu
  late int _currentlyOpenMenuIndex = -1;

  late bool _isMoreMenuOpen = false;

  late List<BottomNavItem> _bottomNavItems = [];

  // Tambahan untuk mendeteksi keyboard
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _animationController.forward();

    Future.delayed(Duration.zero, () {
      loadTemporarilyStoredNotifications();
      debugPrint(
          "DEBUG HomeScreen: schoolCode before fetchSchoolConfiguration = '${AuthRepository().schoolCode}'");
      context
          .read<SchoolConfigurationCubit>()
          .fetchSchoolConfiguration(useParentApi: false);
      // Safety Net Poin 2: Cek invoice pending saat halaman pertama dibuka (HANYA UNTUK PARENT)
      if (context.read<AuthCubit>().isParent()) {
        context.read<PendingPaymentCheckCubit>().checkAllPendingPayments();
      }

      // ✅ REGISTER FCM TOKEN: Daftarkan token setelah login dipastikan sudah siap
      AuthRepository().GetDeviceToken().then((token) {
        if (token.isNotEmpty) {
          AuthRepository().registerDeviceToken(fcmId: token);
        }
      });

      // ✅ SINKRON FOTO PROFIL: cek ke server bila foto diubah dari web,
      // khusus login siswa (parent diabaikan). Silent, gagal/offline diam.
      if (!context.read<AuthCubit>().isParent()) {
        context.read<AuthCubit>().refreshStudentProfileIfChanged();
      }
    });
    debugPrint("HomeScreen initStated exam submit");
    Future.microtask(() => ExamSubmitSyncService.syncIfCached());
  }

  void loadTemporarilyStoredNotifications() {
    NotificationRepository.getTemporarilyStoredNotifications()
        .then((notifications) {
      //
      for (var notificationData in notifications) {
        NotificationRepository.addNotification(
            notificationDetails:
                NotificationDetails.fromJson(Map.from(notificationData)));
      }
      //
      if (notifications.isNotEmpty) {
        NotificationRepository.clearTemporarilyNotification();
      }

      //
    });
  }

  void updateBottomNavItems() {
    _bottomNavItems = context
            .read<SchoolConfigurationCubit>()
            .getSchoolConfiguration()
            .isAssignmentModuleEnabled()
        ? [
            BottomNavItem(
              activeImageUrl: Utils.getImagePath("home_active_icon_red.svg"),
              disableImageUrl: Utils.getImagePath("home_icon.svg"),
              title: homeKey,
            ),
            BottomNavItem(
                activeImageUrl:
                    Utils.getImagePath("assignment_active_icon_red.svg"),
                disableImageUrl: Utils.getImagePath("assignment_icon.svg"),
                title: assignmentsKey,
                size: 30),
            BottomNavItem(
              activeImageUrl: Utils.getImagePath("menu_active_icon_red.svg"),
              disableImageUrl: Utils.getImagePath("menu_icon.svg"),
              title: menuKey,
            ),
          ]
        : [
            BottomNavItem(
              activeImageUrl: Utils.getImagePath("home_active_icon_red.svg"),
              disableImageUrl: Utils.getImagePath("home_icon.svg"),
              title: homeKey,
            ),
            BottomNavItem(
              activeImageUrl: Utils.getImagePath("menu_active_icon_red.svg"),
              disableImageUrl: Utils.getImagePath("menu_icon.svg"),
              title: menuKey,
            ),
          ];

    //Update the animaitons controller based on assignment module enable
    initAnimations();

    setState(() {});
  }

  void navigateToAssignmentContainer() {
    Get.until((route) => route.isFirst);
    changeBottomNavItem(1);
  }

  void initAnimations() {
    for (var i = 0; i < _bottomNavItems.length; i++) {
      _bottomNavItemTitlesAnimationController.add(
        AnimationController(
          value: i == _currentSelectedBottomNavIndex ? 0.0 : 1.0,
          vsync: this,
          duration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    for (var animationController in _bottomNavItemTitlesAnimationController) {
      animationController.dispose();
    }
    _moreMenuBottomsheetAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      loadTemporarilyStoredNotifications();
      // Safety Net Poin 2: Re-cek invoice pending saat app dibuka kembali dari background
      // Safety Net Poin 1: Cek saat resume (HANYA UNTUK PARENT)
      if (mounted && context.read<AuthCubit>().isParent()) {
        context.read<PendingPaymentCheckCubit>().checkAllPendingPayments();
      }
      // ✅ SINKRON FOTO PROFIL saat kembali dari background (siswa saja).
      // Menangkap kasus: foto diganti via web saat app di background.
      if (mounted && !context.read<AuthCubit>().isParent()) {
        context.read<AuthCubit>().refreshStudentProfileIfChanged();
      }
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = View.of(context).viewInsets.bottom;
    final newValue = bottomInset > 0.0;

    if (newValue != _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = newValue;
      });
    }
  }

  bool canPopScreen() {
    if (_currentlyOpenMenuIndex != -1) {
      return false;
    }
    if (_isMoreMenuOpen) {
      return false;
    }
    if (_currentSelectedBottomNavIndex != 0) {
      return false;
    }
    return true;
  }

  Future<void> changeBottomNavItem(int index) async {
    if (_moreMenuBottomsheetAnimationController.isAnimating) {
      return;
    }

    // If bottom index is last means open/close the bottom sheet
    // IMPORTANT: Handle menu toggle FIRST without changing _currentSelectedBottomNavIndex
    if (index == _bottomNavItems.length - 1) {
      // If currently viewing a menu item, show menu list over it without closing the menu item
      if (_currentlyOpenMenuIndex != -1) {
        if (_isMoreMenuOpen) {
          // If bottom sheet is already open, close it with smooth animation
          await _moreMenuBottomsheetAnimationController.reverse();
          setState(() {
            _isMoreMenuOpen = false;
          });
        } else {
          // If bottom sheet is closed, open it
          setState(() {
            _isMoreMenuOpen = true;
          });
          // Ensure animation starts from the beginning if needed
          if (!_moreMenuBottomsheetAnimationController.isAnimating) {
            await _moreMenuBottomsheetAnimationController.forward();
          }
        }
        return;
      }

      // Normal menu toggle behavior
      if (_moreMenuBottomsheetAnimationController.isCompleted) {
        // Close the menu with smooth animation
        await _moreMenuBottomsheetAnimationController.reverse();
        setState(() {
          _isMoreMenuOpen = false;
        });
      } else {
        // Open menu - trigger state change first for smooth indicator animation
        setState(() {
          _isMoreMenuOpen = true;
        });
        _bottomNavItemTitlesAnimationController[_currentSelectedBottomNavIndex]
            .forward();
        await _moreMenuBottomsheetAnimationController.forward();
      }
      return; // Exit here, don't change the index
    }

    // For non-menu items, proceed with normal index change
    _bottomNavItemTitlesAnimationController[_currentSelectedBottomNavIndex]
        .forward();

    // Change current selected bottom index
    setState(() {
      _currentSelectedBottomNavIndex = index;
      _currentlyOpenMenuIndex = -1;
    });

    _bottomNavItemTitlesAnimationController[_currentSelectedBottomNavIndex]
        .reverse();

    // If menu is open then close it when switching to non-menu tab
    if (_moreMenuBottomsheetAnimationController.isCompleted) {
      await _moreMenuBottomsheetAnimationController.reverse();
      setState(() {
        _isMoreMenuOpen = false;
      });
    }
  }

  Future<void> _closeBottomMenu() async {
    // Always just close the bottom sheet with smooth animation, don't close the menu item
    await _moreMenuBottomsheetAnimationController.reverse();
    setState(() {
      _isMoreMenuOpen = false;
    });
  }

  Future<void> _closeMenuItem() async {
    // Kembali dari halaman fitur ke tampilan terakhir (grid menu seperti di foto),
    // bukan ke beranda. Jadi tutup konten fitur lalu buka kembali bottom sheet menu.
    setState(() {
      _currentlyOpenMenuIndex = -1;
      _isMoreMenuOpen = true;
    });
    if (!_moreMenuBottomsheetAnimationController.isAnimating) {
      await _moreMenuBottomsheetAnimationController.forward();
    }
  }

  Future<void> _onTapMoreMenuItemContainer(int index) async {
    setState(() {
      _currentlyOpenMenuIndex = index;
      _isMoreMenuOpen = false;
    });
    await _moreMenuBottomsheetAnimationController.reverse();
  }

  Widget _buildBottomNavigationContainer() {
    // Sembunyikan navbar hanya ketika keyboard muncul
    if (_isKeyboardVisible) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _bottomNavAndTopProfileAnimation,
      child: SlideTransition(
        position: _bottomNavAndTopProfileAnimation.drive(
          Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero),
        ),
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(
            bottom: 16.0,
            left: 20.0,
            right: 20.0,
          ),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 3),
                blurRadius: 15,
                spreadRadius: 1,
              )
            ],
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24.0),
          ),
          width: MediaQuery.of(context).size.width * 0.85,
          height: 64.0,
          child: LayoutBuilder(
            builder: (context, boxConstraints) {
              final itemWidth = _bottomNavItems.isEmpty
                  ? 0.0
                  : boxConstraints.maxWidth / _bottomNavItems.length;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Animated background indicator
                  if (_bottomNavItems.isNotEmpty)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutQuint,
                      left: ((_isMoreMenuOpen || _currentlyOpenMenuIndex != -1)
                                  ? _bottomNavItems.length - 1
                                  : _currentSelectedBottomNavIndex) *
                              itemWidth +
                          (itemWidth - 48) / 2,
                      width: 48,
                      bottom: 0,
                      height: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),

                  // Base navigation bar with inactive icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _bottomNavItems.isEmpty
                        ? [const SizedBox()]
                        : List.generate(_bottomNavItems.length, (index) {
                            // Menu icon should be active when it's selected OR when menu bottom sheet is open OR when viewing a menu item
                            final bool isMenuIcon =
                                index == _bottomNavItems.length - 1;
                            final bool isActiveTab =
                                index == _currentSelectedBottomNavIndex;
                            // final bool isMenuActive = isMenuIcon &&
                            //     (_isMoreMenuOpen ||
                            //         _currentlyOpenMenuIndex != -1);

                            // Only hide the icon that has the floating bubble
                            final bool shouldHideIcon = (_isMoreMenuOpen ||
                                    _currentlyOpenMenuIndex != -1)
                                ? isMenuIcon // When menu is open or menu item is viewed, hide only menu icon
                                : isActiveTab; // When menu is closed, hide only active tab icon

                            // Don't hide active item, just style it differently in base row
                            return GestureDetector(
                              onTap: () => changeBottomNavItem(index),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: itemWidth,
                                height: 64.0,
                                alignment: Alignment.center,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: shouldHideIcon ? 0.0 : 1.0,
                                  child: SvgPicture.asset(
                                    _bottomNavItems[index].disableImageUrl,
                                    colorFilter: ColorFilter.mode(
                                        shouldHideIcon
                                            ? Colors.transparent
                                            : Colors.grey[400]!,
                                        BlendMode.srcIn),
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              ),
                            );
                          }),
                  ),

                  // Floating active icon bubble with rich effects
                  if (_bottomNavItems.isNotEmpty)
                    Positioned(
                      left: ((_isMoreMenuOpen || _currentlyOpenMenuIndex != -1)
                                  ? _bottomNavItems.length - 1
                                  : _currentSelectedBottomNavIndex) *
                              itemWidth +
                          (itemWidth / 2) -
                          28,
                      bottom: 15.0,
                      child: IgnorePointer(
                        // This ignores pointer events, allowing clicks to pass through
                        child: Stack(
                          children: [
                            // White base layer
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            // Gradient layer
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.75),
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.9),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  _bottomNavItems[(_isMoreMenuOpen ||
                                              _currentlyOpenMenuIndex != -1)
                                          ? _bottomNavItems.length - 1
                                          : _currentSelectedBottomNavIndex]
                                      .activeImageUrl,
                                  colorFilter: ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn),
                                  fit: BoxFit.contain,
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMenuBackgroundContainer() {
    return GestureDetector(
      onTap: () async {
        _closeBottomMenu();
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.75),
      ),
    );
  }

  Widget _buildMenuItemContainer() {
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == attendanceKey) {
      return const AttendanceContainer();
    }
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == timeTableKey) {
      return const TimeTableContainer();
    }
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == "Notifikasi") {
      return const NotificationHistoryContainer();
    }
    // if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == subjectAttendanceKey) {
    //   return const SubjectAttendanceContainer();
    // }
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == settingsKey) {
      return const SettingsContainer();
    }
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == noticeBoardKey) {
      return const NoticeBoardContainer(
        showBackButton: false,
      );
    }
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title ==
        guardianDetailsKey) {
      return const GuardianProfileContainer();
    }

    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == holidaysKey) {
      return const HolidaysContainer();
    }
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == examsKey) {
      return const ExamContainer();
    }
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == gradesKey) {
      return const ResultsContainer();
    }

    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == reportsKey) {
      return const ReportSubjectsContainer();
    }

    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == galleryKey) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => SchoolGalleryCubit(SchoolRepository()),
          ),
          BlocProvider(
            create: (context) => SchoolSessionYearsCubit(SchoolRepository()),
          ),
        ],
        child: SchoolGalleryWithSessionYearFilterContainer(
            showBackButton: false,
            student: context.read<AuthCubit>().getStudentDetails()),
      );
    }

    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title ==
        extracurricularKey) {
      return const ExtracurricularContainer(showBackButton: false);
    }

    // Fitur baru eschool 1.3.3 - Galang
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title ==
        subjectAttendanceKey) {
      return BlocProvider(
        create: (context) => SubjectAttendanceCubit(StudentRepository()),
        child: SubjectAttendanceContainer(),
      );
    }
    // Modul Pelanggaran Siswa (ringkasan siswa, read-only)
    if (homeBottomSheetMenu[_currentlyOpenMenuIndex].title == violationsKey) {
      return BlocProvider(
        create: (context) => ViolationCubit(ViolationRepository()),
        child: ViolationContainer(
          onBack: _closeMenuItem,
        ),
      );
    }
    return const SizedBox();
  }

  // This method is no longer used after refactoring
  // Kept for backward compatibility if needed
  // _buildBottomSheetBackgroundContent removed

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPopScreen(),
      onPopInvokedWithResult: (value, _) {
        if (_currentlyOpenMenuIndex != -1) {
          // System back dari halaman fitur -> kembali ke grid menu terakhir
          _closeMenuItem();
          return;
        }
        if (_isMoreMenuOpen) {
          _closeBottomMenu();
          return;
        }
        if (_currentSelectedBottomNavIndex != 0) {
          changeBottomNavItem(0);
          return;
        }
      },
      child: Scaffold(
        // Tambahkan resizeToAvoidBottomInset untuk mencegah resize otomatis
        resizeToAvoidBottomInset: false,
        body: context.read<AppConfigurationCubit>().appUnderMaintenance()
            ? const AppUnderMaintenanceContainer()
            : MultiBlocListener(
                listeners: [
                  BlocListener<SchoolConfigurationCubit,
                      SchoolConfigurationState>(
                    listener: (context, state) {
                      if (state is SchoolConfigurationFetchSuccess ||
                          state is SchoolConfigurationFetchFailure) {
                        updateBottomNavItems();
                        if (state is SchoolConfigurationFetchSuccess) {
                          if (Utils.isModuleEnabled(
                              context: context,
                              moduleId: galleryManagementModuleId.toString())) {
                            context
                                .read<SchoolGalleryCubit>()
                                .fetchSchoolGallery(
                                    useParentApi: false,
                                    sessionYearId: state.schoolConfiguration
                                            .sessionYear.id ??
                                        0);
                          }
                        }
                      }
                    },
                  ),
                  // Safety Net Poin 2: Tampilkan feedback visual saat background check menemukan payment "PAID"
                  BlocListener<PendingPaymentCheckCubit,
                      PendingPaymentCheckState>(
                    listener: (context, state) {
                      if (state is PendingPaymentFoundPaid) {
                        Utils.showCustomSnackBar(
                          context: context,
                          errorMessage:
                              "Sip! Sistem mendeteksi pembayaran tagihan Anda berhasil masuk (Lunas).",
                          backgroundColor: Colors.green,
                        );
                        // Refresh data Home jika diperlukan (e.g list tagihan/riwayat)
                        context
                            .read<StudentGuardianDetailsCubit>()
                            .getStudentGuardianDetails();
                      }
                    },
                  ),
                ],
                child: BlocBuilder<SchoolConfigurationCubit,
                    SchoolConfigurationState>(
                  builder: (context, state) {
                    if (state is SchoolConfigurationFetchSuccess) {
                      return Stack(
                        children: [
                          IndexedStack(
                            index: _currentSelectedBottomNavIndex,
                            children: state.schoolConfiguration
                                    .isAssignmentModuleEnabled()
                                ? [
                                    const HomeContainer(
                                      isForBottomMenuBackground: false,
                                    ),
                                    const AssignmentsContainer(
                                      isForBottomMenuBackground: false,
                                    ),
                                  ]
                                : [
                                    const HomeContainer(
                                      isForBottomMenuBackground: false,
                                    ),
                                  ],
                          ),

                          // Show menu item content as full screen when a menu item is opened
                          // Setiap fitur mendapat tombol back seperti Poin Pelanggaran,
                          // tap back / system back mengarah kembali ke menu utama.
                          if (_currentlyOpenMenuIndex != -1)
                            Material(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                                child: Stack(
                                  children: [
                                    _buildMenuItemContainer(),
                                    // Poin Pelanggaran sudah punya tombol back sendiri
                                    // (ViolationContainer onBack), jadi overlay hanya
                                    // untuk menu lainnya agar tidak dobel.
                                    if (homeBottomSheetMenu[
                                            _currentlyOpenMenuIndex]
                                        .title !=
                                        violationsKey)
                                      Positioned(
                                        left: 10,
                                        top: MediaQuery.of(context)
                                                .padding
                                                .top +
                                            Utils.screenContentTopPadding -
                                            2,
                                        child: CustomBackButton(
                                          onTap: _closeMenuItem,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                          // Background overlay - tampil hanya saat menu bottom sheet terbuka (harus di atas menu item)
                          IgnorePointer(
                            ignoring: !_isMoreMenuOpen,
                            child: FadeTransition(
                              opacity:
                                  _moreMenuBackgroundContainerColorAnimation,
                              child: _buildMoreMenuBackgroundContainer(),
                            ),
                          ),

                          //More menu bottom sheet - sembunyikan ketika keyboard muncul
                          if (!_isKeyboardVisible && _isMoreMenuOpen)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SlideTransition(
                                position: _moreMenuBottomsheetAnimation,
                                child: MoreMenuBottomsheetContainer(
                                  closeBottomMenu: _closeBottomMenu,
                                  onTapMoreMenuItemContainer:
                                      _onTapMoreMenuItemContainer,
                                ),
                              ),
                            ),

                          // Bottom navigation - sudah ada kondisi di dalam method
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildBottomNavigationContainer(),
                          ),

                          //Check forece update here
                          context.read<AppConfigurationCubit>().forceUpdate()
                              ? FutureBuilder<bool>(
                                  future: Utils.forceUpdate(
                                    context
                                        .read<AppConfigurationCubit>()
                                        .getAppVersion(),
                                  ),
                                  builder: (context, snaphsot) {
                                    if (snaphsot.hasData) {
                                      return (snaphsot.data ?? false)
                                          ? const ForceUpdateDialogContainer()
                                          : const SizedBox();
                                    }

                                    return const SizedBox();
                                  },
                                )
                              : const SizedBox(),
                        ],
                      );
                    }
                    if (state is SchoolConfigurationFetchFailure) {
                      return Center(
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            ErrorContainer(
                              errorMessageCode: state.errorMessage,
                              onTapRetry: () {
                                context
                                    .read<SchoolConfigurationCubit>()
                                    .fetchSchoolConfiguration(
                                        useParentApi: false);
                              },
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            CustomRoundedButton(
                              height: 40,
                              widthPercentage: 0.355,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              onTap: () {
                                Get.toNamed(Routes.settings);
                              },
                              titleColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              buttonTitle:
                                  Utils.getTranslatedLabel(settingsKey),
                              showBorder: false,
                            )
                          ],
                        ),
                      );
                    }

                    final primaryColor = Theme.of(context).colorScheme.primary;
                    return Stack(
                      children: [
                        // Background gradient with header shimmer (like homeContainer)
                        Container(
                          height: MediaQuery.of(context).size.height,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor.withValues(alpha: 0.9),
                                primaryColor.withValues(alpha: 0.8),
                                primaryColor,
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: const ProfileHeaderShimmerLoadingContainer(),
                        ),
                        // White content card with skeleton loading on top
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.18,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Card(
                            margin: EdgeInsets.zero,
                            elevation: 10.0,
                            shadowColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30.0),
                                topRight: Radius.circular(30.0),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30.0),
                                topRight: Radius.circular(30.0),
                              ),
                              child: HomeScreenDataLoadingContainer(
                                addTopPadding: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
