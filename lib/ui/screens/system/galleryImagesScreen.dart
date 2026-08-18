import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/system/galleryFile.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/ui/widgets/system/customAppbar.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:eschool/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:pinch_zoom/pinch_zoom.dart';

import '../../widgets/academic/studyMaterialWithDownloadButtonContainer.dart';

class GalleryImagesScreen extends StatefulWidget {
  final List<GalleryFile> images;
  final int currentImageIndex;
  GalleryImagesScreen(
      {Key? key, required this.currentImageIndex, required this.images})
      : super(key: key);

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return GalleryImagesScreen(
        currentImageIndex: arguments['currentImageIndex'],
        images: arguments['images']);
  }

  @override
  State<GalleryImagesScreen> createState() => _GalleryImagesScreenState();
}

class _GalleryImagesScreenState extends State<GalleryImagesScreen> {
  late final PageController _pageController =
      PageController(initialPage: widget.currentImageIndex);

  String _fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return Utils.fixImageUrl(url);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height *
                    (Utils.appBarSmallerHeightPercentage)),
            child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  final galleryImage = widget.images[index];
                  return LayoutBuilder(builder: (context, boxConstraints) {
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: StudyMaterialWithDownloadButtonContainer(
                            boxConstraints: boxConstraints,
                            studyMaterial: StudyMaterial(
                                fileExtension: galleryImage.fileExtension!,
                                fileUrl: galleryImage.fileUrl!,
                                fileThumbnail: galleryImage.fileThumbnail!,
                                fileName: galleryImage.fileName!,
                                id: galleryImage.id!,
                                studyMaterialType: StudyMaterialType.file),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height *
                                  (Utils.appBarSmallerHeightPercentage)),
                          child: PinchZoom(
                            maxScale: 5,
                            child: galleryImage.isSvgImage()
                                ? SvgPicture.network(
                                    _fixUrl(galleryImage.fileUrl),
                                    placeholderBuilder: (context) => Center(
                                      child: CustomCircularProgressIndicator(
                                        indicatorColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: _fixUrl(galleryImage.fileUrl)),
                          ),
                        ),
                      ],
                    );
                  });
                }),
          ),
          CustomAppBar(
            title: "",
          ),
        ],
      ),
    );
  }
}
