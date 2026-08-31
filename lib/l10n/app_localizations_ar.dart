// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Compound Lab';

  @override
  String get historyTitle => 'حساباتك';

  @override
  String get newCalculation => 'حساب جديد';

  @override
  String get emptyTitle => 'لا توجد عمليات محفوظة بعد';

  @override
  String get emptyBody =>
      'كم يتراكم مالك عبر السنين، وكم يبقى منه فعليًا بعد الرسوم والضرائب.';

  @override
  String get startingAmount => 'رأس المال الأولي';

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
  String get interestEarned => 'أرباح الفائدة المركبة';

  @override
  String get feesPaid => 'الرسوم المدفوعة';

  @override
  String get taxPaid => 'الضرائب المدفوعة';

  @override
  String get netProfit => 'صافي الربح';

  @override
  String get growthOverTime => 'نمو رأس المال';

  @override
  String get legendBalance => 'الرصيد';

  @override
  String get legendDeposited => 'رأس المال المودع';

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
  String get addToFavourites => 'إضافة إلى المفضّلة';

  @override
  String get removeFromFavourites => 'إزالة من المفضّلة';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تحديد $count عنصر',
      many: 'تم تحديد $count عنصرًا',
      few: 'تم تحديد $count عناصر',
      two: 'تم تحديد عنصرين',
      one: 'تم تحديد عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedTitle => 'حذف العمليات المحدّدة؟';

  @override
  String get select => 'تحديد';

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

  @override
  String get share => 'مشاركة';

  @override
  String get shareFailed => 'تعذّر إنشاء الصورة.';

  @override
  String get sharedFrom => 'حُسِب باستخدام Compound Lab';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get termsOfUse => 'شروط الاستخدام';

  @override
  String get tryAgain => 'إعادة المحاولة';

  @override
  String get assumptions => 'افتراضات الحساب';

  @override
  String get chartIsPreTax =>
      'يتتبع الرسم البياني قيمة المحفظة قبل ضريبة أرباح رأس المال، التي تُخصم مرة واحدة من إجمالي الربح في النهاية.';

  @override
  String get errIncomplete => 'يرجى إدخال العائد السنوي ومدة الاستثمار.';

  @override
  String get chartEndsAt => 'نهاية الرسم البياني';

  @override
  String get yoursAfterTax => 'لك بعد الضريبة';
}
