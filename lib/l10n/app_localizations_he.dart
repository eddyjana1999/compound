// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Compound Lab';

  @override
  String get historyTitle => 'החישובים שלך';

  @override
  String get newCalculation => 'חישוב חדש';

  @override
  String get emptyTitle => 'כאן יופיעו החישובים שלך';

  @override
  String get emptyBody =>
      'כמה יצבור הכסף שלך לאורך השנים — וכמה מזה יישאר אחרי דמי ניהול ומס.';

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
  String get interestEarned => 'רווחי ריבית דריבית';

  @override
  String get feesPaid => 'דמי ניהול ששולמו';

  @override
  String get taxPaid => 'מס ששולם';

  @override
  String get netProfit => 'רווח נטו';

  @override
  String get growthOverTime => 'צמיחת ההון';

  @override
  String get legendBalance => 'יתרה';

  @override
  String get legendDeposited => 'הון שהופקד';

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
  String get addToFavourites => 'הוספה למועדפים';

  @override
  String get removeFromFavourites => 'הסרה מהמועדפים';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'נבחרו $count',
      two: 'נבחרו שניים',
      one: 'נבחר אחד',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedTitle => 'למחוק את החישובים שנבחרו?';

  @override
  String get select => 'בחירה';

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

  @override
  String get share => 'שיתוף';

  @override
  String get shareFailed => 'לא ניתן היה ליצור את התמונה.';

  @override
  String get sharedFrom => 'חושב באמצעות Compound Lab';

  @override
  String get privacyPolicy => 'מדיניות פרטיות';

  @override
  String get termsOfUse => 'תנאי שימוש';

  @override
  String get tryAgain => 'נסה שוב';

  @override
  String get assumptions => 'הנחות החישוב';

  @override
  String get chartIsPreTax =>
      'הגרף עוקב אחר שווי התיק לפני מס רווחי הון, שנגבה פעם אחת מסך הרווח בסוף התקופה.';

  @override
  String get errIncomplete => 'יש למלא את התשואה השנתית ואת טווח ההשקעה.';

  @override
  String get chartEndsAt => 'הגרף מסתיים ב';

  @override
  String get yoursAfterTax => 'נשאר לך אחרי מס';

  @override
  String get rateApp => 'דרגו את האפליקציה';

  @override
  String get shareApp => 'שתפו את האפליקציה';

  @override
  String get shareAppMessage =>
      'Compound Lab — כמה הכסף שלכם באמת שווה, אחרי דמי ניהול ומס.';
}
