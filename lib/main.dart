import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:glass_video_editor/app.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/project.dart';
import 'package:glass_video_editor/core/models/text_overlay.dart';
import 'package:glass_video_editor/features/projects/projects_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(ClipAdapter());
  Hive.registerAdapter(TextOverlayAdapter());
  await Hive.openBox<Project>(projectsBoxName);
  runApp(const ProviderScope(child: GlassApp()));
}
