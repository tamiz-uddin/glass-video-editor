import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:glass_video_editor/app.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/models/project.dart';
import 'package:glass_video_editor/core/models/text_overlay.dart';
import 'package:glass_video_editor/features/projects/projects_provider.dart';

const enableFirebase = bool.fromEnvironment('ENABLE_FIREBASE', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (enableFirebase) {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  await Hive.initFlutter();
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(ClipAdapter());
  Hive.registerAdapter(TextOverlayAdapter());
  await Hive.openBox<Project>(projectsBoxName);
  await Hive.openBox('settings');
  runApp(const ProviderScope(child: GlassApp()));
}
