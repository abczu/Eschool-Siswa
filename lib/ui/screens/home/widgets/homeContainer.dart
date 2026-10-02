import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/academic/classElectiveSubjectsCubit.dart';
import 'package:eschool/cubits/system/noticeBoardCubit.dart';
import 'package:eschool/cubits/system/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/academic/studentSubjectAndSlidersCubit.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/ui/screens/home/widgets/homeScreenDataLoadingContainer.dart';
import 'package:eschool/ui/widgets/system/borderedProfilePictureContainer.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/latestNoticesContainer.dart';
import 'package:eschool/ui/widgets/system/schoolGalleryContainer.dart';
import 'package:eschool/ui/widgets/system/slidersContainer.dart';
import 'package:eschool/ui/widgets/academic/studentSubjectsContainer.dart';
import 'package:eschool/utils/system/ZoomHelper.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/systemModules.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeContainer extends StatefulWidget {
  final bool isForBottomMenuBackground;
  final bool forced;
  const HomeContainer(
      {Key? key, required this.isForBottomMenuBackground, this.forced = false})
      : super(key: key);

  @override
  State<HomeContainer> createState() => _HomeContainerState();
}

class _HomeContainerState extends State<HomeContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late final ScrollController ScrollControlContent;
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    ScrollControlContent = ScrollController();
    ScrollControlContent.addListener(() {
      if (!mounted) return;
      _scrollOffsetNotifier.value = ScrollControlContent.offset;
    });

    if (!widget.isForBottomMenuBackground) {
      _animationController.forward();
      Future.delayed(Duration.zero, () {
        fetchSubjectSlidersAndNoticeBoardDetails();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    ScrollControlContent.dispose();
    super.dispose();
  }

  void fetchSubjectSlidersAndNoticeBoardDetails() {
    context.read<StudentSubjectsAndSlidersCubit>().fetchSubjectsAndSliders(
        useParentApi: false,
        isSliderModuleEnable: Utils.isModuleEnabled(
            context: context, moduleId: sliderManagementModuleId.toString()));

    if (Utils.isModuleEnabled(
        context: context,
        moduleId: announcementManagementModuleId.toString())) {
      context
          .read<NoticeBoardCubit>()
          .fetchNoticeBoardDetails(useParentApi: false);
    }
  }

  Widget _buildAdvertisemntSliders() {
    final sliders = context.read<StudentSubjectsAndSlidersCubit>().getSliders();

    if (sliders.isEmpty) {
      return const SizedBox();
    }

    return FadeInUp(
      duration: Duration(milliseconds: 600),
      from: 30,
      child: Column(children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * (0.013),
        ),
        SlidersContainer(sliders: sliders),
        SizedBox(
          height: MediaQuery.of(context).size.height * (0.013),
        ),
      ]),
    );
  }

  Widget _buildContentCard({required Widget child}) {
    final double headerTapHeight = MediaQuery.of(context).size.height * 0.20;
    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffsetNotifier,
      builder: (context, currentOffset, _) {
        final double spacerHeight =
            (headerTapHeight - currentOffset).clamp(0.0, headerTapHeight);
        final double topMargin = (spacerHeight > 0) ? currentOffset : 0.0;

        return Card(
          margin: EdgeInsets.only(top: topMargin),
          elevation: 10.0,
          shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 20),
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).size.height * 0.18,
            ),
            child: child,
          ),
        );
      },
    ).animate(
      controller: _animationController,
      effects: [
        SlideEffect(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutQuint,
        ),
      ],
    );
  }

  Widget _redirectSelectSubjects() {
    return BlocConsumer<ClassElectiveSubjectsCubit, ClassElectiveSubjectsState>(
      listener: (context, state) {
        if (state is ClassElectiveSubjectsFetchSuccess) {
          // Check if there's any group where totalSelectableSubjects > subjects.length
          // If so, redirect immediately to home page before rendering any UI
          for (var electiveSubjectGroup in state.electiveSubjectGroups) {
            if (electiveSubjectGroup.totalSelectableSubjects <
                    electiveSubjectGroup.subjects.length &&
                electiveSubjectGroup.subjects.length != 0) {
              Get.offNamed(Routes.selectSubjects);
              break;
            }
          }
        }
      },
      builder: (BuildContext context, ClassElectiveSubjectsState state) {
        // Return an empty container as this widget is mainly for redirection logic
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSlidersSubjectsAndLatestNotcies({ScrollController? ScrollControlContent}) {
    return BlocConsumer<StudentSubjectsAndSlidersCubit,
        StudentSubjectsAndSlidersState>(
      listener: (context, state) {
        _redirectSelectSubjects();
        if (state is StudentSubjectsAndSlidersFetchSuccess) {
          if (state.doesClassHaveElectiveSubjects &&
              state.electiveSubjects.isEmpty) {
            if (Get.currentRoute == Routes.selectSubjects) {
              return;
            }
          }
        }
      },
      builder: (context, state) {
        if (state is StudentSubjectsAndSlidersFetchSuccess) {
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<SchoolConfigurationCubit>()
                  .fetchSchoolConfiguration(useParentApi: false);
              // Ikut sinkron foto profil (mis. diganti via web).
              // Silent + no-op bila tidak ada perubahan.
              await context.read<AuthCubit>().refreshStudentProfileIfChanged();
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: Utils.screenContentTopPadding / 2),
              controller: ScrollControlContent,
              physics: const FasterScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: _buildContentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdvertisemntSliders(),
                    Utils.isModuleEnabled(
                            context: context,
                            moduleId: announcementManagementModuleId.toString())
                        ? AnimationConfiguration.staggeredList(
                            position: 0,
                            duration: const Duration(milliseconds: 700),
                            child: SlideAnimation(
                              horizontalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Column(
                                  children: [
                                    LatestNoticiesContainer(
                                      animate:
                                          !widget.isForBottomMenuBackground,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                    SizedBox(
                        height: Utils.isModuleEnabled(
                                context: context,
                                moduleId:
                                    announcementManagementModuleId.toString())
                            ? 30
                            : 0),
                    AnimationConfiguration.staggeredList(
                      position: 1,
                      duration: const Duration(milliseconds: 800),
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: StudentSubjectsContainer(
                            header: true,
                            subjects: context
                                .read<StudentSubjectsAndSlidersCubit>()
                                .getSubjects(),
                            subjectsTitleKey: mySubjectsKey,
                            animate: !widget.isForBottomMenuBackground,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: Utils.isModuleEnabled(
                                context: context,
                                moduleId: galleryManagementModuleId.toString())
                            ? 30
                            : 0),
                    Utils.isModuleEnabled(
                            context: context,
                            moduleId: galleryManagementModuleId.toString())
                        ? AnimationConfiguration.staggeredList(
                            position: 2,
                            duration: const Duration(milliseconds: 900),
                            child: SlideAnimation(
                              horizontalOffset: 50.0,
                              child: FadeInAnimation(
                                child: SchoolGalleryContainer(
                                  student: context
                                      .read<AuthCubit>()
                                      .getStudentDetails(),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height *
                          (Utils.appBarSmallerHeightPercentage / 2),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is StudentSubjectsAndSlidersFetchFailure) {
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<SchoolConfigurationCubit>()
                  .fetchSchoolConfiguration(useParentApi: false);
              await context.read<AuthCubit>().refreshStudentProfileIfChanged();
            },
            child: SingleChildScrollView(
              controller: ScrollControlContent,
              physics: AlwaysScrollableScrollPhysics(),
              child: _buildContentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ErrorContainer(
                        onTapRetry: () {
                          context
                              .read<StudentSubjectsAndSlidersCubit>()
                              .fetchSubjectsAndSliders(
                                  useParentApi: false,
                                  isSliderModuleEnable: Utils.isModuleEnabled(
                                      context: context,
                                      moduleId:
                                          sliderManagementModuleId.toString()));
                        },
                        errorMessageCode: state.errorMessage,
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        // Loading state
        return _buildContentCard(
          child: HomeScreenDataLoadingContainer(
            addTopPadding: true,
          ),
        );
      },
    );
  }

  Widget _buildDecorativeCircle(double size, Color color,
      {bool isAnimated = true}) {
    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );

    if (isAnimated && !widget.isForBottomMenuBackground) {
      return circle.animate(
        onPlay: (controller) => controller.repeat(reverse: true),
        effects: [
          ScaleEffect(
            begin: Offset(1, 1),
            end: Offset(1.1, 1.1),
            duration: Duration(seconds: 2),
          ),
        ],
      );
    }

    return circle;
  }

  Widget _buildDecorativeSquare(double size, Color color,
      {bool isAnimated = true}) {
    Widget square = Transform.rotate(
      angle: 0.3,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: color,
        ),
      ),
    );

    if (isAnimated && !widget.isForBottomMenuBackground) {
      return square.animate(
        onPlay: (controller) => controller.repeat(reverse: true),
        effects: [
          RotateEffect(
            begin: 0.3,
            end: 0.5,
            duration: Duration(seconds: 3),
          ),
        ],
      );
    }

    return square;
  }

  Widget _buildWelcomeText(Student studentDetails) {
    final timeNow = DateTime.now().hour;
    String greeting = '';

    if (timeNow < 11) {
      greeting = 'Selamat Pagi';
    } else if (timeNow < 15) {
      greeting = 'Selamat Siang';
    } else if (timeNow < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    return InkWell(
      onTap: () {
        Get.toNamed(Routes.studentProfile);
      },
      child: FadeInDown(
        duration: Duration(milliseconds: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
                color:
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    studentDetails.getFullName(),
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.amber,
                  size: 20,
                ).animate(
                  onPlay: (controller) => controller.repeat(
                      reverse: true, period: Duration(seconds: 1)),
                  effects: [
                    RotateEffect(
                      begin: -0.1,
                      end: 0.02,
                      duration: Duration(milliseconds: 500),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: FadeInLeft(
                    duration: Duration(milliseconds: 600),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              "${studentDetails.classSection?.name ?? ''}",
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: FadeInRight(
                    duration: Duration(milliseconds: 600),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FontAwesomeIcons.idCard,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              "${Utils.getTranslatedLabel(rollNoKey)}: ${studentDetails.rollNumber}",
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    // BlocBuilder agar foto/nama langsung ter-update saat AuthCubit emit
    // state baru (mis. setelah siswa ubah foto profil) tanpa pull-refresh.
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final studentDetails = context.read<AuthCubit>().getStudentDetails();
        return Container(
      padding: EdgeInsets.symmetric(
        vertical:
            MediaQuery.of(context).padding.top + Utils.screenContentTopPadding,
        horizontal: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FadeIn(
                duration: Duration(milliseconds: 800),
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                    BoxShadow(
                        color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                  ]),
                  child: Hero(
                    tag: 'profileImage',
                    child: BorderedProfilePictureContainer(
                      key: ValueKey(studentDetails.image ?? ""),
                      heightAndWidth: 80,
                      imageUrl: studentDetails.image ?? "",
                      onTap: () async {
                        final url = studentDetails.image ?? "";
                        showBlurZoomImagePreview(
                          context,
                          imageUrl: url,
                          heroTag: 'profileImage', // sama dengan Hero kecil
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * (0.05),
              ),
              Expanded(
                child: _buildWelcomeText(studentDetails),
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final double headerTapHeight = MediaQuery.of(context).size.height * 0.20;

    return Stack(
      children: [
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
          child: Stack(
            children: [
              Positioned(
                top: 20,
                right: 20,
                child:
                    _buildDecorativeCircle(40, Colors.white.withValues(alpha: 0.08), isAnimated: false),
              ),
              Positioned(
                top: 60,
                left: -15,
                child:
                    _buildDecorativeCircle(60, Colors.white.withValues(alpha: 0.1), isAnimated: false),
              ),
              Positioned(
                top: 90,
                right: 60,
                child:
                    _buildDecorativeSquare(20, Colors.white.withValues(alpha: 0.12), isAnimated: false),
              ),
              Positioned(
                top: 65,
                left: 100,
                child:
                    _buildDecorativeSquare(15, Colors.white.withValues(alpha: 0.09), isAnimated: false),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.4,
                left: 30,
                child:
                    _buildDecorativeCircle(25, Colors.white.withValues(alpha: 0.06), isAnimated: false),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.5,
                right: 20,
                child:
                    _buildDecorativeSquare(30, Colors.white.withValues(alpha: 0.07), isAnimated: false),
              ),
              _buildHeaderSection(),
            ],
          ),
        ),
        Positioned(
          child: Column(
            children: [
              ValueListenableBuilder<double>(
                valueListenable: _scrollOffsetNotifier,
                builder: (context, currentOffset, _) {
                  final double spacerHeight =
                      (headerTapHeight - currentOffset).clamp(0.0, headerTapHeight);
                  if (spacerHeight > 0) {
                    return IgnorePointer(
                      ignoring: true,
                      child: SizedBox(height: spacerHeight),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: _buildSlidersSubjectsAndLatestNotcies(
                  ScrollControlContent: ScrollControlContent,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class FasterScrollPhysics extends ScrollPhysics {
  const FasterScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  FasterScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FasterScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    if (velocity.abs() < tolerance.velocity) {
      return null;
    }

    // A lower 'drag' value makes the scroll glide further and smoother (less friction).
    // Default is 0.135. We use 0.08 for a super smooth and fast feel.
    return FrictionSimulation(
      0.08,
      position.pixels,
      velocity,
    );
  }
}
