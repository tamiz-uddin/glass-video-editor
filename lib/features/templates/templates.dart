import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/text_overlay.dart';

class EditorTemplate {
  const EditorTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.transitions,
    this.titleText,
  });

  final String id;
  final String name;
  final String description;
  final List<String> transitions;
  final String? titleText;

  List<String> transitionsForClips(int clipCount) {
    final result = <String>[];
    for (var i = 0; i < clipCount - 1; i++) {
      result.add(transitions[i % transitions.length]);
    }
    return result;
  }

  TextOverlay? titleOverlay(String id, int totalDurationMs) {
    final text = titleText;
    if (text == null) return null;
    return TextOverlay(
      id: id,
      text: text,
      startMs: 0,
      endMs: (totalDurationMs * 0.2).round(),
      y: 0.2,
      fontSize: 36,
    );
  }
}

const builtinTemplates = <EditorTemplate>[
  EditorTemplate(
    id: 'plain',
    name: 'Plain cut',
    description: 'No transitions, straight cuts.',
    transitions: ['none'],
  ),
  EditorTemplate(
    id: 'smooth',
    name: 'Smooth fades',
    description: 'Crossfade between every clip.',
    transitions: ['fade'],
    titleText: 'My Story',
  ),
  EditorTemplate(
    id: 'dynamic',
    name: 'Dynamic',
    description: 'Alternating slides and fades.',
    transitions: ['slideLeft', 'fade', 'slideRight', 'zoom'],
  ),
  EditorTemplate(
    id: 'zoomstory',
    name: 'Zoom story',
    description: 'Zoom transitions with a title card.',
    transitions: ['zoom'],
    titleText: 'Watch this',
  ),
];

List<Clip> applyTemplateToClips(List<Clip> clips, EditorTemplate template) {
  final transitions = template.transitionsForClips(clips.length);
  return [
    for (var i = 0; i < clips.length; i++)
      clips[i].copyWith(transition: i < transitions.length ? transitions[i] : 'none'),
  ];
}
