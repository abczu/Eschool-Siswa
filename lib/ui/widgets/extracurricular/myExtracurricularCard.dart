import 'package:eschool/cubits/extracurricular/extracurricularCubit.dart';
import 'package:eschool/data/models/extracurricular/extracurricular.dart';
import 'package:eschool/data/models/extracurricular/studentExtracurricular.dart';
import 'package:eschool/app/routes.dart';
import 'package:eschool/ui/widgets/extracurricular/modernPatternPainter.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class MyExtracurricularCard extends StatelessWidget {
  final StudentExtracurricular studentExtracurricular;

  const MyExtracurricularCard({
    Key? key,
    required this.studentExtracurricular,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final extracurricular = studentExtracurricular.extracurricular;
    if (extracurricular == null) return const SizedBox.shrink();

    // Modern color scheme - My Ekstrakurikuler theme (Red for joined activities)
    final colorScheme = {
      'primary': const Color(0xffE53935), // Red
      'gradient1': const Color(0xffC62828), // Dark red
      'gradient2': const Color(0xffE53935), // Primary red
      'gradient3': const Color(0xffEF5350), // Light red
      'neutral1': const Color(0xFF333333), // Dark gray for primary text
      'neutral2': const Color(0xFF666666), // Medium gray for secondary text
      'accent': const Color(0xffE53935), // Same as primary
      'success': const Color(0xff4CAF50), // Green for active status
      'warning': const Color(0xffFF9800), // Orange for pending status
    };

    // Status color based on studentExtracurricular.status
    Color statusColor;
    String statusText;
    switch (studentExtracurricular.status) {
      case 0:
        statusColor = colorScheme['warning']!;
        statusText = 'Menunggu';
        break;
      case 1:
        statusColor = colorScheme['success']!;
        statusText = 'Disetujui';
        break;
      case 2:
        statusColor = Colors.red;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Tidak Diketahui';
    }

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
              color: Colors.white,
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
                      _buildMyExtracurricularCardHeader(
                          extracurricular, colorScheme, statusColor, statusText),
                      _buildMyExtracurricularCardContent(
                          studentExtracurricular, extracurricular, colorScheme, context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyExtracurricularCardHeader(Extracurricular extracurricular,
      Map<String, Color> colorScheme, Color statusColor, String statusText) {
    return Container(
      height: 200,
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

          // Ekstrakurikuler Label
          Positioned(
            top: 20,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Ekstrakurikuler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status Badge
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Title and basic info
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extracurricular.title ?? 'Tidak ada judul',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyExtracurricularCardContent(
      StudentExtracurricular studentExtracurricular,
      Extracurricular extracurricular,
      Map<String, Color> colorScheme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pembimbing Card - moved to white section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme['primary']!.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme['primary']!.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Coach Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme['primary']!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: colorScheme['primary'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Coach Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembimbing',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme['neutral2'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildInstructorNameWidget(extracurricular, colorScheme, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          if (extracurricular.description != null &&
              extracurricular.description!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deskripsi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme['neutral1'],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  extracurricular.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme['neutral2'],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
              ],
            ),

          // Join Date and Update Date
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.event_available,
                  label: 'Bergabung',
                  value: Utils.formatDate(DateTime.tryParse(
                          studentExtracurricular.createdAt ?? '') ??
                      DateTime.now()),
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.update,
                  label: 'Diperbarui',
                  value: Utils.formatDate(DateTime.tryParse(
                          studentExtracurricular.updatedAt ?? '') ??
                      DateTime.now()),
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInstructorNameWidget(
      Extracurricular extracurricular, Map<String, Color> colorScheme, BuildContext context) {
    // Use BlocBuilder to listen for ExtracurricularCubit state changes
    // This ensures coach names update when All Extracurriculars data is loaded
    return BlocBuilder<ExtracurricularCubit, ExtracurricularState>(
      builder: (context, state) {
        String displayName = _getInstructorNameSimple(extracurricular, context);

        return Text(
          _formatInstructorName(displayName),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme['neutral1'],
          ),
        );
      },
    );
  }

  String _getInstructorNameSimple(Extracurricular extracurricular, BuildContext context) {
    // The instructor field already contains coach_name from API endpoint /show
    if (extracurricular.instructor?.isNotEmpty == true) {
      return extracurricular.instructor!;
    }

    // For My Extracurricular cards, try to get coach name from All Extracurriculars data
    if (extracurricular.coachId != null) {
      final coachName =
          _getCoachNameFromAllExtracurriculars(extracurricular.coachId!, context);
      if (coachName != null) {
        return coachName;
      }
      return 'Pembimbing (ID: ${extracurricular.coachId})';
    }

    return 'Tidak ada pembimbing';
  }

  String? _getCoachNameFromAllExtracurriculars(int coachId, BuildContext context) {
    // Try to get coach name from All Extracurriculars data which has coach_name
    final extracurricularState = context.read<ExtracurricularCubit>().state;
    if (extracurricularState is ExtracurricularFetchSuccess) {
      for (final extracurricular in extracurricularState.extracurriculars) {
        if (extracurricular.coachId == coachId &&
            extracurricular.instructor?.isNotEmpty == true) {
          return extracurricular.instructor;
        }
      }
    }
    return null;
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Map<String, Color> colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme['primary']!.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme['primary']!.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: colorScheme['primary'],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme['primary'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme['neutral1'],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
