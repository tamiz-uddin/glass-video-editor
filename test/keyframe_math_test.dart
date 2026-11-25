import 'package:flutter_test/flutter_test.dart';
import 'package:glass_video_editor/core/models/keyframe.dart';
import 'package:glass_video_editor/features/editor/keyframe_math.dart';

void main() {
  group('transformAt', () {
    test('empty keyframes returns identity', () {
      final t = transformAt(const [], 0.5);
      expect(t.zoom, 1.0);
      expect(t.opacity, 1.0);
    });

    test('single keyframe applies everywhere', () {
      final t = transformAt(const [Keyframe(t: 0, zoom: 2)], 0.7);
      expect(t.zoom, 2.0);
    });

    test('interpolates between two keyframes', () {
      final kfs = const [
        Keyframe(t: 0, zoom: 1, panX: 0),
        Keyframe(t: 1, zoom: 3, panX: 10),
      ];
      final mid = transformAt(kfs, 0.5);
      expect(mid.zoom, closeTo(2.0, 1e-9));
      expect(mid.panX, closeTo(5.0, 1e-9));
    });

    test('clamps outside range', () {
      final kfs = const [
        Keyframe(t: 0.2, zoom: 1),
        Keyframe(t: 0.8, zoom: 2),
      ];
      expect(transformAt(kfs, 0.0).zoom, 1.0);
      expect(transformAt(kfs, 1.0).zoom, 2.0);
    });

    test('unsorted input is sorted', () {
      final kfs = const [
        Keyframe(t: 1, zoom: 3),
        Keyframe(t: 0, zoom: 1),
      ];
      expect(transformAt(kfs, 0.5).zoom, closeTo(2.0, 1e-9));
    });
  });
}
