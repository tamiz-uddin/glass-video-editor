import 'package:flutter/material.dart';

class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('bn')];

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings) ?? AppStrings(const Locale('en'));
  }

  static const _en = {
    'appTitle': 'Glass Editor',
    'projects': 'Your projects',
    'emptyProjects': 'No projects yet. Tap + to create one.',
    'newProject': 'New project',
    'settings': 'Settings',
    'language': 'Language',
    'export': 'Export',
    'onboardTitle1': 'Edit like a pro',
    'onboardBody1': 'Multi-track timeline, glass-smooth UI, cinema-grade export.',
    'onboardTitle2': 'AI-powered tools',
    'onboardBody2': 'Auto captions, background removal, voiceover and more.',
    'onboardTitle3': 'Export anywhere',
    'onboardBody3': '720p to 4K, 24-60fps, share straight to social.',
    'getStarted': 'Get started',
  };

  static const _bn = {
    'appTitle': 'Glash Editor',
    'projects': 'Apnar project somuh',
    'emptyProjects': 'Ekhan o kono project nei. + tap kore notun banan.',
    'newProject': 'Notun project',
    'settings': 'Settings',
    'language': 'Bhasha',
    'export': 'Export',
    'onboardTitle1': 'Pro der moto edit korun',
    'onboardBody1': 'Multi-track timeline, glass-smooth UI, cinema-grade export.',
    'onboardTitle2': 'AI chuto tools',
    'onboardBody2': 'Auto captions, background remove, voiceover ar onek kichu.',
    'onboardTitle3': 'Jekono jaigai export',
    'onboardBody3': '720p theke 4K, 24-60fps, direct social e share.',
    'getStarted': 'Shuru korun',
  };

  String t(String key) {
    final map = locale.languageCode == 'bn' ? _bn : _en;
    return map[key] ?? _en[key] ?? key;
  }
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'bn'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant AppStringsDelegate old) => false;
}
