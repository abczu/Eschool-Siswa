import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// Kontrol play/pause untuk video upload langsung (MP4).
// Video YouTube dibuka ke aplikasi YouTube eksternal (tanpa player tambahan).
class PlayPauseButtonContainer extends StatefulWidget {
  final VideoPlayerController? videoPlayerController;
  final AnimationController controlsAnimationController;

  const PlayPauseButtonContainer({
    Key? key,
    this.videoPlayerController,
    required this.controlsAnimationController,
  }) : super(key: key);

  @override
  State<PlayPauseButtonContainer> createState() =>
      _PlayPauseButtonContainerState();
}

class _PlayPauseButtonContainerState extends State<PlayPauseButtonContainer> {
  bool _isPlaying = false;
  bool _isCompleted = false;

  @override
  void initState() {
    widget.videoPlayerController?.addListener(videoPlayerListener);
    _isPlaying = widget.videoPlayerController?.value.isPlaying ?? false;
    super.initState();
  }

  void videoPlayerListener() {
    if (!mounted) return;
    final controller = widget.videoPlayerController;
    if (controller == null) return;
    if (controller.value.isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = controller.value.isPlaying;
      });
    }

    final duration = controller.value.duration;
    final isCompleted = duration > Duration.zero &&
        controller.value.position >= duration;

    if (isCompleted != _isCompleted) {
      setState(() {
        _isCompleted = isCompleted;
      });
    }
  }

  @override
  void dispose() {
    widget.videoPlayerController?.removeListener(videoPlayerListener);
    super.dispose();
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 30,
    bool isCircle = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3), // Subtly dark like YouTube
        shape: BoxShape.circle,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: IconButton(
        iconSize: size,
        color: Colors.white,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mundur 10 Detik
          _buildControlButton(
            icon: Icons.replay_10,
            onPressed: () {
              if (!widget.controlsAnimationController.isCompleted) {
                widget.controlsAnimationController.forward();
                return;
              }
              final controller = widget.videoPlayerController;
              if (controller == null) return;
              final currentPos = controller.value.position;
              final newPos = currentPos - const Duration(seconds: 10);
              controller.seekTo(newPos);
            },
          ),

          // Play / Pause / Restart (Main Focus)
          _buildControlButton(
            size: 55, // Larger for international standard
            icon: _isCompleted
                ? Icons.restart_alt
                : _isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
            onPressed: () async {
              if (!widget.controlsAnimationController.isCompleted) {
                widget.controlsAnimationController.forward();
                return;
              }

              final controller = widget.videoPlayerController;
              if (controller == null) return;

              if (_isCompleted) {
                controller.seekTo(Duration.zero);
                controller.play();
                return;
              }

              if (_isPlaying) {
                controller.pause();
              } else {
                controller.play();
                // Sembunyikan kontrol setelah jeda sebentar
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) widget.controlsAnimationController.reverse();
              }
            },
          ),

          // Maju 10 Detik
          _buildControlButton(
            icon: Icons.forward_10,
            onPressed: () {
              if (!widget.controlsAnimationController.isCompleted) {
                widget.controlsAnimationController.forward();
                return;
              }
              final controller = widget.videoPlayerController;
              if (controller == null) return;
              final currentPos = controller.value.position;
              final newPos = currentPos + const Duration(seconds: 10);
              controller.seekTo(newPos);
            },
          ),
        ],
      ),
    );
  }
}
