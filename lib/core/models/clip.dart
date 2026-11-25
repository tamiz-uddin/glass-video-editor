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
    this.reverse = false,
    this.zoom = 1.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.removeBg = false,
    this.chromaHex,
    this.stabilize = false,
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
  final bool reverse;
  final double zoom;
  final double panX;
  final double panY;
  final bool removeBg;
  final int? chromaHex;
  final bool stabilize;

  int get sourceEndMs => trimEndMs == 0 ? durationMs : trimEndMs;

  int get effectiveDurationMs => ((sourceEndMs - trimStartMs) / speed).round();

  bool get hasAdvancedOps =>
      speed != 1.0 || filter != 'none' || transition != 'none' || reverse || zoom != 1.0 || removeBg || chromaHex != null || stabilize;

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
    bool? reverse,
    double? zoom,
    double? panX,
    double? panY,
    bool? removeBg,
    int? chromaHex,
    bool? stabilize,
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
      reverse: reverse ?? this.reverse,
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      removeBg: removeBg ?? this.removeBg,
      chromaHex: chromaHex ?? this.chromaHex,
      stabilize: stabilize ?? this.stabilize,
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
        'reverse': reverse,
        'zoom': zoom,
        'panX': panX,
        'panY': panY,
        'removeBg': removeBg,
        'chromaHex': chromaHex,
        'stabilize': stabilize,
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
        reverse: json['reverse'] as bool? ?? false,
        zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
        panX: (json['panX'] as num?)?.toDouble() ?? 0.0,
        panY: (json['panY'] as num?)?.toDouble() ?? 0.0,
        removeBg: json['removeBg'] as bool? ?? false,
        chromaHex: (json['chromaHex'] as num?)?.toInt(),
        stabilize: json['stabilize'] as bool? ?? false,
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
