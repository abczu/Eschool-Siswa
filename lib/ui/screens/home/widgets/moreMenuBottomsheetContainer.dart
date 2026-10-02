import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/ui/widgets/system/customUserProfileImageWidget.dart';
import 'package:eschool/utils/system/homeBottomsheetMenu.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class MoreMenuBottomsheetContainer extends StatefulWidget {
  final Function onTapMoreMenuItemContainer;
  final Function closeBottomMenu;
  const MoreMenuBottomsheetContainer({
    Key? key,
    required this.onTapMoreMenuItemContainer,
    required this.closeBottomMenu,
  }) : super(key: key);

  @override
  State<MoreMenuBottomsheetContainer> createState() =>
      _MoreMenuBottomsheetContainerState();
}

class _MoreMenuBottomsheetContainerState
    extends State<MoreMenuBottomsheetContainer> {
  double _dragOffset = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (details.primaryDelta == null) return;
    // Hanya ikuti tarikan ke bawah
    final next = _dragOffset + details.primaryDelta!;
    setState(() {
      _dragOffset = next.clamp(0.0, 320.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    // Tutup jika ditarik cukup jauh atau difling ke bawah dengan cepat
    if (_dragOffset > 90 || velocity > 600) {
      widget.closeBottomMenu();
    }
    setState(() {
      _dragOffset = 0;
    });
  }

  Widget _buildMoreMenuContainer(
      {required BuildContext context,
      required BoxConstraints boxConstraints,
      required Menu menu}) {
    final Color primaryRed = const Color(0xFFE57373);
    final Color lightRed = const Color(0xFFFFCDD2);
    // final Color darkRed = const Color(0xFFD32F2F);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          widget.onTapMoreMenuItemContainer(
            homeBottomSheetMenu
                .indexWhere((element) => element.title == menu.title),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: primaryRed,
                  width: 1.2,
                ),
                color: lightRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.0),
              ),
              margin: EdgeInsets.symmetric(
                horizontal: boxConstraints.maxWidth * (0.065),
              ),
              width: boxConstraints.maxWidth * (0.2),
              height: boxConstraints.maxWidth * (0.2),
              padding: const EdgeInsets.all(12.5),
              child: SvgPicture.asset(menu.iconUrl),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: boxConstraints.maxWidth * (0.3),
              height: 33,
              child: Text(
                Utils.getTranslatedLabel(menu.title),
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 12.5,
                  wordSpacing: 0.0,
                  height: 1.25,
                ),
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFFE57373);

    // Hitung tinggi navbar yang lebih akurat
    final double navbarTotalHeight =
        80.0; // 64px (container) + 16px (margin bottom)

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _dragOffset, 0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * (0.85),
        minHeight: MediaQuery.of(context).size.height * (0.25),
      ),
      padding: EdgeInsets.only(
        top: 15.0, // Dikurangi dari 20.0 ke 15.0
        right: 25.0,
        left: 25.0,
        bottom: navbarTotalHeight, // Gunakan tinggi navbar yang sudah dihitung
      ),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return SingleChildScrollView(
            physics:
                const ClampingScrollPhysics(), // Ubah ke ClampingScrollPhysics
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Area tarik: handle + profile (drag ke bawah untuk tutup)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // Drag indicator
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(
                        top: 2,
                        bottom: 15), // Area sentuh lebih besar
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                // Profile section dengan ukuran yang lebih compact
                // BlocBuilder agar foto langsung ter-update setelah ubah foto
                // tanpa perlu tutup/buka ulang menu.
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    final studentDetails =
                        context.read<AuthCubit>().getStudentDetails();
                    return Container(
                  padding: const EdgeInsets.all(12), // Dikurangi dari 16 ke 12
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: primaryRed,
                    ),
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: boxConstraints.maxWidth *
                            (0.15), // Dikurangi dari 0.18 ke 0.15
                        width: boxConstraints.maxWidth * (0.15),
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 2.0,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(
                            boxConstraints.maxWidth *
                                (0.075), // Sesuaikan dengan ukuran baru
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CustomUserProfileImageWidget(
                          key: ValueKey(
                              studentDetails.image ?? ""),
                          profileUrl: studentDetails.image ?? "",
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(
                        width: boxConstraints.maxWidth *
                            (0.04), // Dikurangi dari 0.05 ke 0.04
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentDetails.getFullName(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15.0, // Dikurangi dari 16.0 ke 15.0
                              ),
                            ),
                            const SizedBox(height: 3), // Dikurangi dari 4 ke 3
                            Row(
                              children: [
                                Icon(
                                  Icons.class_outlined,
                                  size: 13, // Dikurangi dari 14 ke 13
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    studentDetails.classSection?.name ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize:
                                          13.0, // Dikurangi dari 14.0 ke 13.0
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.numbers_outlined,
                                  size: 13, // Dikurangi dari 14 ke 13
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    "${Utils.getTranslatedLabel(rollNoKey)}: ${studentDetails.rollNumber}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize:
                                          13.0, // Dikurangi dari 14.0 ke 13.0
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Material(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () async {
                            widget.closeBottomMenu();
                            Get.toNamed(Routes.studentProfile);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 16,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                    );
                  },
                ),

                SizedBox(
                  height: boxConstraints.maxWidth *
                      (0.04), // Dikurangi dari 0.05 ke 0.04
                ),
                    ],
                  ),
                ),

                // Menu items dengan padding yang lebih kecil
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.start,
                  runSpacing: 10,
                  children: homeBottomSheetMenu
                      .map(
                        (e) => Utils.isModuleEnabled(
                                context: context, moduleId: e.menuModuleId)
                            ? _buildMoreMenuContainer(
                                context: context,
                                boxConstraints: boxConstraints,
                                menu: e)
                            : const SizedBox(),
                      )
                      .toList(),
                ),

                const SizedBox(height: 15), // Spacing tambahan yang lebih kecil
              ],
            ),
          );
        },
      ),
    );
  }
}
