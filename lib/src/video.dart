import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';import 'package:flutter/services.dart';
import 'package:flutter_screen_wake/flutter_screen_wake.dart';
import 'package:http/http.dart' as http;
import 'package:custom_hls_video/lecle_yoyo_player.dart';
import 'package:custom_hls_video/src/model/models.dart';
import 'package:custom_hls_video/src/utils/utils.dart';
import 'package:custom_hls_video/src/widgets/video_loading.dart';
import 'package:custom_hls_video/src/widgets/video_quality_picker.dart';
import 'package:custom_hls_video/src/widgets/video_quality_widget.dart';
import 'package:custom_hls_video/src/widgets/widget_bottombar.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'responses/regex_response.dart';

class YoYoPlayer extends StatefulWidget {
  /// **Video source**
  /// ```dart
  /// url:"https://example.com/index.m3u8";
  /// ```
  final String url;

  /// Custom style for the video player
  ///```dart
  ///videoStyle : VideoStyle(
  ///     playIcon =  Icon(Icons.play_arrow),
  ///     pauseIcon = Icon(Icons.pause),
  ///     fullscreenIcon =  Icon(Icons.fullScreen),
  ///     forwardIcon =  Icon(Icons.skip_next),
  ///     backwardIcon =  Icon(Icons.skip_previous),
  ///     progressIndicatorColors = VideoProgressColors(
  ///       playedColor: Colors.green,
  ///     ),
  ///     qualityStyle = const TextStyle(
  ///       color: Colors.white,
  ///     ),
  ///      qaShowStyle = const TextStyle(
  ///       color: Colors.white,
  ///     ),
  ///   );
  ///```
  final VideoStyle videoStyle;

  /// The style for the loading widget which use while waiting for the video to load.
  /// ```dart
  /// VideoLoadingStyle(
  ///   loading: Center(
  ///      child: Column(
  ///      mainAxisAlignment: MainAxisAlignment.center,
  ///      crossAxisAlignment: CrossAxisAlignment.center,
  ///      children: const [
  ///         Image(
  ///           image: AssetImage('image/yoyo_logo.png'),
  ///           fit: BoxFit.fitHeight,
  ///           height: 50,
  ///         ),
  ///         SizedBox(height: 16.0),
  ///         Text("Loading video..."),
  ///       ],
  ///     ),
  ///   ),
  //  ),
  /// ```
  final VideoLoadingStyle videoLoadingStyle;

  /// Video aspect ratio. Ex: [aspectRatio: 16 / 9 ]
  final double aspectRatio;
  final int initialSeek;
  final bool isMode;
  final bool isPipEnable;

  /// Callback function for on fullscreen event.
  final void Function(bool fullScreenTurnedOn)? onFullScreen;

  /// Callback function for start playing a video event. The function will return the type of the playing video.
  final void Function(String videoType)? onPlayingVideo;

  /// Callback function for tapping play video button event.
  final void Function(bool isPlaying)? onPlayButtonTap;

  /// Callback function for fast forward button tap event.
  final ValueChanged<VideoPlayerValue>? onFastForward;

  /// Callback function for rewind button tap event.
  final ValueChanged<VideoPlayerValue>? onRewind;

  /// Callback function for live direct button tap event.
  final ValueChanged<VideoPlayerValue>? onLiveDirectTap;

  /// Callback function for showing menu event.
  final void Function(bool showMenu, bool m3u8Show)? onShowMenu;

  /// Callback function for video init completed event.
  /// This function will expose the video controller and you can use it to track the video progress.
  final void Function(VideoPlayerController controller)? onVideoInitCompleted;

  /// The headers for the video url request.
  final Map<String, String>? headers;

  /// If set to [true] the video will be played after the video initialize steps are completed and vice versa.
  /// Default value is [true].
  final bool autoPlayVideoAfterInit;

  /// If set to [true] the video will be played in full screen mode after the video initialize steps is completed and vice versa.
  /// Default value is [false].
  final bool displayFullScreenAfterInit;

  /// Callback function execute when the file cached to the device local storage and it will return a list of
  /// paths of the cached files.
  ///
  /// ***This function will be called only when the [allowCacheFile] property is set to true.***
  final void Function(List<File>? files)? onCacheFileCompleted;

  /// Callback function execute when there is an error occurs while caching the file.
  /// The error will be return within the function.
  final void Function(dynamic error)? onCacheFileFailed;

  /// If set to [true] the video will be cached into the device local storage and the [onCacheFileCompleted]
  /// method will be executed after the file is cached.
  final bool allowCacheFile;

  /// Callback method for closed caption file event.
  /// You have to return a [ClosedCaptionFile] object for this method.
  final Future<ClosedCaptionFile>? closedCaptionFile;

  /// Provide additional configuration options (optional).
  /// Like setting the audio mode to mix.
  final VideoPlayerOptions? videoPlayerOptions;

  ///
  /// ```dart
  /// YoYoPlayer(
  /// // url types = (m3u8[hls],.mp4,.mkv)
  ///   url : "video_url",
  /// // Video's style
  ///   videoStyle : VideoStyle(),
  /// // Video's loading style
  ///   videoLoadingStyle : VideoLoadingStyle(),
  /// // Video's aspect ratio
  ///   aspectRatio : 16/9,
  /// )
  /// ```
  const YoYoPlayer({
    Key? key,
    required this.url,
    this.aspectRatio = 16 / 9,
    this.videoStyle = const VideoStyle(),
    this.videoLoadingStyle = const VideoLoadingStyle(),
    this.onFullScreen,
    this.onPlayingVideo,
    this.onPlayButtonTap,
    this.onShowMenu,
    this.onFastForward,
    this.onRewind,
    this.headers,
    this.autoPlayVideoAfterInit = true,
    this.displayFullScreenAfterInit = false,
    this.allowCacheFile = false,
    this.onCacheFileCompleted,
    this.onCacheFileFailed,
    this.onVideoInitCompleted,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.onLiveDirectTap,
    this.initialSeek=0,
    this.isPipEnable = false,
    this.isMode = true,
  }) : super(key: key);

  @override
  State<YoYoPlayer> createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer>
    with SingleTickerProviderStateMixin {
  /// Video play type (hls,mp4,mkv,offline)
   String? playType;
  double previousVideoSeekSecond = 0.0; // To track the last known seek position
bool isVideoSeeking = false; // To indicate if the video is currently seeking
Timer? hideSeekTimer; 
  /// Animation Controller
  late AnimationController controlBarAnimationController;

  /// Video Top Bar Animation
  Animation<double>? controlTopBarAnimation;

  /// Video Bottom Bar Animation
  Animation<double>? controlBottomBarAnimation;

  /// Video Player Controller
  late VideoPlayerController controller;

  /// Video init error default :false
  bool hasInitError = false;

  /// Video Total Time duration
  String? videoDuration;

  /// Video Seed to
  String? videoSeek;

  /// Video duration 1
  Duration? duration;

  /// Video seek second by user
  double? videoSeekSecond;

  /// Video duration second
  double? videoDurationSecond;

  /// m3u8 data video list for user choice
  List<M3U8Data> yoyo = [];

  /// m3u8 audio list
  List<AudioModel> audioList = [];

  /// m3u8 temp data
  String? m3u8Content;

  /// Subtitle temp data
  String? subtitleContent;

  /// Menu show m3u8 list
  bool m3u8Show = false;

  bool playbackSpeedShow = false;

  bool showVideoMenu = false;

  /// Video full screen
  bool fullScreen = false;

  /// Menu show
  bool showMenu = false;

  /// Auto show subtitle
  bool showSubtitles = false;

  /// Video status
  bool? isOffline;

  /// Video auto quality
  String m3u8Quality = "Auto";

  double currentPlaybackSpeed = 1.0; 

  /// Time for duration
  Timer? showTime;

  /// Video quality overlay
  OverlayEntry? overlayEntry;

  /// Global key to calculate quality options
  GlobalKey videoQualityKey = GlobalKey();

  /// Last playing position of the current video before changing the quality
  Duration? lastPlayedPos;

  /// If set to true the live direct button will display with the live color
  /// and if not it will display with the disable color.
  bool isAtLivePosition = true;

  @override
  void initState() {
    super.initState();

    urlCheck(widget.url);

    /// Control bar animation
    controlBarAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    controlTopBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    controlBottomBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      WidgetsBinding.instance.addPersistentFrameCallback((callback) {
        if (!mounted) return;
        var orientation = MediaQuery.of(context).orientation;
        bool? fullScr;

        if (orientation == Orientation.landscape) {
          // Horizontal screen
          fullScr = true;
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [SystemUiOverlay.bottom],
          );
        
        } else if (orientation == Orientation.portrait) {
          // Portrait screen
          fullScr = false;
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
        }

        if (fullScr != fullScreen) {
          setState(() {
            fullScreen = !fullScreen;
            _navigateLocally(context);
            widget.onFullScreen?.call(fullScreen);
          });
        }

        WidgetsBinding.instance.scheduleFrame();
      });
    });

    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);

    if (widget.videoStyle.enableSystemOrientationsOverride) {
      SystemChrome.setPreferredOrientations(
        widget.videoStyle.orientation ?? DeviceOrientation.values,
      );
    }

    if (widget.displayFullScreenAfterInit) {
      // toggleFullScreen();
      ScreenUtils.toggleFullScreen(fullScreen);
    }

    FlutterScreenWake.keepOn(true);
  }

  @override
  void dispose() {
   if(!widget.isPipEnable){ hideSeekTimer?.cancel();
  //  if(controller.value.isPlaying) controller.pause();
   controller.removeListener(listener);
    m3u8Clean();
    controller.dispose();
    controlBarAnimationController.dispose();}
    super.dispose();
  }


@override
Widget build(BuildContext context) {
  bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  double screenHeight = MediaQuery.of(context).size.height;
double screenWidth = MediaQuery.of(context).size.width;

// Calculate aspect ratio based on screen size
// Standard video aspect ratio of 16:9
double videoAspectRatio = 16 / 9;

// Check if the screen is a tablet (or larger device) and adjust for portrait mode
bool isLargeScreenPortrait = !isLandscape && screenWidth > 500;
  return isLandscape
      ? SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: controller.value.isInitialized
              ? Stack(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        toggleControls();
                        removeOverlay();
                      },
                      onDoubleTap: () {
                        togglePlay();
                        removeOverlay();
                      },
                      child: Stack(
                        children: [
                          Center( // Center the AspectRatio widget
                        child: AspectRatio(
                          aspectRatio: videoAspectRatio,
                          child: VideoPlayer(controller), // VideoPlayer widget
                        ),
                      ),
                  
                          // Video Player takes full screen in landscape
                          // VideoPlayer(controller),

                          // Background color overlay when controls are visible
                          Visibility(
                            visible: showMenu,
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Align(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Rewind Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(10),
                                      child: InkWell(
                                        onTap: () {
                                          controller.rewind().then((value) {
                                            widget.onRewind?.call(controller.value);
                                          });
                                        },
                                        child: widget.videoStyle.backwardIcon ??
                                            Icon(
                                              Icons.fast_rewind_rounded,
                                              color: widget.videoStyle.forwardIconColor,
                                              size: widget.videoStyle.forwardAndBackwardBtSize,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: widget.videoStyle.spaceBetweenBottomBarButtons),

                                    // Play/Pause Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(10),
                                      child: InkWell(
                                        onTap: () => togglePlay(),
                                        child: Icon(
                                          controller.value.isPlaying
                                              ?  Icons.pause
                                                : Icons.play_arrow,
                                          color: widget.videoStyle.playButtonIconColor ?? Colors.white,
                                          size: widget.videoStyle.playButtonIconSize ?? 35,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: widget.videoStyle.spaceBetweenBottomBarButtons),

                                    // Fast Forward Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(10),
                                      child: InkWell(
                                        onTap: () {
                                          controller.fastForward().then((value) {
                                            widget.onFastForward?.call(controller.value);
                                          });
                                        },
                                        child: widget.videoStyle.forwardIcon ??
                                            Icon(
                                              Icons.fast_forward_rounded,
                                              color: widget.videoStyle.forwardIconColor,
                                              size: widget.videoStyle.forwardAndBackwardBtSize,
                                            ),
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
//                                        Visibility(
//   visible: isVideoSeeking && !controller.value.isPlaying, // Only show when the user is seeking
//   child: Positioned(
//     bottom:50,
//     left: screenWidth*0.1,
//      child:  Container(
//     width: 100,
//     height: 40,
//     decoration: BoxDecoration(
//     color: Colors.black.withOpacity(0.85),
//     borderRadius: BorderRadius.circular(15),
//     ),
//     alignment: Alignment.bottomCenter,
//     padding: EdgeInsets.all(8),
//     child: Text(
//       videoSeek??"", // Show the current seek time
//       style: TextStyle(
//         color: Colors.white,
//         fontWeight: FontWeight.bold,
//         fontSize: 18,
//       ),
//     ),
//   ),
//       ),
// ),
                    ...videoBuiltInChildren(),
                  ],
                )
              : VideoLoading(loadingStyle: widget.videoLoadingStyle),
        )
      : Container(
        // For portrait mode, use the full width and calculate the height based on the 16:9 aspect ratio
        width: screenWidth, // Full width
        height: isLargeScreenPortrait ? screenWidth / videoAspectRatio : screenHeight * 0.4,
        child: controller.value.isInitialized
            ? Stack(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        toggleControls();
                        removeOverlay();
                      },
                      onDoubleTap: () {
                        togglePlay();
                        removeOverlay();
                      },
                      child: Stack(
                        children: [
                          // Video Player takes full screen in landscape
                          VideoPlayer(controller),

                          // Background color overlay when controls are visible
                          Visibility(
                            visible: showMenu,
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Align(
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Rewind Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(10),
                                      child: InkWell(
                                        onTap: () {
                                          controller.rewind().then((value) {
                                            widget.onRewind?.call(controller.value);
                                          });
                                        },
                                        child: widget.videoStyle.backwardIcon ??
                                            Icon(
                                              Icons.fast_rewind_rounded,
                                              color: widget.videoStyle.forwardIconColor,
                                              size: widget.videoStyle.forwardAndBackwardBtSize,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: widget.videoStyle.spaceBetweenBottomBarButtons),

                                    // Play/Pause Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(10),
                                      child: InkWell(
                                        onTap: () => togglePlay(),
                                        child: Icon(
                                          controller.value.isPlaying
                                              ?  Icons.pause
                                                : Icons.play_arrow,
                                          color: widget.videoStyle.playButtonIconColor ?? Colors.white,
                                          size: widget.videoStyle.playButtonIconSize ?? 35,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: widget.videoStyle.spaceBetweenBottomBarButtons),

                                    // Fast Forward Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(10),
                                      child: InkWell(
                                        onTap: () {
                                          controller.fastForward().then((value) {
                                            widget.onFastForward?.call(controller.value);
                                          });
                                        },
                                        child: widget.videoStyle.forwardIcon ??
                                            Icon(
                                              Icons.fast_forward_rounded,
                                              color: widget.videoStyle.forwardIconColor,
                                              size: widget.videoStyle.forwardAndBackwardBtSize,
                                            ),
                                      ),
                                    ),
                                    
                                  ],
                                ),
                              ),
                            ),
                          ),
//                               Visibility(
//   visible: isVideoSeeking && !controller.value.isPlaying, // Only show when the user is seeking
//   child: Positioned(
//     bottom:50,
//     left: 150,
//      child:  Container(
//     width: 100,
//     height: 40,
//     decoration: BoxDecoration(
//     color: Colors.black.withOpacity(0.85),
//     borderRadius: BorderRadius.circular(15),
//     ),
//     alignment: Alignment.bottomCenter,
//     padding: EdgeInsets.all(8),
//     child: Text(
//       videoSeek??"", // Show the current seek time
//       style: TextStyle(
//         color: Colors.white,
//         fontWeight: FontWeight.bold,
//         fontSize: 18,
//       ),
//     ),
//   ),
//       ),
// ),
                        ],
                      ),
                    ),
                    ...videoBuiltInChildren(),
                  ],
                )
            : VideoLoading(loadingStyle: widget.videoLoadingStyle),
      );
}


//   Widget build(BuildContext context) {
//     return AspectRatio(
//       aspectRatio: fullScreen
//           ? MediaQuery.of(context).size.aspectRatio
//           : widget.aspectRatio,
//       child: controller.value.isInitialized
//           ? Stack(
//               children: <Widget>[
//                 GestureDetector(
//                   onTap: () {
//                     toggleControls();
//                     removeOverlay();
//                   },
//                   onDoubleTap: () {
//                     togglePlay();
//                     removeOverlay();
//                   },
//                     child: AspectRatio(
//   aspectRatio: controller.value.aspectRatio,
//   child: Stack(
//     children: [
//       // Video Player
//       VideoPlayer(controller),
      
//       // Background color overlay when controls are visible
//       Visibility(
//         visible: showMenu,
//         child: Container(
//           color: Colors.black.withOpacity(0.5),
//           child: Align(
//             alignment: Alignment.center,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               mainAxisSize: MainAxisSize.max,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // Rewind Button with rounded container
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                     shape: BoxShape.circle,
//                   ),
//                   padding: EdgeInsets.all(10),
//                   child: InkWell(
//                     onTap: () {
//                       controller.rewind().then((value) {
//                         widget.onRewind?.call(controller.value);
//                       });
//                     },
//                     child: widget.videoStyle.backwardIcon ??
//                         Icon(
//                           Icons.fast_rewind_rounded,
//                           color: widget.videoStyle.forwardIconColor,
//                           size: widget.videoStyle.forwardAndBackwardBtSize,
//                         ),
//                   ),
//                 ),
//                 SizedBox(width: widget.videoStyle.spaceBetweenBottomBarButtons),

//                 // Play/Pause Button with rounded container
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                     shape: BoxShape.circle,
//                   ),
//                   padding: EdgeInsets.all(10),
//                   child: InkWell(
//                     onTap: () => togglePlay(),
//                     child: () {
//                       var defaultIcon = Icon(
//                         controller.value.isPlaying
//                             ? Icons.pause_circle_outline
//                             : Icons.play_circle_outline,
//                         color: widget.videoStyle.playButtonIconColor ??
//                             Colors.white,
//                         size: widget.videoStyle.playButtonIconSize ?? 35,
//                       );

//                       if (widget.videoStyle.playIcon != null &&
//                           widget.videoStyle.pauseIcon == null) {
//                         return controller.value.isPlaying
//                             ? defaultIcon
//                             : widget.videoStyle.playIcon;
//                       } else if (widget.videoStyle.pauseIcon != null &&
//                           widget.videoStyle.playIcon == null) {
//                         return controller.value.isPlaying
//                             ? widget.videoStyle.pauseIcon
//                             : defaultIcon;
//                       } else if (widget.videoStyle.playIcon != null &&
//                           widget.videoStyle.pauseIcon != null) {
//                         return controller.value.isPlaying
//                             ? widget.videoStyle.pauseIcon
//                             : widget.videoStyle.playIcon;
//                       }

//                       return defaultIcon;
//                     }(),
//                   ),
//                 ),
//                 SizedBox(width: widget.videoStyle.spaceBetweenBottomBarButtons),

//                 // Fast Forward Button with rounded container
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.5),
//                     shape: BoxShape.circle,
//                   ),
//                   padding: EdgeInsets.all(10),
//                   child: InkWell(
//                     onTap: () {
//                       controller.fastForward().then((value) {
//                         widget.onFastForward?.call(controller.value);
//                       });
//                     },
//                     child: widget.videoStyle.forwardIcon ??
//                         Icon(
//                           Icons.fast_forward_rounded,
//                           color: widget.videoStyle.forwardIconColor,
//                           size: widget.videoStyle.forwardAndBackwardBtSize,
//                         ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
      
//       Visibility(
//   visible: isVideoSeeking && !controller.value.isPlaying, // Only show when the user is seeking
//   child: Positioned(
//     top:10,
//     left: 150,
//      child:  Container(
//     width: 100,
//     height: 40,
//     decoration: BoxDecoration(
//     color: Colors.black.withOpacity(0.85),
//     borderRadius: BorderRadius.circular(15),
//     ),
//     alignment: Alignment.bottomCenter,
//     padding: EdgeInsets.all(8),
//     child: Text(
//       videoSeek??"", // Show the current seek time
//       style: TextStyle(
//         color: Colors.white,
//         fontWeight: FontWeight.bold,
//         fontSize: 18,
//       ),
//     ),
//   ),
//       ),
// ),

//     ],
//   ),
// ),

//                 ),
//                 ...videoBuiltInChildren(),
//               ],
//             )
//           : VideoLoading(loadingStyle: widget.videoLoadingStyle),
//     );
//   }

  List<Widget> videoBuiltInChildren() {
    return [
      actionBar(),
      liveDirectButton(),
      bottomBar(),
      // m3u8List(),
    ];
  }

  /// Video player ActionBar
  Widget actionBar() {
    return Visibility(
      visible: showMenu,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: widget.videoStyle.actionBarPadding ??
              const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
          // color: widget.videoStyle.actionBarBgColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // VideoQualityWidget(
              //   key: videoQualityKey,
              //   videoStyle: widget.videoStyle,
              //   onTap: () {
              //     // Quality function
              //     setState(() {
              //       m3u8Show = !m3u8Show;

              //       if (m3u8Show) {
              //         showOverlay();
              //       } else {
              //         removeOverlay();
              //       }
              //     });
              //   },
              //   child: Text(m3u8Quality, style: widget.videoStyle.qualityStyle),
              // ),

    //          IconButton(
    //   icon: Icon(
    //       Icons.speed, // Customize the icon, change to any relevant icon
    //       size: 24.0, // Customize icon size
    //       color: Colors.white, // Icon color
    //     ),
    //   onPressed: (){
    //      setState(() {
    //                 playbackSpeedShow = !playbackSpeedShow;

    //                 if (playbackSpeedShow) {
    //                   showPlaybackSpeedOverlay();
    //                 } else {
    //                   removeOverlay();
    //                 }
    //               });

    //   }, // Calls the provided onTap function when pressed
    // ),

     IconButton(
      icon: Icon(
          Icons.settings, // Customize the icon, change to any relevant icon
          size: 24.0, // Customize icon size
          color: Colors.white, // Icon color
        ),
      onPressed: (){
         setState(() {
                    showVideoMenu = !showVideoMenu;
                    m3u8Show = true;
                    if (showVideoMenu) {
                      showVideoMenuOverlay();
                    } else {
                      removeOverlay();
                    }
                  });

      }, 
    ),

              SizedBox(
                width: widget.videoStyle.qualityButtonAndFullScrIcoSpace,
              ),
              // InkWell(
              //   onTap: () => ScreenUtils.toggleFullScreen(fullScreen),
              //   child: widget.videoStyle.fullscreenIcon ??
              //       Icon(
              //         Icons.fullscreen,
              //         color: widget.videoStyle.fullScreenIconColor,
              //         size: widget.videoStyle.fullScreenIconSize,
              //       ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  /// Video player BottomBar
  Widget bottomBar() {
    return Visibility(
      visible: showMenu,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: PlayerBottomBar(
          fullScreen: fullScreen,
          controller: controller,
          videoSeek: videoSeek ?? '00:00:00',
          videoDuration: videoDuration ?? '00:00:00',
          videoStyle: widget.videoStyle,
          showBottomBar: showMenu,
          onPlayButtonTap: () => togglePlay(),
          onFastForward: (value) {
            widget.onFastForward?.call(value);
          },
          onRewind: (value) {
            widget.onRewind?.call(value);
          },
        ),
      ),
    );
  }

  /// Video player live direct button
  Widget liveDirectButton() {
    return Visibility(
      visible: widget.videoStyle.showLiveDirectButton && showMenu,
      child: Align(
        alignment: Alignment.topLeft,
        child: IntrinsicWidth(
          child: InkWell(
            onTap: () {
              controller.seekTo(controller.value.duration).then((value) {
                widget.onLiveDirectTap?.call(controller.value);
                controller.play();
              });
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 14.0,
              ),
              margin: const EdgeInsets.only(left: 9.0),
              child: Row(
                children: [
                  Container(
                    width: widget.videoStyle.liveDirectButtonSize,
                    height: widget.videoStyle.liveDirectButtonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAtLivePosition
                          ? widget.videoStyle.liveDirectButtonColor
                          : widget.videoStyle.liveDirectButtonDisableColor,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    widget.videoStyle.liveDirectButtonText ?? 'Live',
                    style: widget.videoStyle.liveDirectButtonTextStyle ??
                        const TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget m3u8List() {
  return VideoQualityPicker(
    videoData: yoyo, // Your video data source
    videoStyle: widget.videoStyle, // Custom video styling if applicable
    showPicker: m3u8Show, // Controls whether to show the picker
    onQualitySelected: (data) {
      // If a new quality is selected, update the state
      if (data.dataQuality != m3u8Quality) {
        setState(() {
          m3u8Quality = data.dataQuality == "Auto"
              ? "${data.dataQuality}"
              : "${data.dataQuality?.split('x').last.trim() ?? m3u8Quality}p";
        });
        // Handle quality selection event
        onSelectQuality(data);
        print("--- Quality selected ---\nquality : ${data.dataQuality}\nlink : ${data.dataURL}");
      }

      // Hide the picker after selection
      setState(() {
        m3u8Show = false;
      });
      // Remove the overlay after selection
      removeOverlay();
    },
  );
}


  /// Video quality list
//   Widget m3u8List() {
//   RenderBox? renderBox =
//       videoQualityKey.currentContext?.findRenderObject() as RenderBox?;
//   var offset = renderBox?.localToGlobal(Offset.zero);

//   return VideoQualityPicker(
//     videoData: yoyo,
//     videoStyle: widget.videoStyle,
//     showPicker: m3u8Show,
//     positionRight: (renderBox?.size.width ?? 0.0) / 3,
//     positionTop: (offset?.dy ?? 0.0) + 35.0,
//     onQualitySelected: (data) {
//       if (data.dataQuality != m3u8Quality) {
//         setState(() {
//           // Extracting the string part after "x"
//        m3u8Quality = data.dataQuality =="Auto" ? "${data.dataQuality}" :"${data.dataQuality?.split('x').last.trim() ?? m3u8Quality}p";
//         });
//         onSelectQuality(data);
//         print("--- Quality select ---\nquality : ${data.dataQuality}\nlink : ${data.dataURL}");
//       }
//       setState(() {
//         m3u8Show = false;
//       });
//       removeOverlay();
//     },
//   );
// }


  void urlCheck(String url) {
    final netRegex = RegExp(RegexResponse.regexHTTP);
    final isNetwork = netRegex.hasMatch(url);
    final uri = Uri.parse(url);

    print("Parsed url data end : ${uri.pathSegments.last}");
    if (isNetwork) {
      setState(() {
        isOffline = false;
      });
      if (uri.pathSegments.last.endsWith("mkv")) {
        setState(() {
          playType = "MKV";
        });
        print("urlEnd : mkv");
        widget.onPlayingVideo?.call("MKV");

        videoControlSetup(url);

        if (widget.allowCacheFile) {
          FileUtils.cacheFileToLocalStorage(
            url,
            fileExtension: 'mkv',
            headers: widget.headers,
            onSaveCompleted: (file) {
              widget.onCacheFileCompleted?.call(file != null ? [file] : null);
            },
            onSaveFailed: widget.onCacheFileFailed,
          );
        }
      } else if (uri.pathSegments.last.endsWith("mp4")) {
        setState(() {
          playType = "MP4";
        });
        print("urlEnd: $playType");
        widget.onPlayingVideo?.call("MP4");

        videoControlSetup(url);

        if (widget.allowCacheFile) {
          FileUtils.cacheFileToLocalStorage(
            url,
            fileExtension: 'mp4',
            headers: widget.headers,
            onSaveCompleted: (file) {
              widget.onCacheFileCompleted?.call(file != null ? [file] : null);
            },
            onSaveFailed: widget.onCacheFileFailed,
          );
        }
      } else if (uri.pathSegments.last.endsWith('webm')) {
        setState(() {
          playType = "WEBM";
        });
        print("urlEnd: $playType");
        widget.onPlayingVideo?.call("WEBM");

        videoControlSetup(url);

        if (widget.allowCacheFile) {
          FileUtils.cacheFileToLocalStorage(
            url,
            fileExtension: 'webm',
            headers: widget.headers,
            onSaveCompleted: (file) {
              widget.onCacheFileCompleted?.call(file != null ? [file] : null);
            },
            onSaveFailed: widget.onCacheFileFailed,
          );
        }
      } else if (uri.pathSegments.last.endsWith("m3u8")) {
        setState(() {
          playType = "HLS";
        });
        widget.onPlayingVideo?.call("M3U8");

        print("urlEnd: M3U8");
        videoControlSetup(url);
        getM3U8(url);
      } else {
        print("urlEnd: null");
        videoControlSetup(url);
        getM3U8(url);
      }
      print("--- Current Video Status ---\noffline : $isOffline");
    } else {
      setState(() {
        isOffline = true;
        print(
            "--- Current Video Status ---\noffline : $isOffline \n --- :3 Done url check ---");
      });

      videoControlSetup(url);
    }
  }

  /// M3U8 Data Setup
  void getM3U8(String videoUrl) {
    if (yoyo.isNotEmpty) {
      print("${yoyo.length} : data start clean");
      m3u8Clean();
    }
    print("---- m3u8 fitch start ----\n$videoUrl\n--- please wait –––");
    m3u8Video(videoUrl);
  }

  Future<M3U8s?> m3u8Video(String? videoUrl) async {
    yoyo.add(M3U8Data(dataQuality: "Auto", dataURL: videoUrl));

    // RegExp regExpAudio = RegExp(
    //   RegexResponse.regexMEDIA,
    //   caseSensitive: false,
    //   multiLine: true,
    // );
    RegExp regExp = RegExp(
      RegexResponse.regexM3U8Resolution,
      caseSensitive: false,
      multiLine: true,
    );

    if (m3u8Content != null) {
      setState(() {
        print("--- HLS Old Data ----\n$m3u8Content");
        m3u8Content = null;
      });
    }

    if (m3u8Content == null && videoUrl != null) {
      http.Response response =
          await http.get(Uri.parse(videoUrl), headers: widget.headers);
      if (response.statusCode == 200) {
        m3u8Content = utf8.decode(response.bodyBytes);

        List<File> cachedFiles = [];
        int index = 0;

        List<RegExpMatch> matches =
            regExp.allMatches(m3u8Content ?? '').toList();
        // List<RegExpMatch> audioMatches =
        //     regExpAudio.allMatches(m3u8Content ?? '').toList();
        print(
            "--- HLS Data ----\n$m3u8Content \nTotal length: ${yoyo.length} \nFinish!!!");

        for(RegExpMatch regExpMatch in matches)
        {
            String quality = (regExpMatch.group(1)).toString();
            String sourceURL = (regExpMatch.group(3)).toString();
            final netRegex = RegExp(RegexResponse.regexHTTP);
            final netRegex2 = RegExp(RegexResponse.regexURL);
            final isNetwork = netRegex.hasMatch(sourceURL);
            final match = netRegex2.firstMatch(videoUrl);
            String url;
            if (isNetwork) {
              url = sourceURL;
            } else {
              print(
                  'Match: ${match?.pattern} --- ${match?.groupNames} --- ${match?.input}');
              final dataURL = match?.group(0);
              url = "$dataURL$sourceURL";
              print("--- HLS child url integration ---\nChild url :$url");
            }
            for(RegExpMatch regExpMatch2 in matches)  {
                String audioURL = (regExpMatch2.group(1)).toString();
                final isNetwork = netRegex.hasMatch(audioURL);
                final match = netRegex2.firstMatch(videoUrl);
                String auURL = audioURL;

                if (!isNetwork) {
                  print(
                      'Match: ${match?.pattern} --- ${match?.groupNames} --- ${match?.input}');
                  final auDataURL = match!.group(0);
                  auURL = "$auDataURL$audioURL";
                  print("Url network audio  $url $audioURL");
                }

                audioList.add(AudioModel(url: auURL));
                print(audioURL);
              }

            String audio = "";
            print("-- Audio ---\nAudio list length: ${audio.length}");
            if (audioList.isNotEmpty) {
              audio =
                  """#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-medium",NAME="audio",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",
                  URI="${audioList.last.url}"\n""";
            } else {
              audio = "";
            }

            if (widget.allowCacheFile) {
              try {
                var file = await FileUtils.cacheFileUsingWriteAsString(
                  contents:
                      """#EXTM3U\n#EXT-X-INDEPENDENT-SEGMENTS\n$audio#EXT-X-STREAM-INF:CLOSED-CAPTIONS=NONE,BANDWIDTH=1469712,
                  RESOLUTION=$quality,FRAME-RATE=30.000\n$url""",
                  quality: quality,
                  videoUrl: url,
                );

                cachedFiles.add(file);

                if (index < matches.length) {
                  index++;
                }

                if (widget.allowCacheFile && index == matches.length) {
                  widget.onCacheFileCompleted
                      ?.call(cachedFiles.isEmpty ? null : cachedFiles);
                }
              } catch (e) {
                print("Couldn't write file: $e");
                widget.onCacheFileFailed?.call(e);
              }
            }

            yoyo.add(M3U8Data(dataQuality: quality, dataURL: url));
          }
        M3U8s m3u8s = M3U8s(m3u8s: yoyo);

        print(
            "--- m3u8 File write --- ${yoyo.map((e) => e.dataQuality == e.dataURL).toList()} --- length : ${yoyo.length} --- Success");
        return m3u8s;
      }
    }

    return null;
  }

// Init video controller
  void videoControlSetup(String? url) async {
    videoInit(url);
        controller.seekTo(Duration(seconds: widget.initialSeek));
    controller.addListener(listener);

    if (widget.autoPlayVideoAfterInit) {
      controller.play();
    }
    widget.onVideoInitCompleted?.call(controller);
  }

// Video listener
  void listener() async {
    if (widget.videoStyle.showLiveDirectButton) {
      if (controller.value.position != controller.value.duration) {
        if (isAtLivePosition) {
          setState(() {
            isAtLivePosition = false;
          });
        }
      } else {
        if (!isAtLivePosition) {
          setState(() {
            isAtLivePosition = true;
          });
        }
      }
    }

    if (controller.value.isInitialized) {
      if (!await WakelockPlus.enabled) {
        await WakelockPlus.enable();
      }

      if(mounted){ 
        setState(() {
        videoDuration = controller.value.duration.convertDurationToString();
        videoSeek = controller.value.position.convertDurationToString();
        videoSeekSecond = controller.value.position.inSeconds.toDouble();
        videoDurationSecond = controller.value.duration.inSeconds.toDouble();
      
      // Hide the seek duration text after 2 seconds of inactivity
    });}

    // Check if the seek position is changing
    if (videoSeekSecond != previousVideoSeekSecond) {
      if(mounted){
      setState(() {
        isVideoSeeking = true; // Video is currently seeking
      });}

      // Reset the timer to hide the seek text after inactivity
      hideSeekTimer?.cancel();
      hideSeekTimer = Timer(Duration(seconds: 1), () {
       if(mounted) {setState(() {
          isVideoSeeking = false; // Reset seeking status
        });}
      });
    } else {
      // If not changing, reset the seeking status
      if(mounted){ 
        setState(() {
        isVideoSeeking = false;
      });}
    }

    // Store the current seek position for future comparison
    previousVideoSeekSecond = videoSeekSecond ?? 0.0;
    } else {
      if (await WakelockPlus.enabled) {
        await WakelockPlus.disable();
        // setState(() {});
      }
    }
  }

  void createHideControlBarTimer() {
    clearHideControlBarTimer();
    showTime = Timer(const Duration(milliseconds: 5000), () {
      // if (controller != null && controller.value.isPlaying) {
      if (controller.value.isPlaying) {
        if (showMenu) {
          setState(() {
            showMenu = false;
            m3u8Show = false;
            controlBarAnimationController.reverse();

            widget.onShowMenu?.call(showMenu, m3u8Show);
            removeOverlay();
          });
        }
      }
    });
  }

  void clearHideControlBarTimer() {
    showTime?.cancel();
  }

  void toggleControls() {
    clearHideControlBarTimer();

    if (!showMenu) {
      setState(() {
        showMenu = true;
      });
      widget.onShowMenu?.call(showMenu, m3u8Show);

      createHideControlBarTimer();
    } else {
      setState(() {
        m3u8Show = false;
        showMenu = false;
      });

      widget.onShowMenu?.call(showMenu, m3u8Show);
    }
    // setState(() {
    if (showMenu) {
      controlBarAnimationController.forward();
    } else {
      controlBarAnimationController.reverse();
    }
    // });
  }

  void togglePlay() {
    createHideControlBarTimer();
    if (controller.value.isPlaying) {
      controller.pause().then((_) {
        widget.onPlayButtonTap?.call(controller.value.isPlaying);
      });
    } else {
      controller.play().then((_) {
        widget.onPlayButtonTap?.call(controller.value.isPlaying);
      });
    }
    setState(() {});
  }

  void videoInit(String? url) {
    if (isOffline == false) {
      print(
          "--- Player status ---\nplay url : $url\noffline : $isOffline\n--- start playing –––");

      if (playType == "MP4" || playType == "WEBM") {
        // Play MP4 and WEBM video
        controller = VideoPlayerController.networkUrl(
          Uri.parse(url!),
          formatHint: VideoFormat.other,
          httpHeaders: widget.headers ?? const <String, String>{},
          closedCaptionFile: widget.closedCaptionFile,
          videoPlayerOptions: widget.videoPlayerOptions,
        )..initialize().then((value) => seekToLastPlayingPosition);
      } else if (playType == "MKV") {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(url!),
          formatHint: VideoFormat.dash,
          httpHeaders: widget.headers ?? const <String, String>{},
          closedCaptionFile: widget.closedCaptionFile,
          videoPlayerOptions: widget.videoPlayerOptions,
        )..initialize().then((value) => seekToLastPlayingPosition);
      } else if (playType == "HLS") {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(url!),
          formatHint: VideoFormat.hls,
          httpHeaders: widget.headers ?? const <String, String>{},
          closedCaptionFile: widget.closedCaptionFile,
          videoPlayerOptions: widget.videoPlayerOptions,
        )..initialize().then((_) {
            setState(() => hasInitError = false);
                    controller.seekTo(Duration(seconds: widget.initialSeek));
          }).catchError((e) {
            setState(() => hasInitError = true);
          });
      }
    } else {
      print(
          "--- Player status ---\nplay url : $url\noffline : $isOffline\n--- start playing –––");
      controller = VideoPlayerController.file(
        File(url!),
        closedCaptionFile: widget.closedCaptionFile,
        videoPlayerOptions: widget.videoPlayerOptions,
      )..initialize().then((value) {
          setState(() => hasInitError = false);
          seekToLastPlayingPosition();
        }).catchError((e) {
          setState(() => hasInitError = true);
        });
    }
  }

  void _navigateLocally(context) async {
    if (!fullScreen) {
      if (ModalRoute.of(context)?.willHandlePopInternally ?? false) {
        Navigator.of(context).pop();
      }
      return;
    }

    ModalRoute.of(context)?.addLocalHistoryEntry(
      LocalHistoryEntry(
        onRemove: () {
          if (fullScreen) ScreenUtils.toggleFullScreen(fullScreen);
        },
      ),
    );
  }

void onSelectSpeed(String speed) async {
  // Convert the speed string to a double
  double playbackSpeed = double.tryParse(speed) ?? 1.0; // Default to 1.0 if parsing fails

  // Ensure the widget is still mounted before making changes
  if (!mounted) return;

  // Set the playback speed in the video controller
  controller.setPlaybackSpeed(playbackSpeed);

  // If the video is playing, we want to ensure that playback speed takes effect
  if (controller.value.isPlaying) {
    // Pause the video briefly to apply the new playback speed
    await controller.pause(); // Pause the video

    // Ensure the widget is still mounted after pause
    if (!mounted) return;

    await Future.delayed(Duration(milliseconds: 100)); // Short delay to ensure pause is applied

    // Ensure the widget is still mounted before playing again
    if (!mounted) return;

    await controller.play(); // Resume playback with new speed
  }

  print('Playback speed set to $speed ($playbackSpeed)');
}


// void onSelectSpeed(String speed) async {
//   // Convert the speed string to a double
//   double playbackSpeed = double.tryParse(speed) ?? 1.0; // Default to 1.0 if parsing fails

//   // Set the playback speed in the video controller
//   controller.setPlaybackSpeed(playbackSpeed);

//   // If the video is playing, we want to ensure that playback speed takes effect
//   if (controller.value.isPlaying) {
//     // Pause the video briefly to apply the new playback speed
//     await controller.pause(); // Pause the video
//     await Future.delayed(Duration(milliseconds: 100)); // Short delay to ensure pause is applied
//     await controller.play(); // Resume playback with new speed
//   }

//   print('Playback speed set to $speed ($playbackSpeed)');
// }
  void onSelectQuality(M3U8Data data) async {
    lastPlayedPos = await controller.position;

    if (controller.value.isPlaying) {
      await controller.pause();
    } 

    if (data.dataQuality == "Auto") {
      videoControlSetup(data.dataURL);
    } else {
      try {

        setState(() {
          currentPlaybackSpeed = 1.0;
        });
        String text;
        var file = await FileUtils.readFileFromPath(
            videoUrl: data.dataURL ?? '', quality: data.dataQuality ?? '');
        if (file != null) {
          print("Start reading file");
          text = await file.readAsString();
          print("Video file data: $text");

          if (data.dataURL != null) {
            playLocalM3U8File(data.dataURL!);
          } else {
            print('Play ${data.dataQuality} m3u8 video file failed');
          }
          // videoControlSetup(file);
        }
      } catch (e) {
        print("Couldn't read file ${data.dataQuality}: $e");
      }
    }
  }

  void playLocalM3U8File(String url) {
    controller.dispose();
    controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      closedCaptionFile: widget.closedCaptionFile,
      videoPlayerOptions: widget.videoPlayerOptions,
    )..initialize().then((_) {
        setState(() => hasInitError = false);
        seekToLastPlayingPosition();
        controller.play();
      }).catchError((e) {
        setState(() => hasInitError = true);
        print('Init local file error $e');
      });

    controller.addListener(listener);
    controller.play();
  }

  void m3u8Clean() async {
    print('Video list length: ${yoyo.length}');
    for (int i = 2; i < yoyo.length; i++) {
      try {
        var file = await FileUtils.readFileFromPath(
            videoUrl: yoyo[i].dataURL ?? '',
            quality: yoyo[i].dataQuality ?? '');
        var exists = await file?.exists();
        if (exists ?? false) {
          await file?.delete();
          print("Delete success $file");
        }
      } catch (e) {
        print("Couldn't delete file $e");
      }
    }
    try {
      print("Cleaning audio m3u8 list");
      audioList.clear();
      print("Cleaning audio m3u8 list completed");
    } catch (e) {
      print("Audio list clean error $e");
    }
    audioList.clear();
    try {
      print("Cleaning m3u8 data list");
      yoyo.clear();
      print("Cleaning m3u8 data list completed");
    } catch (e) {
      print("m3u8 video list clean error $e");
    }
  }

  void showOverlay(Color? clr) {
  showModalBottomSheet(
    backgroundColor: Colors.transparent, // Make the background transparent for rounded corners effect
    context: context,
    isScrollControlled: true, // Allows the bottom sheet to adjust based on the content height
    builder: (BuildContext context) {
      return Container(
        height: 300,
        width: MediaQuery.of(context).size.width, // Adjust the height based on your content
        padding: const EdgeInsets.only(top: 8.0), // Optional: Add padding if needed
        decoration:  BoxDecoration(
          color:  clr, // Background color of the bottom sheet
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0), // Rounded corners for the top left
            topRight: Radius.circular(25.0), // Rounded corners for the top right
          ),
        ),
        child: m3u8List(), // Display the m3u8List widget here
      );
    },
  );
}

void showVideoMenuOverlay() {
  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Container(
        height: 150, // Adjust the height as needed
        decoration:  BoxDecoration(
          color: widget.isMode ? const Color.fromARGB(255, 34, 34, 34): Colors.grey[400], // Background color of the bottom sheet
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15.0), // Add padding here
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Playback Speed Option
              Center(child: Container(height: 5,width: 60,decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),color: Colors.white,),),),
              SizedBox(height: 20,),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close the current bottom sheet
                  showPlaybackSpeedOverlay(widget.isMode ? const Color.fromARGB(255, 34, 34, 34): Colors.grey[400]);
                  setState(() {
                    showVideoMenu = false;
                  }); // Open the playback speed picker overlay
                },
                child: Container(
                   color: Colors.transparent, 
    padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.speed, size: 20), // Prefix icon for Playback Speed
                        SizedBox(width: 8), // Spacing between icon and text
                        Text('Playback Speed', style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('$currentPlaybackSpeed', style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)), // Current playback speed
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_right),
                      ],
                    ),
                  ],
                ),)
              ),
              const SizedBox(height: 8), // Add space between rows
              // Quality Option
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close the current bottom sheet
                  showOverlay(widget.isMode ? const Color.fromARGB(255, 34, 34, 34): Colors.grey[400]);
                  setState(() {
                    showVideoMenu = false;
                  }); // Open the quality selection overlay
                },
                child: Container(
                  color: Colors.transparent,
                  child:Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.high_quality, size: 20), // Prefix icon for Quality
                        SizedBox(width: 8), // Spacing between icon and text
                        Text('Quality', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    Row(
                      children: [
                        Text(m3u8Quality, style: TextStyle(fontSize: 16)), // Current quality
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_right),
                      ],
                    ),
                  ],
                ),)
              ),
            ],
          ),
        ),
      );
    },
  );
  setState(() {
    showVideoMenu = false;
  });
}



// void showVideoMenuOverlay() {
//   showModalBottomSheet(
//     backgroundColor: Colors.transparent,
//     context: context,
//     isScrollControlled: true,
//     builder: (BuildContext context) {
//       return Container(
//         height: 300, // Adjust the height as needed
//         padding: const EdgeInsets.only(top: 8.0),
//         decoration: const BoxDecoration(
//           color: Colors.grey, // Background color of the bottom sheet
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(25.0),
//             topRight: Radius.circular(25.0),
//           ),
//         ),
//         child:Column(
//   crossAxisAlignment: CrossAxisAlignment.start,
//   children: [
//     // Playback Speed Option
//     GestureDetector(
//       onTap: () {
//         Navigator.pop(context); // Close the current bottom sheet
//         showPlaybackSpeedOverlay();
//         setState(() {
//           showVideoMenu = false;
//         }); // Open the playback speed picker overlay
//       },
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//            Text('Playback Speed', style: TextStyle(fontSize: 16,)),
//           Row(
//             children: [
//               Text('$currentPlaybackSpeed', style: TextStyle(fontSize: 16,)), // Current playback speed
//               const SizedBox(width: 8),
//               const Icon(Icons.arrow_right),
//             ],
//           ),
//         ],
//       ),
//     ),
//     const SizedBox(height: 16), // Add space between rows
//     // Quality Option
//     GestureDetector(
//       onTap: () {
//         Navigator.pop(context); // Close the current bottom sheet
//         showOverlay(); 
//          setState(() {
//           showVideoMenu = false;
//         });// Open the quality selection overlay
//       },
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text('Quality', style: TextStyle(fontSize: 16)),
//           Row(
//             children: [
//               Text(m3u8Quality, style: TextStyle(fontSize: 16)), // Current quality
//               const SizedBox(width: 8),
//               const Icon(Icons.arrow_right),
//             ],
//           ),
//         ],
//       ),
//     ),
//   ],
// )
//       );
//     },
//   );
//     setState(() {
//           showVideoMenu = false;
//         });
// }

void showPlaybackSpeedOverlay(Color? clr) {
  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Container(
        height: 300, // Adjust the height as needed
        padding: const EdgeInsets.only(top: 8.0),
        decoration:  BoxDecoration(
          color:  clr, // Background color of the bottom sheet
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        child: playbackSpeedList(),
      );
    },
  );
}

Widget playbackSpeedList() {
  List<double> playbackSpeeds = [0.5, 1.0, 1.5, 2.0]; // Define your playback speeds here
  return PlaybackSpeedPicker(
    speeds: playbackSpeeds,
    videoStyle: widget.videoStyle,
    showPicker: true, // You can control the visibility here
    selectedSpeed: currentPlaybackSpeed, // Your current playback speed variable
    onSpeedSelected: (speed) {
      setState(() {
        currentPlaybackSpeed = speed; 
        playbackSpeedShow = false;// Update the playback speed
      });
     onSelectSpeed(speed.toString());
      print("--- Speed selected ---\nspeed: $speed");
      
    },
    
  );
}




  // void showOverlay() {
  //   setState(() {
  //     overlayEntry = OverlayEntry(
  //       builder: (_) => m3u8List(),
  //     );
  //     Overlay.of(context).insert(overlayEntry!);
  //   });
  // }

  void removeOverlay() {
  // setState(() {
    // Navigator.of(context).pop(); // Dismiss the bottom sheet
  // });
}


  // void removeOverlay() {
  //   setState(() {
  //     overlayEntry?.remove();
  //     overlayEntry = null;
  //   });
  // }

  void seekToLastPlayingPosition() {
    if (lastPlayedPos != null) {
      controller.seekTo(lastPlayedPos!);
      widget.onVideoInitCompleted?.call(controller);
      lastPlayedPos = null;
    }
  }
}

