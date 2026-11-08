import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

export 'app_localizations.dart';

AppLocalizations stringsForLanguage(String languageCode) =>
    languageCode == 'id' ? AppLocalizationsId() : AppLocalizationsEn();

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
