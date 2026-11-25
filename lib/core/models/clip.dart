import 'package:hive/hive.dart';

class Clip extends HiveObject {
  Clip({
    required this.id,
    required this.path,
    required this.durationMs,
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.speed = 1.0,
  });

  final String id;
  final String path;
  final int durationMs;
  final int trimStartMs;
  final int trimEndMs;
  final double speed;

  int get effectiveDurationMs {
    final end = trimEndMs == 0 ? durationMs : trimEndMs;
    return ((end - trimStartMs) / speed).round();
  }

  Clip copyWith({
    String? id,
    String? path,
    int? durationMs,
    int? trimStartMs,
    int? trimEndMs,
    double? speed,
  }) {
    return Clip(
      id: id ?? this.id,
      path: path ?? this.path,
      durationMs: durationMs ?? this.durationMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      speed: speed ?? this.speed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'durationMs': durationMs,
        'trimStartMs': trimStartMs,
        'trimEndMs': trimEndMs,
        'speed': speed,
      };

  factory Clip.fromJson(Map<String, dynamic> json) => Clip(
        id: json['id'] as String,
        path: json['path'] as String,
        durationMs: json['durationMs'] as int,
        trimStartMs: (json['trimStartMs'] as num?)?.toInt() ?? 0,
        trimEndMs: (json['trimEndMs'] as num?)?.toInt() ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      );
}

class ClipAdapter extends TypeAdapter<Clip> {
  @override
  final int typeId = 1;

  @override
  Clip read(BinaryReader reader) => Clip.fromJson(
        Map<String, dynamic>.from(reader.read() as Map),
      );

  @override
  void write(BinaryWriter writer, Clip obj) => writer.write(obj.toJson());
}
