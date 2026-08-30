// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Compound';

  @override
  String get historyTitle => 'حساباتك';

  @override
  String get newCalculation => 'حساب جديد';

  @override
  String get emptyTitle => 'لا يوجد شيء بعد';

  @override
  String get emptyBody =>
      'ابدأ أول توقع لك وشاهد ما يصنعه الربح المركّب مع مرور الوقت.';

  @override
  String get startingAmount => 'المبلغ الأولي';

  @override
  String get monthlyContribution => 'الإيداع الشهري';

  @override
  String get annualReturn => 'العائد السنوي';

  @override
  String get timeHorizon => 'مدة الاستثمار';

  @override
  String yearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سنة',
      many: '$count سنة',
      few: '$count سنوات',
      two: 'سنتان',
      one: 'سنة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get advanced => 'خيارات متقدمة';

  @override
  String get advancedSubtitle => 'الرسوم والضرائب';

  @override
  String get managementFee => 'رسوم الإدارة السنوية';

  @override
  String get capitalGainsTax => 'ضريبة الأرباح الرأسمالية';

  @override
  String get optional => 'اختياري';

  @override
  String get calculate => 'احسب';

  @override
  String get results => 'النتائج';

  @override
  String youWouldHave(String years) {
    return 'بعد $years سيكون لديك';
  }

  @override
  String get totalDeposited => 'إجمالي المودع';

  @override
  String get interestEarned => 'الأرباح المحققة';

  @override
  String get feesPaid => 'الرسوم المدفوعة';

  @override
  String get taxPaid => 'الضرائب المدفوعة';

  @override
  String get netProfit => 'صافي الربح';

  @override
  String get growthOverTime => 'النمو عبر الزمن';

  @override
  String get legendBalance => 'الرصيد';

  @override
  String get legendDeposited => 'المودع';

  @override
  String get save => 'حفظ';

  @override
  String get savedToHistory => 'تم الحفظ في حساباتك';

  @override
  String get delete => 'حذف';

  @override
  String get deleted => 'تم الحذف';

  @override
  String get undo => 'تراجع';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get clearAllTitle => 'مسح جميع الحسابات؟';

  @override
  String get clearAllBody =>
      'سيؤدي هذا إلى حذف كل الحسابات المحفوظة، ولا يمكن التراجع عنه.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get disclaimer =>
      'تقديرات فقط مبنية على عائد ثابت. هذه ليست نصيحة استثمارية.';

  @override
  String get checkYourNumbers => 'راجع الأرقام المدخلة';

  @override
  String yearShort(int count) {
    return 'س$count';
  }

  @override
  String get perYear => 'سنويًا';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get appearance => 'المظهر';

  @override
  String get systemDefault => 'النظام';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get currency => 'العملة';

  @override
  String get adPrivacy => 'خصوصية الإعلانات';

  @override
  String get removeAds => 'إزالة الإعلانات';

  @override
  String get removeAdsBody => 'دفعة واحدة، وتختفي الإعلانات نهائيًا.';

  @override
  String get restorePurchases => 'استعادة المشتريات';

  @override
  String get purchaseThanks => 'شكرًا لك. لقد اختفت الإعلانات.';

  @override
  String get purchaseFailed => 'تعذّر إتمام عملية الشراء.';

  @override
  String get nothingToRestore =>
      'لم يُعثر على عملية شراء سابقة على هذا الحساب.';

  @override
  String get adsRemovedTitle => 'تمت إزالة الإعلانات';

  @override
  String get proBadge => 'PRO';

  @override
  String get proTitle => 'تحكّم بالكامل في مستقبلك المالي';

  @override
  String get proBlurb => 'دفعة واحدة. ملكك للأبد على هذا الحساب.';

  @override
  String get proInflation => 'التضخّم — اعرف ما ستشتريه أموالك فعليًا';

  @override
  String get proGrowth => 'إيداع شهري يزداد مع راتبك';

  @override
  String get proExport => 'صدّر أي عملية حسابية إلى PDF أو CSV';

  @override
  String get proNoAds => 'بلا إعلانات، نهائيًا';

  @override
  String get proCta => 'الترقية إلى Pro';

  @override
  String get proActive => 'Pro مُفعَّل';

  @override
  String get proThanks => 'شكرًا لك. تم تفعيل Pro.';

  @override
  String get proUnavailable => 'Pro غير متاح حاليًا. يُرجى المحاولة لاحقًا.';

  @override
  String get termsOfUse => 'شروط الاستخدام';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get proNotSubscription =>
      'عملية شراء لمرة واحدة وليست اشتراكًا. لا تجديد ولا خصم مرة أخرى.';

  @override
  String get proLockedHint => 'Pro';

  @override
  String get export => 'تصدير';

  @override
  String get exportPdf => 'مستند PDF';

  @override
  String get exportCsv => 'جدول CSV';

  @override
  String get exportFailed => 'تعذّر إنشاء ملف التصدير.';

  @override
  String get inflationLabel => 'التضخّم';

  @override
  String get contributionGrowthLabel => 'الزيادة السنوية للإيداع';

  @override
  String get beforeCosts => 'قبل الرسوم والضرائب';

  @override
  String youKeepShare(String percent) {
    return 'يبقى لك $percent';
  }

  @override
  String get inTodaysMoney => 'بقيمة اليوم';

  @override
  String get depositedShort => 'المودع';

  @override
  String get growthShort => 'الأرباح';

  @override
  String get errNegativeAmount => 'لا يمكن أن تكون المبالغ سالبة.';

  @override
  String get errHorizonTooShort => 'اختر سنة واحدة على الأقل.';

  @override
  String get errHorizonTooLong => 'اختر 100 سنة أو أقل.';

  @override
  String get errReturnTooLow => 'يجب أن يكون العائد أعلى من ‎−100٪.';

  @override
  String get errFeeRange => 'يجب أن تكون الرسوم بين 0٪ و100٪.';

  @override
  String get errTaxRange => 'يجب أن تكون نسبة الضريبة بين 0٪ و100٪.';

  @override
  String get errInflationRange => 'يجب أن يكون التضخّم بين 0٪ و100٪.';

  @override
  String get errGrowthRange => 'يجب أن تكون الزيادة السنوية بين 0٪ و100٪.';

  @override
  String get errNothingInvested => 'أدخل مبلغًا أوليًا أو إيداعًا شهريًا.';
}
