// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'OK';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get next => 'Далее';

  @override
  String get nameLabel => 'Название';

  @override
  String get menu => 'Меню';

  @override
  String get settings => 'Настройки';

  @override
  String get categories => 'Категории';

  @override
  String get category => 'Категория';

  @override
  String get theme => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeAuto => 'Авто';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get addCategory => 'Добавить категорию';

  @override
  String get newCategory => 'Новая категория';

  @override
  String get rename => 'Переименовать';

  @override
  String get noCategories => 'Нет категорий';

  @override
  String get addSite => 'Добавить сайт';

  @override
  String get editSiteTitle => 'Изменить сайт';

  @override
  String get noSitesInCategory => 'Нет сайтов в этой категории';

  @override
  String get selectCategory => 'Выбрать категорию';

  @override
  String get icon => 'Иконка';

  @override
  String get siteIcon => 'Иконка сайта';

  @override
  String get pressBackAgainToExit => 'Нажмите ещё раз для выхода';

  @override
  String editSite(String name) {
    return 'Изменить «$name»';
  }

  @override
  String deleteSite(String name) {
    return 'Удалить «$name»';
  }

  @override
  String deleteSiteConfirm(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String deleteCategoryConfirm(String name) {
    return 'Удалить категорию «$name»?';
  }

  @override
  String sitesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сайтов',
      many: '$count сайтов',
      few: '$count сайта',
      one: '$count сайт',
    );
    return '$_temp0';
  }
}
