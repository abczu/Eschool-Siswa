import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool/data/models/academic/studyMaterial.dart';
import 'package:eschool/ui/screens/system/playVideo/widgets/videoControlsContainer.dart';
import 'package:eschool/ui/screens/system/playVideo/widgets/playPauseButton.dart';
import 'package:eschool/ui/widgets/system/videoDoubleTapSkipOverlay.dart';
import 'package:eschool/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/system/svgButton.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PlayVideoScreen extends StatefulWidget {
  final List<StudyMaterial> relatedVideos;
  final StudyMaterial currentlyPlayingVideo;
  final Duration initialPosition;

  const PlayVideoScreen({
    Key? key,
    required this.relatedVideos,
    required this.currentlyPlayingVideo,
    this.initialPosition = Duration.zero,
  }) : super(key: key);

  @override
  State<PlayVideoScreen> createState() => _PlayVideoScreenState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return PlayVideoScreen(
      currentlyPlayingVideo:
          arguments['currentlyPlayingVideo'] as StudyMaterial,
      relatedVideos: arguments['relatedVideos'] as List<StudyMaterial>,
      initialPosition:
          arguments['initialPosition'] as Duration? ?? Duration.zero,
    );
  }
}

class _PlayVideoScreenState extends State<PlayVideoScreen>
    with TickerProviderStateMixin {
  late StudyMaterial currentlyPlayingStudyMaterialVideo =
      widget.currentlyPlayingVideo;

  final double _videoContainerPotraitHeightPercentage = 0.3;

  //need to use this to ensure youtube/video controller disposed properlly
  //When user changed the video so for 100 milliseconds we set assignedVideoController
  //to false
  late bool assignedVideoController = false;

  YoutubePlayerController? _youtubePlayerController;
  VideoPlayerController? _videoPlayerController;

  late final AnimationController controlsMenuAnimationController =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late Animation<double> controlsMenuAnimation =
      Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: controlsMenuAnimationController,
      curve: Curves.easeInOut,
    ),
  );

  @override
  void initState() {
    if (currentlyPlayingStudyMaterialVideo.studyMaterialType ==
        StudyMaterialType.youtubeVideo) {
      loadYoutubeController();
    } else {
      loadVideoController();
    }
    super.initState();
    // Munculkan kontrol otomatis saat layar dibuka
    controlsMenuAnimationController.forward();
  }

  //To load non youtube video
  void loadVideoController() {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(currentlyPlayingStudyMaterialVideo.fileUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((value) {
        if (widget.initialPosition != Duration.zero) {
          _videoPlayerController?.seekTo(widget.initialPosition);
        }
        setState(() {});
        _videoPlayerController?.play();
      });
    assignedVideoController = true;
  }

  //to load youtube video
  void loadYoutubeController() {
    try {
      String youTubeId = YoutubePlayer.convertUrlToId(
            currentlyPlayingStudyMaterialVideo.fileUrl,
          ) ??
          "";

      _youtubePlayerController = YoutubePlayerController(
        initialVideoId: youTubeId,
        flags: YoutubePlayerFlags(
          hideThumbnail: true,
          hideControls: true,
          autoPlay: true, // Pastikan autoPlay aktif
          startAt: widget.initialPosition.inSeconds,
        ),
      );
      assignedVideoController = true;
    } catch (e) {
      print("Error loading YouTube controller: $e");
      // Handle YouTube player initialization errors gracefully
      if (mounted) {
        setState(() {
          assignedVideoController = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // ✅ Reset orientation ke portrait saat keluar dari video screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    controlsMenuAnimationController.dispose();
    _youtubePlayerController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  //To show play/pause button and and other control related details
  //Now separated from the dimming background to allow double tap to work
  Widget _buildVideoControlButtons(Orientation orientation) {
    return Stack(
      children: [
        Align(
          alignment: AlignmentDirectional.topStart,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: orientation == Orientation.landscape
                  ? Utils.screenContentHorizontalPadding
                  : 0,
              start: Utils.screenContentHorizontalPadding,
            ),
            child: SvgButton(
              onTap: () {
                // Get current position to return to previous screen
                Duration currentPosition = Duration.zero;
                if (currentlyPlayingStudyMaterialVideo.studyMaterialType ==
                    StudyMaterialType.youtubeVideo) {
                  currentPosition = _youtubePlayerController?.value.position ??
                      Duration.zero;
                } else {
                  currentPosition =
                      _videoPlayerController?.value.position ?? Duration.zero;
                }

                // Jika video dari Galeri (tidak ada video terkait), langsung kembali ke Galeri
                if (widget.relatedVideos.isEmpty) {
                  Get.back(result: currentPosition);
                  return;
                }

                if (orientation == Orientation.landscape) {
                  SystemChrome.setPreferredOrientations(
                    [DeviceOrientation.portraitUp],
                  );
                  return;
                }
                Get.back(result: currentPosition);
              },
              svgIconUrl: Utils.getBackButtonPath(context),
            ),
          ),
        ),
        Center(
          child: PlayPauseButtonContainer(
            isYoutubeVideo: currentlyPlayingStudyMaterialVideo
                    .studyMaterialType ==
                StudyMaterialType.youtubeVideo,
            controlsAnimationController:
                controlsMenuAnimationController,
            youtubePlayerController: _youtubePlayerController,
            videoPlayerController: _videoPlayerController,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: orientation == Orientation.landscape
                ? const EdgeInsets.only(bottom: 15, left: 10, right: 10)
                : EdgeInsets.zero,
            child: VideoControlsContainer(
              isGalleryVideo: widget.relatedVideos.isEmpty,
              isYoutubeVideo: currentlyPlayingStudyMaterialVideo
                      .studyMaterialType ==
                  StudyMaterialType.youtubeVideo,
              youtubePlayerController: _youtubePlayerController,
              videoPlayerController: _videoPlayerController,
              controlsAnimationController:
                  controlsMenuAnimationController,
            ),
          ),
        ),
      ],
    );
  }

  //To display the video and it's controls
  Widget _buildPlayVideoContainer(Orientation orientation) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: orientation == Orientation.landscape
              ? MediaQuery.of(context).size.height
              : MediaQuery.of(context).size.height *
                  _videoContainerPotraitHeightPercentage,
          child: Stack(
            children: [
              // 1. Base Layer: The Video
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: currentlyPlayingStudyMaterialVideo.studyMaterialType ==
                          StudyMaterialType.youtubeVideo
                      ? YoutubePlayerBuilder(
                          player: YoutubePlayer(
                            actionsPadding: EdgeInsets.zero,
                            controller: _youtubePlayerController!,
                            aspectRatio: 16 / 9,
                          ),
                          builder: (context, player) => player,
                        )
                      : _videoPlayerController!.value.isInitialized
                          ? VideoPlayer(_videoPlayerController!)
                          : Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: CachedNetworkImageProvider(
                                    currentlyPlayingStudyMaterialVideo
                                        .fileThumbnail,
                                  ),
                                ),
                              ),
                              child: CustomCircularProgressIndicator(
                                indicatorColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                              ),
                            ),
                ),
              ),

              // 2. Interaction Layer: Double tap skip + Single tap toggle
              // This is ON TOP of the video but BELOW the dimming background when hidden
              // and ABOVE the dimming background when shown to ensure double tap always works.
              VideoDoubleTapSkipOverlay(
                youtubePlayerController: _youtubePlayerController,
                videoPlayerController: _videoPlayerController,
                onTap: () {
                  if (controlsMenuAnimationController.isCompleted) {
                    controlsMenuAnimationController.reverse();
                  } else {
                    controlsMenuAnimationController.forward();
                  }
                },
                child: AnimatedBuilder(
                  animation: controlsMenuAnimationController,
                  builder: (context, _) {
                    return Container(
                      color: Colors.black.withValues(
                        alpha: controlsMenuAnimation.value * 0.45,
                      ),
                    );
                  },
                ),
              ),

              // 3. UI Layer: Controls (Buttons)
              // Wrapped in Opacity and IgnorePointer when hidden
              AnimatedBuilder(
                animation: controlsMenuAnimationController,
                builder: (context, _) {
                  return Opacity(
                    opacity: controlsMenuAnimation.value,
                    child: IgnorePointer(
                      ignoring: !controlsMenuAnimationController.isCompleted,
                      child: _buildVideoControlButtons(orientation),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoDetailsContainer({
    required StudyMaterial studyMaterial,
    required int videoIndex,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          if (studyMaterial.id == currentlyPlayingStudyMaterialVideo.id) {
            return;
          }

          assignedVideoController = false;

          currentlyPlayingStudyMaterialVideo = studyMaterial;
          setState(() {});

          await Future.delayed(const Duration(milliseconds: 100));
          //disposing controllers
          _youtubePlayerController?.dispose();
          _videoPlayerController?.dispose();
          _youtubePlayerController = null;
          _videoPlayerController = null;

          if (currentlyPlayingStudyMaterialVideo.studyMaterialType ==
              StudyMaterialType.youtubeVideo) {
            loadYoutubeController();
          } else {
            loadVideoController();
          }
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                offset: const Offset(5, 5),
                blurRadius: 10,
              )
            ],
          ),
          child: LayoutBuilder(
            builder: (context, boxConstraints) {
              return Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: CachedNetworkImageProvider(
                              studyMaterial.fileThumbnail,
                            ),
                          ),
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: 65,
                        width: boxConstraints.maxWidth * (0.3),
                      ),
                      currentlyPlayingStudyMaterialVideo.id == studyMaterial.id
                          ? Container(
                              height: 65,
                              width: boxConstraints.maxWidth * (0.3),
                              decoration: BoxDecoration(
                                color: const Color(0xff212121).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Lottie.asset(
                                "assets/animations/music_playing.json",
                                animate: true,
                              ),
                            )
                          : const SizedBox()
                    ],
                  ),
                  SizedBox(
                    width: boxConstraints.maxWidth * (0.05),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studyMaterial.fileName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.0,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedVideos() {
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * (0.075),
          right: MediaQuery.of(context).size.width * (0.075),
          top: MediaQuery.of(context).size.height *
                  _videoContainerPotraitHeightPercentage +
              MediaQuery.of(context).padding.top +
              15,
        ),
        itemCount: widget.relatedVideos.length,
        itemBuilder: (context, index) {
          return _buildVideoDetailsContainer(
            studyMaterial: widget.relatedVideos[index],
            videoIndex: index,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return PopScope(
          canPop: orientation == Orientation.portrait,
          onPopInvokedWithResult: (dynamic, _) {
            if (orientation == Orientation.landscape) {
              SystemChrome.setPreferredOrientations(
                  [DeviceOrientation.portraitUp]);
            }
          },
          child: Scaffold(
            body: Stack(
              children: [
                orientation == Orientation.landscape
                    ? const SizedBox()
                    : _buildRelatedVideos(),

                //Dimming background when video changes
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height *
                      _videoContainerPotraitHeightPercentage,
                  color: Colors.black45,
                  child: Center(
                    child: CustomCircularProgressIndicator(
                      indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),

                //Video container
                assignedVideoController
                    ? _buildPlayVideoContainer(orientation)
                    : const SizedBox()
              ],
            ),
          ),
        );
      },
    );
  }
}
