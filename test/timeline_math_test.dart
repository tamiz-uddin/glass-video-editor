import 'package:flutter_test/flutter_test.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/features/editor/timeline_math.dart';

Clip clip({
  String id = 'a',
  int durationMs = 10000,
  int trimStartMs = 0,
  int trimEndMs = 0,
  double speed = 1.0,
}) =>
    Clip(
      id: id,
      path: '/tmp/$id.mp4',
      durationMs: durationMs,
      trimStartMs: trimStartMs,
      trimEndMs: trimEndMs,
      speed: speed,
    );

void main() {
  group('effective duration', () {
    test('full clip at 1x', () {
      expect(clip().effectiveDurationMs, 10000);
    });

    test('trimmed clip', () {
      expect(clip(trimStartMs: 2000, trimEndMs: 8000).effectiveDurationMs, 6000);
    });

    test('speed 2x halves duration', () {
      expect(clip(speed: 2).effectiveDurationMs, 5000);
    });

    test('trim + speed combined', () {
      expect(clip(trimStartMs: 1000, trimEndMs: 9000, speed: 2).effectiveDurationMs, 4000);
    });
  });

  group('clampTrim', () {
    test('clamps start to >= 0', () {
      final c = clampTrim(clip(), -500, 5000);
      expect(c.trimStartMs, 0);
      expect(c.trimEndMs, 5000);
    });

    test('clamps end to duration and enforces min length', () {
      final c = clampTrim(clip(), 9900, 99999);
      expect(c.trimEndMs, 10000);
      expect(c.trimStartMs, 9900);
    });

    test('end cannot go below start + min', () {
      final c = clampTrim(clip(), 5000, 5050);
      expect(c.trimEndMs, 5100);
    });
  });

  group('splitClipInList', () {
    test('splits into two clips preserving total duration', () {
      final original = clip(durationMs: 10000);
      final result = splitClipInList([original], 'a', 4000);
      expect(result.length, 2);
      expect(result[0].effectiveDurationMs + result[1].effectiveDurationMs, 10000);
      expect(result[0].trimEndMs, 4000);
      expect(result[1].trimStartMs, 4000);
    });

    test('split accounts for speed', () {
      final original = clip(durationMs: 10000, speed: 2);
      final result = splitClipInList([original], 'a', 2000);
      expect(result[0].effectiveDurationMs, 2000);
      expect(result[1].effectiveDurationMs, 3000);
    });

    test('unknown id returns list unchanged', () {
      final list = [clip()];
      expect(splitClipInList(list, 'zzz', 1000), same(list));
    });
  });

  group('reorderClips', () {
    test('moves item from index to index', () {
      final list = [clip(id: 'a'), clip(id: 'b'), clip(id: 'c')];
      final result = reorderClips(list, 0, 2);
      expect(result.map((c) => c.id), ['b', 'c', 'a']);
    });
  });

  group('timeline positions', () {
    test('clipIndexAt and timelineStartOf are consistent', () {
      final list = [clip(id: 'a', durationMs: 4000), clip(id: 'b', durationMs: 6000)];
      expect(timelineStartOf(list, 'b'), 4000);
      expect(clipIndexAt(list, 0), 0);
      expect(clipIndexAt(list, 3999), 0);
      expect(clipIndexAt(list, 4000), 1);
      expect(clipIndexAt(list, 9999), 1);
      expect(totalDurationMs(list), 10000);
    });
  });

  group('speed and volume clamping', () {
    test('speed clamped to 0.1..100', () {
      expect(setSpeed(clip(), 0.01).speed, 0.1);
      expect(setSpeed(clip(), 500).speed, 100.0);
    });

    test('volume clamped to 0..1', () {
      expect(setVolume(clip(), -1).volume, 0.0);
      expect(setVolume(clip(), 5).volume, 1.0);
    });
  });
}
