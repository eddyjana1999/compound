// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Compound';

  @override
  String get historyTitle => '計算履歴';

  @override
  String get newCalculation => '新しい計算';

  @override
  String get emptyTitle => 'まだ何もありません';

  @override
  String get emptyBody => '最初のシミュレーションを実行して、複利が時間をかけて生み出すものを確かめましょう。';

  @override
  String get startingAmount => '初期投資額';

  @override
  String get monthlyContribution => '毎月の積立額';

  @override
  String get annualReturn => '年利回り';

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
  String get managementFee => '年間信託報酬';

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
  String get interestEarned => '運用収益';

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
  String get legendDeposited => '元本';

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
}
