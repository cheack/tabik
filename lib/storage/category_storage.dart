import 'package:shared_preferences/shared_preferences.dart';

import '../sites/site_config.dart';

class CategoryStorage {
  static const _prefsKey = 'categories_v1';

  Future<List<CategoryConfig>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    return json != null ? CategoryConfig.decodeList(json) : defaultCategories;
  }

  Future<void> saveCategories(List<CategoryConfig> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, CategoryConfig.encodeList(categories));
  }
}
