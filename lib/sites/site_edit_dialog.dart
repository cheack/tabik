import 'dart:async';
import 'package:flutter/material.dart';
import 'site_config.dart';
import 'site_icon.dart';

Future<SiteConfig?> showSiteEditDialog(
  BuildContext context, {
  SiteConfig? existing,
  String? initialUrl,
}) {
  final labelCtrl = TextEditingController(text: existing?.label ?? '');
  final urlCtrl = TextEditingController(
    text: existing?.url ?? initialUrl ?? '',
  );
  IconData selectedIcon = existing?.icon ?? allIcons.first;
  String? faviconUrl = existing?.faviconUrl;
  bool useFavicon = existing?.faviconUrl != null;
  bool faviconLoading = false;
  Timer? debounce;

  void fetchFavicon(String url, void Function(void Function()) setDialogState) {
    debounce?.cancel();
    setDialogState(() {
      faviconLoading = url.isNotEmpty;
      faviconUrl = null;
    });
    if (url.isEmpty) return;
    debounce = Timer(const Duration(milliseconds: 800), () async {
      final resolved = await resolveFavicon(url);
      setDialogState(() {
        faviconUrl = resolved;
        faviconLoading = false;
      });
    });
  }

  return showDialog<SiteConfig>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Добавить сайт' : 'Изменить сайт'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
                onChanged: useFavicon
                    ? (v) => fetchFavicon(v, setDialogState)
                    : null,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Иконка',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Авто')),
                  ButtonSegment(value: false, label: Text('Из списка')),
                ],
                selected: {useFavicon},
                onSelectionChanged: (s) {
                  useFavicon = s.first;
                  if (useFavicon && faviconUrl == null) {
                    fetchFavicon(urlCtrl.text, setDialogState);
                  }
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 12),
              if (useFavicon)
                SizedBox(
                  height: 40,
                  child: faviconLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : faviconUrl != null
                      ? Image.network(
                          faviconUrl!,
                          width: 40,
                          height: 40,
                          errorBuilder: (_, e, s) =>
                              const Icon(Icons.broken_image, size: 40),
                        )
                      : const Text(
                          'Введите URL',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                )
              else
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allIcons.map((icon) {
                        final selected = icon == selectedIcon;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Colors.grey.shade600,
                              ),
                            ),
                            child: Icon(
                              icon,
                              size: 24,
                              color: selected ? Colors.white : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debounce?.cancel();
              Navigator.pop(ctx);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final label = labelCtrl.text.trim();
              final url = urlCtrl.text.trim();
              if (label.isEmpty || url.isEmpty) return;
              debounce?.cancel();
              Navigator.pop(
                ctx,
                SiteConfig(
                  label: label,
                  url: url,
                  icon: selectedIcon,
                  faviconUrl: useFavicon ? faviconUrl : null,
                ),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ),
  );
}
