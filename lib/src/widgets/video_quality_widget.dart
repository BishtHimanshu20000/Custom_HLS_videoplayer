import 'package:flutter/material.dart';
import 'package:custom_hls_video/lecle_yoyo_player.dart';

/// A widget to display the video's current selected quality type.
class VideoQualityWidget extends StatelessWidget {
  /// Constructor
  const VideoQualityWidget({
    Key? key,
    required this.child,
    this.onTap,
    this.videoStyle = const VideoStyle(),
  }) : super(key: key);

  /// Callback function when user tap this widget to open the options list.
  final void Function()? onTap;

  /// The custom child to display the selected quality type.
  final Widget child;

  /// The model to provide custom style for the video display widget.
  final VideoStyle videoStyle;

  @override
  Widget build(BuildContext context) {
   // Extract the text from the child if it's a Text widget
    final String qualityText = (child is Text) ? (child as Text).data ?? '' : '';

    return IconButton(
      icon: Icon(
          Icons.settings, // Customize the icon, change to any relevant icon
          size: 24.0, // Customize icon size
          color: Colors.white, // Icon color
        ),
      onPressed: onTap, // Calls the provided onTap function when pressed
    );
  }
}

    
  //   InkWell(
  //     onTap: onTap,
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: videoStyle.videoQualityBgColor ?? Colors.grey,
  //         borderRadius: videoStyle.videoQualityRadius ??
  //             const BorderRadius.all(Radius.circular(5.0)),
  //       ),
  //       child: Padding(
  //         padding: videoStyle.videoQualityPadding ??
  //             const EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
  //         child: child,
  //       ),
  //     ),
  //   );
  // }
