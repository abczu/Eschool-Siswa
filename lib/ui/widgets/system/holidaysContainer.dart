import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/system/holidaysCubit.dart';
import 'package:eschool/cubits/system/schoolConfigurationCubit.dart';
import 'package:eschool/data/models/system/holiday.dart';
import 'package:eschool/ui/widgets/system/changeCalendarMonthButton.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/shimmerLoadingContainer.dart';
import 'package:eschool/utils/system/animationConfiguration.dart';
import 'package:eschool/utils/system/constants.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

class HolidaysContainer extends StatefulWidget {
  final int? childId;
  const HolidaysContainer({Key? key, this.childId}) : super(key: key);

  @override
  State<HolidaysContainer> createState() => _HolidaysContainerState();
}

class _HolidaysContainerState extends State<HolidaysContainer> {
  //last and first day of calendar
  late DateTime firstDay = DateTime.now();
  late DateTime lastDay = DateTime.now();

  //current day
  late DateTime focusedDay = DateTime.now();
  late List<Holiday> holidays = [];
  PageController? calendarPageController;

  // Map to track expanded state for each holiday description
  Map<int, bool> expandedStates = {};

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      context.read<HolidaysCubit>().fetchHolidays(childId: widget.childId);
    });
    super.initState();
  }

  void updateMonthViceHolidays() {
    holidays.clear();
    for (final holiday in context.read<HolidaysCubit>().holidays()) {
      // Check if the holiday range overlaps with the current month
      if ((holiday.startDate.month == focusedDay.month &&
              holiday.startDate.year == focusedDay.year) ||
          (holiday.endDate.month == focusedDay.month &&
              holiday.endDate.year == focusedDay.year) ||
          (holiday.startDate
                  .isBefore(DateTime(focusedDay.year, focusedDay.month, 1)) &&
              holiday.endDate.isAfter(
                  DateTime(focusedDay.year, focusedDay.month + 1, 0)))) {
        holidays.add(holiday);
      }
    }

    holidays
        .sort((first, second) => first.startDate.compareTo(second.startDate));
    setState(() {});
  }

  String _formatDateRange(Holiday holiday) {
    if (holiday.startDate == holiday.endDate) {
      return Utils.formatDate(holiday.startDate);
    } else {
      return "${Utils.formatDate(holiday.startDate)}  ~  ${Utils.formatDate(holiday.endDate)}";
    }
  }

  Widget _buildHolidayDetailsList() {
    final primaryColor =
        Theme.of(context).colorScheme.primary; // Red color for header

    return Column(
      children: List.generate(
        holidays.length,
        (index) => Animate(
          key: isApplicationItemAnimationOn ? UniqueKey() : null,
          effects: listItemAppearanceEffects(
              itemIndex: index, totalLoadedItems: holidays.length),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16.0),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date indicator with primary color
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.9),
                            primaryColor.withValues(alpha: 0.8)
                          ],
                          end: Alignment.topRight,
                          begin: Alignment.bottomLeft,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, size: 20, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatDateRange(holidays[index]),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Holiday title
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 12.0),
                      child: Animate(
                        effects: [
                          FadeEffect(
                              duration: const Duration(milliseconds: 300)),
                          SlideEffect(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                            duration: const Duration(milliseconds: 300),
                          ),
                        ],
                        child: Text(
                          holidays[index].title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 17.0,
                          ),
                        ),
                      ),
                    ),
                    // Holiday description with elegant styling
                    if (holidays[index].description.isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1.0,
                            ),
                          ),
                          child: Animate(
                            effects: [
                              FadeEffect(
                                duration: const Duration(milliseconds: 400),
                                delay: const Duration(milliseconds: 100),
                              ),
                            ],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14.0,
                                      height: 1.6,
                                      letterSpacing: 0.2,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _getDisplayText(
                                            holidays[index].description, index),
                                      ),
                                      if (_shouldShowReadMore(
                                          holidays[index].description, index))
                                        TextSpan(
                                          text: expandedStates[index] == true
                                              ? ''
                                              : '...',
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (_shouldShowReadMore(
                                    holidays[index].description, index))
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        expandedStates[index] =
                                            !(expandedStates[index] ?? false);
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        expandedStates[index] == true
                                            ? "Baca lebih sedikit"
                                            : "Baca selengkapnya",
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(
              begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms),
        ),
      ),
    );
  }

  Widget _buildCalendarContainer() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.075),
            offset: const Offset(5.0, 5),
            blurRadius: 10,
          )
        ],
        borderRadius: BorderRadius.circular(15.0),
      ),
      margin: const EdgeInsets.only(top: 20),
      child: TableCalendar(
        locale: 'id_ID',
        headerVisible: false,
        daysOfWeekHeight: 40,
        onPageChanged: (DateTime dateTime) {
          setState(() {
            focusedDay = dateTime;
          });
          updateMonthViceHolidays();
        },

        onCalendarCreated: (contoller) {
          calendarPageController = contoller;
        },

        holidayPredicate: (dateTime) {
          // Check if the date is part of any holiday range
          return holidays.any((holiday) {
            return dateTime.isAtSameMomentAs(holiday.startDate) ||
                dateTime.isAtSameMomentAs(holiday.endDate) ||
                (dateTime.isAfter(holiday.startDate) &&
                    dateTime.isBefore(holiday.endDate)) ||
                (dateTime.year == holiday.startDate.year &&
                    dateTime.month == holiday.startDate.month &&
                    dateTime.day == holiday.startDate.day) ||
                (dateTime.year == holiday.endDate.year &&
                    dateTime.month == holiday.endDate.month &&
                    dateTime.day == holiday.endDate.day);
          });
        },

        availableGestures: AvailableGestures.none,
        calendarStyle: CalendarStyle(
          isTodayHighlighted: false,
          holidayTextStyle:
              TextStyle(color: Theme.of(context).scaffoldBackgroundColor),
          holidayDecoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekendStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          weekdayStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        headerStyle:
            const HeaderStyle(titleCentered: true, formatButtonVisible: false),
        firstDay: firstDay, //start education year
        lastDay: lastDay, //end education year
        focusedDay: focusedDay,
      ),
    );
  }

  Widget _buildHolidaysCalendar() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width *
              Utils.screenContentHorizontalPaddingInPercentage,
          right: MediaQuery.of(context).size.width *
              Utils.screenContentHorizontalPaddingInPercentage,
          bottom: Utils.getScrollViewBottomPadding(context),
          top: Utils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
          ),
        ),
        child: BlocConsumer<HolidaysCubit, HolidaysState>(
          listener: (context, state) {
            if (state is HolidaysFetchSuccess) {
              print(context
                  .read<SchoolConfigurationCubit>()
                  .getSchoolConfiguration()
                  .sessionYear
                  .toJson());
              if (Utils.isTodayInSessionYear(
                context
                    .read<SchoolConfigurationCubit>()
                    .getSchoolConfiguration()
                    .sessionYear
                    .getStartDateInDateTime(),
                context
                    .read<SchoolConfigurationCubit>()
                    .getSchoolConfiguration()
                    .sessionYear
                    .getEndDateInDateTime(),
              )) {
                firstDay = context
                    .read<SchoolConfigurationCubit>()
                    .getSchoolConfiguration()
                    .sessionYear
                    .getStartDateInDateTime();
                lastDay = context
                    .read<SchoolConfigurationCubit>()
                    .getSchoolConfiguration()
                    .sessionYear
                    .getEndDateInDateTime();

                updateMonthViceHolidays();
              }
            }
          },
          builder: (context, state) {
            if (state is HolidaysFetchSuccess) {
              return Column(
                children: [
                  _buildCalendarContainer(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * (0.025),
                  ),
                  _buildHolidayDetailsList()
                ],
              );
            }

            if (state is HolidaysFetchFailure) {
              return Center(
                child: ErrorContainer(
                  errorMessageCode: state.errorMessage,
                  onTapRetry: () {
                    context
                        .read<HolidaysCubit>()
                        .fetchHolidays(childId: widget.childId);
                  },
                ),
              );
            }
            return Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    height: MediaQuery.of(context).size.height * (0.425),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    bool _disableChangeNextMonthButton() {
      return focusedDay.year == lastDay.year &&
          focusedDay.month == lastDay.month;
    }

    bool _disableChangePrevMonthButton() {
      return firstDay.month == focusedDay.month &&
          firstDay.year == focusedDay.year;
    }

    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarMediumtHeightPercentage,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          context.read<AuthCubit>().isParent()
              ? CustomBackButton()
              : const SizedBox(),
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              Utils.getTranslatedLabel(holidaysKey),
              style: TextStyle(
                color: Theme.of(context).scaffoldBackgroundColor,
                fontSize: Utils.screenTitleFontSize,
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -20,
            start: MediaQuery.of(context).size.width * (0.075),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.075),
                    offset: const Offset(2.5, 2.5),
                    blurRadius: 5,
                  )
                ],
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              width: MediaQuery.of(context).size.width * (0.85),
              child: Stack(
                children: [
                  Align(
                    child: Text(
                      "${Utils.getTranslatedLabel(Utils.getMonthName(focusedDay.month))} ${focusedDay.year}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ChangeCalendarMonthButton(
                      onTap: () {
                        if (context.read<HolidaysCubit>().state
                            is HolidaysFetchInProgress) {
                          return;
                        }

                        if (_disableChangePrevMonthButton()) {
                          return;
                        }

                        calendarPageController?.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      isDisable: _disableChangePrevMonthButton(),
                      isNextButton: false,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ChangeCalendarMonthButton(
                      onTap: () {
                        if (context.read<HolidaysCubit>().state
                            is HolidaysFetchInProgress) {
                          return;
                        }

                        if (_disableChangeNextMonthButton()) {
                          return;
                        }

                        calendarPageController?.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      isDisable: _disableChangeNextMonthButton(),
                      isNextButton: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for read more functionality
  String _getDisplayText(String text, int index) {
    if (expandedStates[index] == true) {
      return text;
    } else {
      // Split text by words and limit to approximately 100 characters
      List<String> words = text.split(' ');
      String truncated = '';
      for (String word in words) {
        if ((truncated + word).length > 100) break;
        truncated += (truncated.isEmpty ? '' : ' ') + word;
      }
      return truncated;
    }
  }

  bool _shouldShowReadMore(String text, int index) {
    return text.length > 100;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildHolidaysCalendar(),
        _buildAppBar(),
      ],
    );
  }
}
