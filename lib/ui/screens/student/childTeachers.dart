import 'package:eschool/cubits/student/childTeachersCubit.dart';
import 'package:eschool/data/models/academic/subjectTeacher.dart';
import 'package:eschool/data/repositories/auth/parentRepository.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/customUserProfileImageWidget.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/noDataContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/shimmerLoadingContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ChildTeachersScreen extends StatefulWidget {
  final int childId;
  const ChildTeachersScreen({Key? key, required this.childId})
      : super(key: key);

  @override
  State<ChildTeachersScreen> createState() => _ChildTeachersScreenState();

  static Widget routeInstance() {
    return BlocProvider<ChildTeachersCubit>(
      create: (context) => ChildTeachersCubit(ParentRepository()),
      child: ChildTeachersScreen(childId: Get.arguments as int),
    );
  }
}

class _ChildTeachersScreenState extends State<ChildTeachersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    Future.delayed(Duration.zero, () {
      context
          .read<ChildTeachersCubit>()
          .fetchChildTeachers(childId: widget.childId);
      _animationController.forward();
    });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildTeacherCard(SubjectTeacher subjectTeacher, int index) {
    return Animate(
      effects: [
        FadeEffect(
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
        ),
        SlideEffect(
          begin: Offset(0.2, 0),
          end: Offset.zero,
          duration: Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
          curve: Curves.easeOutQuint,
        ),
      ],
      autoPlay: true,
      onComplete: (controller) => controller.stop(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Show teacher details or action
              _showTeacherDetailsBottomSheet(subjectTeacher);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Hero(
                    tag:
                        'teacher_${subjectTeacher.teacher?.id}_${subjectTeacher.subject?.id}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomUserProfileImageWidget(
                          profileUrl: subjectTeacher.teacher?.image ?? "",
                          radius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectTeacher.teacher?.fullName ?? "",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: subjectTeacher.subject?.nameWithType ==
                                    "Wali Kelas"
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: subjectTeacher.subject?.nameWithType ==
                                    "Wali Kelas"
                                ? Border.all(
                                    color: Colors.orange.withValues(alpha: 0.5))
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (subjectTeacher.subject?.nameWithType ==
                                  "Wali Kelas")
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  subjectTeacher.subject?.nameWithType ?? "",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subjectTeacher.subject?.nameWithType ==
                                            "Wali Kelas"
                                        ? Colors.orange
                                        : Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.call_outlined,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              subjectTeacher.teacher?.mobile ?? "Not available",
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String? mobile) async {
    if (mobile == null || mobile.isEmpty) return;

    var contactNumber = mobile.trim();
    if (contactNumber.startsWith("0")) {
      contactNumber = contactNumber.replaceFirst("0", "62");
    }

    final url = Uri.parse("https://wa.me/$contactNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback or error handling
      if (mounted) {
        Utils.showCustomSnackBar(
          context: context,
          errorMessage: "Could not launch WhatsApp",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  Future<void> _launchDialer(String? mobile) async {
    if (mobile == null || mobile.isEmpty) return;
    final url = Uri.parse("tel:$mobile");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        Utils.showCustomSnackBar(
          context: context,
          errorMessage: "Could not launch dialer",
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  void _showTeacherDetailsBottomSheet(SubjectTeacher subjectTeacher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 10,
              alignment: Alignment.center,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Hero(
                      tag:
                          'teacher_${subjectTeacher.teacher?.id}_${subjectTeacher.subject?.id}',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CustomUserProfileImageWidget(
                            profileUrl: subjectTeacher.teacher?.image ?? "",
                            radius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subjectTeacher.teacher?.fullName ?? "",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        subjectTeacher.subject?.nameWithType ?? "",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildContactActions(
                      context: context,
                      mobile: subjectTeacher.teacher?.mobile,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContactActions({
    required BuildContext context,
    required String? mobile,
  }) {
    final bool hasMobile = mobile != null && mobile.isNotEmpty;
    final String displayMobile = hasMobile ? mobile : "Not available";

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.phone_iphone_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nomer Telepon",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayMobile,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (hasMobile) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: Icons.call_rounded,
                    label: "Call",
                    color: Colors.green,
                    onTap: () => _launchDialer(mobile),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: FontAwesomeIcons.whatsapp,
                    label: "WhatsApp",
                    color: Color(0xFF25D366),
                    onTap: () => _launchWhatsApp(mobile),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: Icons.copy_rounded,
                    label: "Copy",
                    color: Theme.of(context).colorScheme.primary,
                    isOutlined: true,
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: mobile));
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                      child:
                                          Text("Nomor disalin ke papan klip")),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(12),
                            ),
                          );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return Material(
      color: isOutlined ? Colors.transparent : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isOutlined
                ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isOutlined ? color : color,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOutlined ? color : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherShimmerLoading() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ShimmerLoadingContainer(
              child: CustomShimmerContainer(
                width: 70,
                height: 70,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoadingContainer(
                    child: CustomShimmerContainer(
                      height: 18,
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 8),
                    ),
                  ),
                  ShimmerLoadingContainer(
                    child: CustomShimmerContainer(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.3,
                      margin: EdgeInsets.only(bottom: 12),
                    ),
                  ),
                  ShimmerLoadingContainer(
                    child: CustomShimmerContainer(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachersList() {
    return BlocBuilder<ChildTeachersCubit, ChildTeachersState>(
      builder: (context, state) {
        if (state is ChildTeachersFetchSuccess) {
          if (state.subjectTeachers.isEmpty) {
            return Animate(
              effects: [
                FadeEffect(duration: Duration(milliseconds: 400)),
                ScaleEffect(duration: Duration(milliseconds: 400)),
              ],
              autoPlay: true,
              onComplete: (controller) => controller.stop(),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image.asset(
                    //   'assets/images/no_data.png',
                    //   height: 150,
                    //   width: 150,
                    //   fit: BoxFit.contain,
                    // ),
                    // const SizedBox(height: 16),
                    const NoDataContainer(titleKey: noTeachersFoundKey),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              top: Utils.getScrollViewTopPadding(
                context: context,
                appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
              ),
              bottom: 20,
            ),
            itemCount: state.subjectTeachers.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildTeacherCard(state.subjectTeachers[index], index),
                    Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2),
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                  ],
                );
              }
              return _buildTeacherCard(state.subjectTeachers[index], index);
            },
          );
        }

        if (state is ChildTeachersFetchFailure) {
          return Center(
            child: ErrorContainer(
              errorMessageCode: state.errorMessage,
              onTapRetry: () {
                context
                    .read<ChildTeachersCubit>()
                    .fetchChildTeachers(childId: widget.childId);
              },
            ),
          );
        }

        // Loading state
        return ListView.builder(
          padding: EdgeInsets.only(
            top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
                ) +
                10,
            bottom: 20,
          ),
          itemCount: 5,
          itemBuilder: (context, index) => _buildTeacherShimmerLoading(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      _buildTeachersList(),
      ScreenTopBackgroundContainer(
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
                    child: const CustomBackButton(),
                  ),
                  Text(
                    Utils.getTranslatedLabel(teachersKey),
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ]),
          ))
    ]));
  }

  // Align(
  //   alignment: Alignment.topCenter,
  //   child: ScreenTopBackgroundContainer(
  //     heightPercentage: Utils.appBarSmallerHeightPercentage,
  //     child: Stack(
  //       clipBehavior: Clip.none,
  //       alignment: Alignment.topCenter,
  //       children: [
  //         const CustomBackButton(),
  //         Center(
  //             child: Animate(
  //           effects: [
  //             FadeEffect(duration: Duration(milliseconds: 300)),
  //             SlideEffect(
  //                 begin: Offset(0, -0.1),
  //                 end: Offset.zero,
  //                 duration: Duration(milliseconds: 300)),
  //           ],
  //           autoPlay: true,
  //           onComplete: (controller) => controller.stop(),
  //           child: Text(
  //             Utils.getTranslatedLabel(teachersKey),
  //             style: TextStyle(
  //               color: Theme.of(context).scaffoldBackgroundColor,
  //               fontSize: Utils.screenTitleFontSize,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         )),
  //       ],
  //     ),
  //   ),
  // ),
}
