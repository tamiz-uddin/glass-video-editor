import 'package:hive/hive.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/text_overlay.dart';

class Project extends HiveObject {
  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    this.clips = const [],
    this.overlays = const [],
    this.exportWidth = 1080,
    this.exportHeight = 1920,
    this.exportFps = 30,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<Clip> clips;
  final List<TextOverlay> overlays;
  final int exportWidth;
  final int exportHeight;
  final int exportFps;

  int get totalDurationMs => clips.fold(0, (sum, c) => sum + c.effectiveDurationMs);

  Project copyWith({
    String? name,
    List<Clip>? clips,
    List<TextOverlay>? overlays,
    int? exportWidth,
    int? exportHeight,
    int? exportFps,
  }) => Project(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        clips: clips ?? this.clips,
        overlays: overlays ?? this.overlays,
        exportWidth: exportWidth ?? this.exportWidth,
        exportHeight: exportHeight ?? this.exportHeight,
        exportFps: exportFps ?? this.exportFps,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'clips': clips.map((c) => c.toJson()).toList(),
        'overlays': overlays.map((o) => o.toJson()).toList(),
        'exportWidth': exportWidth,
        'exportHeight': exportHeight,
        'exportFps': exportFps,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        clips: (json['clips'] as List<dynamic>? ?? [])
            .map((e) => Clip.fromJson(e as Map<String, dynamic>))
            .toList(),
        overlays: (json['overlays'] as List<dynamic>? ?? [])
            .map((e) => TextOverlay.fromJson(e as Map<String, dynamic>))
            .toList(),
        exportWidth: (json['exportWidth'] as num?)?.toInt() ?? 1080,
        exportHeight: (json['exportHeight'] as num?)?.toInt() ?? 1920,
        exportFps: (json['exportFps'] as num?)?.toInt() ?? 30,
      );
}

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 0;

  @override
  Project read(BinaryReader reader) =>
      Project.fromJson(Map<String, dynamic>.from(reader.read() as Map));

  @override
  void write(BinaryWriter writer, Project obj) => writer.write(obj.toJson());
}
