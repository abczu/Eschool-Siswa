import 'package:eschool/data/models/student/leave.dart';
import 'package:eschool/ui/widgets/student/applyLeavesContainer.dart';
import 'package:eschool/ui/widgets/student/leaveImageViewer.dart';
import 'package:eschool/ui/widgets/student/leaveReasonSection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

/// Animated card for a single leave entry.
/// Tapping the card navigates to edit (unless already approved).
class LeaveCard extends StatelessWidget {
  final Leave leave;
  final int index;
  final int? childId;
  final String studentFullName;
  final VoidCallback onRefresh;

  const LeaveCard({
    Key? key,
    required this.leave,
    required this.index,
    required this.childId,
    required this.studentFullName,
    required this.onRefresh,
  }) : super(key: key);

  // ─── Helpers ───────────────────────────────────────────────────────────────

  _LeaveDisplayInfo _resolveDisplayInfo(BuildContext context) {
    String leaveType = "";
    String leaveStatus = "";
    Color statusBgColor = Colors.grey;
    Color statusTextColor = Colors.grey;
    IconData statusIcon = Icons.info_rounded;

    final nonFileDetails = leave.leaveDetail
        .where((d) => !d.isFile)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    final status = leave.status;

    if (status == 1) {
      leaveStatus = "Disetujui";
      statusBgColor = const Color(0xFFE6F4EA);
      statusTextColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 0) {
      leaveStatus = "Tertunda";
      statusBgColor = const Color(0xFFFFF4E5);
      statusTextColor = const Color(0xFFEF6C00);
      statusIcon = Icons.hourglass_empty_rounded;
    } else if (status == 2) {
      leaveStatus = "Ditolak";
      statusBgColor = const Color(0xFFFDEAEA);
      statusTextColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.cancel;
    }

    if (nonFileDetails.isNotEmpty) {
      final type = nonFileDetails.first.type.toLowerCase();
      leaveType = type == "leave"
          ? "Izin"
          : type == "sick"
              ? "Sakit"
              : "Tipe tidak diketahui";
    } else {
      leaveType = "Tipe tidak diketahui";
    }

    return _LeaveDisplayInfo(
      leaveType: leaveType,
      leaveStatus: leaveStatus,
      statusBgColor: statusBgColor,
      statusTextColor: statusTextColor,
      statusIcon: statusIcon,
    );
  }

  Widget _buildDateText(BuildContext context) {
    final details = leave.leaveDetail;
    if (details.isEmpty) {
      return const Text("—", style: TextStyle(fontSize: 13));
    }
    try {
      final date = DateTime.tryParse(details.first.date) ?? DateTime.now();
      return Text(
        DateFormat("dd MMM yyyy", 'id').format(date),
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context)
              .colorScheme
              .secondary
              .withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
      );
    } catch (_) {
      return Text(
        "Invalid date",
        style: TextStyle(
            fontSize: 13, color: Theme.of(context).colorScheme.error),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final info = _resolveDisplayInfo(context);
    final typeColor =
        info.leaveType == "Sakit" ? Theme.of(context).colorScheme.primary : Colors.blue;

    return Animate(
      effects: [
        FadeEffect(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
        ),
        SlideEffect(
          begin: const Offset(0.2, 0),
          end: Offset.zero,
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
          curve: Curves.easeOutQuint,
        ),
      ],
      autoPlay: true,
      onComplete: (c) => c.stop(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (leave.status == 1) return; // approved — no edit
              Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: (_) => ApplyLeavesContainer(
                      childId: childId,
                      data: leave,
                    ),
                  ))
                  .then((_) => onRefresh());
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header row ─────────────────────────────────────────
                  Row(
                    children: [
                      // Type icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          info.leaveType == "Sakit"
                              ? Icons.medical_services_rounded
                              : Icons.event_busy_rounded,
                          color: typeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentFullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Type chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    info.leaveType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: typeColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildDateText(context),
                                const Spacer(),
                                // Status badge
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        info.leaveStatus.isNotEmpty ? 10 : 7,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: info.statusTextColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(info.statusIcon,
                                          color: info.statusBgColor, size: 16),
                                      if (info.leaveStatus.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          info.leaveStatus,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: info.statusBgColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ─── Reason section ────────────────────────────────────
                  LeaveReasonSection(
                    title: 'Alasan izin',
                    text: leave.reason,
                    sourceLabel: 'Wali Murid',
                    icon: Icons.notes_rounded,
                    accent: typeColor,
                    margin: EdgeInsets.zero,
                  ),

                  // ─── Reject reason (if any) ────────────────────────────
                  if (leave.rejectReason.trim().isNotEmpty && leave.status == 2)
                    LeaveReasonSection(
                      title: 'Alasan ditolak',
                      text: leave.rejectReason,
                      sourceLabel: 'Guru/Wali Kelas',
                      icon: Icons.block_rounded,
                      accent: typeColor,
                      margin: const EdgeInsets.only(top: 10),
                    ),

                  // ─── Attachment row ────────────────────────────────────
                  // Cek lampiran dari fileDetail (sumber utama API) ATAU leaveDetail yang isFile
                  if (leave.fileDetail.isNotEmpty || leave.leaveDetail.any((d) => d.isFile)) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Lampiran",
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Prioritas: fileDetail (dari API), fallback ke leaveDetail
                            LeaveDetail? file;
                            if (leave.fileDetail.isNotEmpty) {
                              file = leave.fileDetail.first;
                            } else {
                              file = leave.leaveDetail.cast<LeaveDetail?>().firstWhere(
                                (d) => d?.isFile == true,
                                orElse: () => null,
                              );
                            }
                            if (file != null) {
                              LeaveImageViewer.show(context, file);
                            }
                          },
                          icon: const Icon(Icons.visibility_rounded, size: 16),
                          label: const Text("Lihat"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeColor.withValues(alpha: 0.1),
                            foregroundColor: typeColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaveDisplayInfo {
  final String leaveType;
  final String leaveStatus;
  final Color statusBgColor;
  final Color statusTextColor;
  final IconData statusIcon;

  const _LeaveDisplayInfo({
    required this.leaveType,
    required this.leaveStatus,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.statusIcon,
  });
}
