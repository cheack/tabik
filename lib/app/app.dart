import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tabik/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_page.dart';

class TabikApp extends StatefulWidget {
  const TabikApp({super.key});

  @override
  State<TabikApp> createState() => _TabikAppState();
}

class _TabikAppState extends State<TabikApp> {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_themeKey);
    final locale = prefs.getString(_localeKey);
    setState(() {
      if (theme != null) _themeMode = _parseTheme(theme);
      _locale = _parseLocale(locale);
    });
  }

  Future<void> _setTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> _setLocale(Locale? locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }

  ThemeMode _parseTheme(String value) => switch (value) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.system,
  };

  Locale? _parseLocale(String? value) => switch (value) {
    'ru' => const Locale('ru'),
    'en' => const Locale('en'),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tabik',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru'), Locale('en')],
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      locale: _locale,
      home: HomePage(
        themeMode: _themeMode,
        onThemeChanged: _setTheme,
        locale: _locale,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}
