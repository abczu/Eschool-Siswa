import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/cubits/student/violationCubit.dart';
import 'package:eschool/data/models/student/violation.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/ZoomHelper.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ViolationContainer extends StatefulWidget {
  /// Dipanggil saat tombol back ditekan. Jika null, fallback ke `Get.back()`
  /// (untuk pemakaian via route `/violations`).
  final VoidCallback? onBack;

  const ViolationContainer({Key? key, this.onBack}) : super(key: key);

  @override
  State<ViolationContainer> createState() => _ViolationContainerState();
}

class _ViolationContainerState extends State<ViolationContainer> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _fetchSummary);
  }

  void _fetchSummary() {
    context.read<ViolationCubit>().fetchSummary();
  }

  Future<void> _onRefresh() async {
    _fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: BlocBuilder<ViolationCubit, ViolationState>(
            builder: (context, state) {
              if (state is ViolationFetchInProgress ||
                  state is ViolationInitial) {
                return _buildLoading();
              }
              if (state is ViolationFetchFailure) {
                return _buildError(state.errorMessage);
              }
              if (state is ViolationFetchSuccess) {
                return _buildContent(state.summary);
              }
              return const SizedBox();
            },
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
                Positioned(
                  left: 10,
                  top: -2,
                  child: CustomBackButton(onTap: widget.onBack),
                ),
                Text(
                  Utils.getTranslatedLabel(violationsKey),
                  style: TextStyle(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    fontSize: Utils.screenTitleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: Utils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
          ),
          left: 16,
          right: 16,
          bottom: 24,
        ),
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              3,
              (_) => Container(
                height: 90,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        alignment: Alignment.center,
        padding: EdgeInsets.only(
          top: Utils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
          ),
        ),
        child: ErrorContainer(
          errorMessageCode: message,
          onTapRetry: _fetchSummary,
        ),
      ),
    );
  }

  Widget _buildContent(ViolationSummary summary) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: Utils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: Utils.appBarSmallerHeightPercentage,
        ),
        left: 16,
        right: 16,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(summary),
          const SizedBox(height: 12),
          _buildSanctionGuide(summary),
          const SizedBox(height: 16),
          Text(
            Utils.getTranslatedLabel(violationHistoryKey),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          if (summary.violations.isEmpty)
            _buildEmptyState()
          else
            ...summary.violations.asMap().entries.map(
                  (e) => _buildHistoryTile(e.value, e.key,
                      isLast: e.key == summary.violations.length - 1),
                ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildSummaryCard(ViolationSummary summary) {
    final level = summary.sanctionLevel;
    // Flat 1 warna solid agar simpel & teks putih jelas terbaca.
    final cardBase = level.cardColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBase,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardBase.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Utils.getTranslatedLabel(totalViolationPointsKey),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
              _buildBadge(level, summary.sanctionStatus),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${summary.totalPoints}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          Text(
            Utils.getTranslatedLabel(violationPointsUnitKey),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Text(
                '${summary.totalViolations} ${Utils.getTranslatedLabel(violationRecordsKey)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (summary.sanctionDescription.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    summary.isWarningActive
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.sanctionDescription,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (summary.activeSanctions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: summary.activeSanctions
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(SanctionLevel level, String statusText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText.isEmpty ? level.label : statusText,
        style: TextStyle(
          // Warna solid gelap di atas putih, kontras jelas.
          color: level.color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Panduan tingkatan sanksi — dirender DINAMIS dari `sanction_levels` API
  /// (konfigurasi tiap sekolah). Level aktif siswa di-highlight.
  /// Fallback: section disembunyikan bila daftar kosong (belum disetel admin).
  Widget _buildSanctionGuide(ViolationSummary summary) {
    if (summary.sanctionLevels.isEmpty) return const SizedBox.shrink();
    final unit = Utils.getTranslatedLabel(violationPointsUnitKey);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Utils.getTranslatedLabel(sanctionGuideTitleKey),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          ...summary.sanctionLevels.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast =
                entry.key == summary.sanctionLevels.length - 1;
            final kind = item.kind;
            final isActive =
                _isActiveLevel(summary.activeSanction, item);
            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? kind.backgroundColor
                    : Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? kind.color
                      : Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.25),
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: kind.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isActive
                                      ? kind.color
                                      : Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kind.color,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  Utils.getTranslatedLabel(
                                      activeSanctionKey),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.rangeLabel(unit),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? kind.color
                                : Colors.grey.shade700,
                          ),
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isActiveLevel(
      SanctionLevelModel? active, SanctionLevelModel item) {
    if (active == null) return false;
    if (identical(active, item)) return true;
    if (active.id != 0 && item.id != 0) {
      return active.id == item.id;
    }
    return active.name == item.name &&
        active.minPoints == item.minPoints &&
        active.maxPoints == item.maxPoints;
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_outlined,
              size: 52, color: Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          Text(
            Utils.getTranslatedLabel(noViolationsKey),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            Utils.getTranslatedLabel(noViolationsDescKey),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(ViolationRecord record, int index,
      {required bool isLast}) {
    // Card polos tanpa border: hanya background + shadow lembut.
    // Badge poin netral; chip kategori (Sedang/Berat) tidak ditampilkan.
    // Angka poin hanya tampil SATU kali (badge di card).
    const neutralBadge = Color(0xFF616161);
    final cardColor = Theme.of(context).cardColor;
    final secondary = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            record.violationName.isEmpty
                                ? Utils.getTranslatedLabel(
                                    violationsKey)
                                : record.violationName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: secondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: neutralBadge,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+${record.points} ${Utils.getTranslatedLabel(violationPointsUnitKey)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (record.incidentDate.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 13,
                              color: Colors.grey.shade500),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              record.incidentDate,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (record.detailText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        record.detailText,
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: Colors.grey.shade800),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (record.recordedBy.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 13,
                              color: Colors.grey.shade500),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${Utils.getTranslatedLabel(recordedByKey)}: ${record.recordedBy}',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (record.photoUrl != null &&
                        record.photoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildEvidenceThumbnail(record),
                    ],
                  ],
                ),
              ),
            );
  }

  Widget _buildEvidenceThumbnail(ViolationRecord record) {
    final url = Utils.fixImageUrl(record.photoUrl!);
    return GestureDetector(
      onTap: () => showBlurZoomImagePreview(
        context,
        imageUrl: url,
        heroTag: 'violation-evidence-${record.id}',
      ),
      child: Row(
        children: [
          Hero(
            tag: 'violation-evidence-${record.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_outlined,
                      color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Utils.getTranslatedLabel(evidencePhotoKey),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  Utils.getTranslatedLabel(tapToViewEvidenceKey),
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Icon(Icons.zoom_in, size: 20, color: Colors.grey),
        ],
      ),
    );
  }
}
