import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/project.dart';
import 'package:glass_video_editor/core/models/text_overlay.dart';
import 'package:glass_video_editor/features/editor/timeline_math.dart';
import 'package:glass_video_editor/features/projects/projects_provider.dart';
import 'package:glass_video_editor/features/templates/templates.dart';

class EditorState {
  const EditorState({
    this.clips = const [],
    this.overlays = const [],
    this.selectedId,
    this.playheadMs = 0,
    this.playing = false,
    this.exportWidth = 1080,
    this.exportHeight = 1920,
    this.exportFps = 30,
    this.musicPath,
    this.musicVolume = 1.0,
    this.musicStartMs = 0,
  });

  final List<Clip> clips;
  final List<TextOverlay> overlays;
  final String? selectedId;
  final int playheadMs;
  final bool playing;
  final int exportWidth;
  final int exportHeight;
  final int exportFps;
  final String? musicPath;
  final double musicVolume;
  final int musicStartMs;

  int get totalDurationMs => totalDurationMsOf(clips);

  Clip? get selectedClip {
    if (selectedId == null) return null;
    for (final c in clips) {
      if (c.id == selectedId) return c;
    }
    return null;
  }

  int get currentClipIndex => clipIndexAt(clips, playheadMs);

  bool get needsFfmpeg => clips.any((c) => c.hasAdvancedOps);

  EditorState copyWith({
    List<Clip>? clips,
    List<TextOverlay>? overlays,
    String? selectedId,
    int? playheadMs,
    bool? playing,
    int? exportWidth,
    int? exportHeight,
    int? exportFps,
    String? musicPath,
    double? musicVolume,
    int? musicStartMs,
  }) => EditorState(
        clips: clips ?? this.clips,
        overlays: overlays ?? this.overlays,
        selectedId: selectedId,
        playheadMs: playheadMs ?? this.playheadMs,
        playing: playing ?? this.playing,
        exportWidth: exportWidth ?? this.exportWidth,
        exportHeight: exportHeight ?? this.exportHeight,
        exportFps: exportFps ?? this.exportFps,
        musicPath: musicPath ?? this.musicPath,
        musicVolume: musicVolume ?? this.musicVolume,
        musicStartMs: musicStartMs ?? this.musicStartMs,
      );
}

int totalDurationMsOf(List<Clip> clips) => totalDurationMs(clips);

final editorControllerProvider =
    StateNotifierProvider.family<EditorController, EditorState, String>(
  (ref, projectId) {
    final box = Hive.box<Project>(projectsBoxName);
    return EditorController(projectId, box.get(projectId));
  },
);

class EditorController extends StateNotifier<EditorState> {
  EditorController(this.projectId, Project? project)
      : super(EditorState(
          clips: project?.clips ?? const [],
          overlays: project?.overlays ?? const [],
          selectedId: project?.clips.isNotEmpty == true ? project!.clips.first.id : null,
          exportWidth: project?.exportWidth ?? 1080,
          exportHeight: project?.exportHeight ?? 1920,
          exportFps: project?.exportFps ?? 30,
          musicPath: project?.musicPath,
          musicVolume: project?.musicVolume ?? 1.0,
          musicStartMs: project?.musicStartMs ?? 0,
        ));

  final String projectId;

  Box<Project> get _box => Hive.box<Project>(projectsBoxName);

  void _persist() {
    final project = _box.get(projectId);
    if (project == null) return;
    _box.put(
      projectId,
      project.copyWith(
        clips: state.clips,
        overlays: state.overlays,
        exportWidth: state.exportWidth,
        exportHeight: state.exportHeight,
        exportFps: state.exportFps,
        musicPath: state.musicPath,
        musicVolume: state.musicVolume,
        musicStartMs: state.musicStartMs,
      ),
    );
  }

  void addClips(List<Clip> newClips) {
    if (newClips.isEmpty) return;
    state = state.copyWith(
      clips: [...state.clips, ...newClips],
      selectedId: state.selectedId ?? newClips.first.id,
    );
    _persist();
  }

  void select(String? clipId) {
    state = state.copyWith(selectedId: clipId);
  }

  void removeClip(String clipId) {
    final clips = state.clips.where((c) => c.id != clipId).toList();
    state = state.copyWith(
      clips: clips,
      selectedId: state.selectedId == clipId
          ? (clips.isNotEmpty ? clips.first.id : null)
          : state.selectedId,
      playheadMs: state.playheadMs > totalDurationMsOf(clips)
          ? totalDurationMsOf(clips)
          : state.playheadMs,
    );
    _persist();
  }

  void splitSelectedAt(int timelineMs) {
    final id = state.selectedId;
    if (id == null) return;
    final offset = timelineMs - timelineStartOf(state.clips, id);
    state = state.copyWith(clips: splitClipInList(state.clips, id, offset));
    _persist();
  }

  void setTrim(String clipId, int startMs, int endMs) {
    final clips = state.clips
        .map((c) => c.id == clipId ? clampTrim(c, startMs, endMs) : c)
        .toList();
    state = state.copyWith(clips: clips);
    _persist();
  }

  void moveClip(int from, int to) {
    state = state.copyWith(clips: reorderClips(state.clips, from, to));
    _persist();
  }

  void setSpeed(String clipId, double speed) {
    state = state.copyWith(
      clips: state.clips.map((c) => c.id == clipId ? setSpeed(c, speed) : c).toList(),
    );
    _persist();
  }

  void setVolume(String clipId, double volume) {
    state = state.copyWith(
      clips: state.clips.map((c) => c.id == clipId ? setVolume(c, volume) : c).toList(),
    );
    _persist();
  }

  void setTransition(String clipId, String transition) {
    state = state.copyWith(
      clips: state.clips
          .map((c) => c.id == clipId ? c.copyWith(transition: transition) : c)
          .toList(),
    );
    _persist();
  }

  void setFilter(String clipId, String filter) {
    state = state.copyWith(
      clips: state.clips
          .map((c) => c.id == clipId ? c.copyWith(filter: filter) : c)
          .toList(),
    );
    _persist();
  }

  void setReverse(String clipId, bool reverse) {
    state = state.copyWith(
      clips: state.clips
          .map((c) => c.id == clipId ? c.copyWith(reverse: reverse) : c)
          .toList(),
    );
    _persist();
  }

  void setZoom(String clipId, double zoom, {double? panX, double? panY}) {
    state = state.copyWith(
      clips: state.clips
          .map((c) => c.id == clipId
              ? c.copyWith(zoom: zoom, panX: panX ?? c.panX, panY: panY ?? c.panY)
              : c)
          .toList(),
    );
    _persist();
  }

  void setMusic({String? path, double? volume, int? startMs}) {
    state = state.copyWith(
      musicPath: path,
      musicVolume: volume,
      musicStartMs: startMs,
    );
    _persist();
  }

  void applyTemplate(EditorTemplate template) {
    final clips = applyTemplateToClips(state.clips, template);
    final title = template.titleOverlay(newOverlayId(), totalDurationMsOf(clips));
    state = state.copyWith(
      clips: clips,
      overlays: title != null ? [...state.overlays, title] : state.overlays,
    );
    _persist();
  }

  void addOverlay(TextOverlay overlay) {
    state = state.copyWith(overlays: [...state.overlays, overlay]);
    _persist();
  }

  void removeOverlay(String id) {
    state = state.copyWith(overlays: state.overlays.where((o) => o.id != id).toList());
    _persist();
  }

  void setExportSettings({int? width, int? height, int? fps}) {
    state = state.copyWith(
      exportWidth: width,
      exportHeight: height,
      exportFps: fps,
    );
    _persist();
  }

  void setPlayhead(int ms) {
    state = state.copyWith(playheadMs: ms.clamp(0, state.totalDurationMs));
  }

  void setPlaying(bool playing) {
    state = state.copyWith(playing: playing);
  }

  void togglePlay() => setPlaying(!state.playing);

  Project snapshotProject(String name) => Project(
        id: projectId,
        name: name,
        createdAt: _box.get(projectId)?.createdAt ?? DateTime.now(),
        clips: state.clips,
        overlays: state.overlays,
        exportWidth: state.exportWidth,
        exportHeight: state.exportHeight,
        exportFps: state.exportFps,
        musicPath: state.musicPath,
        musicVolume: state.musicVolume,
        musicStartMs: state.musicStartMs,
      );

  String newOverlayId() => const Uuid().v4();
}
