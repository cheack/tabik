import 'dart:io';
import 'package:flutter/material.dart';
import 'site_config.dart';

Future<String?> resolveFavicon(String siteUrl) async {
  try {
    final raw = siteUrl.startsWith('http') ? siteUrl : 'https://$siteUrl';
    final uri = Uri.parse(raw);
    final base = '${uri.scheme}://${uri.host}';
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

    try {
      final req = await client.headUrl(Uri.parse('$base/favicon.ico'));
      final resp = await req.close();
      await resp.drain<void>();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        client.close();
        return '$base/favicon.ico';
      }
    } catch (_) {}

    try {
      final req = await client.getUrl(uri);
      final resp = await req.close();
      final bytes = <int>[];
      await for (final chunk in resp) {
        bytes.addAll(chunk);
        if (bytes.length >= 8192) break;
      }
      await resp.drain<void>();
      final html = String.fromCharCodes(bytes);
      for (final pattern in [
        RegExp(
          r'''<link[^>]+rel=["'](?:shortcut )?icon["'][^>]*href=["']([^"']+)["']''',
          caseSensitive: false,
        ),
        RegExp(
          r'''<link[^>]+href=["']([^"']+)["'][^>]*rel=["'](?:shortcut )?icon["']''',
          caseSensitive: false,
        ),
      ]) {
        final m = pattern.firstMatch(html);
        if (m != null) {
          final href = m.group(1)!;
          client.close();
          if (href.startsWith('http')) return href;
          if (href.startsWith('//')) return '${uri.scheme}:$href';
          if (href.startsWith('/')) return '$base$href';
          return '$base/$href';
        }
      }
    } catch (_) {}

    client.close();
  } catch (_) {}
  return null;
}

class SiteIcon extends StatelessWidget {
  final SiteConfig site;
  final double size;

  const SiteIcon({super.key, required this.site, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final url = site.faviconUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        errorBuilder: (_, e, s) => Icon(site.icon, size: size),
      );
    }
    return Icon(site.icon, size: size);
  }
}
