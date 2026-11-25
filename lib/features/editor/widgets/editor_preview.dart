import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';

class EditorPreview extends StatelessWidget {
  const EditorPreview({super.key, required this.controller});

  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF14141F), AppColors.background],
            ),
          ),
          child: ready
              ? Center(
                  child: AspectRatio(
                    aspectRatio: controller!.value.aspectRatio,
                    child: VideoPlayer(controller!),
                  ),
                )
              : const Center(
                  child: Icon(Icons.videocam_off_outlined, size: 64, color: AppColors.textSecondary),
                ),
        ),
        if (ready)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: GlassPanel(
                blur: 30,
                opacity: 0.12,
                radius: 40,
                padding: const EdgeInsets.all(10),
                child: IconButton(
                  iconSize: 32,
                  color: Colors.white,
                  icon: Icon(
                    controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  ),
                  onPressed: () {
                    controller!.value.isPlaying
                        ? controller!.pause()
                        : controller!.play();
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
