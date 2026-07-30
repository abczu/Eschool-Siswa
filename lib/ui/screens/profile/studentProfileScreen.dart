import 'package:eschool/cubits/system/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/student/studentAllProfileDetailsCubit.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/data/repositories/student/studentRepository.dart';
import 'package:eschool/data/repositories/auth/authRepository.dart';
import 'package:eschool/ui/styles/colors.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/customUserProfileImageWidget.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/shimmerLoadingContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class StudentProfileScreen extends StatefulWidget {
  final int? childId;

  const StudentProfileScreen({Key? key, this.childId}) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();

  static Widget routeInstance() {
    return BlocProvider(
      create: (context) => StudentAllProfileDetailsCubit(StudentRepository()),
      child: Builder(
        builder: (context) {
          final arguments = Get.arguments;
          int? childId;

          // Handle dari notifikasi (Map) atau navigasi normal (int?)
          if (arguments is int) {
            childId = arguments;
          } else if (arguments is Map<String, dynamic> &&
              arguments['childId'] != null) {
            childId = arguments['childId'] is int
                ? arguments['childId']
                : int.tryParse(arguments['childId'].toString());
          } else {
            // Fallback: null (akan menggunakan student yang login)
            childId = null;
          }

          return StudentProfileScreen(childId: childId);
        },
      ),
    );
  }
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingActionButton = false;
  bool _hasAnimatedOnce = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showFloatingActionButton) {
        setState(() {
          _showFloatingActionButton = true;
        });
      } else if (_scrollController.offset <= 300 && _showFloatingActionButton) {
        setState(() {
          _showFloatingActionButton = false;
        });
      }
    });

    Future.delayed(Duration.zero, () {
      fetchStudentAllProfileDetails();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void fetchStudentAllProfileDetails() {
    context.read<StudentAllProfileDetailsCubit>().getStudentAllProfileDetails(
        useParentApi: widget.childId != null, childId: widget.childId);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildProfileDetailsTile(
      {required String label,
      required String value,
      required String iconUrl,
      Color? iconColor,
      VoidCallback? tapFunction}) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.5, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.2,
          0.6,
          curve: Curves.easeOutCubic,
        ),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.2, 0.6, curve: Curves.easeOut),
          ),
        ),
        child: GestureDetector(
          onTap: tapFunction,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: SvgPicture.asset(
                    iconUrl,
                    theme: SvgTheme(
                        currentColor: iconColor ??
                            Theme.of(context).scaffoldBackgroundColor),
                    colorFilter: iconColor == null
                        ? null
                        : ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                          fontSize: 13.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.0,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
              child: Hero(
                tag: 'backButton',
                child: const CustomBackButton(),
              ),
            ),
            FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0, 0.5, curve: Curves.easeIn),
                ),
              ),
              child: Text(
                Utils.getTranslatedLabel(profileKey),
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsContainer({required Student studentDetails}) {
    // Run animation only once after initial render
    if (!_hasAnimatedOnce) {
      _hasAnimatedOnce = true;
      _animationController.forward(from: 0.0);
    }

    final String activeSchoolCode = (studentDetails.school?.code != null &&
            studentDetails.school!.code!.isNotEmpty)
        ? studentDetails.school!.code!
        : (studentDetails.schoolCode != null &&
                studentDetails.schoolCode!.isNotEmpty)
            ? studentDetails.schoolCode!
            : AuthRepository().schoolCode;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(
          top: Utils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
          ),
          bottom: 30,
        ),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Header
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Interval(0, 0.4, curve: Curves.easeOut),
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0, 0.4, curve: Curves.easeIn),
                  ),
                ),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'profileImage${studentDetails.id}',
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CustomUserProfileImageWidget(
                              profileUrl: Utils.fixImageUrl(
                                  (studentDetails.childUserDetails?.image != null &&
                                          studentDetails.childUserDetails!.image!.isNotEmpty)
                                      ? studentDetails.childUserDetails!.image!
                                      : (studentDetails.image ?? "")),
                              context: context,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        studentDetails.getFullName(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          fontSize: 22.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "${Utils.getTranslatedLabel(grNumberKey)} - ${studentDetails.admissionNo}",
                          style: TextStyle(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                      Utils.getTranslatedLabel(personalDetailsKey)),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(schoolKey),
                    value: Utils.formatEmptyValue(
                      studentDetails.school?.name == null
                          ? ""
                          : activeSchoolCode.isNotEmpty
                              ? "${studentDetails.school!.name} ($activeSchoolCode)"
                              : studentDetails.school!.name!,
                    ),
                    iconUrl: Utils.getImagePath("school.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(classKey),
                    value: Utils.formatEmptyValue(
                      studentDetails.classSection?.name ?? "",
                    ),
                    iconUrl: Utils.getImagePath("user_pro_class_icon.svg"),
                  ),
                  (studentDetails.classSection?.classDetails
                                  ?.includeSemesters ??
                              0) ==
                          1
                      ? _buildProfileDetailsTile(
                          label: Utils.getTranslatedLabel(semesterKey),
                          value: Utils.formatEmptyValue(
                            context
                                    .read<SchoolConfigurationCubit>()
                                    .getSchoolConfiguration()
                                    .semesterDetails
                                    .name ??
                                "",
                          ),
                          iconColor: Theme.of(context).scaffoldBackgroundColor,
                          iconUrl: Utils.getImagePath("sem_pro_icon.svg"),
                        )
                      : const SizedBox(),
                  (studentDetails.classSection?.classDetails?.streamDetails
                                  ?.name ??
                              "")
                          .isNotEmpty
                      ? _buildProfileDetailsTile(
                          label: Utils.getTranslatedLabel(streamKey),
                          value: Utils.formatEmptyValue(
                            studentDetails.classSection?.classDetails
                                    ?.streamDetails?.name ??
                                "",
                          ),
                          iconColor: Theme.of(context).scaffoldBackgroundColor,
                          iconUrl: Utils.getImagePath("stream_pro_icon.svg"),
                        )
                      : const SizedBox(),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(mediumKey),
                    value: Utils.formatEmptyValue(
                      studentDetails.classSection?.medium?.name ?? "",
                    ),
                    iconUrl: Utils.getImagePath("medium_icon.svg"),
                  ),
                  if (studentDetails.classSection?.classDetails?.shift?.name !=
                          null &&
                      (studentDetails.classSection?.classDetails?.shift?.name ??
                              "")
                          .trim()
                          .isNotEmpty)
                    _buildProfileDetailsTile(
                      label: Utils.getTranslatedLabel(shiftKey),
                      value: Utils.formatEmptyValue(
                        "${studentDetails.classSection!.classDetails!.shift!.name} (${studentDetails.classSection!.classDetails!.shift!.startToEndTime ?? ''})",
                      ),
                      iconUrl: Utils.getImagePath("user_pro_shift_icon.svg"),
                    ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(rollNumberKey),
                    value: studentDetails.rollNumber.toString(),
                    iconUrl: Utils.getImagePath("user_pro_roll_no_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(dateOfBirthKey),
                    value: Utils.formatEmptyValue(
                        DateTime.tryParse(studentDetails.dob ?? "") == null
                            ? "-"
                            : Utils.formatDate(
                                DateTime.tryParse(studentDetails.dob!)!)),
                    iconUrl: Utils.getImagePath("user_pro_dob_icon.svg"),
                  ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(currentAddressKey),
                    value: Utils.formatEmptyValue(
                        studentDetails.currentAddress ?? ""),
                    iconUrl: Utils.getImagePath("user_pro_address_icon.svg"),
                    tapFunction: () async {
                      final address = studentDetails.permanentAddress;

                      if (address != null && address.isNotEmpty) {
                        final Uri mapUri = Uri(
                          scheme: 'geo',
                          host: '0,0',
                          queryParameters: {'q': address},
                        );

                        if (await Utils.canLaunchUrl(mapUri)) {
                          await Utils.launchUrl(mapUri);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alamat belum diisi')),
                        );
                      }
                    },
                  ),
                  _buildProfileDetailsTile(
                    label: Utils.getTranslatedLabel(permanentAddressKey),
                    value: Utils.formatEmptyValue(
                        studentDetails.permanentAddress ?? ""),
                    iconUrl: Utils.getImagePath("user_pro_address_icon.svg"),
                    tapFunction: () async {
                      final address = studentDetails.permanentAddress;

                      if (address != null && address.isNotEmpty) {
                        final Uri mapUri = Uri(
                          scheme: 'geo',
                          host: '0,0',
                          queryParameters: {'q': address},
                        );

                        if (await Utils.canLaunchUrl(mapUri)) {
                          await Utils.launchUrl(mapUri);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alamat belum diisi')),
                        );
                      }
                    },
                  ),
                  if ((studentDetails.studentProfileExtraDetails ?? [])
                      .isNotEmpty)
                    ...(studentDetails.studentProfileExtraDetails ?? []).map(
                      (details) {
                        final label = Utils.getTranslatedLabel(
                            details.formField?.name ?? "");
                        final value =
                            Utils.formatEmptyValue(details.data ?? "");

                        return _buildProfileDetailsTile(
                          label: label,
                          value: value,
                          iconColor: Theme.of(context).scaffoldBackgroundColor,
                          iconUrl: Utils.getImagePath("info_pro_icon.svg"),
                          tapFunction: () async {
                            // ✅ Salin ke clipboard
                            if (value.isNotEmpty) {
                              await Clipboard.setData(
                                  ClipboardData(text: value));

                              // ✅ Tampilkan notifikasi berhasil
                              final snackBar = SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                        '$label ${Utils.getTranslatedLabel(copy_to_clipboardKey)}'),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              );

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                          },
                        );
                      },
                    ).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentDetailsShimmerLoading() {
    return Padding(
      padding: EdgeInsets.only(
        top: Utils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Animated shimmer profile header
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: ShimmerLoadingContainer(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  padding: const EdgeInsets.all(20),
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: shimmerContentColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),

            // Section title shimmer
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset((1 - value) * 50, 0),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    ShimmerLoadingContainer(
                      child: Container(
                        height: 24,
                        width: 4,
                        decoration: BoxDecoration(
                          color: shimmerContentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShimmerLoadingContainer(
                      child: Container(
                        height: 20,
                        width: 150,
                        decoration: BoxDecoration(
                          color: shimmerContentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Shimmer details tiles with staggered animation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: List.generate(
                  6,
                  (index) => TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    // Stagger the animations
                    curve: Interval(
                        0.1 * index, (0.1 * index + 0.6).clamp(0.0, 1.0),
                        curve: Curves.easeOut),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset((1 - value) * 100, 0),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: ShimmerLoadingContainer(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: shimmerContentColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Loading indicator at bottom
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1000),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: child,
                  );
                },
                child: Center(
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _showFloatingActionButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
      body: Stack(
        children: [
          BlocBuilder<StudentAllProfileDetailsCubit,
              StudentAllProfileDetailsState>(
            builder: (context, state) {
              if (state is StudentAllProfileDetailsFetchSuccess) {
                return _buildProfileDetailsContainer(
                    studentDetails: state.student);
              }
              if (state is StudentAllProfileDetailsFetchFailure) {
                return Center(
                  child: ErrorContainer(
                    errorMessageCode: state.errorMessage,
                    onTapRetry: () {
                      fetchStudentAllProfileDetails();
                    },
                  ),
                );
              }
              return _buildStudentDetailsShimmerLoading();
            },
          ),
          _buildAppBar(),
        ],
      ),
    );
  }
}
