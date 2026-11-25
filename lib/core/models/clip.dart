import 'package:hive/hive.dart';

class Clip extends HiveObject {
  Clip({
    required this.id,
    required this.path,
    required this.durationMs,
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.speed = 1.0,
    this.volume = 1.0,
    this.transition = 'none',
    this.filter = 'none',
  });

  final String id;
  final String path;
  final int durationMs;
  final int trimStartMs;
  final int trimEndMs;
  final double speed;
  final double volume;
  final String transition;
  final String filter;

  int get sourceEndMs => trimEndMs == 0 ? durationMs : trimEndMs;

  int get effectiveDurationMs => ((sourceEndMs - trimStartMs) / speed).round();

  bool get hasAdvancedOps => speed != 1.0 || filter != 'none' || transition != 'none';

  Clip copyWith({
    String? id,
    String? path,
    int? durationMs,
    int? trimStartMs,
    int? trimEndMs,
    double? speed,
    double? volume,
    String? transition,
    String? filter,
  }) {
    return Clip(
      id: id ?? this.id,
      path: path ?? this.path,
      durationMs: durationMs ?? this.durationMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      transition: transition ?? this.transition,
      filter: filter ?? this.filter,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'durationMs': durationMs,
        'trimStartMs': trimStartMs,
        'trimEndMs': trimEndMs,
        'speed': speed,
        'volume': volume,
        'transition': transition,
        'filter': filter,
      };

  factory Clip.fromJson(Map<String, dynamic> json) => Clip(
        id: json['id'] as String,
        path: json['path'] as String,
        durationMs: (json['durationMs'] as num).toInt(),
        trimStartMs: (json['trimStartMs'] as num?)?.toInt() ?? 0,
        trimEndMs: (json['trimEndMs'] as num?)?.toInt() ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
        volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
        transition: json['transition'] as String? ?? 'none',
        filter: json['filter'] as String? ?? 'none',
      );
}

class ClipAdapter extends TypeAdapter<Clip> {
  @override
  final int typeId = 1;

  @override
  Clip read(BinaryReader reader) =>
      Clip.fromJson(Map<String, dynamic>.from(reader.read() as Map));

  @override
  void write(BinaryWriter writer, Clip obj) => writer.write(obj.toJson());
}
