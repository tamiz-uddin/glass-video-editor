import 'package:flutter/material.dart';
import 'package:glass_video_editor/core/l10n/strings.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            blur: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language, color: AppColors.textPrimary),
              title: Text(strings.t('language'), style: const TextStyle(color: AppColors.textPrimary)),
              trailing: DropdownButton<Locale>(
                value: Localizations.localeOf(context),
                dropdownColor: AppColors.surface,
                underline: const SizedBox.shrink(),
                items: AppStrings.supportedLocales
                    .map((l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.languageCode == 'bn' ? 'বাংলা' : 'English',
                              style: const TextStyle(color: AppColors.textPrimary)),
                        ))
                    .toList(),
                onChanged: (locale) {
                  if (locale != null) LocaleScope.of(context)?.setLocale(locale);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassPanel(
            blur: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline, color: AppColors.textPrimary),
              title: Text('Glass Editor v1.0.0', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('Premium glassmorphism video editor (Android)',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

class LocaleScope extends InheritedNotifier<ValueNotifier<Locale>> {
  const LocaleScope({super.key, required super.child, required ValueNotifier<Locale> notifier})
      : super(notifier: notifier);

  static ValueNotifier<Locale>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;
}
