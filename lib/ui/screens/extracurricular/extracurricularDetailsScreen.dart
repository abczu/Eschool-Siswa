import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/extracurricular/allMyExtracurricularStatusCubit.dart';
import 'package:eschool/cubits/extracurricular/joinExtracurricularCubit.dart';
import 'package:eschool/cubits/extracurricular/extracurricularCubit.dart';
import 'package:eschool/data/models/extracurricular/extracurricular.dart';
import 'package:eschool/data/models/extracurricular/studentExtracurricular.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ExtracurricularDetailsScreen extends StatelessWidget {
  final Extracurricular extracurricular;

  const ExtracurricularDetailsScreen({
    Key? key,
    required this.extracurricular,
  }) : super(key: key);

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return ExtracurricularDetailsScreen(
      extracurricular: arguments['extracurricular'] as Extracurricular,
    );
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional light background
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: BlocBuilder<ExtracurricularCubit, ExtracurricularState>(
                  builder: (context, state) {
                    return _buildContent(context, studentId, nisn, joinedStatus);
                  },
                ),
              ),
            ],
          ),
          _buildBottomAction(context, studentId, nisn, joinedStatus),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final hasImage = extracurricular.image != null && extracurricular.image!.isNotEmpty;
    if (!hasImage) {
      return SliverToBoxAdapter(
        child: ScreenTopBackgroundContainer(
          heightPercentage: Utils.appBarSmallerHeightPercentage,
          child: Stack(
            children: [
              const CustomBackButton(),
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: Center(
                  child: Text(
                    'Detail Ekstrakurikuler',
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
      );
    }

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: CustomBackButton(
        iconColor: Theme.of(context).colorScheme.primary,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'extracurricular_image_${extracurricular.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: extracurricular.image!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    _buildDefaultHeader(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, int studentId, String nisn,
      StudentExtracurricular? joinedStatus) {
    // Logic to find coach name if it's missing in the current object
    String? rawInstructor = extracurricular.instructor;
    String instructorName = (rawInstructor != null && rawInstructor.trim().isNotEmpty) 
        ? rawInstructor 
        : '-';

    if (instructorName == '-' || instructorName == 'Tidak ada pembimbing') {
      // Try to get instructor name from ExtracurricularCubit global state
      final state = context.read<ExtracurricularCubit>().state;
      if (state is ExtracurricularFetchSuccess) {
        // Try to find by ID
        final fullExt = state.extracurriculars.firstWhereOrNull(
          (e) => e.id == extracurricular.id,
        );
        
        if (fullExt != null && 
            fullExt.instructor != null && 
            fullExt.instructor!.trim().isNotEmpty &&
            fullExt.instructor != '-') {
          instructorName = fullExt.instructor!;
        } else if (extracurricular.coachId != null) {
          // If not found by ID, try to find any extracurricular with this coach ID
          final coachExt = state.extracurriculars.firstWhereOrNull(
            (e) => e.coachId == extracurricular.coachId && 
                   e.instructor != null && 
                   e.instructor!.trim().isNotEmpty,
          );
          if (coachExt != null) {
            instructorName = coachExt.instructor!;
          }
        }
      }
    }

    // Still missing or dash? Use a proper label
    if (instructorName == '-' || instructorName.trim().isEmpty) {
      instructorName = 'Tidak ada pembimbing';
    }

    final hasImage = extracurricular.image != null && extracurricular.image!.isNotEmpty;
    return Container(
      width: double.infinity,
      margin: hasImage ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: hasImage
            ? const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              )
            : const BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            extracurricular.title ?? 'Tidak ada judul',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),

          // Info Cards (Pembimbing & Jadwal)
          Row(
            children: [
              Expanded(
                child: _buildJoinedInfoItem(
                  context,
                  icon: Icons.person_outline,
                  label: 'Pembimbing',
                  value: _formatInstructorName(instructorName),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildJoinedInfoItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  label: 'Jadwal',
                  value: extracurricular.schedule ?? '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Joined Info (Only if joined)
          if (joinedStatus != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildJoinedInfoItem(
                    context,
                    icon: Icons.event_available,
                    label: 'Bergabung',
                    value: Utils.formatDate(DateTime.tryParse(
                            joinedStatus.createdAt ?? '') ??
                        DateTime.now()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildJoinedInfoItem(
                    context,
                    icon: Icons.update,
                    label: 'Diperbarui',
                    value: Utils.formatDate(DateTime.tryParse(
                            joinedStatus.updatedAt ?? '') ??
                        DateTime.now()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // Description
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            extracurricular.description ?? 'Tidak ada deskripsi',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 100), // Space for bottom action
        ],
      ),
    );
  }

  Widget _buildDefaultHeader(BuildContext context) {
    return Container(
      color: Colors.transparent,
    );
  }

  Widget _buildJoinedInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
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
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context,
      {required String title, required String value, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, int studentId, String nisn,
      StudentExtracurricular? joinedStatus) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BlocConsumer<JoinExtracurricularCubit, JoinExtracurricularState>(
          listener: (context, state) {
            if (state is JoinExtracurricularSuccess) {
              Utils.showCustomSnackBar(
                context: context,
                errorMessage: state.message,
                backgroundColor: Colors.green,
              );
            } else if (state is JoinExtracurricularFailure) {
              Utils.showCustomSnackBar(
                context: context,
                errorMessage: state.errorMessage,
                backgroundColor: Colors.red,
              );
            }
          },
          builder: (context, state) {
            if (joinedStatus != null) {
              String text = 'Terdaftar';
              Color color = Colors.blue;
              IconData icon = Icons.check_circle;

              if (joinedStatus.status == 0) {
                text = 'Menunggu Persetujuan';
                color = Colors.orange;
                icon = Icons.access_time;
              } else if (joinedStatus.status == 2) {
                text = 'Ditolak';
                color = Colors.red;
                icon = Icons.cancel;
              }

              return _buildActionButton(
                text: text,
                color: color,
                icon: icon,
                onTap: null,
              );
            }

            final isLoading = state is JoinExtracurricularInProgress;
            final isAvailable = extracurricular.isAvailable;

            return _buildActionButton(
              text: isAvailable ? 'Bergabung Sekarang' : 'Kapasitas Penuh',
              color: isAvailable ? Colors.green : Colors.grey,
              icon: isAvailable ? Icons.add_circle_outline : Icons.block,
              isLoading: isLoading,
              onTap: isAvailable && !isLoading
                  ? () {
                      context
                          .read<JoinExtracurricularCubit>()
                          .joinExtracurricular(
                            extracurricularId: extracurricular.id!,
                            studentId: studentId,
                            nisn: nisn,
                          );
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  String _formatInstructorName(String name) {
    if (name == '-' || name == 'Tidak ada pembimbing') return name;

    // Detect if name has repeating parts (e.g., "Yotam Rumkorem Yotam")
    List<String> parts = name.split(' ');
    if (parts.length > 2 &&
        parts.first.toLowerCase() == parts.last.toLowerCase()) {
      parts.removeLast();
      return parts.join(' ');
    }
    return name;
  }
}
