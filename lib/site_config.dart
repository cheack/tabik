import 'dart:convert';
import 'package:flutter/material.dart';

const _icons = [
  // weather
  Icons.wb_sunny,
  Icons.wb_cloudy,
  Icons.thunderstorm,
  Icons.water_drop,
  Icons.air,
  Icons.thermostat,
  // navigation & maps
  Icons.map,
  Icons.navigation,
  Icons.satellite_alt,
  Icons.place,
  Icons.directions_car,
  Icons.train,
  // web & search
  Icons.language,
  Icons.public,
  Icons.search,
  Icons.travel_explore,
  // news & media
  Icons.newspaper,
  Icons.feed,
  Icons.tv,
  Icons.radio,
  Icons.movie,
  Icons.music_note,
  Icons.headphones,
  Icons.podcasts,
  // social
  Icons.people,
  Icons.chat_bubble,
  Icons.forum,
  Icons.share,
  Icons.thumb_up,
  // shopping & finance
  Icons.shopping_cart,
  Icons.storefront,
  Icons.local_offer,
  Icons.payments,
  Icons.account_balance,
  Icons.trending_up,
  Icons.currency_bitcoin,
  // work & productivity
  Icons.work,
  Icons.email,
  Icons.calendar_month,
  Icons.task_alt,
  Icons.folder,
  Icons.description,
  Icons.code,
  Icons.terminal,
  Icons.cloud_upload,
  // health & lifestyle
  Icons.favorite,
  Icons.fitness_center,
  Icons.restaurant,
  Icons.local_cafe,
  Icons.sports_esports,
  Icons.sports_soccer,
  Icons.book,
  Icons.school,
  Icons.science,
  // home & services
  Icons.home,
  Icons.apartment,
  Icons.local_hospital,
  Icons.local_pharmacy,
  Icons.directions_bus,
  Icons.flight,
  Icons.hotel,
  // misc
  Icons.bolt,
  Icons.cloud,
  Icons.star,
  Icons.settings,
  Icons.lock,
  Icons.photo_camera,
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
