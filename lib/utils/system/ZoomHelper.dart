import 'dart:ui'; // untuk ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/utils/system/utils.dart';

void showBlurZoomImagePreview(
  BuildContext context, {
  required String imageUrl,
  String? heroTag,
}) {
  final sanitizedUrl = Utils.fixImageUrl(imageUrl);
  if (sanitizedUrl.isEmpty) return;

  showGeneralDialog(
    context: context,
    barrierLabel: 'ImagePreview',
    barrierDismissible: true, // tap di luar untuk tutup
    barrierColor: Colors.black.withValues(alpha: 0.25), // gelapkan latar
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(), // tap di area gelap nutup
        child: Stack(
          children: [
            // BLUR background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(color: Colors.black.withValues(alpha: 0.20)),
              ),
            ),

            // IMAGE di tengah (blok tap supaya tidak menutup saat tap di gambar)
            Center(
              child: GestureDetector(
                onTap: () {}, // consume tap
                child: Hero(
                  tag: heroTag ?? sanitizedUrl,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _ZoomableImage(imageUrl: sanitizedUrl),
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 12,
              right: 12,
              child: IconButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Colors.black.withValues(alpha: 0.5),
                  ),
                ),
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
                tooltip: 'Tutup',
              ),
            ),
          ],
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      // animasi fade + scale halus
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

/// Widget internal untuk zoom/pan (pinch to zoom)
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.imageUrl});
  final String imageUrl;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sanitizedUrl = Utils.fixImageUrl(widget.imageUrl);

    return InteractiveViewer(
      transformationController: _controller,
      minScale: 1.0,
      maxScale: 4.0,
      panEnabled: true,
      clipBehavior: Clip.none,
      child: CachedNetworkImage(
        imageUrl: sanitizedUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) =>
            Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(
          Icons.person_rounded,
          color: Colors.white70,
          size: 64,
        ),
      ),
    );
  }
}
