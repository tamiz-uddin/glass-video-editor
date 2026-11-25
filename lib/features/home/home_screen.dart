import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:glass_video_editor/core/l10n/strings.dart';
import 'package:glass_video_editor/core/models/clip.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/video/video_engine.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';
import 'package:glass_video_editor/features/editor/editor_screen.dart';
import 'package:glass_video_editor/features/onboarding/onboarding_screen.dart';
import 'package:glass_video_editor/features/projects/projects_provider.dart';
import 'package:glass_video_editor/features/settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _engine = VideoEngine();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seen = Hive.box('settings').get(onboardingSeenKey, defaultValue: false) as bool;
      if (!seen && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OnboardingScreen(onDone: () => Navigator.of(context).pop()),
          ),
        );
      }
    });
  }

  Future<void> _newProject() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    final paths = result?.files.map((f) => f.path).whereType<String>().toList() ?? [];
    if (paths.isEmpty) return;

    final clips = <Clip>[];
    for (final path in paths) {
      final durationMs = await _engine.probeDurationMs(path) ?? 0;
      clips.add(Clip(id: const Uuid().v4(), path: path, durationMs: durationMs));
    }
    final now = DateTime.now();
    final project = await ref.read(projectsProvider.notifier).createProject(
          'Project ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          clips: clips,
        );

    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondary) => EditorScreen(projectId: project.id),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: 350.ms,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppStrings.of(context).t('appTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [Color(0x338B5CF6), Colors.transparent],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.of(context).t('projects'), style: Theme.of(context).textTheme.displayLarge)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                  Expanded(
                    child: projects.isEmpty
                        ? Center(
                            child: Text(
                              AppStrings.of(context).t('emptyProjects'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.separated(
                            itemCount: projects.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final project = projects[index];
                              return GlassPanel(
                                blur: 20,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      gradient: AppColors.accentGradient,
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                    child: const Icon(Icons.movie_outlined, color: Colors.white),
                                  ),
                                  title: Text(project.name, style: Theme.of(context).textTheme.titleLarge),
                                  subtitle: Text(
                                    '${project.clips.length} clip(s) • ${project.totalDurationMs ~/ 1000}s • ${project.createdAt.toIso8601String().substring(0, 10)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                                    onPressed: () => ref
                                        .read(projectsProvider.notifier)
                                        .deleteProject(project.id),
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EditorScreen(projectId: project.id),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(duration: 300.ms, delay: (index * 60).ms).slideX(begin: 0.1, end: 0);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newProject,
        icon: const Icon(Icons.add),
        label: const Text('New project'),
        backgroundColor: AppColors.accentViolet,
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }
}
