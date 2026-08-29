// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Compound';

  @override
  String get historyTitle => 'Deine Berechnungen';

  @override
  String get newCalculation => 'Neue Berechnung';

  @override
  String get emptyTitle => 'Noch nichts vorhanden';

  @override
  String get emptyBody =>
      'Starte deine erste Hochrechnung und sieh, was der Zinseszins bewirkt.';

  @override
  String get startingAmount => 'Startbetrag';

  @override
  String get monthlyContribution => 'Monatliche Sparrate';

  @override
  String get annualReturn => 'Jährliche Rendite';

  @override
  String get timeHorizon => 'Anlagehorizont';

  @override
  String yearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jahre',
      one: '1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String get advanced => 'Erweitert';

  @override
  String get advancedSubtitle => 'Gebühren und Steuern';

  @override
  String get managementFee => 'Jährliche Verwaltungsgebühr';

  @override
  String get capitalGainsTax => 'Kapitalertragsteuer';

  @override
  String get optional => 'Optional';

  @override
  String get calculate => 'Berechnen';

  @override
  String get results => 'Ergebnis';

  @override
  String youWouldHave(String years) {
    return 'Nach $years hättest du';
  }

  @override
  String get totalDeposited => 'Eingezahlt insgesamt';

  @override
  String get interestEarned => 'Erwirtschaftete Erträge';

  @override
  String get feesPaid => 'Gezahlte Gebühren';

  @override
  String get taxPaid => 'Gezahlte Steuern';

  @override
  String get netProfit => 'Nettogewinn';

  @override
  String get growthOverTime => 'Entwicklung über die Zeit';

  @override
  String get legendBalance => 'Guthaben';

  @override
  String get legendDeposited => 'Eingezahlt';

  @override
  String get save => 'Speichern';

  @override
  String get savedToHistory => 'In deinen Berechnungen gespeichert';

  @override
  String get delete => 'Löschen';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get undo => 'Rückgängig';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get clearAllTitle => 'Alle Berechnungen löschen?';

  @override
  String get clearAllBody =>
      'Dadurch werden alle gespeicherten Berechnungen entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get disclaimer =>
      'Nur Schätzungen auf Basis einer konstanten Rendite. Keine Anlageberatung.';

  @override
  String get checkYourNumbers => 'Bitte Eingaben prüfen';

  @override
  String yearShort(int count) {
    return 'J$count';
  }

  @override
  String get perYear => 'pro Jahr';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get systemDefault => 'System';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get currency => 'Währung';

  @override
  String get adPrivacy => 'Anzeigen-Datenschutz';

  @override
  String get removeAds => 'Werbung entfernen';

  @override
  String get removeAdsBody => 'Einmal zahlen. Die Werbung ist dauerhaft weg.';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get purchaseThanks => 'Danke. Die Werbung ist weg.';

  @override
  String get purchaseFailed => 'Der Kauf konnte nicht abgeschlossen werden.';

  @override
  String get nothingToRestore =>
      'Kein früherer Kauf für dieses Konto gefunden.';

  @override
  String get adsRemovedTitle => 'Werbung entfernt';
}
