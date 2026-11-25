import 'package:flutter_test/flutter_test.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/features/templates/templates.dart';

Clip c(String id, int ms) => Clip(id: id, path: '/$id.mp4', durationMs: ms);

void main() {
  group('templates', () {
    test('transitionsForClips cycles and matches boundaries', () {
      const t = EditorTemplate(
        id: 'x',
        name: 'x',
        description: 'x',
        transitions: ['fade', 'zoom'],
      );
      expect(t.transitionsForClips(4), ['fade', 'zoom', 'fade']);
      expect(t.transitionsForClips(1), isEmpty);
    });

    test('applyTemplateToClips sets transition on all but last clip', () {
      final clips = [c('a', 1000), c('b', 1000), c('c', 1000)];
      final dynamicT = builtinTemplates.firstWhere((t) => t.id == 'dynamic');
      final result = applyTemplateToClips(clips, dynamicT);
      expect(result[0].transition, 'slideLeft');
      expect(result[1].transition, 'fade');
      expect(result[2].transition, 'none');
      expect(result.length, 3);
    });

    test('titleOverlay covers first 20% of timeline', () {
      const t = EditorTemplate(
        id: 'x',
        name: 'x',
        description: 'x',
        transitions: ['fade'],
        titleText: 'Hello',
      );
      final o = t.titleOverlay('ov', 10000);
      expect(o, isNotNull);
      expect(o!.text, 'Hello');
      expect(o.endMs, 2000);
    });

    test('builtin templates exist', () {
      expect(builtinTemplates.length, >=(3));
    });
  });
}
