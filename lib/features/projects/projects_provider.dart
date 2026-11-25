import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/project.dart';

const projectsBoxName = 'projects';

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<Project>>((ref) {
  return ProjectsNotifier(Hive.box<Project>(projectsBoxName));
});

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier(this._box) : super(_box.values.toList());

  final Box<Project> _box;

  Future<Project> createProject(String name, {List<Clip> clips = const []}) async {
    final project = Project(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
      clips: clips,
    );
    await _box.put(project.id, project);
    state = _box.values.toList();
    return project;
  }

  Future<void> updateProject(Project project) async {
    await _box.put(project.id, project);
    state = _box.values.toList();
  }

  Future<void> deleteProject(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }
}
