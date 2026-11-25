import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/text_overlay.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';
import 'package:glass_video_editor/features/editor/keyframe_math.dart';

class EditorPreview extends StatelessWidget {
  const EditorPreview({
    super.key,
    required this.controller,
    required this.clip,
    required this.overlays,
    required this.playing,
    required this.onTogglePlay,
    this.transform,
  });

  final VideoPlayerController? controller;
  final Clip? clip;
  final List<TextOverlay> overlays;
  final bool playing;
  final VoidCallback onTogglePlay;
  final KeyframeTransform? transform;

  @override
  Widget build(BuildContext context) {
    final ready = controller != null && controller!.value.isInitialized && clip != null;

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
                    child: Opacity(
                      opacity: transform?.opacity ?? 1.0,
                      child: Transform.scale(
                        scale: transform?.zoom ?? 1.0,
                        child: Transform.translate(
                          offset: Offset(
                            (transform?.panX ?? 0) * 200,
                            (transform?.panY ?? 0) * 200,
                          ),
                          child: Stack(
                      children: [
                        VideoPlayer(controller!),
                        ...overlays
                            .map(
                              (o) => Positioned(
                                left: o.x * MediaQuery.of(context).size.width * 0.9,
                                top: o.y * 300,
                                child: Text(
                                  o.text,
                                  style: TextStyle(
                                    color: Color(o.colorHex),
                                    fontSize: o.fontSize,
                                    fontWeight: FontWeight.w700,
                                    shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
                                  ),
                                ),
                              ),
                            ),
                      ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const Center(
                  child: Icon(Icons.videocam_off_outlined, size: 64, color: AppColors.textSecondary),
                ),
        ),
        if (ready)
          Positioned.fill(
            child: GestureDetector(
              onTap: onTogglePlay,
              child: Center(
                child: AnimatedOpacity(
                  opacity: playing ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: GlassPanel(
                    blur: 30,
                    opacity: 0.14,
                    radius: 40,
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.play_circle_filled, size: 56, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
