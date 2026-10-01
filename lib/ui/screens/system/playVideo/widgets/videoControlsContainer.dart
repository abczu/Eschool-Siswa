import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

// Kontrol bawah (durasi + slider + fullscreen) untuk video upload langsung.
// Video YouTube dibuka ke aplikasi YouTube eksternal (tanpa player tambahan).
class VideoControlsContainer extends StatefulWidget {
  final AnimationController controlsAnimationController;
  final VideoPlayerController? videoPlayerController;
  final bool isGalleryVideo;
  final VoidCallback? onFullscreenPressed;
  const VideoControlsContainer({
    Key? key,
    this.videoPlayerController,
    required this.controlsAnimationController,
    this.isGalleryVideo = false,
    this.onFullscreenPressed,
  }) : super(key: key);

  @override
  State<VideoControlsContainer> createState() => _VideoControlsContainerState();
}

class _VideoControlsContainerState extends State<VideoControlsContainer> {
  late Duration currentVideoDuration = Duration.zero;
  final double sliderHeight = 4.0;

  void listener() {
    final controller = widget.videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return;
    currentVideoDuration = controller.value.position;
    setState(() {});
  }

  bool _allowGesture() {
    return widget.controlsAnimationController.isCompleted;
  }

  String _buildCurrentVideoDurationInHMS() {
    String time = "";
    if (currentVideoDuration.inHours != 0) {
      time = "${currentVideoDuration.inHours.toString().padLeft(2, '0')}:";
    }
    if (currentVideoDuration.inMinutes != 0) {
      time =
          "$time${(currentVideoDuration.inMinutes - (24 * currentVideoDuration.inHours)).toString().padLeft(2, '0')}:";
    }
    if (currentVideoDuration.inSeconds != 0) {
      time =
          "$time${(currentVideoDuration.inSeconds - (60 * currentVideoDuration.inMinutes)).toString().padLeft(2, '0')}";
    }
    return time;
  }

  String _buildVideoDurationInHMS() {
    final controller = widget.videoPlayerController;
    Duration videoDuration = controller?.value.duration ?? Duration.zero;
    String time = "";
    if (videoDuration.inHours != 0) {
      time = "${(videoDuration.inHours).toString().padLeft(2, '0')}:";
    }
    if (videoDuration.inMinutes != 0) {
      time =
          "$time${(videoDuration.inMinutes - (24 * videoDuration.inHours)).toString().padLeft(2, '0')}:";
    }
    if (videoDuration.inSeconds != 0) {
      time =
          "$time${(videoDuration.inSeconds - (60 * videoDuration.inMinutes)).toString().padLeft(2, '0')}";
    }
    return time;
  }

  @override
  void initState() {
    widget.videoPlayerController?.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    widget.videoPlayerController?.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = (widget.videoPlayerController?.value.duration.inSeconds ?? 0)
        .toDouble();
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 15,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  _buildCurrentVideoDurationInHMS().isEmpty
                      ? ""
                      : "${_buildCurrentVideoDurationInHMS()} / ${_buildVideoDurationInHMS()}",
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  iconSize: 32, // Larger icon
                  onPressed: () {
                    if (_allowGesture()) {
                      if (widget.onFullscreenPressed != null) {
                        widget.onFullscreenPressed!();
                        return;
                      }
                      if (widget.isGalleryVideo) {
                        Get.back();
                        return;
                      }
                      if (MediaQuery.of(context).orientation ==
                          Orientation.portrait) {
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.landscapeRight,
                          DeviceOrientation.landscapeLeft
                        ]);
                      } else {
                        SystemChrome.setPreferredOrientations(
                          [DeviceOrientation.portraitUp],
                        );
                      }
                    } else {
                      //if control menu is not open then open here
                      widget.controlsAnimationController.forward();
                    }
                  },
                  icon: const Icon(Icons.fullscreen),
                  tooltip: "Fullscreen",
                )
              ],
            ),
          ),
          SizedBox(
            height: sliderHeight,
            width: MediaQuery.of(context).size.width,
            child: SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 0.0),
                    trackHeight: sliderHeight,
                    trackShape: CustomTrackShape(),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                  ),
              child: Slider(
                max: totalSeconds,
                activeColor: Colors.white,
                inactiveColor: Colors.white38,
                value: currentVideoDuration.inSeconds.toDouble().clamp(0.0, totalSeconds > 0 ? totalSeconds : 0.0),
                thumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  if (_allowGesture()) {
                    setState(() {
                      currentVideoDuration = Duration(
                        seconds: value.toInt(),
                      );
                    });
                    widget.videoPlayerController?.seekTo(currentVideoDuration);
                  } else {
                    //if control menu is not open then open here
                    widget.controlsAnimationController.forward();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTrackShape extends RectangularSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    return Offset(offset.dx, offset.dy) &
        Size(parentBox.size.width, sliderTheme.trackHeight!);
  }
}
