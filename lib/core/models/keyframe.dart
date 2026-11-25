class Keyframe {
  const Keyframe({
    required this.t,
    this.zoom = 1.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.opacity = 1.0,
  });

  final double t;
  final double zoom;
  final double panX;
  final double panY;
  final double opacity;

  Map<String, dynamic> toJson() => {
        't': t,
        'zoom': zoom,
        'panX': panX,
        'panY': panY,
        'opacity': opacity,
      };

  factory Keyframe.fromJson(Map<String, dynamic> json) => Keyframe(
        t: (json['t'] as num).toDouble(),
        zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
        panX: (json['panX'] as num?)?.toDouble() ?? 0.0,
        panY: (json['panY'] as num?)?.toDouble() ?? 0.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      );
}
