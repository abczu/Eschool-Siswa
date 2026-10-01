import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/system/gallery.dart';
import 'package:eschool/data/models/system/galleryFile.dart';
import 'package:eschool/data/models/academic/sessionYear.dart';
import 'package:eschool/app/routes.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';

import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:readmore/readmore.dart';
import 'package:video_player/video_player.dart';
import 'package:eschool/utils/system/youtubeHelper.dart';

class GalleryDetailsScreen extends StatefulWidget {
  final Gallery gallery;
  final SessionYear sessionYear;

  GalleryDetailsScreen(
      {Key? key, required this.gallery, required this.sessionYear})
      : super(key: key);

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return GalleryDetailsScreen(
      gallery: arguments['gallery'] as Gallery,
      sessionYear: arguments['sessionYear'] as SessionYear,
    );
  }

  @override
  State<GalleryDetailsScreen> createState() => _GalleryDetailsScreenState();
}

class _GalleryDetailsScreenState extends State<GalleryDetailsScreen> {
  String selectedTabTitleKey = photosKey;
  Duration tabChangeAnimationDuration = const Duration(milliseconds: 400);

  /// Sanitasi URL gambar: konversi http:// → https:// agar gambar baru
  /// yang diupload backend tidak gagal dimuat karena mixed-content.
  /// Di dev/testing mode, menggunakan HTTP jika URL merujuk ke domain dev.
  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return Utils.fixImageUrl(url);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // ✅ Reset orientation ke portrait saat keluar dari screen gallery
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Widget _buildTabBarContainer() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
            // offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, boxConstraints) {
        return Stack(
          children: [
            AnimatedAlign(
              duration: tabChangeAnimationDuration,
              curve: Curves.easeInOut,
              alignment: selectedTabTitleKey == photosKey
                  ? AlignmentDirectional.centerStart
                  : AlignmentDirectional.centerEnd,
              child: Container(
                margin: EdgeInsetsDirectional.all(5),
                width: boxConstraints.maxWidth * (0.5) - 10,
                height: boxConstraints.maxHeight - 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabTitleKey = photosKey;
                      });
                    },
                    child: Container(
                      height: boxConstraints.maxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        Utils.getTranslatedLabel(photosKey),
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: selectedTabTitleKey == photosKey
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTabTitleKey = videosKey;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: boxConstraints.maxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Text(
                        Utils.getTranslatedLabel(videosKey),
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: selectedTabTitleKey == videosKey
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  void _showFullScreenImage(BuildContext context, int index) {
    final photos = widget.gallery.getImages();
    final PageController pageController = PageController(initialPage: index);
    int currentPage = index;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          return StatefulBuilder(
            builder: (context, setState) {
              return GestureDetector(
                onTap: () {
                  // Close on tap anywhere on the screen
                  Navigator.of(context).pop();
                },
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: pageController,
                          itemCount: photos.length,
                          onPageChanged: (page) {
                            setState(() {
                              currentPage = page;
                            });
                          },
                          itemBuilder: (context, currentIndex) {
                            final galleryFile = photos[currentIndex];
                            return Center(
                              child: GestureDetector(
                                // Prevent taps on the image from closing (for better zoom experience)
                                onTap: () {
                                  // Stop propagation by doing nothing
                                },
                                child: PinchZoom(
                                  maxScale: 2.5,
                                  child: Hero(
                                    tag: "gallery_image_${galleryFile.id ?? currentIndex}",
                                    child: galleryFile.isSvgImage()
                                        ? SvgPicture.network(
                                            _fixUrl(galleryFile.fileUrl),
                                            fit: BoxFit.contain,
                                            placeholderBuilder: (context) =>
                                                Center(
                                              child:
                                                  CustomCircularProgressIndicator(
                                                indicatorColor: Colors.white,
                                              ),
                                            ),
                                          )
                                        : CachedNetworkImage(
                                            imageUrl:
                                                _fixUrl(galleryFile.fileUrl),
                                            placeholder: (context, url) =>
                                                Center(
                                              child:
                                                  CustomCircularProgressIndicator(
                                                indicatorColor: Colors.white,
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error,
                                                        color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Title and edit date
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  photos[currentPage].fileName ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Updated: ${photos[currentPage].updatedAt != null ? Utils.formatDate(DateTime.parse(photos[currentPage].updatedAt!)) : 'N/A'}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Control buttons
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Row(
                            children: [
                              // Download button
                              GestureDetector(
                                onTap: () {
                                  final galleryFile = photos[currentPage];
                                  Utils.openDownloadBottomsheet(
                                    context: context,
                                    storeInExternalStorage: true,
                                    studyMaterial: StudyMaterial(
                                      id: galleryFile.id ?? 0,
                                      fileName: galleryFile.fileName!,
                                      fileUrl: galleryFile.fileUrl ?? "",
                                      fileExtension:
                                          galleryFile.fileExtension ?? "",
                                      fileThumbnail:
                                          galleryFile.fileThumbnail ?? "",
                                      studyMaterialType: StudyMaterialType.file,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.download,
                                      color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Close button
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Image counter
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${currentPage + 1}/${photos.length}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// true jika file adalah video upload langsung (MP4), bukan YouTube.
  bool _isDirectVideoFile(GalleryFile file) {
    final fixed = _fixUrl(file.fileUrl ?? "");
    if (fixed.isEmpty) return true;
    final yid = YoutubeHelper.extractYoutubeId(fixed);
    return file.isUploadedVideo() || file.type == "3" || yid == null;
  }

  /// Membuka video YouTube di aplikasi YouTube (eksternal).
  /// Mengembalikan true jika berhasil dibuka.
  Future<bool> _openYoutubeExternal(BuildContext context, String? url) async {
    final opened = await Utils.launchExternalUrl(url);
    if (!opened && context.mounted) {
      Utils.showCustomSnackBar(
        context: context,
        errorMessage: "Tidak dapat membuka video YouTube",
        backgroundColor: Colors.red,
      );
    }
    return opened;
  }

  void _showFullScreenVideo(BuildContext context, int index) {
    final allVideos = widget.gallery.getVideos();
    if (allVideos.isEmpty || index >= allVideos.length) return;

    // Viewer internal hanya untuk video upload langsung (MP4).
    // Video YouTube dibuka di aplikasi YouTube (lihat onTap thumbnail).
    final videos = allVideos.where(_isDirectVideoFile).toList();
    if (videos.isEmpty) return;
    final tapped = allVideos[index];
    if (!_isDirectVideoFile(tapped)) return;
    final initialPage = videos.indexOf(tapped);
    if (initialPage < 0) return;

    final PageController pageController =
        PageController(initialPage: initialPage);
    int currentPage = initialPage;
    bool showControls = true;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true, // Ubah ke true untuk mencegah bug layar terbagi saat rotasi
        barrierColor: Colors.black,
        pageBuilder: (BuildContext context, _, __) {
          return StatefulBuilder(
            builder: (context, setState) {
              return PopScope(
                canPop: true,
                onPopInvokedWithResult: (didPop, result) async {
                  // ✅ Reset orientation ke portrait saat back button
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                  ]);
                },
                child: GestureDetector(
                  onTap: () {
                    // Close on tap anywhere on the background (except video)
                    // ✅ Reset orientation sebelum pop
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                    ]);
                    Navigator.of(context).pop();
                  },
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: SafeArea(
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: pageController,
                            itemCount: videos.length,
                            onPageChanged: (page) {
                              setState(() {
                                currentPage = page;
                              });
                            },
                            itemBuilder: (context, currentIndex) {
                              final galleryFile = videos[currentIndex];
                              final String rawUrl = galleryFile.fileUrl ?? "";
                              final String videoUrl = _fixUrl(rawUrl);

                              if (videoUrl.isEmpty) {
                                return const Center(
                                    child: Text("URL video tidak valid",
                                        style: TextStyle(color: Colors.white)));
                              }

                              return Center(
                                child: GalleryDirectVideoPlayer(
                                  videoUrl: videoUrl,
                                  onToggleControls: (visible) {
                                    setState(() {
                                      showControls = visible;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                          // Title and controls
                          Positioned(
                            top: 16,
                            right: 16,
                            child: AnimatedOpacity(
                              opacity: showControls ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: IgnorePointer(
                                ignoring: !showControls,
                                child: Row(
                                  children: [
                                    // Copy link button
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(
                                            text: videos[currentPage]
                                                    .fileUrl!));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                              alpha: 0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.link,
                                            color: Colors.black),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Close button
                                    GestureDetector(
                                      onTap: () {
                                        // ✅ Reset orientation sebelum pop
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                        ]);
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.white.withValues(alpha: 0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Video counter
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: AnimatedOpacity(
                              opacity: showControls ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${currentPage + 1}/${videos.length}",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildPhotosContainer() {
    final photos = widget.gallery.getImages();
    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            Utils.getTranslatedLabel(noPhotosAvailableKey),
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final galleryFile = photos[index];
        return GestureDetector(
          onTap: () {
            _showFullScreenImage(context, index);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Hero(
              tag: "gallery_image_${galleryFile.id ?? index}",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: galleryFile.isSvgImage()
                    ? SvgPicture.network(
                        _fixUrl(galleryFile.fileUrl),
                        fit: BoxFit.cover,
                        placeholderBuilder: (context) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: _fixUrl(galleryFile.fileUrl),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.error,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosContainer() {
    final videos = widget.gallery.getVideos();
    if (videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            Utils.getTranslatedLabel(noVideosAvailableKey),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: videos
          .map((galleryFile) {
            final String rawUrl = galleryFile.fileUrl ?? "";
            final String videoUrl = _fixUrl(rawUrl);
            final String? youtubeId =
                YoutubeHelper.extractYoutubeId(videoUrl);
            final bool isDirectVideo = galleryFile.isUploadedVideo() ||
                galleryFile.type == "3" ||
                youtubeId == null;

            final String? fileThumb = galleryFile.fileThumbnail;
            final String thumbnailUrl = isDirectVideo
                ? (fileThumb != null && fileThumb.isNotEmpty
                    ? _fixUrl(fileThumb)
                    : _fixUrl(widget.gallery.thumbnail))
                : (fileThumb != null && fileThumb.isNotEmpty
                    ? _fixUrl(fileThumb)
                    : (youtubeId != null
                        ? YoutubeHelper.thumbnailUrlForId(youtubeId)
                        : _fixUrl(widget.gallery.thumbnail)));

            final String ext = (galleryFile.fileExtension ??
                    (videoUrl.contains('.') && videoUrl.split('.').last.length <= 4
                        ? videoUrl.split('.').last
                        : 'VIDEO'))
                .toUpperCase();

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            fit: BoxFit.cover,
                            width: MediaQuery.of(context).size.width,
                            height: 180,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              height: 180,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              height: 180,
                              child: const Icon(Icons.video_library,
                                  color: Colors.white, size: 48),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            height: 180,
                            child: const Icon(Icons.video_library,
                                color: Colors.white, size: 48),
                          ),
                    // Play Button overlay
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // Type Badge (e.g., MP4 vs YOUTUBE)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDirectVideo
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.9)
                              : Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDirectVideo
                                  ? Icons.video_file
                                  : Icons.play_circle_fill,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDirectVideo ? ext : "YOUTUBE",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Penanda video YouTube dibuka di aplikasi YouTube
                    if (!isDirectVideo)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Tonton di YouTube",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        // Video YouTube dibuka di aplikasi YouTube
                        // (tanpa player tambahan di dalam aplikasi).
                        if (!isDirectVideo) {
                          _openYoutubeExternal(context, videoUrl);
                          return;
                        }
                        _showFullScreenVideo(
                          context,
                          videos.indexOf(galleryFile),
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        width: MediaQuery.of(context).size.width,
                        height: 180,
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(),
    );
  }

  Widget _buildAppBar(String title) {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarSmallerHeightPercentage,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                left: 10,
                top: -2,
                child: const CustomBackButton(),
              ),
              // Judul dibatasi agar tidak menimpa tombol back.
              Positioned(
                left: 60,
                right: 16,
                top: 2,
                child: Text(
                  Utils.getTranslatedLabel(title),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    fontSize: Utils.screenTitleFontSize,
                  ),
                ),
              ),
            ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 25,
                top: MediaQuery.of(context).size.height *
                    Utils.appBarMediumtHeightPercentage),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured image
                Container(
                  height: 220,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: _fixUrl(widget.gallery.thumbnail),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child:
                            Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

                // Title and description
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 5),
                  child: Text(
                    widget.gallery.title ?? "",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 20),
                  child: ReadMoreText(
                    widget.gallery.description ?? "",
                    trimLines: 3,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: ' Show more',
                    trimExpandedText: ' Show less',
                    moreStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    lessStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),

                // Tab Bar
                _buildTabBarContainer(),

                const SizedBox(height: 20),

                // Tab Content
                selectedTabTitleKey == photosKey
                    ? _buildPhotosContainer()
                    : _buildVideosContainer(),
              ],
            ),
          ),
          _buildAppBar(widget.gallery.title ?? ""),
        ],
      ),
    );
  }
}

class GalleryDirectVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final ValueChanged<bool>? onToggleControls;

  const GalleryDirectVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.onToggleControls,
  }) : super(key: key);

  @override
  State<GalleryDirectVideoPlayer> createState() =>
      _GalleryDirectVideoPlayerState();
}

class _GalleryDirectVideoPlayerState extends State<GalleryDirectVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isFullscreen = false;
  bool _isMuted = false;
  double _playbackSpeed = 1.0;
  bool _isCompleted = false;

  // Auto-hide controls timer
  DateTime _lastInteraction = DateTime.now();
  static const _controlsHideDelay = Duration(seconds: 4);

  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  void _setControlsVisibility(bool visible) {
    _lastInteraction = DateTime.now();
    if (_showControls != visible) {
      setState(() {
        _showControls = visible;
      });
    }
    if (widget.onToggleControls != null) {
      widget.onToggleControls!(visible);
    }
  }

  void _toggleControlsVisibility() {
    _setControlsVisibility(!_showControls);
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
          _controller.addListener(_videoListener);
          _startControlsAutoHide();
        }
      }).catchError((error) {
        debugPrint("Error initializing VideoPlayer: $error");
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  void _videoListener() {
    if (!mounted) return;

    final value = _controller.value;

    // Detect video completed
    if (value.duration > Duration.zero &&
        (value.position >= value.duration ||
            (value.position >= value.duration - const Duration(milliseconds: 200) &&
                !value.isPlaying))) {
      if (!_isCompleted) {
        _isCompleted = true;
        _setControlsVisibility(true);
      }
    } else if (value.isPlaying && _isCompleted) {
      _isCompleted = false;
    }

    // Trigger rebuild for timer update
    if (value.isPlaying) {
      setState(() {});
    }
  }

  void _startControlsAutoHide() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _checkAutoHide();
    });
  }

  void _checkAutoHide() {
    if (!mounted) return;

    if (_showControls &&
        _controller.value.isPlaying &&
        !_isCompleted &&
        DateTime.now().difference(_lastInteraction) > _controlsHideDelay) {
      _setControlsVisibility(false);
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _checkAutoHide();
    });
  }

  void _onUserInteraction() {
    _lastInteraction = DateTime.now();
    if (!_showControls) {
      _setControlsVisibility(true);
    }
  }

  Future<void> _togglePlayPause() async {
    _onUserInteraction();
    if (_isCompleted) {
      await _controller.seekTo(Duration.zero);
      await _controller.play();
      if (mounted) {
        _isCompleted = false;
        _setControlsVisibility(true);
      }
      return;
    }
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _seekForward() async {
    _onUserInteraction();
    final duration = _controller.value.duration;
    final current = _controller.value.position;
    final target = current + const Duration(seconds: 10);

    if (duration > Duration.zero && target >= duration) {
      await _controller.seekTo(duration);
      await _controller.pause();
      if (mounted) {
        _isCompleted = true;
        _setControlsVisibility(true);
      }
    } else {
      await _controller.seekTo(target);
      await _controller.play();
      if (mounted) {
        _isCompleted = false;
        _setControlsVisibility(true);
      }
    }
  }

  Future<void> _seekBackward() async {
    _onUserInteraction();
    final current = _controller.value.position;
    final target = current - const Duration(seconds: 10);
    final destination = target < Duration.zero ? Duration.zero : target;
    await _controller.seekTo(destination);
    await _controller.play();
    if (mounted) {
      _isCompleted = false;
      _setControlsVisibility(true);
    }
  }

  void _toggleMute() {
    _onUserInteraction();
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _toggleFullscreen() {
    _onUserInteraction();
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void _showSpeedPicker() {
    _onUserInteraction();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kecepatan Putar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._speedOptions.map((speed) => ListTile(
                  leading: Icon(
                    speed == _playbackSpeed
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: speed == _playbackSpeed
                        ? Colors.greenAccent
                        : Colors.white38,
                    size: 22,
                  ),
                  title: Text(
                    speed == 1.0 ? 'Normal' : '${speed}x',
                    style: TextStyle(
                      color: speed == _playbackSpeed
                          ? Colors.greenAccent
                          : Colors.white,
                      fontWeight: speed == _playbackSpeed
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _playbackSpeed = speed;
                      _controller.setPlaybackSpeed(speed);
                    });
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }



  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            const Text(
              "Gagal memuat video",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.videoUrl.length > 60
                  ? '...${widget.videoUrl.substring(widget.videoUrl.length - 50)}'
                  : widget.videoUrl,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomCircularProgressIndicator(
              indicatorColor: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              "Memuat video...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final isPlaying = _controller.value.isPlaying;
    final isBuffering = _controller.value.isBuffering &&
        !_isCompleted &&
        position < duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControlsVisibility,
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio > 0
              ? _controller.value.aspectRatio
              : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video layer
              VideoPlayer(_controller),

              // Buffering indicator
              if (isBuffering)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),

              // Controls overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black87,
                          ],
                          stops: [0.0, 0.25, 0.6, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        // Top bar: speed + mute + fullscreen
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Playback speed button
                              _buildTopButton(
                                onTap: _showSpeedPicker,
                                child: Text(
                                  _playbackSpeed == 1.0
                                      ? '1x'
                                      : '${_playbackSpeed}x',
                                  style: TextStyle(
                                    color: _playbackSpeed != 1.0
                                        ? Colors.greenAccent
                                        : Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Mute button
                              _buildTopButton(
                                onTap: _toggleMute,
                                child: Icon(
                                  _isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Fullscreen button
                              _buildTopButton(
                                onTap: _toggleFullscreen,
                                child: Icon(
                                  _isFullscreen
                                      ? Icons.fullscreen_exit_rounded
                                      : Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center controls: skip back, play/pause, skip forward
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Skip backward 10s
                            _buildCenterButton(
                              onTap: _seekBackward,
                              icon: Icons.replay_10_rounded,
                              size: 32,
                            ),
                            const SizedBox(width: 32),
                            // Play/Pause/Replay
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _isCompleted
                                      ? Icons.replay_rounded
                                      : isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            // Skip forward 10s
                            _buildCenterButton(
                              onTap: _seekForward,
                              icon: Icons.forward_10_rounded,
                              size: 32,
                            ),
                          ],
                        ),

                        // Bottom bar: progress bar + time
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 12, right: 12, bottom: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Seek bar
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14),
                                  activeTrackColor: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  inactiveTrackColor:
                                      Colors.white.withValues(alpha: 0.3),
                                  thumbColor: Colors.white,
                                  overlayColor:
                                      Colors.white.withValues(alpha: 0.2),
                                ),
                                child: Slider(
                                  value: progress.clamp(0.0, 1.0),
                                  onChanged: (value) {
                                    _onUserInteraction();
                                    final newPosition = Duration(
                                      milliseconds:
                                          (value * duration.inMilliseconds)
                                              .toInt(),
                                    );
                                    _controller.seekTo(newPosition);
                                  },
                                  onChangeStart: (_) {
                                    _controller.pause();
                                  },
                                  onChangeEnd: (value) async {
                                    final newPosition = Duration(
                                      milliseconds:
                                          (value * duration.inMilliseconds)
                                              .toInt(),
                                    );
                                    await _controller.seekTo(newPosition);
                                    await _controller.play();
                                    if (mounted) {
                                      setState(() {
                                        _isCompleted = false;
                                        _showControls = true;
                                      });
                                    }
                                  },
                                ),
                              ),
                              // Time display
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }

  Widget _buildCenterButton({
    required VoidCallback onTap,
    required IconData icon,
    double size = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}



