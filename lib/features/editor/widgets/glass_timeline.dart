import 'package:flutter/material.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';

const double pxPerSecond = 60;
const double minClipWidth = 48;
const double maxClipWidth = 240;

class GlassTimeline extends StatelessWidget {
  const GlassTimeline({
    super.key,
    required this.clips,
    required this.selectedId,
    required this.playheadMs,
    required this.onSelect,
    required this.onReorder,
    required this.onTrim,
    required this.onSeek,
  });

  final List<Clip> clips;
  final String? selectedId;
  final int playheadMs;
  final ValueChanged<String> onSelect;
  final void Function(int from, int to) onReorder;
  final void Function(String clipId, int startMs, int endMs) onTrim;
  final ValueChanged<int> onSeek;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      blur: 28,
      opacity: 0.10,
      radius: AppRadius.panel,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 18,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    final total = clips.fold<int>(0, (s, c) => s + c.effectiveDurationMs);
                    if (total <= 0) return;
                    onSeek((details.localPosition.dx / constraints.maxWidth * total).round());
                  },
                  child: Stack(
                    children: [
                      Container(
                        height: 2,
                        color: AppColors.glassBorder,
                        margin: const EdgeInsets.only(top: 8),
                      ),
                      if (clips.isNotEmpty)
                        Positioned(
                          left: constraints.maxWidth *
                              (playheadMs /
                                  clips.fold<int>(0, (s, c) => s + c.effectiveDurationMs)),
                          top: 2,
                          child: Container(
                            width: 2,
                            height: 14,
                            color: AppColors.accentCyan,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: clips.isEmpty
                ? const Center(
                    child: Text('Timeline is empty', style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: clips.length,
                    onReorder: onReorder,
                    itemBuilder: (context, index) {
                      final clip = clips[index];
                      final selected = clip.id == selectedId;
                      final width = (clip.effectiveDurationMs / 1000 * pxPerSecond)
                          .clamp(minClipWidth, maxClipWidth);
                      return _ClipCard(
                        key: ValueKey(clip.id),
                        clip: clip,
                        width: width,
                        selected: selected,
                        onTap: () => onSelect(clip.id),
                        onTrim: (s, e) => onTrim(clip.id, s, e),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClipCard extends StatefulWidget {
  const _ClipCard({
    super.key,
    required this.clip,
    required this.width,
    required this.selected,
    required this.onTap,
    required this.onTrim,
  });

  final Clip clip;
  final double width;
  final bool selected;
  final VoidCallback onTap;
  final void Function(int startMs, int endMs) onTrim;

  @override
  State<_ClipCard> createState() => _ClipCardState();
}

class _ClipCardState extends State<_ClipCard> {
  late int _start;
  late int _end;

  @override
  void initState() {
    super.initState();
    _start = widget.clip.trimStartMs;
    _end = widget.clip.sourceEndMs;
  }

  @override
  void didUpdateWidget(covariant _ClipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _start = widget.clip.trimStartMs;
    _end = widget.clip.sourceEndMs;
  }

  void _dragLeft(double deltaPx) {
    final ms = (deltaPx / widget.width * widget.clip.effectiveDurationMs * widget.clip.speed).round();
    widget.onTrim(_start + ms, _end);
  }

  void _dragRight(double deltaPx) {
    final ms = (deltaPx / widget.width * widget.clip.effectiveDurationMs * widget.clip.speed).round();
    widget.onTrim(_start, _end + ms);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: widget.selected
              ? AppColors.accentGradient
              : const LinearGradient(colors: [Color(0x2622D3EE), Color(0x268B5CF6)]),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: widget.selected ? Colors.white38 : AppColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            if (widget.selected)
              GestureDetector(
                onPanUpdate: (d) => _dragLeft(d.delta.dx),
                child: Container(
                  width: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(AppRadius.chip)),
                  ),
                  child: const Icon(Icons.chevron_left, size: 14, color: Colors.white),
                ),
              ),
            Expanded(
              child: Center(
                child: Text(
                  '${(widget.clip.effectiveDurationMs / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (widget.selected)
              GestureDetector(
                onPanUpdate: (d) => _dragRight(d.delta.dx),
                child: Container(
                  width: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.chip)),
                  ),
                  child: const Icon(Icons.chevron_right, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
