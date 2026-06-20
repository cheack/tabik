import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tabik/l10n/app_localizations.dart';

import '../sites/site_config.dart';
import '../sites/site_icon.dart';

class BottomBar extends StatelessWidget {
  final List<SiteConfig> sites;
  final int selectedIndex;
  final void Function(int) onTap;
  final void Function(int, Offset) onLongPress;

  const BottomBar({
    super.key,
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
                          isSite
                              ? site.label
                              : AppLocalizations.of(context)!.menu,
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
