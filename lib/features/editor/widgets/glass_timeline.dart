import 'package:flutter/material.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';

class GlassTimeline extends StatelessWidget {
  const GlassTimeline({super.key, required this.clips, this.selectedId, this.onSelect});

  final List<Clip> clips;
  final String? selectedId;
  final ValueChanged<Clip>? onSelect;

  @override
  Widget build(BuildContext context) {
    const pxPerSecond = 60.0;

    return GlassPanel(
      blur: 28,
      opacity: 0.10,
      radius: AppRadius.panel,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SizedBox(
        height: 64,
        child: clips.isEmpty
            ? const Center(
                child: Text('Timeline is empty', style: TextStyle(color: AppColors.textSecondary)),
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: clips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final clip = clips[index];
                  final selected = clip.id == selectedId;
                  final width = (clip.effectiveDurationMs / 1000 * pxPerSecond).clamp(48.0, 240.0);
                  return GestureDetector(
                    onTap: () => onSelect?.call(clip),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: width,
                      decoration: BoxDecoration(
                        gradient: selected
                            ? AppColors.accentGradient
                            : const LinearGradient(
                                colors: [Color(0x2622D3EE), Color(0x268B5CF6)],
                              ),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(
                          color: selected ? Colors.white38 : AppColors.glassBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${(clip.effectiveDurationMs / 1000).toStringAsFixed(1)}s',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
