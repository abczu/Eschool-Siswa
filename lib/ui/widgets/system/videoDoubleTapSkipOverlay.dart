import 'package:flutter/material.dart';

class VideoDoubleTapSkipOverlay extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const VideoDoubleTapSkipOverlay({
    Key? key,
    required this.child,
    this.onTap,
    // Parameter ini tetap ada agar tidak error di file lain, meski tidak dipakai lagi
    dynamic videoPlayerController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            child,
            // Lapisan transparan penuh untuk menangani ketukan tunggal (show/hide controls)
            // Kita gunakan Positioned.fill agar menutupi seluruh area video
            Positioned.fill(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}
