import 'package:glass_video_editor/core/models/keyframe.dart';

class KeyframeTransform {
  const KeyframeTransform({
    this.zoom = 1.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.opacity = 1.0,
  });

  final double zoom;
  final double panX;
  final double panY;
  final double opacity;
}

double _lerp(double a, double b, double f) => a + (b - a) * f;

KeyframeTransform transformAt(List<Keyframe> keyframes, double t) {
  if (keyframes.isEmpty) return const KeyframeTransform();
  final sorted = [...keyframes]..sort((a, b) => a.t.compareTo(b.t));
  final tc = t.clamp(0.0, 1.0);
  if (tc <= sorted.first.t) {
    final k = sorted.first;
    return KeyframeTransform(zoom: k.zoom, panX: k.panX, panY: k.panY, opacity: k.opacity);
  }
  if (tc >= sorted.last.t) {
    final k = sorted.last;
    return KeyframeTransform(zoom: k.zoom, panX: k.panX, panY: k.panY, opacity: k.opacity);
  }
  for (var i = 0; i < sorted.length - 1; i++) {
    final a = sorted[i];
    final b = sorted[i + 1];
    if (tc >= a.t && tc <= b.t) {
      final f = (b.t - a.t) == 0 ? 0.0 : (tc - a.t) / (b.t - a.t);
      return KeyframeTransform(
        zoom: _lerp(a.zoom, b.zoom, f),
        panX: _lerp(a.panX, b.panX, f),
        panY: _lerp(a.panY, b.panY, f),
        opacity: _lerp(a.opacity, b.opacity, f),
      );
    }
  }
  return const KeyframeTransform();
}
