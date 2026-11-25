import 'package:hive/hive.dart';
import 'package:glass_video_editor/core/models/clip.dart';

class Project extends HiveObject {
  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    this.clips = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<Clip> clips;

  Project copyWith({String? name, List<Clip>? clips}) => Project(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        clips: clips ?? this.clips,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'clips': clips.map((c) => c.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        clips: (json['clips'] as List<dynamic>)
            .map((e) => Clip.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 0;

  @override
  Project read(BinaryReader reader) => Project.fromJson(
        Map<String, dynamic>.from(reader.read() as Map),
      );

  @override
  void write(BinaryWriter writer, Project obj) => writer.write(obj.toJson());
}
