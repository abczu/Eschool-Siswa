import 'package:eschool/cubits/academic/assignmentsCubit.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/academic/undoAssignmentSubmissionCubit.dart';
import 'package:eschool/cubits/academic/uploadAssignmentCubit.dart';
import 'package:eschool/data/models/academic/assignment.dart';
import 'package:eschool/data/repositories/academic/assignmentRepository.dart';
import 'package:eschool/ui/screens/academic/assignment/widgets/assignmentContentSection.dart';
import 'package:eschool/ui/screens/academic/assignment/widgets/assignmentDetailsCard.dart';
import 'package:eschool/ui/screens/academic/assignment/widgets/assignmentFloatingActionButton.dart';
import 'package:eschool/ui/screens/academic/assignment/widgets/assignmentSubmissionStatusCard.dart';
import 'package:eschool/ui/screens/academic/assignment/widgets/undoAssignmentBottomsheetContainer.dart';
import 'package:eschool/ui/screens/academic/assignment/widgets/uploadAssignmentFilesBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';

class AssignmentScreen extends StatefulWidget {
  final Assignment assignment;
  const AssignmentScreen({Key? key, required this.assignment})
      : super(key: key);

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();

  static Widget routeInstance() {
    final args = Get.arguments;
    print("Args di AssignmentScreen: $args");
    late Assignment assignment;

    if (args is Assignment) {
      assignment = args;
    } else if (args is Map<String, dynamic>) {
      assignment = Assignment.fromJson(args);
    } else {
      throw ArgumentError("Invalid arguments for AssignmentScreen: $args");
    }

    return AssignmentScreen(
      assignment: assignment,
    );
  }
}

class _AssignmentScreenState extends State<AssignmentScreen>
    with SingleTickerProviderStateMixin {
  bool isUndoAssignmentSubmissionButtonToBeShown = false;
  late bool assignmentSubmitted =
      submittedAssignment.assignmentSubmission.id != 0;
  late Assignment submittedAssignment = widget.assignment;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerAnimation;
  late Animation<Offset> _contentAnimation;
  late Animation<Offset> _submissionAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _headerAnimation = Tween<Offset>(
            begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic)));

    _contentAnimation = Tween<Offset>(
            begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)));

    _submissionAnimation = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic)));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void uploadAssignment() {
    Utils.showBottomSheet(
      child: BlocProvider<UploadAssignmentCubit>(
        create: (_) => UploadAssignmentCubit(AssignmentRepository()),
        child: UploadAssignmentFilesBottomsheetContainer(
          assignment: submittedAssignment,
        ),
      ),
      context: context,
      enableDrag: true,
    ).then((value) {
      if (value != null) {
        if (value['error']) {
          final rawMsg = value['message'].toString();
          final String errMsg = RegExp(r'^\d+$').hasMatch(rawMsg)
              ? Utils.getErrorMessageFromErrorCode(
                  context,
                  rawMsg,
                  source: "tugas",
                )
              : ErrorMessageMapper.getUserFriendlyMessage(rawMsg);
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: errMsg,
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        } else {
          submittedAssignment = submittedAssignment
              .updateAssignmentSubmission(value['assignmentSubmission']);
          assignmentSubmitted = true;
          context
              .read<AssignmentsCubit>()
              .updateAssignments(submittedAssignment);
          setState(() {});
        }
      }
    });
  }

  void undoAssignment() {
    Utils.showBottomSheet(
      child: BlocProvider<UndoAssignmentSubmissionCubit>(
        create: (_) => UndoAssignmentSubmissionCubit(AssignmentRepository()),
        child: UndoAssignmentBottomsheetContainer(
          assignmentSubmissionId: submittedAssignment.assignmentSubmission.id,
        ),
      ),
      context: context,
      enableDrag: false,
    ).then((value) {
      if (value != null) {
        if (value['error']) {
          final rawMsg = value['message'].toString();
          final String errMsg = RegExp(r'^\d+$').hasMatch(rawMsg)
              ? Utils.getErrorMessageFromErrorCode(
                  context,
                  rawMsg,
                  source: "tugas",
                )
              : ErrorMessageMapper.getUserFriendlyMessage(rawMsg);
          Utils.showCustomSnackBar(
            context: context,
            errorMessage: errMsg,
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        } else {
          submittedAssignment = submittedAssignment
              .updateAssignmentSubmission(AssignmentSubmission.fromJson({}));
          assignmentSubmitted = false;
          isUndoAssignmentSubmissionButtonToBeShown = false;
          setState(() {});
          context
              .read<AssignmentsCubit>()
              .updateAssignments(submittedAssignment);
          uploadAssignment();
        }
      }
    });
  }

  bool _showUploadAssignmentButton() {
    if (context.read<AuthCubit>().isParent()) {
      return false;
    }
    String assignmentStatusKey = Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    );

    DateTime currentDayDateTime = DateTime.now();

    if (assignmentStatusKey == inReviewKey &&
        currentDayDateTime.compareTo(submittedAssignment.dueDate) != 1) {
      isUndoAssignmentSubmissionButtonToBeShown = true;
      return true;
    }

    if (assignmentStatusKey == acceptedKey ||
        assignmentStatusKey == inReviewKey ||
        assignmentStatusKey == resubmittedKey) {
      return false;
    }

    if (assignmentStatusKey == rejectedKey) {
      if (submittedAssignment.resubmission == 0) {
        return false;
      }
      if (currentDayDateTime.compareTo(
            submittedAssignment.dueDate.add(
              Duration(
                days: submittedAssignment.extraDaysForResubmission,
              ),
            ),
          ) ==
          1) {
        return false;
      }
      return true;
    }

    return true;
  }

  String getAssignmentSubmissionStatus() {
    if (Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    ).isNotEmpty) {
      return Utils.getTranslatedLabel(
        Utils.getAssignmentSubmissionStatusKey(
            submittedAssignment.assignmentSubmission.status),
      );
    }
    return "";
  }

  Widget _buildUnifiedAssignmentView() {
    String assignmentStatusKey = Utils.getAssignmentSubmissionStatusKey(
      submittedAssignment.assignmentSubmission.status,
    );

    DateTime dueDate = submittedAssignment.dueDate;
    if ((assignmentStatusKey == rejectedKey &&
            submittedAssignment.resubmission == 1) ||
        assignmentStatusKey == resubmittedKey) {
      dueDate = submittedAssignment.dueDate
          .add(Duration(days: submittedAssignment.extraDaysForResubmission));
    }

    final now = DateTime.now();
    final isToday = dueDate.day == now.day &&
        dueDate.month == now.month &&
        dueDate.year == now.year;
    final hasPassed = dueDate.isBefore(now) && !isToday;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Column(
      children: [
        SlideTransition(
          position: _headerAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AssignmentDetailsCard(
                  assignment: submittedAssignment,
                  isSmallScreen: isSmallScreen,
                  hasPassed: hasPassed,
                  isToday: isToday,
                  assignmentSubmitted: assignmentSubmitted,
                  submissionStatus: getAssignmentSubmissionStatus(),
                ),
                SlideTransition(
                  position: _contentAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    child: AssignmentContentSection(
                      assignment: submittedAssignment,
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (assignmentSubmitted)
          SlideTransition(
            position: _submissionAnimation,
            child: AssignmentSubmissionStatusCard(
              assignment: submittedAssignment,
              isSmallScreen: isSmallScreen,
              submissionStatus: getAssignmentSubmissionStatus(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height *
                  Utils.appBarMediumtHeightPercentage,
              bottom: 90,
            ),
            physics: const BouncingScrollPhysics(),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: child,
                );
              },
              child: _buildUnifiedAssignmentView(),
            ),
          ),
          ScreenTopBackgroundContainer(
            heightPercentage: Utils.appBarSmallerHeightPercentage,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  const Positioned(
                    left: 10,
                    top: -2,
                    child: CustomBackButton(),
                  ),
                  Text(
                    Utils.getTranslatedLabel(assignmentKey),
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showUploadAssignmentButton())
            AssignmentFloatingActionButton(
              isUndo: isUndoAssignmentSubmissionButtonToBeShown,
              onTap: () {
                if (isUndoAssignmentSubmissionButtonToBeShown) {
                  undoAssignment();
                } else {
                  uploadAssignment();
                }
              },
            ),
        ],
      ),
    );
  }
}
