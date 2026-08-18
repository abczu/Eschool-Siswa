import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PlayPauseButtonContainer extends StatefulWidget {
  final bool isYoutubeVideo;
  final VideoPlayerController? videoPlayerController;
  final YoutubePlayerController? youtubePlayerController;
  final AnimationController controlsAnimationController;

  const PlayPauseButtonContainer({
    Key? key,
    this.youtubePlayerController,
    this.videoPlayerController,
    required this.isYoutubeVideo,
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
    if (widget.isYoutubeVideo) {
      widget.youtubePlayerController!.addListener(youtubePlayerListener);
      _isPlaying = widget.youtubePlayerController!.value.isPlaying;
    } else {
      widget.videoPlayerController!.addListener(videoPlayerListener);
      _isPlaying = widget.videoPlayerController!.value.isPlaying;
    }
    super.initState();
  }

  void youtubePlayerListener() {
    if (!mounted) return;
    if (widget.youtubePlayerController!.value.isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = widget.youtubePlayerController!.value.isPlaying;
      });
    }

    final duration = widget.youtubePlayerController!.metadata.duration;
    final isCompleted = duration > Duration.zero &&
        widget.youtubePlayerController!.value.position >= duration;

    if (isCompleted != _isCompleted) {
      setState(() {
        _isCompleted = isCompleted;
      });
    }
  }

  void videoPlayerListener() {
    if (!mounted) return;
    if (widget.videoPlayerController!.value.isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = widget.videoPlayerController!.value.isPlaying;
      });
    }

    final duration = widget.videoPlayerController!.value.duration;
    final isCompleted = duration > Duration.zero &&
        widget.videoPlayerController!.value.position >= duration;

    if (isCompleted != _isCompleted) {
      setState(() {
        _isCompleted = isCompleted;
      });
    }
  }

  @override
  void dispose() {
    if (widget.isYoutubeVideo) {
      widget.youtubePlayerController?.removeListener(youtubePlayerListener);
    } else {
      widget.videoPlayerController?.removeListener(videoPlayerListener);
    }
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
              final currentPos = widget.isYoutubeVideo
                  ? widget.youtubePlayerController!.value.position
                  : widget.videoPlayerController!.value.position;
              final newPos = currentPos - const Duration(seconds: 10);
              widget.isYoutubeVideo
                  ? widget.youtubePlayerController!.seekTo(newPos)
                  : widget.videoPlayerController!.seekTo(newPos);
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

              if (_isCompleted) {
                if (widget.isYoutubeVideo) {
                  widget.youtubePlayerController!.seekTo(Duration.zero);
                  widget.youtubePlayerController!.play();
                } else {
                  widget.videoPlayerController!.seekTo(Duration.zero);
                  widget.videoPlayerController!.play();
                }
                return;
              }

              if (_isPlaying) {
                widget.isYoutubeVideo
                    ? widget.youtubePlayerController!.pause()
                    : widget.videoPlayerController!.pause();
              } else {
                widget.isYoutubeVideo
                    ? widget.youtubePlayerController!.play()
                    : widget.videoPlayerController!.play();
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
              final currentPos = widget.isYoutubeVideo
                  ? widget.youtubePlayerController!.value.position
                  : widget.videoPlayerController!.value.position;
              final newPos = currentPos + const Duration(seconds: 10);
              widget.isYoutubeVideo
                  ? widget.youtubePlayerController!.seekTo(newPos)
                  : widget.videoPlayerController!.seekTo(newPos);
            },
          ),
        ],
      ),
    );
  }
}
