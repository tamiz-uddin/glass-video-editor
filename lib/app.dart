import 'package:flutter/material.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/features/home/home_screen.dart';

class GlassApp extends StatelessWidget {
  const GlassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glass Editor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
