// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Compound';

  @override
  String get historyTitle => 'Your calculations';

  @override
  String get newCalculation => 'New calculation';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get emptyBody =>
      'Run your first projection and see what compounding does over time.';

  @override
  String get startingAmount => 'Starting amount';

  @override
  String get monthlyContribution => 'Monthly contribution';

  @override
  String get annualReturn => 'Annual return';

  @override
  String get timeHorizon => 'Time horizon';

  @override
  String yearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String get advanced => 'Advanced';

  @override
  String get advancedSubtitle => 'Fees and tax';

  @override
  String get managementFee => 'Annual management fee';

  @override
  String get capitalGainsTax => 'Capital gains tax';

  @override
  String get optional => 'Optional';

  @override
  String get calculate => 'Calculate';

  @override
  String get results => 'Results';

  @override
  String youWouldHave(String years) {
    return 'After $years, you would have';
  }

  @override
  String get totalDeposited => 'Total deposited';

  @override
  String get interestEarned => 'Interest earned';

  @override
  String get feesPaid => 'Fees paid';

  @override
  String get taxPaid => 'Tax paid';

  @override
  String get netProfit => 'Net profit';

  @override
  String get growthOverTime => 'Growth over time';

  @override
  String get legendBalance => 'Balance';

  @override
  String get legendDeposited => 'Deposited';

  @override
  String get save => 'Save';

  @override
  String get savedToHistory => 'Saved to your calculations';

  @override
  String get delete => 'Delete';

  @override
  String get deleted => 'Deleted';

  @override
  String get undo => 'Undo';

  @override
  String get clearAll => 'Clear all';

  @override
  String get clearAllTitle => 'Clear all calculations?';

  @override
  String get clearAllBody =>
      'This removes every saved calculation. It cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get disclaimer =>
      'Estimates only, based on a constant rate of return. Not investment advice.';

  @override
  String get checkYourNumbers => 'Check your numbers';

  @override
  String yearShort(int count) {
    return 'Y$count';
  }

  @override
  String get perYear => 'per year';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemDefault => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get currency => 'Currency';

  @override
  String get adPrivacy => 'Ad privacy';
}
