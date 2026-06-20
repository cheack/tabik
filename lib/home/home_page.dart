import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tabik/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'bottom_bar.dart';
import 'site_index.dart';
import '../settings/settings_page.dart';
import '../sites/site_config.dart';
import '../sites/site_edit_dialog.dart';
import '../storage/category_storage.dart';

class HomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChanged;
  final Locale? locale;
  final void Function(Locale?) onLocaleChanged;

  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.locale,
    required this.onLocaleChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';
  static const _shareChannel = MethodChannel('net.cheack.tabik/share');

  final _storage = CategoryStorage();

  List<CategoryConfig> _categories = [];
  bool _categoriesLoaded = false;
  int _categoryIndex = 0;
  int _siteIndex = 0;

  List<WebViewController> _controllers = [];
  List<bool> _loading = [];
  DateTime? _lastBackPress;

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
    final l = AppLocalizations.of(context)!;
    int selectedCategory = _categoryIndex;

    final cat = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int picked = selectedCategory;
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: Text(l.category),
            content: DropdownButtonFormField<int>(
              initialValue: picked,
              decoration: InputDecoration(labelText: l.category),
              items: [
                for (int i = 0; i < _categories.length; i++)
                  DropdownMenuItem(value: i, child: Text(_categories[i].label)),
              ],
              onChanged: (v) => setSt(() => picked = v!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, picked),
                child: Text(l.next),
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
        _controllers.add(_createController(site.url, _controllers.length));
        _loading.add(true);
      }
    });
    _saveCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _storage.loadCategories();
    _applyCategories(cats, categoryIndex: 0);
    _checkPendingShare();
  }

  Future<void> _saveCategories() => _storage.saveCategories(_categories);

  void _applyCategories(List<CategoryConfig> cats, {int categoryIndex = 0}) {
    setState(() {
      _categories = cats;
      _categoriesLoaded = true;
      _categoryIndex = cats.isEmpty
          ? 0
          : categoryIndex.clamp(0, cats.length - 1);
      _siteIndex = 0;
    });
    _buildControllers();
  }

  WebViewController _createController(String url, int index) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_mobileUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _setLoading(index, true),
          onPageFinished: (_) => _setLoading(index, false),
          onWebResourceError: (_) => _setLoading(index, false),
        ),
      )
      ..loadRequest(_parseUrl(url));
  }

  void _buildControllers({int siteIndex = 0}) {
    if (_categories.isEmpty) {
      setState(() {
        _controllers = [];
        _loading = [];
        _siteIndex = 0;
      });
      return;
    }
    final sites = _categories[_categoryIndex].sites;
    final loading = List.filled(sites.length, true);
    final controllers = <WebViewController>[];

    for (var i = 0; i < sites.length; i++) {
      controllers.add(_createController(sites[i].url, i));
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
    final l = AppLocalizations.of(context)!;
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
              Text(l.editSite(site.label)),
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
                l.deleteSite(site.label),
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
          content: Text(l.deleteSiteConfirm(site.label)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete),
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

  Future<void> _onBackPressed() async {
    if (_controllers.isNotEmpty && _siteIndex < _controllers.length) {
      if (await _controllers[_siteIndex].canGoBack()) {
        await _controllers[_siteIndex].goBack();
        return;
      }
    }
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pressBackAgainToExit),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openSettings({
    bool addCategoryOnOpen = false,
    int? openCategoryIndex,
    bool addSiteOnOpen = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          categories: _categories,
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
          locale: widget.locale,
          onLocaleChanged: widget.onLocaleChanged,
          addCategoryOnOpen: addCategoryOnOpen,
          openCategoryIndex: openCategoryIndex,
          addSiteOnOpen: addSiteOnOpen,
          onSave: (newCats) {
            _applyCategories(newCats, categoryIndex: _categoryIndex);
            _saveCategories();
          },
        ),
      ),
    );
  }

  void _showMenu() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l.categories,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
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
                title: Text(l.settings),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (!_categoriesLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_categories.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers_clear, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(l.noCategories, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _openSettings(addCategoryOnOpen: true),
                icon: const Icon(Icons.add),
                label: Text(l.addCategory),
              ),
            ],
          ),
        ),
      );
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
              Text(
                l.noSitesInCategory,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _openSettings(
                  openCategoryIndex: _categoryIndex,
                  addSiteOnOpen: true,
                ),
                icon: const Icon(Icons.add),
                label: Text(l.addSite),
              ),
              if (_categories.length > 1) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showMenu,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(l.selectCategory),
                ),
              ],
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
      bottomNavigationBar: BottomBar(
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
