import 'package:flutter/material.dart';
import 'package:glass_video_editor/core/l10n/strings.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/features/home/home_screen.dart';
import 'package:glass_video_editor/features/settings/settings_screen.dart';

class GlassApp extends StatefulWidget {
  const GlassApp({super.key});

  @override
  State<GlassApp> createState() => _GlassAppState();
}

class _GlassAppState extends State<GlassApp> {
  final _locale = ValueNotifier<Locale>(const Locale('en'));

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      notifier: _locale,
      child: ValueListenableBuilder<Locale>(
        valueListenable: _locale,
        builder: (context, locale, _) => MaterialApp(
          title: 'Glass Editor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          locale: locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [AppStringsDelegate()],
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
