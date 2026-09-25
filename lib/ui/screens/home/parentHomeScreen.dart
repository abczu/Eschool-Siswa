import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/system/appConfigurationCubit.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/ui/widgets/system/appUnderMaintenanceContainer.dart';
import 'package:eschool/ui/widgets/system/borderedProfilePictureContainer.dart';
import 'package:eschool/ui/widgets/system/forceUpdateDialogContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({Key? key}) : super(key: key);

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();

  static Widget routeInstance() {
    return const ParentHomeScreen();
  }
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    Future.delayed(Duration.zero, () {
      _animationController.forward();
    });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    // Memanggil logika fetch API & cache buster yang baru kita buat
    await context.read<AuthCubit>().refreshProfileImage();
    
    // Add a small delay for UI feedback (optional, tapi bagus buat pull-to-refresh)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildAppBar() {
    return Animate(
      effects: [
        FadeEffect(
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut),
        SlideEffect(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
            curve: Curves.easeOut),
      ],
      child: Align(
        alignment: Alignment.topCenter,
        child: ScreenTopBackgroundContainer(
          padding: EdgeInsets.zero,
          heightPercentage: Utils.appBarMediumtHeightPercentage,
          child: LayoutBuilder(
            builder: (context, boxConstraints) {
              return Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: MediaQuery.of(context).size.width * (-0.2),
                    left: MediaQuery.of(context).size.width * (-0.225),
                    child: Container(
                      padding: const EdgeInsetsDirectional.only(
                          end: 20.0, bottom: 20.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.1),
                        ),
                        shape: BoxShape.circle,
                      ),
                      width: MediaQuery.of(context).size.width * (0.6),
                      height: MediaQuery.of(context).size.width * (0.6),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context)
                                .scaffoldBackgroundColor
                                .withValues(alpha: 0.1),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: MediaQuery.of(context).size.width * (-0.15),
                    right: MediaQuery.of(context).size.width * (-0.15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      width: MediaQuery.of(context).size.width * (0.4),
                      height: MediaQuery.of(context).size.width * (0.4),
                    ),
                  ),

                  // Profile info
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: EdgeInsetsDirectional.only(
                        end: boxConstraints.maxWidth * (0.02),
                        start: boxConstraints.maxWidth * (0.075),
                        bottom: boxConstraints.maxHeight * (0.13),
                      ),
                      child: Row(
                        children: [
                          Animate(
                            effects: [
                              ScaleEffect(
                                delay: const Duration(milliseconds: 200),
                                duration: const Duration(milliseconds: 400),
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeOutBack,
                              ),
                            ],
                            child: BorderedProfilePictureContainer(
                              heightAndWidth: 65,
                              onTap: () {
                                Get.toNamed(Routes.parentProfile);
                              },
                              imageUrl: context
                                      .watch<AuthCubit>()
                                      .getParentDetails()
                                      .image ??
                                  "",
                            ),
                          ),
                          SizedBox(
                            width: boxConstraints.maxWidth * (0.04),
                          ),
                          Animate(
                            effects: [
                              FadeEffect(
                                  delay: const Duration(milliseconds: 300),
                                  duration: const Duration(milliseconds: 500)),
                              SlideEffect(
                                delay: const Duration(milliseconds: 300),
                                duration: const Duration(milliseconds: 500),
                                begin: const Offset(-0.2, 0),
                                end: Offset.zero,
                              ),
                            ],
                            child: InkWell(
                              onTap: () => {
                                Get.toNamed(Routes.parentProfile),
                              },
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: boxConstraints.maxWidth * (0.5),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context
                                              .watch<AuthCubit>()
                                              .getParentDetails()
                                              .getFullName(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                          ),
                                        ),
                                        Text(
                                          context
                                                  .watch<AuthCubit>()
                                                  .getParentDetails()
                                                  .email ??
                                              "",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w400,
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor
                                                .withValues(alpha: 0.85),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Animate(
                            effects: [
                              FadeEffect(
                                  delay: const Duration(milliseconds: 500),
                                  duration: const Duration(milliseconds: 400)),
                              ScaleEffect(
                                delay: const Duration(milliseconds: 500),
                                duration: const Duration(milliseconds: 400),
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.0, 1.0),
                              ),
                            ],
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(50),
                                onTap: () {
                                  Get.toNamed(Routes.settings);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor
                                        .withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.settings,
                                    size: 24,
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  ),
                                ),
                              ),
                            ),
                          )
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

  Widget _buildChildDetailsContainer({
    required double width,
    required Student student,
    required int index,
  }) {
    return Animate(
      effects: [
        FadeEffect(
          delay: Duration(milliseconds: 200 + (index * 100)),
          duration: const Duration(milliseconds: 500),
        ),
        SlideEffect(
          delay: Duration(milliseconds: 200 + (index * 100)),
          duration: const Duration(milliseconds: 500),
          begin: const Offset(0, 0.2),
          end: Offset.zero,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Switch to the selected child's session using proper method
          context.read<AuthCubit>().switchToChildSession(student);
          Get.toNamed(Routes.parentChildDetails, arguments: student);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          width: width,
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, boxConstraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background decoration
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Content
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 15.0),
                        child: Column(
                          children: [
                            BorderedProfilePictureContainer(
                              onTap: () {
                                context
                                    .read<AuthCubit>()
                                    .switchToChildSession(student);
                                Get.toNamed(Routes.parentChildDetails,
                                    arguments: student);
                              },
                              heightAndWidth: 60,
                              imageUrl: student.image ?? student.childUserDetails?.image ?? "",
                            ),
                            const SizedBox(height: 15),
                            Text(
                              student.getFullName(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15.0,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${student.schoolName}",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .scaffoldBackgroundColor
                                    .withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${student.classSection?.name}",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .scaffoldBackgroundColor
                                    .withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              textAlign: TextAlign.center,
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
      )
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .shimmer(
            duration: const Duration(seconds: 3),
            color: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: 0.2),
            size: 0.1,
            curve: Curves.easeInOutSine,
            delay: Duration(milliseconds: 1000 + (index * 500)),
          ),
    );
  }

  Widget _buildChildrenContainer() {
    final children =
        context.read<AuthCubit>().getChildren();

    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Animate(
                effects: [
                  FadeEffect(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 500),
                  ),
                  SlideEffect(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 500),
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Utils.getTranslatedLabel(myChildrenKey),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              LayoutBuilder(
                builder: (context, boxConstraints) {
                  return Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: boxConstraints.maxWidth * 0.05,
                        runSpacing: 32.5,
                        children: List.generate(
                          children.length,
                          (index) => _buildChildDetailsContainer(
                            width: boxConstraints.maxWidth * 0.45,
                            student: children[index],
                            index: index,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Animate(
      effects: [
        FadeEffect(duration: const Duration(milliseconds: 600)),
        SlideEffect(
          duration: const Duration(milliseconds: 600),
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ),
      ],
      child: InkWell(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.89),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Utils.getTranslatedLabel(welcomeBackKey),
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                Utils.getTranslatedLabel(welcomeDescKey),
                style: TextStyle(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.9),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .shimmer(
            duration: const Duration(seconds: 5),
            color: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: 0.2),
            size: 0.1,
            curve: Curves.easeInOutSine,
            delay: Duration(milliseconds: 1000),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
      body: context.read<AppConfigurationCubit>().appUnderMaintenance()
          ? const AppUnderMaintenanceContainer()
          : Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: Theme.of(context).colorScheme.primary,
                    edgeOffset: Utils.getScrollViewTopPadding(
                      context: context,
                      appBarHeightPercentage:
                          Utils.appBarMediumtHeightPercentage,
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: 50,
                        top: Utils.getScrollViewTopPadding(
                          context: context,
                          appBarHeightPercentage:
                              Utils.appBarMediumtHeightPercentage,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildWelcomeMessage(),
                          const SizedBox(height: 15),
                          _buildChildrenContainer(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildAppBar(),
                //Check force update here
                context.read<AppConfigurationCubit>().forceUpdate()
                    ? FutureBuilder<bool>(
                        future: Utils.forceUpdate(
                          context.read<AppConfigurationCubit>().getAppVersion(),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return (snapshot.data ?? false)
                                ? const ForceUpdateDialogContainer()
                                : const SizedBox();
                          }
                          return const SizedBox();
                        },
                      )
                    : const SizedBox(),
              ],
            ),
    );
  }
}
