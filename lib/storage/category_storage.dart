import 'package:shared_preferences/shared_preferences.dart';

import '../sites/site_config.dart';

class CategoryStorage {
  static const _prefsKey = 'categories_v1';
  static const _categoryIndexKey = 'last_category_index';
  static const _siteIndexKey = 'last_site_index';

  Future<List<CategoryConfig>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    return json != null ? CategoryConfig.decodeList(json) : defaultCategories;
  }

  Future<void> saveCategories(List<CategoryConfig> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, CategoryConfig.encodeList(categories));
  }

  Future<(int, int)> loadLastIndices() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getInt(_categoryIndexKey) ?? 0,
      prefs.getInt(_siteIndexKey) ?? 0,
    );
  }

  Future<void> saveLastIndices(int categoryIndex, int siteIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_categoryIndexKey, categoryIndex);
    await prefs.setInt(_siteIndexKey, siteIndex);
  }
}
