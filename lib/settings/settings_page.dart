import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tabik/l10n/app_localizations.dart';
import '../sites/site_config.dart';
import '../sites/site_edit_dialog.dart';
import '../sites/site_icon.dart';

class SettingsPage extends StatefulWidget {
  final List<CategoryConfig> categories;
  final void Function(List<CategoryConfig>) onSave;
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChanged;
  final Locale? locale;
  final void Function(Locale?) onLocaleChanged;
  final bool addCategoryOnOpen;
  final int? openCategoryIndex;
  final bool addSiteOnOpen;

  const SettingsPage({
    super.key,
    required this.categories,
    required this.onSave,
    required this.themeMode,
    required this.onThemeChanged,
    required this.locale,
    required this.onLocaleChanged,
    this.addCategoryOnOpen = false,
    this.openCategoryIndex,
    this.addSiteOnOpen = false,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late List<CategoryConfig> _categories;
  late Locale? _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
    _categories = widget.categories
        .map((c) => c.copyWith(sites: List.of(c.sites)))
        .toList();
    if (widget.addCategoryOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _addCategory());
    } else if (widget.openCategoryIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openSites(
          widget.openCategoryIndex!,
          addSiteOnOpen: widget.addSiteOnOpen,
        ),
      );
    }
  }

  void _addCategory() async {
    final l = AppLocalizations.of(context)!;
    final name = await _showNameDialog(l.newCategory, '');
    if (name != null && name.isNotEmpty) {
      setState(() => _categories.add(CategoryConfig(label: name, sites: [])));
    }
  }

  void _renameCategory(int index) async {
    final l = AppLocalizations.of(context)!;
    final name = await _showNameDialog(l.rename, _categories[index].label);
    if (name != null && name.isNotEmpty) {
      setState(
        () => _categories[index] = _categories[index].copyWith(label: name),
      );
    }
  }

  void _deleteCategory(int index) async {
    final l = AppLocalizations.of(context)!;
    final ok = await _confirm(
      l.deleteCategoryConfirm(_categories[index].label),
    );
    if (ok) setState(() => _categories.removeAt(index));
  }

  Future<String?> _showNameDialog(String title, String initial) {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.nameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l.ok),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String message) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
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
    return ok == true;
  }

  Future<void> _exportSettings() async {
    final json = CategoryConfig.encodeList(_categories);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tabik_settings.json');
    await file.writeAsString(json);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _importSettings() async {
    final l = AppLocalizations.of(context)!;
    const typeGroup = XTypeGroup(label: 'JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    List<CategoryConfig> imported;
    try {
      imported = CategoryConfig.decodeList(await file.readAsString());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.importError)));
      }
      return;
    }

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.importConfirm(imported.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.ok),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      setState(() => _categories = imported);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.importSuccess(imported.length))));
    }
  }

  void _openSites(int categoryIndex, {bool addSiteOnOpen = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SitesPage(
          categoryLabel: _categories[categoryIndex].label,
          sites: _categories[categoryIndex].sites,
          addSiteOnOpen: addSiteOnOpen,
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
    final l = AppLocalizations.of(context)!;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.onSave(_categories);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.settings), actions: []),
        body: ReorderableListView(
          buildDefaultDragHandles: false,
          header: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.theme,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode),
                      label: Text(l.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(l.themeAuto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode),
                      label: Text(l.themeDark),
                    ),
                  ],
                  selected: {widget.themeMode},
                  onSelectionChanged: (s) => widget.onThemeChanged(s.first),
                ),
                const SizedBox(height: 16),
                Text(
                  l.language,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _locale?.languageCode ?? 'auto',
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'auto', child: Text(l.themeAuto)),
                    DropdownMenuItem(value: 'ru', child: Text(l.languageRu)),
                    DropdownMenuItem(value: 'en', child: Text(l.languageEn)),
                  ],
                  onChanged: (key) {
                    final locale = key == null || key == 'auto'
                        ? null
                        : Locale(key);
                    setState(() => _locale = locale);
                    widget.onLocaleChanged(locale);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l.categories,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
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
          footer: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add),
                    label: Text(l.addCategory),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _importSettings,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: Text(l.importSettings),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportSettings,
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(l.exportSettings),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            for (int i = 0; i < _categories.length; i++)
              ListTile(
                key: ValueKey(i),
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(_categories[i].label),
                subtitle: Text(l.sitesCount(_categories[i].sites.length)),
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
      ),
    );
  }
}

class _SitesPage extends StatefulWidget {
  final String categoryLabel;
  final List<SiteConfig> sites;
  final void Function(List<SiteConfig>) onSave;
  final bool addSiteOnOpen;

  const _SitesPage({
    required this.categoryLabel,
    required this.sites,
    required this.onSave,
    this.addSiteOnOpen = false,
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
    if (widget.addSiteOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEditDialog());
    }
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
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.deleteSiteConfirm(label)),
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
          footer: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () => _showEditDialog(),
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addSite),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
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
      ),
    );
  }
}
