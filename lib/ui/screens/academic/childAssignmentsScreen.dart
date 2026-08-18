import 'package:eschool/cubits/academic/assignmentsCubit.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/data/models/academic/subject.dart';
import 'package:eschool/data/repositories/academic/assignmentRepository.dart';
import 'package:eschool/ui/widgets/academic/assignmentFilterBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/academic/assignmentsContainer.dart';
import 'package:eschool/ui/widgets/academic/assignmentListContainer.dart';
import 'package:eschool/ui/widgets/academic/assignmentsSubjectsContainer.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/system/svgButton.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ChildAssignmentsScreen extends StatefulWidget {
  final int childId;
  final List<Subject> subjects;
  final String? initialTab;
  const ChildAssignmentsScreen({
    Key? key,
    required this.childId,
    required this.subjects,
    this.initialTab,
  }) : super(key: key);

  @override
  State<ChildAssignmentsScreen> createState() => _ChildAssignmentsScreenState();

  static Widget routeInstance() {
    final arguments = Get.arguments;
    
    return BlocProvider<AssignmentsCubit>(
        create: (context) => AssignmentsCubit(AssignmentRepository()),
        child: Builder(
          builder: (context) {
            int childId;
            List<Subject> subjects;
            String? initialTab;
            
            final authCubit = context.read<AuthCubit>();
            final isParent = authCubit.isParent();
            
            // Handle dari notifikasi (Map) atau navigasi normal (Map dengan data lengkap)
            if (arguments is Map<String, dynamic>) {
              // ✅ FIX: Handle childId untuk parent & student
              if (arguments.containsKey('childId') && arguments['childId'] != null) {
                // Dari notifikasi atau navigasi dengan childId explicit
                childId = arguments['childId'] is int 
                    ? arguments['childId'] 
                    : int.tryParse(arguments['childId'].toString()) ?? 0;
              } else {
                // Fallback: ambil dari AuthCubit (hanya untuk student)
                childId = isParent 
                    ? 0 // Parent harus explicit pass childId
                    : (authCubit.getStudentDetails().id ?? 0);
              }
              
              subjects = arguments['subjects'] ?? [];
              initialTab = arguments['initialTab'];
            } else if (arguments is int) {
              // Legacy: direct childId as argument
              childId = arguments;
              subjects = [];
            } else {
              // Fallback: ambil dari AuthCubit (hanya untuk student)
              childId = isParent 
                  ? 0 // Parent harus explicit pass childId
                  : (authCubit.getStudentDetails().id ?? 0);
              subjects = [];
            }
            
            // ✅ Validasi childId
            if (childId == 0) {
              debugPrint('⚠️ ChildAssignmentsScreen: childId tidak valid! Arguments: $arguments');
            }
            
            return ChildAssignmentsScreen(
              childId: childId,
              subjects: subjects,
              initialTab: initialTab,
            );
          },
        ));
  }
}

class _ChildAssignmentsScreenState extends State<ChildAssignmentsScreen> {
  late String _assignmentStatusTabTitle = widget.initialTab ?? assignedKey;

  int _currentlySelectedClassSubjectId = 0;

  late AssignmentFilters selectedAssignmentFilter =
      AssignmentFilters.assignedDateLatest;

  late final ScrollController _scrollController = ScrollController()
    ..addListener(_assignmentsScrollListener);

  int isAssignmentSubmitted() {
    return _assignmentStatusTabTitle == assignedKey ? 0 : 1;
  }

  void _assignmentsScrollListener() {
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      if (context.read<AssignmentsCubit>().hasMore()) {
        context.read<AssignmentsCubit>().fetchMoreAssignments(
              childId: widget.childId,
              isSubmitted: isAssignmentSubmitted(),
              useParentApi: context.read<AuthCubit>().isParent(),
            );
      }
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      fetchAssignments();
    });
    super.initState();
  }

  void fetchAssignments() {
    context.read<AssignmentsCubit>().fetchAssignments(
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.childId,
          isSubmitted: isAssignmentSubmitted(),
          classSubjectId: _currentlySelectedClassSubjectId,
        );
  }

  void changeAssignmentFilter(AssignmentFilters assignmentFilter) {
    setState(() {
      selectedAssignmentFilter = assignmentFilter;
    });
  }

  void onTapFilterButton() {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Utils.bottomSheetTopRadius),
          topRight: Radius.circular(Utils.bottomSheetTopRadius),
        ),
      ),
      context: context,
      builder: (_) => AssignmentFilterBottomsheetContainer(
        changeAssignmentFilter: changeAssignmentFilter,
        initialAssignmentFilterValue: selectedAssignmentFilter,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_assignmentsScrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildAppBarContainer() {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarBiggerHeightPercentage - (Utils.appBarBiggerHeightPercentage * 0.1),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Stack(
            children: [
              // Back button
              const CustomBackButton(),
              
              // Filter button (only for assigned tab)
              _assignmentStatusTabTitle == submittedKey
                  ? const SizedBox()
                  : Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: Utils.screenContentHorizontalPadding,
                        ),
                        child: SvgButton(
                          onTap: () {
                            onTapFilterButton();
                          },
                          svgIconUrl: Utils.getImagePath("filter_icon.svg"),
                        ),
                      ),
                    ),
              
              // Screen title
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: boxConstraints.maxWidth * (0.5),
                  child: Text(
                    Utils.getTranslatedLabel(assignmentsKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ),
              ),
              
              // Tab selector container
              Align(
                alignment: Alignment(0.0, 0.3),
                child: Container(
                  width: boxConstraints.maxWidth * (0.7),
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      // Assigned Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _assignmentStatusTabTitle = assignedKey;
                            });
                            fetchAssignments();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 5.0,
                            ),
                            decoration: BoxDecoration(
                              color: _assignmentStatusTabTitle == assignedKey
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              Utils.getTranslatedLabel(assignedKey),
                              style: TextStyle(
                                color: _assignmentStatusTabTitle == assignedKey
                                    ? Colors.white
                                    : Theme.of(context).scaffoldBackgroundColor,
                                fontWeight: _assignmentStatusTabTitle == assignedKey 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Submitted Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _assignmentStatusTabTitle = submittedKey;
                            });
                            fetchAssignments();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 5.0,
                            ),
                            decoration: BoxDecoration(
                              color: _assignmentStatusTabTitle == submittedKey
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              Utils.getTranslatedLabel(submittedKey),
                              style: TextStyle(
                                color: _assignmentStatusTabTitle == submittedKey
                                    ? Colors.white
                                    : Theme.of(context).scaffoldBackgroundColor,
                                fontWeight: _assignmentStatusTabTitle == submittedKey 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
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
    );
  }

  Widget _buildAssignments() {
    return CustomRefreshIndicator(
      displacment: Utils.getScrollViewTopPadding(
        context: context,
        appBarHeightPercentage: Utils.appBarBiggerHeightPercentage - (Utils.appBarBiggerHeightPercentage * 0.1),
      ),
      onRefreshCallback: () {
        fetchAssignments();
      },
      child: SizedBox(
        height: double.maxFinite,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: Utils.getScrollViewTopPadding(
              context: context,
              appBarHeightPercentage: Utils.appBarBiggerHeightPercentage - (Utils.appBarBiggerHeightPercentage * 0.1),
            ),
          ),
          child: Column(
            children: [
              //
              AssignmentsSubjectContainer(
                cubitAndState: "assignment",
                subjects: widget.subjects,
                onTapSubject: (int classSubjectId) {
                  setState(() {
                    _currentlySelectedClassSubjectId = classSubjectId;
                  });

                  fetchAssignments();
                },
                selectedClassSubjectId: _currentlySelectedClassSubjectId,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * (0.035),
              ),
              AssignmentListContainer(
                assignmentTabTitle: _assignmentStatusTabTitle,
                currentSelectedSubjectId: _currentlySelectedClassSubjectId,
                selectedAssignmentFilter: selectedAssignmentFilter,
                isAssignmentSubmitted: isAssignmentSubmitted(),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildAssignments(),
          _buildAppBarContainer(),
        ],
      ),
    );
  }
}
