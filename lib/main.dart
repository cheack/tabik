import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'site_config.dart';
import 'settings_page.dart';

void main() {
  runApp(const TabikApp());
}

class TabikApp extends StatefulWidget {
  const TabikApp({super.key});

  @override
  State<TabikApp> createState() => _TabikAppState();
}

class _TabikAppState extends State<TabikApp> {
  static const _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey);
    if (value != null) {
      setState(() => _themeMode = _parseTheme(value));
    }
  }

  Future<void> _setTheme(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  ThemeMode _parseTheme(String value) => switch (value) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tabik',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: HomePage(onThemeChanged: _setTheme, themeMode: _themeMode),
    );
  }
}

class HomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChanged;

  const HomePage({super.key, required this.themeMode, required this.onThemeChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _prefsKey = 'categories_v1';
  static const _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';

  List<CategoryConfig> _categories = [];
  int _categoryIndex = 0;
  int _siteIndex = 0;

  List<WebViewController> _controllers = [];
  List<bool> _loading = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    final cats = json != null ? CategoryConfig.decodeList(json) : defaultCategories;
    _applyCategories(cats, categoryIndex: 0);
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, CategoryConfig.encodeList(_categories));
  }

  void _applyCategories(List<CategoryConfig> cats, {int categoryIndex = 0}) {
    setState(() {
      _categories = cats;
      _categoryIndex = categoryIndex.clamp(0, cats.length - 1);
      _siteIndex = 0;
    });
    _buildControllers();
  }

  void _buildControllers() {
    final sites = _categories[_categoryIndex].sites;
    final loading = List.filled(sites.length, true);
    final controllers = <WebViewController>[];

    for (var i = 0; i < sites.length; i++) {
      final index = i;
      final ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(_mobileUserAgent)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) => _setLoading(index, true),
          onPageFinished: (_) => _setLoading(index, false),
          onWebResourceError: (_) => _setLoading(index, false),
        ))
        ..loadRequest(Uri.parse(sites[i].url));
      controllers.add(ctrl);
    }

    setState(() {
      _controllers = controllers;
      _loading = loading;
      _siteIndex = 0;
    });
  }

  void _setLoading(int index, bool value) {
    if (!mounted) return;
    setState(() {
      if (index < _loading.length) _loading[index] = value;
    });
  }

  void _switchCategory(int i) {
    if (i == _categoryIndex) return;
    setState(() {
      _categoryIndex = i;
      _siteIndex = 0;
    });
    _buildControllers();
  }

  Future<void> _refresh() async {
    final ctrl = _controllers[_siteIndex];
    final url = _categories[_categoryIndex].sites[_siteIndex].url;
    await ctrl.loadRequest(Uri.parse('about:blank'));
    await ctrl.loadRequest(Uri.parse(url));
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          categories: _categories,
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
          onSave: (newCats) {
            _applyCategories(newCats, categoryIndex: _categoryIndex);
            _saveCategories();
          },
        ),
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Категории',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: Icon(
                      i == _categoryIndex
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: i == _categoryIndex
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(_categories[i].label),
                    selected: i == _categoryIndex,
                    onTap: () {
                      Navigator.pop(ctx);
                      _switchCategory(i);
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Настройки'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openSettings();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_categories.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final sites = _categories[_categoryIndex].sites;
    final isLoading = _loading.isNotEmpty && _loading[_siteIndex];

    if (sites.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers_clear, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Нет вкладок в этой категории',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _showMenu,
                icon: const Icon(Icons.more_vert),
                label: const Text('Меню'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Stack(
        children: [
          IndexedStack(
            index: _siteIndex,
            children: _controllers
                .map((ctrl) => WebViewWidget(controller: ctrl))
                .toList(),
          ),
          if (isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _siteIndex,
        onDestinationSelected: (i) {
          if (i == sites.length) {
            _showMenu();
          } else if (i == _siteIndex) {
            _refresh();
          } else {
            setState(() => _siteIndex = i);
          }
        },
        destinations: [
          ...sites.map(
            (s) => NavigationDestination(
              icon: Icon(s.icon),
              label: s.label,
            ),
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_vert),
            label: 'Меню',
          ),
        ],
      ),
    );
  }
}
