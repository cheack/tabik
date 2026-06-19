import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'site_config.dart';
import 'site_icon.dart';
import 'site_edit_dialog.dart';
import 'settings_page.dart';

void main() {
  runApp(const TabikApp());
}

int siteIndexAfterRemoval(int removedIndex) =>
    removedIndex > 0 ? removedIndex - 1 : 0;

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

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _prefsKey = 'categories_v1';
  static const _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';
  static const _shareChannel = MethodChannel('net.cheack.tabik/share');

  List<CategoryConfig> _categories = [];
  int _categoryIndex = 0;
  int _siteIndex = 0;

  List<WebViewController> _controllers = [];
  List<bool> _loading = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'sharedUrl') {
        _handleSharedUrl(call.arguments as String?);
      }
    });
  }

  Future<void> _checkPendingShare() async {
    final url = await _shareChannel.invokeMethod<String>('getSharedUrl');
    if (url != null && url.isNotEmpty) _handleSharedUrl(url);
  }

  void _handleSharedUrl(String? url) {
    if (url == null || url.isEmpty || !mounted) return;
    _showAddFromShareDialog(url);
  }

  void _showAddFromShareDialog(String sharedUrl) async {
    if (_categories.isEmpty || !mounted) return;
    int selectedCategory = _categoryIndex;

    // Выбор категории поверх диалога сайта
    final cat = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int picked = selectedCategory;
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('Категория'),
            content: DropdownButtonFormField<int>(
              initialValue: picked,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: [
                for (int i = 0; i < _categories.length; i++)
                  DropdownMenuItem(value: i, child: Text(_categories[i].label)),
              ],
              onChanged: (v) => setSt(() => picked = v!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, picked),
                child: const Text('Далее'),
              ),
            ],
          ),
        );
      },
    );
    if (cat == null || !mounted) return;
    selectedCategory = cat;

    final site = await showSiteEditDialog(context, initialUrl: sharedUrl);
    if (site == null || !mounted) return;

    setState(() {
      _categories = List<CategoryConfig>.of(_categories);
      _categories[selectedCategory] = _categories[selectedCategory].copyWith(
        sites: [..._categories[selectedCategory].sites, site],
      );
      if (selectedCategory == _categoryIndex) {
        _controllers.add(
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setUserAgent(_mobileUserAgent)
            ..loadRequest(_parseUrl(site.url)),
        );
        _loading.add(true);
      }
    });
    _saveCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    final cats = json != null
        ? CategoryConfig.decodeList(json)
        : defaultCategories;
    _applyCategories(cats, categoryIndex: 0);
    _checkPendingShare();
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

  void _buildControllers({int siteIndex = 0}) {
    final sites = _categories[_categoryIndex].sites;
    final loading = List.filled(sites.length, true);
    final controllers = <WebViewController>[];

    for (var i = 0; i < sites.length; i++) {
      final index = i;
      final ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(_mobileUserAgent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => _setLoading(index, true),
            onPageFinished: (_) => _setLoading(index, false),
            onWebResourceError: (_) => _setLoading(index, false),
          ),
        )
        ..loadRequest(_parseUrl(sites[i].url));
      controllers.add(ctrl);
    }

    setState(() {
      _controllers = controllers;
      _loading = loading;
      _siteIndex = sites.isEmpty ? 0 : siteIndex.clamp(0, sites.length - 1);
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

  Uri _parseUrl(String url) {
    final uri = Uri.parse(url);
    return uri.hasScheme ? uri : Uri.parse('https://$url');
  }

  Future<void> _refresh() async {
    if (_controllers.isEmpty || _siteIndex >= _controllers.length) return;
    final ctrl = _controllers[_siteIndex];
    final url = _categories[_categoryIndex].sites[_siteIndex].url;
    await ctrl.loadRequest(Uri.parse('about:blank'));
    await ctrl.loadRequest(_parseUrl(url));
  }

  void _showSiteActions(int siteIndex, Offset position) async {
    final site = _categories[_categoryIndex].sites[siteIndex];
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final rect = RelativeRect.fromRect(
      Rect.fromCenter(center: position, width: 0, height: 0),
      Offset.zero & overlay.size,
    );

    final action = await showMenu<String>(
      context: context,
      position: rect,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 12),
              Text('Изменить «${site.label}»'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                'Удалить «${site.label}»',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );

    if (!mounted) return;

    if (action == 'edit') {
      final updated = await showSiteEditDialog(context, existing: site);
      if (updated == null || !mounted) return;
      var didUpdate = false;
      setState(() {
        final currentSites = _categories[_categoryIndex].sites;
        final currentIndex = currentSites.indexOf(site);
        if (currentIndex < 0) return;
        final newSites = List<SiteConfig>.of(currentSites);
        newSites[currentIndex] = updated;
        _categories = List<CategoryConfig>.of(_categories);
        _categories[_categoryIndex] = _categories[_categoryIndex].copyWith(
          sites: newSites,
        );
        _controllers[currentIndex].loadRequest(_parseUrl(updated.url));
        didUpdate = true;
      });
      if (didUpdate) _saveCategories();
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text('Удалить «${site.label}»?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      var didDelete = false;
      setState(() {
        final currentSites = _categories[_categoryIndex].sites;
        final currentIndex = currentSites.indexOf(site);
        if (currentIndex < 0) return;
        final newSites = List<SiteConfig>.of(currentSites)
          ..removeAt(currentIndex);
        _siteIndex = siteIndexAfterRemoval(currentIndex);
        _categories = List<CategoryConfig>.of(_categories);
        _categories[_categoryIndex] = _categories[_categoryIndex].copyWith(
          sites: newSites,
        );
        didDelete = true;
      });
      if (didDelete) {
        _buildControllers(siteIndex: _siteIndex);
        _saveCategories();
      }
    }
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
                child: Text(
                  'Категории',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
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
    if (sites.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers_clear, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Нет вкладок в этой категории',
                style: TextStyle(color: Colors.grey),
              ),
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

    final activeSiteIndex = _siteIndex.clamp(0, sites.length - 1);
    final activeControllerIndex = _controllers.isEmpty
        ? 0
        : activeSiteIndex.clamp(0, _controllers.length - 1);
    final isLoading =
        _loading.isNotEmpty &&
        activeControllerIndex < _loading.length &&
        _loading[activeControllerIndex];

    if (_siteIndex != activeSiteIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _siteIndex = activeSiteIndex);
      });
    }

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Stack(
        children: [
          IndexedStack(
            index: activeControllerIndex,
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
      bottomNavigationBar: _BottomBar(
        sites: sites,
        selectedIndex: activeSiteIndex,
        onTap: (i) {
          if (i == sites.length) {
            _showMenu();
          } else if (i == _siteIndex) {
            _refresh();
          } else {
            setState(() => _siteIndex = i);
          }
        },
        onLongPress: (i, pos) => _showSiteActions(i, pos),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final List<SiteConfig> sites;
  final int selectedIndex;
  final void Function(int) onTap;
  final void Function(int, Offset) onLongPress;

  const _BottomBar({
    required this.sites,
    required this.selectedIndex,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      ...sites.asMap().entries.map((e) => (e.key, e.value)),
      (sites.length, null),
    ];

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 12, color: colorScheme.onSurface),
        ),
      ),
      child: Container(
        color: colorScheme.surface,
        child: SafeArea(
          child: SizedBox(
            height: 80,
            child: Row(
              children: items.map((item) {
                final i = item.$1;
                final site = item.$2;
                final isSelected = i == selectedIndex;
                final isSite = site != null;
                return Expanded(
                  key: isSite ? ObjectKey(site) : const ValueKey('menu'),
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      TapGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            TapGestureRecognizer
                          >(
                            () => TapGestureRecognizer(),
                            (r) => r.onTap = () => onTap(i),
                          ),
                      if (isSite)
                        LongPressGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              LongPressGestureRecognizer
                            >(
                              () => LongPressGestureRecognizer(
                                duration: const Duration(milliseconds: 200),
                              ),
                              (r) => r.onLongPressStart = (d) {
                                HapticFeedback.mediumImpact();
                                onLongPress(i, d.globalPosition);
                              },
                            ),
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.secondaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: isSite
                              ? SiteIcon(site: site, size: 24)
                              : Icon(
                                  Icons.more_vert,
                                  size: 24,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSite ? site.label : 'Меню',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
