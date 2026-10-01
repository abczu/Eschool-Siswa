import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/ui/widgets/system/noDataContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eschool/ui/widgets/system/directVideoPlayerDialog.dart';
import 'package:eschool/utils/system/utils.dart';

class VideosContainer extends StatelessWidget {
  final List<StudyMaterial> studyMaterials;
  final bool directPlay = true;
  const VideosContainer({Key? key, required this.studyMaterials})
      : super(key: key);

  // Red accent color with gradient options
  static const Color accentColor = Color(0xFFE94F4F);
  static const Color accentColorFaded = Color(0xCCE94F4F); // 0.8 opacity

  Widget _buildVideoContainer({
    required StudyMaterial studyMaterial,
    required BuildContext context,
    required int index,
  }) {
    // Video YouTube dibuka ke aplikasi YouTube asli (tanpa player tambahan).
    final bool isYoutube =
        studyMaterial.studyMaterialType == StudyMaterialType.youtubeVideo;
    // Remove top margin for the first item

    return Animate(
      effects: [
        FadeEffect(
            duration: Duration(milliseconds: 400),
            delay: Duration(milliseconds: 50 * index),
            curve: Curves.easeOutQuad),
        SlideEffect(
            begin: const Offset(0.05, 0),
            end: const Offset(0, 0),
            duration: Duration(milliseconds: 400),
            delay: Duration(milliseconds: 50 * index),
            curve: Curves.easeOutQuad),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0, left: 12.0, right: 12.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 4),
                blurRadius: 12,
              )
            ],
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _startDirectVideoPlay(context, studyMaterial),
                splashColor: accentColorFaded.withValues(alpha: 0.1),
                highlightColor: accentColorFaded.withValues(alpha: 0.05),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail with gradient overlay
                        Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: studyMaterial.fileThumbnail,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 180,
                                color: Colors.grey[300],
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 180,
                                color: Colors.grey[300],
                                child:
                                    const Icon(Icons.error, color: accentColor),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Play button overlay
                            Positioned.fill(
                              child: Center(
                                  child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentColor.withValues(alpha: 0.9),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              )),
                            ),
                            // Video title on thumbnail
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Text(
                                studyMaterial.fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Video info
                      ],
                    ),
                    // Corner accent
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [accentColor, accentColorFaded],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        child: Icon(
                          isYoutube
                              ? Icons.open_in_new_rounded
                              : Icons.videocam,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Penanda video YouTube dibuka di aplikasi YouTube
                    if (isYoutube)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "YOUTUBE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startDirectVideoPlay(
      BuildContext context, StudyMaterial studyMaterial) async {
    // Video YouTube dibuka di aplikasi YouTube (tanpa player tambahan).
    if (studyMaterial.studyMaterialType == StudyMaterialType.youtubeVideo) {
      final opened = await Utils.launchExternalUrl(studyMaterial.fileUrl);
      if (!opened && context.mounted) {
        Utils.showCustomSnackBar(
          context: context,
          errorMessage: "Tidak dapat membuka video YouTube",
          backgroundColor: Colors.red,
        );
      }
      return;
    }
    showDialog(
      context: context,
      builder: (context) => DirectVideoPlayerDialog(
        currentlyPlayingVideo: studyMaterial,
        relatedVideos: studyMaterials,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('VideosContainer()');

    if (studyMaterials.isEmpty) {
      return const NoDataContainer(titleKey: noVideosUploadedKey);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: studyMaterials.length,
      itemBuilder: (context, index) {
        return _buildVideoContainer(
          studyMaterial: studyMaterials[index],
          context: context,
          index: index,
        );
      },
    );
  }
}
