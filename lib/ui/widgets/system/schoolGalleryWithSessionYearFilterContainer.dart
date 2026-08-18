import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/system/schoolGalleryCubit.dart';
import 'package:eschool/cubits/system/schoolSessionYearsCubit.dart';
import 'package:eschool/data/models/academic/sessionYear.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/shimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/noDataContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class SchoolGalleryWithSessionYearFilterContainer extends StatefulWidget {
  final Student student;
  final bool showBackButton;
  const SchoolGalleryWithSessionYearFilterContainer({
    super.key,
    required this.student,
    required this.showBackButton,
  });

  @override
  State<SchoolGalleryWithSessionYearFilterContainer> createState() =>
      _SchoolGalleryWithSessionYearFilterContainerState();
}

class _SchoolGalleryWithSessionYearFilterContainerState
    extends State<SchoolGalleryWithSessionYearFilterContainer> {
  SessionYear selectedSessionYear = SessionYear();
  List<SessionYear> sessionYears = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      fetchSessionYears();
    });
  }

  void fetchSessionYears() {
    context.read<SchoolSessionYearsCubit>().fetchSessionYears(
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.student.id ?? 0,
        );
  }

  void fetchSchoolGallerySessionYearWise() {
    context.read<SchoolGalleryCubit>().fetchSchoolGallery(
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.student.id ?? 0,
          sessionYearId: selectedSessionYear.id ?? 0,
        );
  }

  String fixImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }
    return Utils.fixImageUrl(url);
  }

  Widget _buildAppBar() {
    return Column(
      children: [
        ScreenTopBackgroundContainer(
          heightPercentage: Utils.appBarMediumtHeightPercentage,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.showBackButton
                  ? const Positioned(
                      left: 10,
                      child: CustomBackButton(),
                    )
                  : const SizedBox(),
              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  Utils.getTranslatedLabel(galleryKey),
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
                  child: _SearchAndFilterWidget(
                    sessionYears: sessionYears,
                    selectedSessionYear: selectedSessionYear,
                    onSearchChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                    onSessionYearChanged: (newSessionYear) {
                      setState(() {
                        selectedSessionYear = newSessionYear;
                        _searchQuery = '';
                      });
                      fetchSchoolGallerySessionYearWise();
                    },
                    onSessionYearsLoaded:
                        (loadedSessionYears, defaultSessionYear) {
                      setState(() {
                        sessionYears = loadedSessionYears;
                        selectedSessionYear = defaultSessionYear;
                      });
                      fetchSchoolGallerySessionYearWise();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
            height: 30), // Add space for the search widget positioned below
      ],
    );
  }

  Widget _buildGalleryShimmerLoading(BuildContext context) {
    return ShimmerLoadingContainer(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: Utils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
          ),
          left: Utils.screenContentHorizontalPadding,
          right: Utils.screenContentHorizontalPadding,
          top: Utils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Shimmer for gallery items
            ...List.generate(3, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gallery image shimmer
                  CustomShimmerContainer(
                    width: MediaQuery.of(context).size.width,
                    height: 175,
                    borderRadius: Utils.bottomSheetTopRadius,
                  ),
                  const SizedBox(height: 15),
                  // Gallery title shimmer
                  CustomShimmerContainer(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 20,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  // Gallery subtitle shimmer
                  CustomShimmerContainer(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 5),
                  // Photos and videos count shimmer
                  Row(
                    children: [
                      CustomShimmerContainer(
                        width: 60,
                        height: 12,
                        borderRadius: 4,
                      ),
                      const SizedBox(width: 10),
                      CustomShimmerContainer(
                        width: 60,
                        height: 12,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocBuilder<SchoolGalleryCubit, SchoolGalleryState>(
          builder: (context, state) {
            if (state is SchoolGalleryFetchSuccess) {
              final filteredGalleries = _searchQuery.isEmpty
                  ? state.gallery
                  : state.gallery
                      .where((gallery) =>
                          gallery.title
                              ?.toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ??
                          false)
                      .toList();

              if (filteredGalleries.isEmpty) {
                return Container(
                    child: NoDataContainer(titleKey: galleryEmptyKey));
              }

              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
                  ),
                  left: Utils.screenContentHorizontalPadding,
                  right: Utils.screenContentHorizontalPadding,
                  top: Utils.getScrollViewTopPadding(
                    context: context,
                    appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
                  ),
                ),
                child: Column(children: [
                  const SizedBox(height: 20),
                  ...filteredGalleries.map((gallery) {
                    final photosAndVideosCountTextStyle = TextStyle(
                      fontSize: 12.0,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.65),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.toNamed(Routes.galleryDetails, arguments: {
                              "gallery": gallery,
                              "sessionYear": selectedSessionYear,
                            });
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 175,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  Utils.bottomSheetTopRadius),
                              child: gallery.isThumbnailSvg()
                                  ? SvgPicture.network(
                                      fixImageUrl(gallery.thumbnail ?? ""),
                                      fit: BoxFit.cover,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: fixImageUrl(gallery.thumbnail),
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5, top: 15),
                          child: Text(
                            gallery.title ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              height: 1.0,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (gallery.getImages().isNotEmpty)
                              Text(
                                "${gallery.getImages().length} ${Utils.getTranslatedLabel(photosKey)}",
                                style: photosAndVideosCountTextStyle,
                              ),
                            if (gallery.getVideos().isNotEmpty &&
                                gallery.getImages().isNotEmpty)
                              Text(
                                " | ",
                                style: photosAndVideosCountTextStyle,
                              ),
                            if (gallery.getVideos().isNotEmpty)
                              Text(
                                "${gallery.getVideos().length} ${Utils.getTranslatedLabel(videosKey)}",
                                style: photosAndVideosCountTextStyle,
                              ),
                          ],
                        ),
                        const SizedBox(height: 25),
                      ],
                    );
                  }).toList(),
                ]),
              );
            }
            if (state is SchoolGalleryFetchFailure) {
              return Center(
                child: ErrorContainer(
                  errorMessageCode: state.errorMessage,
                  onTapRetry: () {
                    fetchSchoolGallerySessionYearWise();
                  },
                ),
              );
            }
            return _buildGalleryShimmerLoading(context);
          },
        ),
        Align(alignment: Alignment.topCenter, child: _buildAppBar()),
      ],
    );
  }
  //     children: [
  //       SingleChildScrollView(
  //         padding: EdgeInsets.only(
  //           bottom: 25,
  //           left: Utils.screenContentHorizontalPadding,
  //           right: Utils.screenContentHorizontalPadding,
  //           top: Utils.getScrollViewTopPadding(
  //             context: context,
  //             appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
  //           ),
  //         ),
  //         child: Column(
  //           children: [
  //             BlocBuilder<SchoolGalleryCubit, SchoolGalleryState>(
  //               builder: (context, state) {
  //                 if (state is SchoolGalleryFetchSuccess) {

  //                   ]);
  //                 }
  //                 if (state is SchoolGalleryFetchFailure) {
  //                   return Center(
  //                     child: ErrorContainer(
  //                       errorMessageCode: state.errorMessage,
  //                       onTapRetry: () {
  //                         fetchSchoolGallerySessionYearWise();
  //                       },
  //                     ),
  //                   );
  //                 }
  //                 return Padding(
  //                   padding: EdgeInsets.only(
  //                     top: MediaQuery.of(context).size.height * 0.3,
  //                   ),
  //                   child: Center(
  //                     child: CustomCircularProgressIndicator(
  //                       indicatorColor: Theme.of(context).colorScheme.primary,
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //           ],
  //         ),
  //       ),
  //       Align(alignment: Alignment.topCenter, child: _buildAppBar()),
  //     ],
  //   );
  // }
}

// Widget terpisah untuk TextField dan DropdownButton
class _SearchAndFilterWidget extends StatefulWidget {
  final List<SessionYear> sessionYears;
  final SessionYear selectedSessionYear;
  final Function(String) onSearchChanged;
  final Function(SessionYear) onSessionYearChanged;
  final Function(List<SessionYear>, SessionYear) onSessionYearsLoaded;

  const _SearchAndFilterWidget({
    required this.sessionYears,
    required this.selectedSessionYear,
    required this.onSearchChanged,
    required this.onSessionYearChanged,
    required this.onSessionYearsLoaded,
  });

  @override
  _SearchAndFilterWidgetState createState() => _SearchAndFilterWidgetState();
}

class _SearchAndFilterWidgetState extends State<_SearchAndFilterWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return BlocConsumer<SchoolSessionYearsCubit, SchoolSessionYearsState>(
      listener: (context, state) {
        if (state is SchoolSessionYearsFetchSuccess) {
          final defaultSessionYear = state.sessionYears
              .firstWhere((element) => element.isDefault == 1);
          widget.onSessionYearsLoaded(state.sessionYears, defaultSessionYear);
        }
      },
      builder: (context, state) {
        if (state is SchoolSessionYearsFetchSuccess) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: primaryColor.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: Utils.getTranslatedLabel(searchKey),
                hintStyle: TextStyle(
                  color: primaryColor.withValues(alpha: 0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.search, color: primaryColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                suffixIcon: Container(
                  padding: const EdgeInsets.only(right: 8),
                  width: 150,
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 12),
                            child: DropdownButton<SessionYear>(
                              isExpanded: true,
                              isDense: true,
                              value: widget.selectedSessionYear,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                              items: widget.sessionYears.map((sessionYear) {
                                return DropdownMenuItem<SessionYear>(
                                  value: sessionYear,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      sessionYear.name ?? "",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            primaryColor.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  widget.onSessionYearChanged(value);
                                  _searchController.clear();
                                }
                              },
                            ),
                          ),
                          Positioned(
                            left: 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 1,
                              height: 20,
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              onChanged: (value) {
                widget.onSearchChanged(value.trim());
              },
            ),
          );
        }

        if (state is SchoolSessionYearsFetchFailure) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  Utils.getTranslatedLabel(failedToGetSessionYearsKey),
                  style: TextStyle(color: primaryColor),
                ),
                const Spacer(),
                // IconButton(
                //   onPressed: () =>
                //       context.read<SchoolSessionYearsCubit>().fetchSessionYears(
                //             useParentApi: context.read<AuthCubit>().isParent(),
                //             childId: widget.student.id ?? 0,
                //           ),
                //   icon: Icon(Icons.refresh, color: primaryColor),
                // ),
              ],
            ),
          );
        }

        return ShimmerLoadingContainer(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomShimmerContainer(
                    width: double.infinity,
                    height: 16,
                    borderRadius: 4,
                  ),
                ),
                const SizedBox(width: 12),
                CustomShimmerContainer(
                  width: 80,
                  height: 16,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
