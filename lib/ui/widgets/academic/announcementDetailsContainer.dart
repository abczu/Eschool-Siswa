import 'dart:ui';

import 'package:eschool/data/models/academic/announcement.dart';
import 'package:eschool/ui/widgets/academic/StudyMaterial_part2.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class AnnouncementDetailsContainer extends StatelessWidget {
  final Announcement announcement;

  // Updated color scheme to match the provided example
  static const Color accentColor = Color(0xFFC62828); // Darker red
  static const Color lightColor = Color(0xFFFFEBEE); // Light red
  static const Color surfaceColor = Colors.white;

  const AnnouncementDetailsContainer({Key? key, required this.announcement})
      : super(key: key);

  void _showDetailsPopup(BuildContext context) {
    // pastikan ada: import 'dart:ui' show ImageFilter;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, _, child) {
        final cs = Theme.of(context).colorScheme;
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        // util kecil (boleh disesuaikan)
        Color lighten(Color c, [double amt = .05]) => c;
        Color darken(Color c, [double amt = .07]) => c;
        Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            child: Stack(
              children: [
                // Backdrop blur
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {},
                          child: LayoutBuilder(
                        builder: (context, constraints) {
                          final screen = MediaQuery.of(context).size;
                          final maxW =
                              screen.width < 380 ? screen.width - 28 : 600.0;
                          final maxH = screen.height * 0.70;

                          return ConstrainedBox(
                            // ==> HANYA batas atas; tidak memaksa penuh jika konten sedikit
                            constraints:
                                BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Stack(
                                children: [
                                  // latar lembut
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            cs.surface,
                                            Color.alphaBlend(
                                                cs.primary
                                                    .withValues(alpha: 0.03),
                                                cs.surface),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // bokeh kanan-atas
                                  Positioned(
                                    right: -40,
                                    top: -40,
                                    child: Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            cs.primary.withValues(alpha: 0.12),
                                            cs.primary.withValues(alpha: 0.0)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // bokeh kiri-bawah
                                  Positioned(
                                    left: -30,
                                    bottom: -30,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            cs.secondary
                                                .withValues(alpha: 0.10),
                                            cs.secondary.withValues(alpha: 0.0)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ===== Konten =====
                                  Column(
                                    // ==> KUNCI: biar dialog setinggi konten saat sedikit
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // HEADER
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(26)),
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 14, 8, 14),
                                          decoration: BoxDecoration(
                                            gradient: RadialGradient(
                                              center:
                                                  const Alignment(-0.85, -1.0),
                                              focal:
                                                  const Alignment(-0.95, -1.05),
                                              focalRadius: 0.07,
                                              radius: 1.2,
                                              colors: [
                                                lighten(cs.primary, .05),
                                                mix(cs.primary, cs.secondary,
                                                    .10),
                                                darken(cs.primary, .08),
                                              ],
                                              stops: const [0.0, 0.42, 1.0],
                                            ),
                                            border: Border(
                                              bottom: BorderSide(
                                                color: cs.outlineVariant
                                                    .withValues(alpha: 0.45),
                                                width: 0.6,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      announcement.title,
                                                      softWrap: true,
                                                      maxLines: null,
                                                      textAlign:
                                                          TextAlign.start,
                                                      textWidthBasis:
                                                          TextWidthBasis.parent,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge
                                                          ?.copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            height: 1.1,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      timeago.format(
                                                          announcement
                                                              .createdAt,
                                                          locale: 'id'),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: Colors.white
                                                                .withValues(
                                                                    alpha: 0.9),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              IconButton.filledTonal(
                                                tooltip: 'Tutup',
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                icon: const Icon(
                                                    Icons.close_rounded),
                                                style: IconButton.styleFrom(
                                                  backgroundColor: Colors.white
                                                      .withValues(alpha: 0.12),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // hairline
                                      Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          color: cs.outlineVariant
                                              .withValues(alpha: 0.3),
                                          // gradient: LinearGradient(
                                          //   begin: Alignment.centerLeft,
                                          //   end: Alignment.centerRight,
                                          //   colors: [
                                          //     cs.outlineVariant
                                          //         .withValues(alpha: 0.0),
                                          //     cs.outlineVariant
                                          //         .withValues(alpha: 0.6),
                                          //     cs.outlineVariant
                                          //         .withValues(alpha: 0.0),
                                          //   ],
                                          // ),
                                        ),
                                      ),

                                      // BODY
                                      // ==> Ganti Expanded -> Flexible(fit: loose) agar tidak memaksa tinggi penuh
                                      Flexible(
                                        fit: FlexFit.loose,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              18, 14, 18, 16),
                                          child: ConstrainedBox(
                                            // ==> Scroll baru aktif jika tinggi konten melebihi maxH
                                            constraints:
                                                BoxConstraints(maxHeight: maxH),
                                            child: Scrollbar(
                                              radius: const Radius.circular(8),
                                              child: SingleChildScrollView(
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SelectableText(
                                                      announcement.description,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                            color: cs.onSurface,
                                                            fontSize: 15.5,
                                                            height: 1.65,
                                                          ),
                                                    ),
                                                    if (announcement
                                                        .files.isNotEmpty) ...[
                                                      const SizedBox(
                                                          height: 22),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            '${Utils.getTranslatedLabel(attachmentsKey)} (${announcement.files.length})',
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleSmall
                                                                ?.copyWith(
                                                                  color: cs
                                                                      .primary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  letterSpacing:
                                                                      0.2,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Container(
                                                              height: 2,
                                                              decoration:
                                                                  BoxDecoration(
                                                                gradient:
                                                                    LinearGradient(
                                                                  colors: [
                                                                    cs.primary.withValues(
                                                                        alpha:
                                                                            0.5),
                                                                    cs.primary.withValues(
                                                                        alpha:
                                                                            0.0),
                                                                  ],
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            999),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                          height: 12),
                                                      LayoutBuilder(
                                                        builder: (context, c) {
                                                          final w = c.maxWidth;
                                                          final cross = w >= 860
                                                              ? 4
                                                              : w >= 600
                                                                  ? 3
                                                                  : w >= 380
                                                                      ? 2
                                                                      : 1;
                                                          return GridView
                                                              .builder(
                                                            shrinkWrap: true,
                                                            physics:
                                                                const NeverScrollableScrollPhysics(),
                                                            itemCount:
                                                                announcement
                                                                    .files
                                                                    .length,
                                                            gridDelegate:
                                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount:
                                                                  cross,
                                                              mainAxisSpacing:
                                                                  12,
                                                              crossAxisSpacing:
                                                                  12,
                                                              childAspectRatio:
                                                                  4 / 3,
                                                            ),
                                                            itemBuilder: (_,
                                                                    i) =>
                                                                StudyMaterialWithDownloadButtonContainer2(
                                                              type: 2,
                                                              studyMaterial:
                                                                  announcement
                                                                      .files[i],
                                                              boxConstraints:
                                                                  const BoxConstraints(
                                                                maxHeight: 150,
                                                                maxWidth: double
                                                                    .infinity,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('id', timeago.IdMessages());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => _showDetailsPopup(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeago.format(announcement.createdAt,
                                  locale: 'id'),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (!announcement.creator.isEmpty) ...[
                              Icon(
                                FontAwesomeIcons.bullhorn,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  announcement.creator,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ])
                        ],
                      ),
                    ),
                    if (announcement.files.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lightColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.8)
                                .withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file_rounded,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${announcement.files.length}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
