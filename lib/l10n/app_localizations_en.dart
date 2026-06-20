// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get next => 'Next';

  @override
  String get nameLabel => 'Name';

  @override
  String get menu => 'Menu';

  @override
  String get settings => 'Settings';

  @override
  String get categories => 'Categories';

  @override
  String get category => 'Category';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeDark => 'Dark';

  @override
  String get addCategory => 'Add category';

  @override
  String get newCategory => 'New category';

  @override
  String get rename => 'Rename';

  @override
  String get noCategories => 'No categories';

  @override
  String get addSite => 'Add site';

  @override
  String get editSiteTitle => 'Edit site';

  @override
  String get noSitesInCategory => 'No sites in this category';

  @override
  String get selectCategory => 'Select category';

  @override
  String get icon => 'Icon';

  @override
  String get siteIcon => 'Site icon';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get language => 'Language';

  @override
  String get languageRu => 'Русский';

  @override
  String get languageEn => 'English';

  @override
  String editSite(String name) {
    return 'Edit \"$name\"';
  }

  @override
  String deleteSite(String name) {
    return 'Delete \"$name\"';
  }

  @override
  String deleteSiteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String deleteCategoryConfirm(String name) {
    return 'Delete category \"$name\"?';
  }

  @override
  String sitesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites',
      one: '$count site',
    );
    return '$_temp0';
  }
}
