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
      builder: (ctx, setDialogState) {
        final primary = Theme.of(ctx).colorScheme.primary;

        Widget currentIconWidget() {
          if (useFavicon) {
            if (faviconLoading) {
              return const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            if (faviconUrl != null && faviconUrl!.isNotEmpty) {
              return Image.network(
                faviconUrl!,
                width: 24,
                height: 24,
                errorBuilder: (_, e, s) =>
                    Icon(Icons.language, size: 24, color: primary),
              );
            }
            return Icon(Icons.language, size: 24, color: primary);
          }
          return Icon(selectedIcon, size: 24, color: primary);
        }

        return AlertDialog(
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
                  onChanged: (v) => fetchFavicon(v, setDialogState),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Иконка',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Builder(
                      builder: (btnCtx) => InkWell(
                        onTap: () async {
                          final box = btnCtx.findRenderObject()! as RenderBox;
                          final overlay =
                              Overlay.of(btnCtx).context.findRenderObject()!
                                  as RenderBox;
                          final rect = RelativeRect.fromRect(
                            box.localToGlobal(Offset.zero, ancestor: overlay) &
                                box.size,
                            Offset.zero & overlay.size,
                          );
                          final result = await showMenu<Object>(
                            context: btnCtx,
                            position: rect,
                            items: [
                              PopupMenuItem<Object>(
                                value: 'favicon',
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: SizedBox(
                                  width: 260,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: faviconLoading
                                            ? const CircularProgressIndicator(
                                                strokeWidth: 2,
                                              )
                                            : faviconUrl != null
                                            ? Image.network(
                                                faviconUrl!,
                                                errorBuilder: (_, e, s) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      size: 20,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.language,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Авто'),
                                      if (useFavicon) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Theme.of(
                                            btnCtx,
                                          ).colorScheme.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<Object>(
                                enabled: false,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: SizedBox(
                                  width: 260,
                                  child: GridView.count(
                                    crossAxisCount: 7,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: allIcons
                                        .map(
                                          (ic) => InkWell(
                                            onTap: () =>
                                                Navigator.pop(btnCtx, ic),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    !useFavicon &&
                                                        ic == selectedIcon
                                                    ? Theme.of(
                                                        btnCtx,
                                                      ).colorScheme.primary
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                ic,
                                                size: 20,
                                                color:
                                                    !useFavicon &&
                                                        ic == selectedIcon
                                                    ? Colors.white
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          );
                          if (result == 'favicon') {
                            setDialogState(() => useFavicon = true);
                          } else if (result is IconData) {
                            setDialogState(() {
                              useFavicon = false;
                              selectedIcon = result;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: currentIconWidget(),
                        ),
                      ),
                    ),
                  ],
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
                    faviconUrl: useFavicon ? (faviconUrl ?? '') : null,
                  ),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    ),
  );
}
