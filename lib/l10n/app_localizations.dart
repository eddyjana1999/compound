import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('he'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Compound Lab'**
  String get appTitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your calculations'**
  String get historyTitle;

  /// No description provided for @newCalculation.
  ///
  /// In en, this message translates to:
  /// **'New calculation'**
  String get newCalculation;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'How much your money builds over the years — and how much of it you keep after fees and tax.'**
  String get emptyBody;

  /// No description provided for @startingAmount.
  ///
  /// In en, this message translates to:
  /// **'Starting amount'**
  String get startingAmount;

  /// No description provided for @monthlyContribution.
  ///
  /// In en, this message translates to:
  /// **'Monthly contribution'**
  String get monthlyContribution;

  /// No description provided for @annualReturn.
  ///
  /// In en, this message translates to:
  /// **'Annual return'**
  String get annualReturn;

  /// No description provided for @timeHorizon.
  ///
  /// In en, this message translates to:
  /// **'Time horizon'**
  String get timeHorizon;

  /// No description provided for @yearsValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year} other{{count} years}}'**
  String yearsValue(int count);

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @advancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fees and tax'**
  String get advancedSubtitle;

  /// No description provided for @managementFee.
  ///
  /// In en, this message translates to:
  /// **'Annual management fee'**
  String get managementFee;

  /// No description provided for @capitalGainsTax.
  ///
  /// In en, this message translates to:
  /// **'Capital gains tax'**
  String get capitalGainsTax;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @youWouldHave.
  ///
  /// In en, this message translates to:
  /// **'After {years}, you would have'**
  String youWouldHave(String years);

  /// No description provided for @totalDeposited.
  ///
  /// In en, this message translates to:
  /// **'Total deposited'**
  String get totalDeposited;

  /// No description provided for @interestEarned.
  ///
  /// In en, this message translates to:
  /// **'Compound interest earned'**
  String get interestEarned;

  /// No description provided for @feesPaid.
  ///
  /// In en, this message translates to:
  /// **'Fees paid'**
  String get feesPaid;

  /// No description provided for @taxPaid.
  ///
  /// In en, this message translates to:
  /// **'Tax paid'**
  String get taxPaid;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get netProfit;

  /// No description provided for @growthOverTime.
  ///
  /// In en, this message translates to:
  /// **'Growth over time'**
  String get growthOverTime;

  /// No description provided for @legendBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get legendBalance;

  /// No description provided for @legendDeposited.
  ///
  /// In en, this message translates to:
  /// **'Capital paid in'**
  String get legendDeposited;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @savedToHistory.
  ///
  /// In en, this message translates to:
  /// **'Saved to your calculations'**
  String get savedToHistory;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @clearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all calculations?'**
  String get clearAllTitle;

  /// No description provided for @clearAllBody.
  ///
  /// In en, this message translates to:
  /// **'This removes every saved calculation. It cannot be undone.'**
  String get clearAllBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Estimates only, based on a constant rate of return. Not investment advice.'**
  String get disclaimer;

  /// No description provided for @checkYourNumbers.
  ///
  /// In en, this message translates to:
  /// **'Check your numbers'**
  String get checkYourNumbers;

  /// No description provided for @yearShort.
  ///
  /// In en, this message translates to:
  /// **'Y{count}'**
  String yearShort(int count);

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get perYear;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemDefault;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @adPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy'**
  String get adPrivacy;

  /// No description provided for @removeAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get removeAds;

  /// No description provided for @removeAdsBody.
  ///
  /// In en, this message translates to:
  /// **'One payment. The ads are gone for good.'**
  String get removeAdsBody;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @purchaseThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you. The ads are gone.'**
  String get purchaseThanks;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed.'**
  String get purchaseFailed;

  /// No description provided for @nothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found on this account.'**
  String get nothingToRestore;

  /// No description provided for @adsRemovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Ads removed'**
  String get adsRemovedTitle;

  /// No description provided for @addToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get addToFavourites;

  /// No description provided for @removeFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removeFromFavourites;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String selectedCount(int count);

  /// No description provided for @deleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the selected calculations?'**
  String get deleteSelectedTitle;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @errNegativeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amounts cannot be negative.'**
  String get errNegativeAmount;

  /// No description provided for @errHorizonTooShort.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one year.'**
  String get errHorizonTooShort;

  /// No description provided for @errHorizonTooLong.
  ///
  /// In en, this message translates to:
  /// **'Choose 100 years or fewer.'**
  String get errHorizonTooLong;

  /// No description provided for @errReturnTooLow.
  ///
  /// In en, this message translates to:
  /// **'The return has to be above −100%.'**
  String get errReturnTooLow;

  /// No description provided for @errFeeRange.
  ///
  /// In en, this message translates to:
  /// **'The fee has to be between 0% and 100%.'**
  String get errFeeRange;

  /// No description provided for @errTaxRange.
  ///
  /// In en, this message translates to:
  /// **'The tax rate has to be between 0% and 100%.'**
  String get errTaxRange;

  /// No description provided for @errInflationRange.
  ///
  /// In en, this message translates to:
  /// **'Inflation has to be between 0% and 100%.'**
  String get errInflationRange;

  /// No description provided for @errGrowthRange.
  ///
  /// In en, this message translates to:
  /// **'The yearly increase has to be between 0% and 100%.'**
  String get errGrowthRange;

  /// No description provided for @errNothingInvested.
  ///
  /// In en, this message translates to:
  /// **'Enter a starting amount or a monthly contribution.'**
  String get errNothingInvested;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'The image could not be created.'**
  String get shareFailed;

  /// No description provided for @sharedFrom.
  ///
  /// In en, this message translates to:
  /// **'Calculated with Compound Lab'**
  String get sharedFrom;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @assumptions.
  ///
  /// In en, this message translates to:
  /// **'Assumptions'**
  String get assumptions;

  /// No description provided for @chartIsPreTax.
  ///
  /// In en, this message translates to:
  /// **'The chart tracks the portfolio before capital gains tax, which is deducted once from the total profit at the end.'**
  String get chartIsPreTax;

  /// No description provided for @errIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Fill in the annual return and the time horizon.'**
  String get errIncomplete;

  /// No description provided for @chartEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Where the chart ends'**
  String get chartEndsAt;

  /// No description provided for @yoursAfterTax.
  ///
  /// In en, this message translates to:
  /// **'Yours after tax'**
  String get yoursAfterTax;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share the app'**
  String get shareApp;

  /// No description provided for @shareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Compound Lab — see what your money really becomes, after fees and tax.'**
  String get shareAppMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'he',
    'ja',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'he':
      return AppLocalizationsHe();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
