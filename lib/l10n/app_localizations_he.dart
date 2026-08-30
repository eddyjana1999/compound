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

  @override
  String get removeAds => 'הסרת פרסומות';

  @override
  String get removeAdsBody => 'תשלום אחד, והפרסומות נעלמות לתמיד.';

  @override
  String get restorePurchases => 'שחזור רכישות';

  @override
  String get purchaseThanks => 'תודה. הפרסומות נעלמו.';

  @override
  String get purchaseFailed => 'לא ניתן היה להשלים את הרכישה.';

  @override
  String get nothingToRestore => 'לא נמצאה רכישה קודמת בחשבון הזה.';

  @override
  String get adsRemovedTitle => 'הפרסומות הוסרו';

  @override
  String get proBadge => 'PRO';

  @override
  String get proTitle => 'קח שליטה מלאה על העתיד הפיננסי שלך';

  @override
  String get proBlurb => 'תשלום אחד. שלך לתמיד, בחשבון הזה.';

  @override
  String get proInflation => 'אינפלציה — כמה הכסף הזה באמת יקנה';

  @override
  String get proGrowth => 'הפקדה חודשית שגדלה יחד עם המשכורת';

  @override
  String get proExport => 'ייצוא כל חישוב ל-PDF או CSV';

  @override
  String get proNoAds => 'בלי פרסומות, לתמיד';

  @override
  String get proCta => 'שדרג ל-Pro';

  @override
  String get proActive => 'Pro פעיל';

  @override
  String get proThanks => 'תודה. Pro נפתח.';

  @override
  String get proUnavailable => 'לא ניתן לרכוש את Pro כרגע. נסה שוב מאוחר יותר.';

  @override
  String get termsOfUse => 'תנאי שימוש';

  @override
  String get privacyPolicy => 'מדיניות פרטיות';

  @override
  String get proNotSubscription =>
      'רכישה חד-פעמית, לא מנוי. שום דבר לא מתחדש ולא תחויב שוב.';

  @override
  String get proLockedHint => 'Pro';

  @override
  String get export => 'ייצוא';

  @override
  String get exportPdf => 'מסמך PDF';

  @override
  String get exportCsv => 'גיליון CSV';

  @override
  String get exportFailed => 'לא ניתן היה ליצור את קובץ הייצוא.';

  @override
  String get inflationLabel => 'אינפלציה';

  @override
  String get contributionGrowthLabel => 'גידול שנתי בהפקדה';

  @override
  String get beforeCosts => 'לפני דמי ניהול ומס';

  @override
  String youKeepShare(String percent) {
    return 'נשאר לך $percent';
  }

  @override
  String get inTodaysMoney => 'בכוח קנייה של היום';

  @override
  String get depositedShort => 'הופקד';

  @override
  String get growthShort => 'רווח';

  @override
  String get errNegativeAmount => 'סכומים לא יכולים להיות שליליים.';

  @override
  String get errHorizonTooShort => 'בחר שנה אחת לפחות.';

  @override
  String get errHorizonTooLong => 'בחר 100 שנים או פחות.';

  @override
  String get errReturnTooLow => 'התשואה חייבת להיות גבוהה מ־‎−100%.';

  @override
  String get errFeeRange => 'דמי הניהול חייבים להיות בין 0% ל־100%.';

  @override
  String get errTaxRange => 'שיעור המס חייב להיות בין 0% ל־100%.';

  @override
  String get errInflationRange => 'האינפלציה חייבת להיות בין 0% ל־100%.';

  @override
  String get errGrowthRange => 'הגידול השנתי חייב להיות בין 0% ל־100%.';

  @override
  String get errNothingInvested => 'הזן סכום התחלתי או הפקדה חודשית.';
}
