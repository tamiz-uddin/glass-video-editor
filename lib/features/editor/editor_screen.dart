import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/text_overlay.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/video/video_engine.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';
import 'package:glass_video_editor/features/editor/editor_controller.dart';
import 'package:glass_video_editor/features/editor/timeline_math.dart';
import 'package:glass_video_editor/features/editor/widgets/editor_preview.dart';
import 'package:glass_video_editor/features/editor/widgets/glass_timeline.dart';
import 'package:glass_video_editor/features/editor/widgets/glass_toolbar.dart';
import 'package:glass_video_editor/features/editor/widgets/tool_sheets.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _engine = VideoEngine();
  VideoPlayerController? _player;
  Timer? _ticker;
  String? _loadedClipId;
  bool _exporting = false;
  double _progress = 0;
  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _progressSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  EditorController get _editor => ref.read(editorControllerProvider(widget.projectId).notifier);

  void _ensurePlayer(EditorState state) {
    final index = state.currentClipIndex;
    if (index < 0 || index >= state.clips.length) {
      if (_player != null) {
        _player?.dispose();
        _player = null;
        _loadedClipId = null;
      }
      return;
    }
    final clip = state.clips[index];
    if (_loadedClipId == clip.id && _player != null) return;
    _player?.dispose();
    _loadedClipId = clip.id;
    _player = VideoPlayerController.networkUrl(Uri.file(clip.path))
      ..initialize().then((_) {
        if (!mounted) return;
        _player?.setPlaybackSpeed(clip.speed);
        _player?.setVolume(clip.volume);
        _player?.seekTo(Duration(milliseconds: clip.trimStartMs));
        if (state.playing) _player?.play();
        setState(() {});
      });
    setState(() {});
  }

  void _tick(Timer _) {
    final state = ref.read(editorControllerProvider(widget.projectId));
    if (!state.playing || _player == null || !_player!.value.isInitialized) return;
    final index = state.currentClipIndex;
    if (index < 0 || index >= state.clips.length) return;
    final clip = state.clips[index];
    final pos = _player!.value.position.inMilliseconds;
    final clipStart = timelineStartOf(state.clips, clip.id);
    final timelinePos = clipStart + ((pos - clip.trimStartMs) / clip.speed).round();

    if (pos >= clip.sourceEndMs) {
      if (index + 1 < state.clips.length) {
        _editor.setPlayhead(timelineStartOf(state.clips, state.clips[index + 1].id));
      } else {
        _editor.setPlayhead(state.totalDurationMs);
        _editor.setPlaying(false);
        _player?.pause();
      }
      return;
    }
    _editor.setPlayhead(timelinePos);
  }

  Future<void> _addVideos() async {
    final paths = await _engine.pickVideos();
    if (paths.isEmpty) return;
    final clips = <Clip>[];
    for (final path in paths) {
      final durationMs = await _engine.probeDurationMs(path) ?? 0;
      clips.add(Clip(id: const Uuid().v4(), path: path, durationMs: durationMs));
    }
    _editor.addClips(clips);
  }

  Future<void> _export() async {
    final state = ref.read(editorControllerProvider(widget.projectId));
    final project = _editor.snapshotProject(widget.projectId);
    final jobId = const Uuid().v4();
    setState(() {
      _exporting = true;
      _progress = 0;
    });
    _progressSub = _engine.exportProgress(jobId).listen((p) {
      if (mounted) setState(() => _progress = p);
    });
    try {
      final output = await _engine.export(
        jobId: jobId,
        project: project,
        width: state.exportWidth,
        height: state.exportHeight,
        fps: state.exportFps,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(output != null ? 'Exported: $output' : 'Export finished')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      _progressSub?.cancel();
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showExportSheet(EditorState state) {
    showToolSheet(
      context: context,
      title: 'Export',
      child: ExportSettingsSheet(
        width: state.exportWidth,
        height: state.exportHeight,
        fps: state.exportFps,
        exporting: _exporting,
        onResolution: (w, h) => _editor.setExportSettings(width: w, height: h),
        onFps: (f) => _editor.setExportSettings(fps: f),
        onExport: () {
          Navigator.of(context).pop();
          _export();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider(widget.projectId));
    _ensurePlayer(state);
    final currentClip = state.currentClipIndex >= 0 && state.currentClipIndex < state.clips.length
        ? state.clips[state.currentClipIndex]
        : null;
    final visibleOverlays = state.overlays.where((o) => o.isVisibleAt(state.playheadMs)).toList();

    final tools = <EditorTool>[
      EditorTool(Icons.add_circle_outline, 'Add', _addVideos),
      EditorTool(Icons.content_cut, 'Split', () => _editor.splitSelectedAt(state.playheadMs)),
      EditorTool(Icons.delete_outline, 'Delete', () {
        if (state.selectedId != null) _editor.removeClip(state.selectedId!);
      }),
      EditorTool(Icons.speed, 'Speed', () {
        final clip = state.selectedClip;
        if (clip == null) return;
        showToolSheet(
          context: context,
          title: 'Speed',
          child: SpeedSheet(
            initial: clip.speed,
            onChanged: (v) => _editor.setSpeed(clip.id, v),
          ),
        );
      }),
      EditorTool(Icons.switch_right, 'Transition', () {
        final clip = state.selectedClip;
        if (clip == null) return;
        showToolSheet(
          context: context,
          title: 'Transition (to next clip)',
          child: OptionSheet(
            options: transitionOptions,
            current: clip.transition,
            onSelected: (t) => _editor.setTransition(clip.id, t),
          ),
        );
      }),
      EditorTool(Icons.filter_vintage, 'Filter', () {
        final clip = state.selectedClip;
        if (clip == null) return;
        showToolSheet(
          context: context,
          title: 'Filter',
          child: OptionSheet(
            options: filterOptions,
            current: clip.filter,
            onSelected: (f) => _editor.setFilter(clip.id, f),
          ),
        );
      }),
      EditorTool(Icons.photo_size_select_small, 'Adjust', () {
        final clip = state.selectedClip;
        if (clip == null) return;
        showToolSheet(
          context: context,
          title: 'Zoom / Reverse',
          child: AdjustSheet(
            zoom: clip.zoom,
            reverse: clip.reverse,
            onZoom: (z) => _editor.setZoom(clip.id, z),
            onReverse: (r) => _editor.setReverse(clip.id, r),
          ),
        );
      }),
      EditorTool(Icons.closed_caption_outlined, 'Captions', () async {
        final clip = state.selectedClip;
        if (clip == null) return;
        final segments = await _engine.transcribe(clip.path);
        final base = timelineStartOf(state.clips, clip.id);
        for (final s in segments) {
          _editor.addOverlay(TextOverlay(
            id: _editor.newOverlayId(),
            text: s['text'] as String,
            startMs: base + (s['startMs'] as int),
            endMs: base + (s['endMs'] as int),
            y: 0.85,
            fontSize: 24,
          ));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${segments.length} caption(s) added')),
          );
        }
      }),
      EditorTool(Icons.music_note, 'Music', () async {
        final result = await FilePicker.platform.pickFiles(type: FileType.audio);
        final path = result?.files.single.path;
        if (path != null) _editor.setMusic(path: path);
      }),
      EditorTool(Icons.volume_up_outlined, 'Volume', () {
        final clip = state.selectedClip;
        if (clip == null) return;
        showToolSheet(
          context: context,
          title: 'Volume',
          child: VolumeSheet(
            initial: clip.volume,
            onChanged: (v) => _editor.setVolume(clip.id, v),
          ),
        );
      }),
      EditorTool(Icons.text_fields, 'Text', () {
        showToolSheet(
          context: context,
          title: 'Add text',
          child: TextSheet(
            onSubmit: (text) => _editor.addOverlay(TextOverlay(
                  id: _editor.newOverlayId(),
                  text: text,
                  startMs: state.playheadMs,
                  endMs: state.totalDurationMs,
                )),
          ),
        );
      }),
      EditorTool(Icons.file_upload_outlined, 'Export', () => _showExportSheet(state)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Project ${widget.projectId.substring(0, 8)}',
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GlassPanel(
                    blur: 20,
                    opacity: 0.10,
                    radius: AppRadius.button,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      '${state.exportWidth}p • ${state.exportFps}fps',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            Expanded(
              child: Stack(
                children: [
                  EditorPreview(
                    controller: _player,
                    clip: currentClip,
                    overlays: visibleOverlays,
                    playing: state.playing && (_player?.value.isPlaying ?? false),
                    onTogglePlay: () {
                      final next = !state.playing;
                      _editor.setPlaying(next);
                      if (next) {
                        _player?.play();
                      } else {
                        _player?.pause();
                      }
                    },
                  ),
                  if (_exporting)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: GlassPanel(
                            blur: 30,
                            opacity: 0.16,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: AppColors.accentCyan),
                                const SizedBox(height: 16),
                                Text('Exporting ${( _progress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GlassToolbar(tools: tools),
            ).animate().slideY(begin: 0.4, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GlassTimeline(
                clips: state.clips,
                selectedId: state.selectedId,
                playheadMs: state.playheadMs,
                onSelect: _editor.select,
                onReorder: _editor.moveClip,
                onTrim: _editor.setTrim,
                onSeek: _editor.setPlayhead,
              ),
            ).animate().slideY(begin: 0.6, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
