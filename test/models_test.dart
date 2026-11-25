import 'package:flutter_test/flutter_test.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/project.dart';
import 'package:glass_video_editor/core/models/text_overlay.dart';

void main() {
  group('Clip JSON roundtrip', () {
    test('preserves all fields', () {
      final clip = Clip(
        id: 'c1',
        path: '/tmp/a.mp4',
        durationMs: 5000,
        trimStartMs: 500,
        trimEndMs: 4500,
        speed: 2.0,
        volume: 0.5,
      );
      final restored = Clip.fromJson(clip.toJson());
      expect(restored.id, clip.id);
      expect(restored.path, clip.path);
      expect(restored.durationMs, 5000);
      expect(restored.trimStartMs, 500);
      expect(restored.trimEndMs, 4500);
      expect(restored.speed, 2.0);
      expect(restored.volume, 0.5);
      expect(restored.effectiveDurationMs, 2000);
    });

    test('transition and filter roundtrip + hasAdvancedOps', () {
      final clip = Clip(
        id: 'c2',
        path: '/tmp/b.mp4',
        durationMs: 2000,
        speed: 2.0,
        transition: 'fade',
        filter: 'warm',
      );
      final restored = Clip.fromJson(clip.toJson());
      expect(restored.transition, 'fade');
      expect(restored.filter, 'warm');
      expect(restored.hasAdvancedOps, isTrue);
      expect(Clip(id: 'c3', path: '/x', durationMs: 1).hasAdvancedOps, isFalse);
    });

    test('defaults for missing fields', () {
      final clip = Clip.fromJson({'id': 'x', 'path': '/p', 'durationMs': 1000});
      expect(clip.trimStartMs, 0);
      expect(clip.trimEndMs, 0);
      expect(clip.speed, 1.0);
      expect(clip.volume, 1.0);
    });
  });

  group('Project JSON roundtrip', () {
    test('with clips and overlays', () {
      final project = Project(
        id: 'p1',
        name: 'Demo',
        createdAt: DateTime(2025, 1, 1),
        clips: [Clip(id: 'c1', path: '/a.mp4', durationMs: 3000)],
        overlays: [
          TextOverlay(id: 't1', text: 'Hello', startMs: 0, endMs: 1000),
        ],
      );
      final restored = Project.fromJson(project.toJson());
      expect(restored.clips.length, 1);
      expect(restored.clips.first.id, 'c1');
      expect(restored.overlays.first.text, 'Hello');
      expect(restored.totalDurationMs, 3000);
      expect(restored.exportWidth, 1080);
    });
  });

  group('TextOverlay visibility', () {
    test('isVisibleAt boundaries', () {
      final o = TextOverlay(id: 't', text: 'x', startMs: 100, endMs: 200);
      expect(o.isVisibleAt(100), isTrue);
      expect(o.isVisibleAt(200), isTrue);
      expect(o.isVisibleAt(99), isFalse);
      expect(o.isVisibleAt(201), isFalse);
    });
  });
}
