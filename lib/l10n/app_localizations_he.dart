// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Compound';

  @override
  String get historyTitle => 'החישובים שלך';

  @override
  String get newCalculation => 'חישוב חדש';

  @override
  String get emptyTitle => 'עדיין אין כאן כלום';

  @override
  String get emptyBody =>
      'הרץ את התחזית הראשונה שלך וראה מה ריבית דריבית עושה לאורך זמן.';

  @override
  String get startingAmount => 'סכום התחלתי';

  @override
  String get monthlyContribution => 'הפקדה חודשית';

  @override
  String get annualReturn => 'תשואה שנתית';

  @override
  String get timeHorizon => 'טווח השקעה';

  @override
  String yearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count שנים',
      two: 'שנתיים',
      one: 'שנה אחת',
    );
    return '$_temp0';
  }

  @override
  String get advanced => 'מתקדם';

  @override
  String get advancedSubtitle => 'דמי ניהול ומס';

  @override
  String get managementFee => 'דמי ניהול שנתיים';

  @override
  String get capitalGainsTax => 'מס רווחי הון';

  @override
  String get optional => 'אופציונלי';

  @override
  String get calculate => 'חשב';

  @override
  String get results => 'תוצאות';

  @override
  String youWouldHave(String years) {
    return 'אחרי $years יהיו לך';
  }

  @override
  String get totalDeposited => 'סך ההפקדות';

  @override
  String get interestEarned => 'רווחי השקעה';

  @override
  String get feesPaid => 'דמי ניהול ששולמו';

  @override
  String get taxPaid => 'מס ששולם';

  @override
  String get netProfit => 'רווח נטו';

  @override
  String get growthOverTime => 'הצמיחה לאורך זמן';

  @override
  String get legendBalance => 'יתרה';

  @override
  String get legendDeposited => 'הפקדות';

  @override
  String get save => 'שמירה';

  @override
  String get savedToHistory => 'נשמר בחישובים שלך';

  @override
  String get delete => 'מחיקה';

  @override
  String get deleted => 'נמחק';

  @override
  String get undo => 'ביטול';

  @override
  String get clearAll => 'מחק הכל';

  @override
  String get clearAllTitle => 'למחוק את כל החישובים?';

  @override
  String get clearAllBody =>
      'הפעולה תמחק את כל החישובים השמורים ואי אפשר לבטל אותה.';

  @override
  String get cancel => 'ביטול';

  @override
  String get disclaimer =>
      'הערכה בלבד, המבוססת על תשואה קבועה. אין באמור ייעוץ השקעות.';

  @override
  String get checkYourNumbers => 'בדוק את הנתונים שהזנת';

  @override
  String yearShort(int count) {
    return 'ש$count';
  }

  @override
  String get perYear => 'לשנה';

  @override
  String get settings => 'הגדרות';

  @override
  String get language => 'שפה';

  @override
  String get appearance => 'מראה';

  @override
  String get systemDefault => 'לפי המערכת';

  @override
  String get light => 'בהיר';

  @override
  String get dark => 'כהה';

  @override
  String get currency => 'מטבע';

  @override
  String get adPrivacy => 'פרטיות מודעות';
}
