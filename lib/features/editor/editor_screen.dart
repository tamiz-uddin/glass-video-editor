import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/project.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/video/video_engine.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';
import 'package:glass_video_editor/features/editor/widgets/editor_preview.dart';
import 'package:glass_video_editor/features/editor/widgets/glass_timeline.dart';
import 'package:glass_video_editor/features/editor/widgets/glass_toolbar.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.project});

  final Project project;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _engine = VideoEngine();
  VideoPlayerController? _controller;
  String? _selectedClipId;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _selectedClipId = widget.project.clips.isNotEmpty ? widget.project.clips.first.id : null;
    if (widget.project.clips.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(
        Uri.file(widget.project.clips.first.path),
      )..initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final output = await _engine.export(
        projectId: widget.project.id,
        clips: widget.project.clips,
        width: 1080,
        height: 1920,
        fps: 30,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(output != null ? 'Exported: $output' : 'Export finished')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tools = <EditorTool>[
      EditorTool(Icons.content_cut, 'Trim', () {}),
      EditorTool(Icons.speed, 'Speed', () {}),
      EditorTool(Icons.text_fields, 'Text', () {}),
      EditorTool(Icons.filter_vintage, 'Filter', () {}),
      EditorTool(Icons.music_note, 'Music', () {}),
      EditorTool(
        _exporting ? Icons.hourglass_top : Icons.file_upload_outlined,
        'Export',
        _exporting ? () {} : _export,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.project.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GlassPanel(
                    blur: 20,
                    opacity: 0.10,
                    radius: AppRadius.button,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: const Text('1080p • 30fps', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            Expanded(child: EditorPreview(controller: _controller)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GlassToolbar(tools: tools),
            ).animate().slideY(begin: 0.4, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GlassTimeline(
                clips: widget.project.clips,
                selectedId: _selectedClipId,
                onSelect: (clip) => setState(() => _selectedClipId = clip.id),
              ),
            ).animate().slideY(begin: 0.6, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
