import 'package:eschool/cubits/extracurricular/extracurricularCubit.dart';
import 'package:eschool/cubits/extracurricular/myExtracurricularCubit.dart';
import 'package:eschool/cubits/extracurricular/allMyExtracurricularStatusCubit.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/noDataContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/ui/widgets/extracurricular/extracurricularSearchBar.dart';
import 'package:eschool/ui/widgets/extracurricular/extracurricularTabBar.dart';
import 'package:eschool/ui/widgets/extracurricular/extracurricularCard.dart';
import 'package:eschool/ui/widgets/extracurricular/myExtracurricularCard.dart';
import 'package:eschool/ui/widgets/extracurricular/extracurricularShimmer.dart';

class ExtracurricularContainer extends StatefulWidget {
  final bool showBackButton;

  const ExtracurricularContainer({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<ExtracurricularContainer> createState() =>
      _ExtracurricularContainerState();
}

class _ExtracurricularContainerState extends State<ExtracurricularContainer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController(initialPage: 0);

    Future.delayed(Duration.zero, () {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchData() {
    context.read<ExtracurricularCubit>().fetchExtracurriculars();
    context.read<MyExtracurricularCubit>().fetchMyExtracurriculars();
    context
        .read<AllMyExtracurricularStatusCubit>()
        .fetchAllMyExtracurricularStatuses();
  }

  Future<void> _onRefresh() async {
    _searchController.clear();
    if (_currentTabIndex == 0) {
      context.read<ExtracurricularCubit>().fetchExtracurriculars();
      context
          .read<AllMyExtracurricularStatusCubit>()
          .fetchAllMyExtracurricularStatuses();
    } else {
      context.read<MyExtracurricularCubit>().fetchMyExtracurriculars();
    }
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  void _refreshAfterJoin() {
    context.read<MyExtracurricularCubit>().fetchMyExtracurriculars();
    context
        .read<AllMyExtracurricularStatusCubit>()
        .fetchAllMyExtracurricularStatuses();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<ExtracurricularCubit>().fetchExtracurriculars();
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_currentTabIndex == 0) {
      context.read<ExtracurricularCubit>().searchExtracurriculars(query);
    } else {
      context.read<MyExtracurricularCubit>().fetchMyExtracurriculars(
            search: query,
          );
    }
  }

  Widget _buildAllExtracurriculars() {
    return _AllExtracurricularsTab(
      onRefresh: _onRefresh,
      onJoinSuccess: _refreshAfterJoin,
    );
  }

  Widget _buildMyExtracurriculars() {
    return _MyExtracurricularsTab(
      onRefresh: _onRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            children: [
              ScreenTopBackgroundContainer(
                heightPercentage: Utils.appBarSmallerHeightPercentage,
                child: Stack(
                  children: [
                    if (widget.showBackButton) const CustomBackButton(),
                    const Positioned(
                      top: 0,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: Text(
                          'Ekstrakurikuler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ExtracurricularSearchBar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onClearSearch: () {
                  setState(() {
                    _searchController.clear();
                    _onSearchChanged('');
                  });
                },
              ),
              ExtracurricularTabBar(
                currentTabIndex: _currentTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                  _tabController.animateTo(index);
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                    _tabController.animateTo(index);
                  },
                  children: [
                    _buildAllExtracurriculars(),
                    _buildMyExtracurriculars(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllExtracurricularsTab extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onJoinSuccess;

  const _AllExtracurricularsTab({
    required this.onRefresh,
    required this.onJoinSuccess,
  });

  @override
  State<_AllExtracurricularsTab> createState() => _AllExtracurricularsTabState();
}

class _AllExtracurricularsTabState extends State<_AllExtracurricularsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ExtracurricularCubit, ExtracurricularState>(
      builder: (context, state) {
        if (state is ExtracurricularFetchInProgress) {
          return const ExtracurricularShimmer();
        } else if (state is ExtracurricularFetchFailure) {
          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ErrorContainer(
              errorMessageCode: state.errorMessage,
              onTapRetry: () {
                context.read<ExtracurricularCubit>().fetchExtracurriculars();
              },
            ),
          );
        } else if (state is ExtracurricularFetchSuccess) {
          if (state.extracurriculars.isEmpty) {
            return RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: const NoDataContainer(titleKey: 'Tidak ada ekstrakurikuler'),
            );
          }

          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 150),
              itemCount: state.extracurriculars.length,
              itemBuilder: (context, index) {
                return ExtracurricularCard(
                  extracurricular: state.extracurriculars[index],
                  onJoinSuccess: widget.onJoinSuccess,
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _MyExtracurricularsTab extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const _MyExtracurricularsTab({
    required this.onRefresh,
  });

  @override
  State<_MyExtracurricularsTab> createState() => _MyExtracurricularsTabState();
}

class _MyExtracurricularsTabState extends State<_MyExtracurricularsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<MyExtracurricularCubit, MyExtracurricularState>(
      builder: (context, state) {
        if (state is MyExtracurricularFetchInProgress) {
          return const ExtracurricularShimmer();
        } else if (state is MyExtracurricularFetchFailure) {
          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ErrorContainer(
              errorMessageCode: state.errorMessage,
              onTapRetry: () {
                context
                    .read<MyExtracurricularCubit>()
                    .fetchMyExtracurriculars();
              },
            ),
          );
        } else if (state is MyExtracurricularFetchSuccess) {
          final approvedExtracurriculars =
              state.myExtracurriculars.where((e) => e.status == 1).toList();

          if (approvedExtracurriculars.isEmpty) {
            return RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: const NoDataContainer(
                  titleKey: 'Anda belum mengikuti ekstrakurikuler apapun'),
            );
          }

          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 150),
              itemCount: approvedExtracurriculars.length,
              itemBuilder: (context, index) {
                return MyExtracurricularCard(
                  studentExtracurricular: approvedExtracurriculars[index],
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
