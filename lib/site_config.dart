import 'dart:convert';
import 'package:flutter/material.dart';

const _icons = [
  Icons.wb_sunny,
  Icons.bolt,
  Icons.wb_cloudy,
  Icons.water_drop,
  Icons.map,
  Icons.search,
  Icons.cloud,
  Icons.thermostat,
  Icons.air,
  Icons.language,
  Icons.public,
  Icons.satellite_alt,
];

IconData iconByIndex(int index) => _icons[index % _icons.length];
int iconToIndex(IconData icon) {
  final i = _icons.indexOf(icon);
  return i < 0 ? 0 : i;
}

List<IconData> get allIcons => _icons;

class SiteConfig {
  final String label;
  final String url;
  final IconData icon;

  const SiteConfig({
    required this.label,
    required this.url,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'url': url,
        'iconIndex': iconToIndex(icon),
      };

  factory SiteConfig.fromJson(Map<String, dynamic> json) => SiteConfig(
        label: json['label'] as String,
        url: json['url'] as String,
        icon: iconByIndex(json['iconIndex'] as int? ?? 0),
      );
}

class CategoryConfig {
  final String label;
  final List<SiteConfig> sites;

  const CategoryConfig({required this.label, required this.sites});

  Map<String, dynamic> toJson() => {
        'label': label,
        'sites': sites.map((s) => s.toJson()).toList(),
      };

  factory CategoryConfig.fromJson(Map<String, dynamic> json) => CategoryConfig(
        label: json['label'] as String,
        sites: (json['sites'] as List)
            .map((e) => SiteConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  CategoryConfig copyWith({String? label, List<SiteConfig>? sites}) =>
      CategoryConfig(label: label ?? this.label, sites: sites ?? this.sites);

  static String encodeList(List<CategoryConfig> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<CategoryConfig> decodeList(String json) =>
      (jsonDecode(json) as List)
          .map((e) => CategoryConfig.fromJson(e as Map<String, dynamic>))
          .toList();
}

const List<CategoryConfig> defaultCategories = [
  CategoryConfig(label: 'Категория 1', sites: []),
];
