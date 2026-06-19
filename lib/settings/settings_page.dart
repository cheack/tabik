import 'package:flutter/material.dart';
import '../sites/site_config.dart';
import '../sites/site_edit_dialog.dart';
import '../sites/site_icon.dart';

class SettingsPage extends StatefulWidget {
  final List<CategoryConfig> categories;
  final void Function(List<CategoryConfig>) onSave;
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChanged;

  const SettingsPage({
    super.key,
    required this.categories,
    required this.onSave,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<CategoryConfig> _categories;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories
        .map((c) => c.copyWith(sites: List.of(c.sites)))
        .toList();
  }

  void _addCategory() async {
    final name = await _showNameDialog('Новая категория', '');
    if (name != null && name.isNotEmpty) {
      setState(() => _categories.add(CategoryConfig(label: name, sites: [])));
    }
  }

  void _renameCategory(int index) async {
    final name = await _showNameDialog(
      'Переименовать',
      _categories[index].label,
    );
    if (name != null && name.isNotEmpty) {
      setState(
        () => _categories[index] = _categories[index].copyWith(label: name),
      );
    }
  }

  void _deleteCategory(int index) async {
    final ok = await _confirm(
      'Удалить категорию «${_categories[index].label}»?',
    );
    if (ok) setState(() => _categories.removeAt(index));
  }

  Future<String?> _showNameDialog(String title, String initial) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
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
    return ok == true;
  }

  void _openSites(int categoryIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SitesPage(
          categoryLabel: _categories[categoryIndex].label,
          sites: _categories[categoryIndex].sites,
          onSave: (newSites) {
            setState(() {
              _categories[categoryIndex] = _categories[categoryIndex].copyWith(
                sites: newSites,
              );
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.onSave(_categories);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Настройки'), actions: []),
        body: ReorderableListView(
          buildDefaultDragHandles: false,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Тема',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Светлая'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('Авто'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Тёмная'),
                    ),
                  ],
                  selected: {widget.themeMode},
                  onSelectionChanged: (s) => widget.onThemeChanged(s.first),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Категории',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              final item = _categories.removeAt(oldIndex);
              _categories.insert(newIndex, item);
            });
          },
          children: [
            for (int i = 0; i < _categories.length; i++)
              ListTile(
                key: ValueKey(i),
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(_categories[i].label),
                subtitle: Text('${_categories[i].sites.length} вкладок'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _renameCategory(i),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _deleteCategory(i),
                    ),
                  ],
                ),
                onTap: () => _openSites(i),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addCategory,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _SitesPage extends StatefulWidget {
  final String categoryLabel;
  final List<SiteConfig> sites;
  final void Function(List<SiteConfig>) onSave;

  const _SitesPage({
    required this.categoryLabel,
    required this.sites,
    required this.onSave,
  });

  @override
  State<_SitesPage> createState() => _SitesPageState();
}

class _SitesPageState extends State<_SitesPage> {
  late List<SiteConfig> _sites;

  @override
  void initState() {
    super.initState();
    _sites = List.of(widget.sites);
  }

  void _showEditDialog({SiteConfig? existing, int? index}) async {
    final site = await showSiteEditDialog(context, existing: existing);
    if (site == null) return;
    setState(() {
      if (index != null) {
        _sites[index] = site;
      } else {
        _sites.add(site);
      }
    });
  }

  Future<bool> _confirmDelete(String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text('Удалить «$label»?'),
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
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.onSave(_sites);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.categoryLabel)),
        body: ReorderableListView(
          buildDefaultDragHandles: false,
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              final item = _sites.removeAt(oldIndex);
              _sites.insert(newIndex, item);
            });
          },
          children: [
            for (int i = 0; i < _sites.length; i++)
              ListTile(
                key: ValueKey(i),
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(_sites[i].label),
                subtitle: Text(
                  _sites[i].url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SiteIcon(site: _sites[i]),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          _showEditDialog(existing: _sites[i], index: i),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () async {
                        if (await _confirmDelete(_sites[i].label)) {
                          setState(() => _sites.removeAt(i));
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showEditDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
