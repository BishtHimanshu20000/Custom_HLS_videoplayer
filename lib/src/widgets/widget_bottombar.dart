import 'package:flutter/material.dart';
import 'package:custom_hls_video/lecle_yoyo_player.dart';
import 'package:custom_hls_video/src/utils/utils.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:custom_hls_video/lecle_yoyo_player.dart';
import 'package:custom_hls_video/src/utils/utils.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class PlayerBottomBar extends StatelessWidget {
  const PlayerBottomBar({
    Key? key,
    required this.controller,
    required this.showBottomBar,
    required this.fullScreen,
    this.onPlayButtonTap,
    this.videoDuration = "00:00:00",
    this.videoSeek = "00:00:00",
    this.videoStyle = const VideoStyle(),
    this.onFastForward,
    this.onRewind,
  }) : super(key: key);

  final VideoPlayerController controller;
  final bool showBottomBar;
  final String videoSeek;
  final bool fullScreen;
  final String videoDuration;
  final void Function()? onPlayButtonTap;
  final VideoStyle videoStyle;
  final ValueChanged<VideoPlayerValue>? onRewind;
  final ValueChanged<VideoPlayerValue>? onFastForward;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: showBottomBar,
      child: Padding(
        padding: videoStyle.bottomBarPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                LayoutBuilder(
                
                  builder: (context, constraints) {
                    
                    return GestureDetector(
                      onPanUpdate: (details) {
                        final newPosition = (details.localPosition.dx / constraints.maxWidth)
                            .clamp(0.0, 1.0) *
                            controller.value.duration.inMilliseconds;
                        controller.seekTo(Duration(milliseconds: newPosition.round()));
                      },
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                          activeTrackColor: const Color.fromARGB(255, 255, 152, 0),
                          inactiveTrackColor: Colors.grey.shade400,
                          thumbColor: const Color.fromARGB(255, 255, 152, 0),
                          overlayColor: const Color.fromARGB(80, 255, 152, 0),
                        ),
                        child: Slider(
                          value: controller.value.position.inMilliseconds.toDouble().clamp(0.0, controller.value.duration.inMilliseconds.toDouble()),
                          min: 0.0,
                          max: controller.value.duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            controller.seekTo(Duration(milliseconds: value.round()));
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            Padding(
              padding: videoStyle.videoDurationsPadding ?? const EdgeInsets.only(top: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$videoSeek / $videoDuration",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  InkWell(
                    onTap: () => ScreenUtils.toggleFullScreen(fullScreen),
                    child: videoStyle.fullscreenIcon ??
                        Icon(
                          Icons.fullscreen,
                          color: videoStyle.fullScreenIconColor,
                          size: videoStyle.fullScreenIconSize,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:lecle_yoyo_player/lecle_yoyo_player.dart';
// import 'package:lecle_yoyo_player/src/utils/utils.dart';
// import 'package:video_player/video_player.dart';
// import 'package:flutter/services.dart';
// /// Widget use to display the bottom bar buttons and the time texts
// class PlayerBottomBar extends StatelessWidget {
//   /// Constructor
//   const PlayerBottomBar({
//     Key? key,
//     required this.controller,
//     required this.showBottomBar,
//     required this.fullScreen,
//     this.onPlayButtonTap,
//     this.videoDuration = "00:00:00",
//     this.videoSeek = "00:00:00",
//     this.videoStyle = const VideoStyle(),
//     this.onFastForward,
//     this.onRewind,
//   }) : super(key: key);

//   /// The controller of the playing video.
//   final VideoPlayerController controller;

//   /// If set to [true] the bottom bar will appear and if you want that user can not interact with the bottom bar you can set it to [false].
//   /// Default value is [true].
//   final bool showBottomBar;

//   /// The text to display the current position progress.
//   final String videoSeek;

//   final bool fullScreen;

//   /// The text to display the video's duration.
//   final String videoDuration;

//   /// The callback function execute when user tapped the play button.
//   final void Function()? onPlayButtonTap;

//   /// The model to provide custom style for the video display widget.
//   final VideoStyle videoStyle;

//   /// The callback function execute when user tapped the rewind button.
//   final ValueChanged<VideoPlayerValue>? onRewind;

//   /// The callback function execute when user tapped the forward button.
//   final ValueChanged<VideoPlayerValue>? onFastForward;

//   @override
//   Widget build(BuildContext context) {
//     return Visibility(
//       visible: showBottomBar,
//       child: Padding(
//         padding: videoStyle.bottomBarPadding,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//   Stack(
//   alignment: Alignment.centerLeft,
//   children: [
//     // Progress bar
//               // Video progress indicator
//              LayoutBuilder(
//                   builder: (context, constraints) {
//                     return InkWell(
                     
//                       onTap: () {
//                         // Calculate the current position based on video progress
//                         final circularContainerPosition = controller.value.position.inMilliseconds.toDouble();
//                         final newPosition = (circularContainerPosition / constraints.maxWidth)
//                             .clamp(0.0, 1.0) * controller.value.duration.inMilliseconds;

//                         // Seek to the new position
//                         controller.seekTo(Duration(milliseconds: newPosition.round()));
//                       },
//                       child: VideoProgressIndicator(
//                         controller,
//                         allowScrubbing: videoStyle.allowScrubbing ?? true,
//                         colors: videoStyle.progressIndicatorColors ??
//                             const VideoProgressColors(
//                               playedColor: Color.fromARGB(255, 255, 152, 0),
//                             ),
//                         padding: videoStyle.progressIndicatorPadding ?? EdgeInsets.zero,
//                       ),
//                     );
//                   },
//                 ),
//     // VideoProgressIndicator(
//     //   controller,
//     //   allowScrubbing: videoStyle.allowScrubbing ?? true,
//     //   colors: videoStyle.progressIndicatorColors ??
//     //       const VideoProgressColors(
//     //         playedColor: Color.fromARGB(255, 255, 152, 0),
//     //       ),
//     //   padding: videoStyle.progressIndicatorPadding ?? EdgeInsets.zero,
//     // ),

//     // LayoutBuilder to get available width
//     LayoutBuilder(
//       builder: (context, constraints) {
//         return AnimatedBuilder(
//           animation: controller,
//           builder: (context, _) {
//             // Get progress between 0.0 and 1.0
//             double progress = controller.value.position.inMilliseconds /
//                 controller.value.duration.inMilliseconds;
            
//             // Ensure progress is a valid number and within bounds
//             if (progress.isNaN) progress = 0.0;
//             progress = progress.clamp(0.0, 1.0);

//             // Calculate the circular container position
//             final double circularContainerPosition = progress * constraints.maxWidth;

//             // Use GestureDetector for seeking functionality
//             return Stack(
//               alignment: Alignment.centerLeft,
//               children: [
//                 // Container for the circular dot
//                 InkWell(
//                   // onPanUpdate: (details) {
//                   //   // Calculate the new position based on the drag position
//                   //   final newPosition = (details.localPosition.dx / constraints.maxWidth)
//                   //       .clamp(0.0, 1.0) * controller.value.duration.inMilliseconds;

//                   //   // Seek to the new position
//                   //   controller.seekTo(Duration(milliseconds: newPosition.round()));
//                   // },
//                   onTap: () {
//                     print("The circle video dot is called !!!");
//                      HapticFeedback.mediumImpact();
//                     // On tap, also allow seeking to the tapped position
//                     final newPosition = (circularContainerPosition / constraints.maxWidth)
//                         .clamp(0.0, 1.0) * controller.value.duration.inMilliseconds;

//                     controller.seekTo(Duration(milliseconds: newPosition.round()));
//                   },
//                   child: Container(
//                     width: 18.0,
//                     height: 18.0,
//                     decoration: BoxDecoration(
//                       color: Color.fromARGB(255, 255, 152, 0),
//                       shape: BoxShape.circle,
//                     ),
//                     transform: Matrix4.translationValues(circularContainerPosition, 0.0, 0.0),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     ),
//   ],
// ),

//             // VideoProgressIndicator(
//             //   controller,
//             //   allowScrubbing: videoStyle.allowScrubbing ?? true,
//             //   colors: videoStyle.progressIndicatorColors ??
//             //       const VideoProgressColors(
//             //         playedColor: Color.fromARGB(255, 255, 152, 0),
//             //       ),
//             //   padding: videoStyle.progressIndicatorPadding ?? EdgeInsets.zero,
//             // ),
//             Padding(
//               padding: videoStyle.videoDurationsPadding ??
//                   const EdgeInsets.only(top: 8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Container(
//                     // margin: const EdgeInsets.only(bottom: 16.0),
//                     child: Text(
//                       "$videoSeek / $videoDuration",
//                       style: videoStyle.videoSeekStyle ??
//                           const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                     ),
//                   ),
//                   // Transform.translate(
//                   //   offset: const Offset(0.0, -4.0),
//                   //   child: Row(
//                   //     mainAxisAlignment: MainAxisAlignment.center,
//                   //     mainAxisSize: MainAxisSize.max,
//                   //     crossAxisAlignment: CrossAxisAlignment.center,
//                   //     children: [
//                   //       InkWell(
//                   //         onTap: () {
//                   //           controller.rewind().then((value) {
//                   //             onRewind?.call(controller.value);
//                   //           });
//                   //         },
//                   //         child: videoStyle.backwardIcon ??
//                   //             Icon(
//                   //               Icons.fast_rewind_rounded,
//                   //               color: videoStyle.forwardIconColor,
//                   //               size: videoStyle.forwardAndBackwardBtSize,
//                   //             ),
//                   //       ),
//                   //       Container(
//                   //         margin: EdgeInsets.symmetric(
//                   //           horizontal: videoStyle.spaceBetweenBottomBarButtons,
//                   //         ),
//                   //         child: InkWell(
//                   //           onTap: onPlayButtonTap,
//                   //           child: () {
//                   //             var defaultIcon = Icon(
//                   //               controller.value.isPlaying
//                   //                   ? Icons.pause_circle_outline
//                   //                   : Icons.play_circle_outline,
//                   //               color: videoStyle.playButtonIconColor ??
//                   //                   Colors.white,
//                   //               size: videoStyle.playButtonIconSize ?? 35,
//                   //             );

//                   //             if (videoStyle.playIcon != null &&
//                   //                 videoStyle.pauseIcon == null) {
//                   //               return controller.value.isPlaying
//                   //                   ? defaultIcon
//                   //                   : videoStyle.playIcon;
//                   //             } else if (videoStyle.pauseIcon != null &&
//                   //                 videoStyle.playIcon == null) {
//                   //               return controller.value.isPlaying
//                   //                   ? videoStyle.pauseIcon
//                   //                   : defaultIcon;
//                   //             } else if (videoStyle.playIcon != null &&
//                   //                 videoStyle.pauseIcon != null) {
//                   //               return controller.value.isPlaying
//                   //                   ? videoStyle.pauseIcon
//                   //                   : videoStyle.playIcon;
//                   //             }

//                   //             return defaultIcon;
//                   //           }(),
//                   //         ),
//                   //       ),
//                   //       InkWell(
//                   //         onTap: () {
//                   //           controller.fastForward().then((value) {
//                   //             onFastForward?.call(controller.value);
//                   //           });
//                   //         },
//                   //         child: videoStyle.forwardIcon ??
//                   //             Icon(
//                   //               Icons.fast_forward_rounded,
//                   //               color: videoStyle.forwardIconColor,
//                   //               size: videoStyle.forwardAndBackwardBtSize,
//                   //             ),
//                   //       ),
                        
//                   //     ],
//                   //   ),
//                   // ),
//                     InkWell(
//                 onTap: () => ScreenUtils.toggleFullScreen(fullScreen),
//                 child: videoStyle.fullscreenIcon ??
//                     Icon(
//                       Icons.fullscreen,
//                       color: videoStyle.fullScreenIconColor,
//                       size: videoStyle.fullScreenIconSize,
//                     ),
//               ),
//                   // Container(
//                   //   margin: const EdgeInsets.only(bottom: 16.0),
//                   //   child: Text(
//                   //     videoDuration,
//                   //     style: videoStyle.videoDurationStyle ??
//                   //         const TextStyle(
//                   //           fontWeight: FontWeight.bold,
//                   //           color: Colors.white,
//                   //         ),
//                   //   ),
//                   // ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
