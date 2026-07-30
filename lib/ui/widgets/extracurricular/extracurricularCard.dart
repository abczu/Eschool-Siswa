import 'dart:math' as math;
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/extracurricular/allMyExtracurricularStatusCubit.dart';
import 'package:eschool/cubits/extracurricular/joinExtracurricularCubit.dart';
import 'package:eschool/data/models/extracurricular/extracurricular.dart';
import 'package:eschool/data/models/extracurricular/studentExtracurricular.dart';
import 'package:eschool/app/routes.dart';
import 'package:eschool/ui/widgets/extracurricular/modernPatternPainter.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ExtracurricularCard extends StatelessWidget {
  final Extracurricular extracurricular;
  final VoidCallback onJoinSuccess;

  const ExtracurricularCard({
    Key? key,
    required this.extracurricular,
    required this.onJoinSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final student = context.read<AuthCubit>().getStudentDetails();
    final studentId = student.id ?? 0;
    final nisn = student.admissionNo ?? '';

    // Check if student has already joined/requested this extracurricular
    StudentExtracurricular? joinedStatus;
    final allStatusState =
        context.watch<AllMyExtracurricularStatusCubit>().state;
    if (allStatusState is AllMyExtracurricularStatusFetchSuccess) {
      joinedStatus =
          allStatusState.getStatusByExtracurricularId(extracurricular.id ?? 0);
    }

    // Modern color scheme - Student theme (Bright Red)
    final colorScheme = {
      'primary': const Color(0xffd22f3c), // App primary red (bright red)
      'gradient1': const Color(0xffd22f3c), // Primary red
      'gradient2': const Color(0xffdc3545), // Slightly lighter red
      'gradient3': const Color(0xffe74c3c), // Bright red
      'neutral1': const Color(0xFF333333), // Dark gray for primary text
      'neutral2': const Color(0xFF666666), // Medium gray for secondary text
      'accent': const Color(0xffd22f3c), // Same as primary
    };

    // Calculate dynamic header height for text wrapping
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 48;
    const double titleFontSize = 24.0;
    const double lineHeight = 1.4;

    final int estimatedCharactersPerLine =
        (availableWidth / (titleFontSize * 0.6)).floor();
    final int estimatedLines = math.max(1,
        (extracurricular.title?.length ?? 0) ~/ estimatedCharactersPerLine + 1);
    final double estimatedTextHeight =
        estimatedLines * (titleFontSize * lineHeight);

    const double minHeight = 260.0;
    const double maxHeight = 400.0;
    final double headerHeight =
        math.min(maxHeight, math.max(minHeight, estimatedTextHeight + 200.0));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed(
              Routes.extracurricularDetails,
              arguments: {'extracurricular': extracurricular},
            );
          },
          borderRadius: BorderRadius.circular(32),
          highlightColor: Colors.transparent,
          splashColor: colorScheme['primary']!.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white, // White background for card
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModernCardHeader(
                          extracurricular, colorScheme, headerHeight),
                      _buildModernCardContent(extracurricular, colorScheme,
                          headerHeight, studentId, nisn, joinedStatus, context),
                    ],
                  ),
                  _buildModernOverlappingCard(
                      extracurricular, colorScheme, headerHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernCardHeader(Extracurricular extracurricular,
      Map<String, Color> colorScheme, double headerHeight) {
    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme['gradient1']!,
            colorScheme['gradient2']!,
            colorScheme['gradient3']!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative Pattern Overlay
          Opacity(
            opacity: 0.07,
            child: CustomPaint(
              size: Size.infinite,
              painter: ModernPatternPainter(
                primaryColor: Colors.white,
                secondaryColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Glow Effect Corner
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Coach name badge
          Positioned(
            top: 30,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: colorScheme['primary']),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _formatInstructorName(extracurricular.instructor ?? 'Tidak ada pembimbing'),
                        style: TextStyle(
                          color: colorScheme['primary'],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title
          Positioned(
            top: 90,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extracurricular.title ?? 'Tidak ada judul',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.left,
                  maxLines: null,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCardContent(
      Extracurricular extracurricular,
      Map<String, Color> colorScheme,
      double headerHeight,
      int studentId,
      String nisn,
      StudentExtracurricular? joinedStatus,
      BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, math.max(120, (headerHeight * 0.35).round().toDouble()), 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Join Button - Modern Design for Students
          SizedBox(
            width: double.infinity,
            height: 56,
            child: BlocConsumer<JoinExtracurricularCubit,
                JoinExtracurricularState>(
              listener: (context, state) {
                if (state is JoinExtracurricularSuccess) {
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: state.message,
                    backgroundColor: Colors.green,
                  );
                  onJoinSuccess();
                } else if (state is JoinExtracurricularFailure) {
                  Utils.showCustomSnackBar(
                    context: context,
                    errorMessage: state.errorMessage,
                    backgroundColor: Colors.red,
                  );
                }
              },
              builder: (context, state) {
                // Check joined status first
                if (joinedStatus != null) {
                  if (joinedStatus.status == 0) {
                    return _buildStatusButton(
                      text: 'Menunggu Persetujuan',
                      color: const Color(0xffFF9800), // Orange
                      icon: Icons.access_time,
                    );
                  } else if (joinedStatus.status == 1) {
                    return _buildStatusButton(
                      text: 'Terdaftar',
                      color: const Color(0xff2196F3), // Blue
                      icon: Icons.check_circle,
                    );
                  } else if (joinedStatus.status == 2) {
                    return _buildStatusButton(
                      text: 'Ditolak',
                      color: Colors.red,
                      icon: Icons.cancel,
                    );
                  }
                }

                final isLoading = state is JoinExtracurricularInProgress;
                final isAvailable = extracurricular.isAvailable;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isAvailable
                          ? [
                              const Color(0xFF4CAF50), // Green
                              const Color(0xFF45A049), // Darker green
                              const Color(0xFF388E3C), // Deep green
                            ]
                          : [
                              Colors.grey[400] ?? Colors.grey,
                              Colors.grey[500] ?? Colors.grey,
                              Colors.grey[600] ?? Colors.grey,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isAvailable
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                              spreadRadius: -5,
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading || !isAvailable
                          ? null
                          : () {
                              context
                                  .read<JoinExtracurricularCubit>()
                                  .joinExtracurricular(
                                    extracurricularId: extracurricular.id!,
                                    studentId: studentId,
                                    nisn: nisn,
                                  );
                            },
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.white.withValues(alpha: 0.2),
                      highlightColor: Colors.transparent,
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isAvailable ? Icons.add : Icons.block,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isAvailable ? 'Bergabung' : 'Penuh',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String text,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernOverlappingCard(Extracurricular extracurricular,
      Map<String, Color> colorScheme, double headerHeight) {
    return Positioned(
      top: headerHeight - 85,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Description section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme['primary']!.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: colorScheme['primary'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme['neutral1'],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          extracurricular.description ?? 'Tidak ada deskripsi',
                          style: TextStyle(
                            color: colorScheme['neutral2'],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme['primary']!.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sports_soccer,
                      color: colorScheme['primary'],
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme['primary']!.withValues(alpha: 0.08),
              indent: 20,
              endIndent: 20,
            ),

            // Category section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme['primary']!.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_rounded,
                          size: 16,
                          color: colorScheme['primary'],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ekstrakurikuler',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme['neutral1'],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
  String _formatInstructorName(String name) {
    if (name == '-' || name == 'Tidak ada pembimbing') return name;

    List<String> parts = name.split(' ');
    if (parts.length > 2 &&
        parts.first.toLowerCase() == parts.last.toLowerCase()) {
      parts.removeLast();
      return parts.join(' ');
    }
    return name;
  }
}
