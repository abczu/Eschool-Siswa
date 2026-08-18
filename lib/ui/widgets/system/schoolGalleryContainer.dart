import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/system/schoolConfigurationCubit.dart';
import 'package:eschool/cubits/system/schoolGalleryCubit.dart';
import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class SchoolGalleryContainer extends StatelessWidget {
  final Student student;
  const SchoolGalleryContainer({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchoolGalleryCubit, SchoolGalleryState>(
      builder: (context, state) {
        if (state is SchoolGalleryFetchSuccess) {
          final schoolGallery = state.gallery;
          if (schoolGallery.isEmpty) {
            return const SizedBox();
          }

          return Container(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with animation
                _buildHeader(context),

                // Gallery grid with staggered animation
                _buildGalleryGrid(context, schoolGallery),
              ],
            ),
          );
        }
        return _buildShimmerLoading(context);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Utils.screenContentHorizontalPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Gallery section title with custom styling
                Icon(
                    Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                  size: 22.0,
                ),
                SizedBox(width: 10),
                Text(
                  Utils.getTranslatedLabel(galleryKey),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20.0,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.start,
                ),

          const Spacer(),
          // View all button with modern styling
          InkWell(
            onTap: () {
              Get.toNamed(Routes.schoolGallery, arguments: student);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Utils.getTranslatedLabel(viewAllKey),
                    style: TextStyle(
                      color: Utils.getColorScheme(context).primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Utils.getColorScheme(context).primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context, List gallery) {
    return Container(
      height: 240,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: Utils.screenContentHorizontalPadding,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: gallery.length,
        itemBuilder: (context, index) {
          final item = gallery[index];

          return GestureDetector(
            onTap: () {
              Get.toNamed(Routes.galleryDetails, arguments: {
                "gallery": item,
                "sessionYear": context
                    .read<SchoolConfigurationCubit>()
                    .getSchoolConfiguration()
                    .sessionYear
              });
            },
            child: Container(
              width: 165,
              // margin: EdgeInsetsDirectional.only(
              //   end: 16,
              //   bottom: 8,
              // ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gallery thumbnail with overlay gradient
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 150,
                          width: 150,
                           child: item.isThumbnailSvg()
                              ? SvgPicture.network(
                                  Utils.fixImageUrl(item.thumbnail ?? ""),
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: Utils.fixImageUrl(item.thumbnail ?? ""),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Utils.getColorScheme(context)
                                        .surfaceContainerHighest,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Utils.getColorScheme(context)
                                            .primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Utils.getColorScheme(context)
                                        .surfaceContainerHighest,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Utils.getColorScheme(context)
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Gradient overlay for better text readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
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
                      // Media count indicators
                      Positioned(
                        bottom: 8,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            if (item.getImages().isNotEmpty)
                              _buildCountBadge(
                                context,
                                Icons.image_outlined,
                                item.getImages().length.toString(),
                              ),
                            if (item.getImages().isNotEmpty &&
                                item.getVideos().isNotEmpty)
                              SizedBox(width: 8),
                            if (item.getVideos().isNotEmpty)
                              _buildCountBadge(
                                context,
                                Icons.videocam_outlined,
                                item.getVideos().length.toString(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Gallery title with modern styling
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4, top: 12),
                    child: Text(
                      (item.title ?? ""),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: Utils.getColorScheme(context).onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountBadge(BuildContext context, IconData icon, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    // Shimmer loading effect for better UX
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: EdgeInsets.symmetric(
        horizontal: Utils.screenContentHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Row(
            children: [
              Container(
                width: 100,
                height: 24,
                decoration: BoxDecoration(
                  color: Utils.getColorScheme(context).surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Utils.getColorScheme(context).surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Gallery items shimmer
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 180,
                  margin: EdgeInsetsDirectional.only(end: 16),
                  decoration: BoxDecoration(
                    color: Utils.getColorScheme(context).surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
