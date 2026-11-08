import '../l10n/localization.dart';

abstract final class BatteryEstimate {
  static const capacityMah = 1500.0;
  static const averageCurrentMa = 150.0;

  static Duration? runtime(int? percent) {
    if (percent == null || percent <= 0) return null;
    final hours =
        capacityMah * (percent.clamp(0, 100) / 100) / averageCurrentMa;
    return Duration(minutes: (hours * 60).round());
  }

  static String label(int? percent, {String languageCode = 'en'}) {
    final l10n = stringsForLanguage(languageCode);
    final duration = runtime(percent);
    if (duration == null) return l10n.notAvailableYet;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours == 0 ? l10n.hr : l10n.hrMin('$hours', '$minutes');
  }
}
