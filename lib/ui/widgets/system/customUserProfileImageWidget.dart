import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/utils/system/ZoomHelper.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

//This widget will return curicular or rectengular profile image or default image on error with cached network image for general usage
class CustomUserProfileImageWidget extends StatelessWidget {
  final String profileUrl;
  final Color? color;
  final BuildContext? context;
  final BorderRadius? radius;
  final VoidCallback? onTaps;
  const CustomUserProfileImageWidget(
      {super.key,
      required this.profileUrl,
      this.color,
      this.radius,
      this.context,this.onTaps});

  String _fixUrl(String url) {
    return Utils.fixImageUrl(url);
  }

  _imageOrDefaultProfileImage(BuildContext ctx) {
    final fixedUrl = _fixUrl(profileUrl);
    return InkWell(
      onTap: onTaps ?? () {
        // Zoom image preview
        showBlurZoomImagePreview(
          context ?? ctx,
          imageUrl: fixedUrl,
        );
      },
      child: CachedNetworkImage(
        fit: BoxFit.cover,
        imageUrl: fixedUrl,
        errorWidget: (context, url, error) {
          return SvgPicture.asset(
            Utils.getImagePath("default_profile.svg"),
            colorFilter: color == null
                ? null
                : ColorFilter.mode(color!, BlendMode.srcIn),
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return radius != null
        ? ClipRRect(
            borderRadius: radius!,
            child: _imageOrDefaultProfileImage(context),
          )
        : ClipOval(
            child: _imageOrDefaultProfileImage(context),
          );
  }
}
