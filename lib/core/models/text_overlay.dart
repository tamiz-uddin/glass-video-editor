import 'package:hive/hive.dart';

class TextOverlay extends HiveObject {
  TextOverlay({
    required this.id,
    required this.text,
    required this.startMs,
    required this.endMs,
    this.x = 0.5,
    this.y = 0.8,
    this.fontSize = 28,
    this.colorHex = 0xFFFFFFFF,
  });

  final String id;
  final String text;
  final int startMs;
  final int endMs;
  final double x;
  final double y;
  final double fontSize;
  final int colorHex;

  bool isVisibleAt(int timelineMs) => timelineMs >= startMs && timelineMs <= endMs;

  TextOverlay copyWith({
    String? text,
    int? startMs,
    int? endMs,
    double? x,
    double? y,
    double? fontSize,
    int? colorHex,
  }) {
    return TextOverlay(
      id: id,
      text: text ?? this.text,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'startMs': startMs,
        'endMs': endMs,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'colorHex': colorHex,
      };

  factory TextOverlay.fromJson(Map<String, dynamic> json) => TextOverlay(
        id: json['id'] as String,
        text: json['text'] as String,
        startMs: (json['startMs'] as num).toInt(),
        endMs: (json['endMs'] as num).toInt(),
        x: (json['x'] as num?)?.toDouble() ?? 0.5,
        y: (json['y'] as num?)?.toDouble() ?? 0.8,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 28,
        colorHex: (json['colorHex'] as num?)?.toInt() ?? 0xFFFFFFFF,
      );
}

class TextOverlayAdapter extends TypeAdapter<TextOverlay> {
  @override
  final int typeId = 2;

  @override
  TextOverlay read(BinaryReader reader) =>
      TextOverlay.fromJson(Map<String, dynamic>.from(reader.read() as Map));

  @override
  void write(BinaryWriter writer, TextOverlay obj) => writer.write(obj.toJson());
}
