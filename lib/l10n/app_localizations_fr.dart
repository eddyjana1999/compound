// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Compound Lab';

  @override
  String get historyTitle => 'Vos calculs';

  @override
  String get newCalculation => 'Nouveau calcul';

  @override
  String get emptyTitle => 'Aucun calcul enregistré';

  @override
  String get emptyBody =>
      'Ce que votre argent accumule au fil des ans, et ce qu\'il en reste après frais et impôts.';

  @override
  String get startingAmount => 'Capital initial';

  @override
  String get monthlyContribution => 'Versement mensuel';

  @override
  String get annualReturn => 'Rendement annuel';

  @override
  String get timeHorizon => 'Horizon de placement';

  @override
  String yearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ans',
      one: '1 an',
    );
    return '$_temp0';
  }

  @override
  String get advanced => 'Avancé';

  @override
  String get advancedSubtitle => 'Frais et fiscalité';

  @override
  String get managementFee => 'Frais de gestion annuels';

  @override
  String get capitalGainsTax => 'Impôt sur les plus-values';

  @override
  String get optional => 'Facultatif';

  @override
  String get calculate => 'Calculer';

  @override
  String get results => 'Résultats';

  @override
  String youWouldHave(String years) {
    return 'Après $years, vous auriez';
  }

  @override
  String get totalDeposited => 'Total versé';

  @override
  String get interestEarned => 'Intérêts composés';

  @override
  String get feesPaid => 'Frais payés';

  @override
  String get taxPaid => 'Impôts payés';

  @override
  String get netProfit => 'Gain net';

  @override
  String get growthOverTime => 'Évolution du capital';

  @override
  String get legendBalance => 'Solde';

  @override
  String get legendDeposited => 'Capital versé';

  @override
  String get save => 'Enregistrer';

  @override
  String get savedToHistory => 'Enregistré dans vos calculs';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleted => 'Supprimé';

  @override
  String get undo => 'Annuler';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get clearAllTitle => 'Effacer tous les calculs ?';

  @override
  String get clearAllBody =>
      'Tous les calculs enregistrés seront supprimés. Action irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get disclaimer =>
      'Estimations basées sur un rendement constant. Ceci n\'est pas un conseil en investissement.';

  @override
  String get checkYourNumbers => 'Vérifiez vos données';

  @override
  String yearShort(int count) {
    return 'A$count';
  }

  @override
  String get perYear => 'par an';

  @override
  String get settings => 'Réglages';

  @override
  String get language => 'Langue';

  @override
  String get appearance => 'Apparence';

  @override
  String get systemDefault => 'Système';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get currency => 'Devise';

  @override
  String get adPrivacy => 'Confidentialité des annonces';

  @override
  String get removeAds => 'Supprimer les publicités';

  @override
  String get removeAdsBody =>
      'Un seul paiement. Les publicités disparaissent définitivement.';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get purchaseThanks => 'Merci. Les publicités ont disparu.';

  @override
  String get purchaseFailed => 'L\'achat n\'a pas pu être finalisé.';

  @override
  String get nothingToRestore => 'Aucun achat antérieur trouvé sur ce compte.';

  @override
  String get adsRemovedTitle => 'Publicités supprimées';

  @override
  String get addToFavourites => 'Ajouter aux favoris';

  @override
  String get removeFromFavourites => 'Retirer des favoris';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '1 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedTitle => 'Supprimer les calculs sélectionnés ?';

  @override
  String get select => 'Sélectionner';

  @override
  String get errNegativeAmount => 'Les montants ne peuvent pas être négatifs.';

  @override
  String get errHorizonTooShort => 'Choisissez au moins un an.';

  @override
  String get errHorizonTooLong => 'Choisissez 100 ans ou moins.';

  @override
  String get errReturnTooLow => 'Le rendement doit être supérieur à −100 %.';

  @override
  String get errFeeRange => 'Les frais doivent être entre 0 % et 100 %.';

  @override
  String get errTaxRange =>
      'Le taux d\'imposition doit être entre 0 % et 100 %.';

  @override
  String get errInflationRange => 'L\'inflation doit être entre 0 % et 100 %.';

  @override
  String get errGrowthRange =>
      'L\'augmentation annuelle doit être entre 0 % et 100 %.';

  @override
  String get errNothingInvested =>
      'Saisissez un montant initial ou un versement mensuel.';

  @override
  String get share => 'Partager';

  @override
  String get shareFailed => 'L\'image n\'a pas pu être créée.';

  @override
  String get sharedFrom => 'Calculé avec Compound';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';
}
