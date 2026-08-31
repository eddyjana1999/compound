// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Compound Lab';

  @override
  String get historyTitle => '計算履歴';

  @override
  String get newCalculation => '新しい計算';

  @override
  String get emptyTitle => '保存された計算はまだありません';

  @override
  String get emptyBody => 'お金が年月をかけてどこまで増えるか、そして手数料と税を引いたあとに何が残るか。';

  @override
  String get startingAmount => '初期投資額';

  @override
  String get monthlyContribution => '毎月の積立額';

  @override
  String get annualReturn => '想定利回り（年率）';

  @override
  String get timeHorizon => '運用期間';

  @override
  String yearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count年',
    );
    return '$_temp0';
  }

  @override
  String get advanced => '詳細設定';

  @override
  String get advancedSubtitle => '手数料と税金';

  @override
  String get managementFee => '信託報酬（年率）';

  @override
  String get capitalGainsTax => '譲渡益課税';

  @override
  String get optional => '任意';

  @override
  String get calculate => '計算する';

  @override
  String get results => '計算結果';

  @override
  String youWouldHave(String years) {
    return '$years後の資産は';
  }

  @override
  String get totalDeposited => '投資元本';

  @override
  String get interestEarned => '複利による運用収益';

  @override
  String get feesPaid => '支払手数料';

  @override
  String get taxPaid => '支払税額';

  @override
  String get netProfit => '純利益';

  @override
  String get growthOverTime => '資産の推移';

  @override
  String get legendBalance => '評価額';

  @override
  String get legendDeposited => '投資元本';

  @override
  String get save => '保存';

  @override
  String get savedToHistory => '計算履歴に保存しました';

  @override
  String get delete => '削除';

  @override
  String get deleted => '削除しました';

  @override
  String get undo => '元に戻す';

  @override
  String get clearAll => 'すべて削除';

  @override
  String get clearAllTitle => 'すべての計算を削除しますか？';

  @override
  String get clearAllBody => '保存されたすべての計算が削除されます。この操作は取り消せません。';

  @override
  String get cancel => 'キャンセル';

  @override
  String get disclaimer => '一定の利回りを前提とした試算です。投資助言ではありません。';

  @override
  String get checkYourNumbers => '入力内容をご確認ください';

  @override
  String yearShort(int count) {
    return '$count年';
  }

  @override
  String get perYear => '年あたり';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get appearance => '外観';

  @override
  String get systemDefault => 'システム';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get currency => '通貨';

  @override
  String get adPrivacy => '広告のプライバシー';

  @override
  String get removeAds => '広告を非表示';

  @override
  String get removeAdsBody => '一度のお支払いで、広告が永久に表示されなくなります。';

  @override
  String get restorePurchases => '購入を復元';

  @override
  String get purchaseThanks => 'ありがとうございます。広告は表示されません。';

  @override
  String get purchaseFailed => '購入を完了できませんでした。';

  @override
  String get nothingToRestore => 'このアカウントに以前の購入は見つかりませんでした。';

  @override
  String get adsRemovedTitle => '広告は非表示です';

  @override
  String get addToFavourites => 'お気に入りに追加';

  @override
  String get removeFromFavourites => 'お気に入りから削除';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件を選択中',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedTitle => '選択した計算を削除しますか？';

  @override
  String get select => '選択';

  @override
  String get errNegativeAmount => '金額にマイナスは入力できません。';

  @override
  String get errHorizonTooShort => '1 年以上を指定してください。';

  @override
  String get errHorizonTooLong => '100 年以内を指定してください。';

  @override
  String get errReturnTooLow => '利回りは −100% より大きい必要があります。';

  @override
  String get errFeeRange => '手数料は 0%〜100% の範囲で入力してください。';

  @override
  String get errTaxRange => '税率は 0%〜100% の範囲で入力してください。';

  @override
  String get errInflationRange => 'インフレ率は 0%〜100% の範囲で入力してください。';

  @override
  String get errGrowthRange => '年間増加率は 0%〜100% の範囲で入力してください。';

  @override
  String get errNothingInvested => '初期投資額か毎月の積立額を入力してください。';

  @override
  String get share => '共有';

  @override
  String get shareFailed => '画像を作成できませんでした。';

  @override
  String get sharedFrom => 'Compound で計算';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfUse => '利用規約';
}
