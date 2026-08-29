// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Compound';

  @override
  String get historyTitle => '我的计算';

  @override
  String get newCalculation => '新建计算';

  @override
  String get emptyTitle => '还没有记录';

  @override
  String get emptyBody => '做一次测算，看看复利在时间里能积累出什么。';

  @override
  String get startingAmount => '初始金额';

  @override
  String get monthlyContribution => '每月投入';

  @override
  String get annualReturn => '年化收益率';

  @override
  String get timeHorizon => '投资年限';

  @override
  String yearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 年',
    );
    return '$_temp0';
  }

  @override
  String get advanced => '高级选项';

  @override
  String get advancedSubtitle => '费用与税费';

  @override
  String get managementFee => '年管理费';

  @override
  String get capitalGainsTax => '资本利得税';

  @override
  String get optional => '选填';

  @override
  String get calculate => '开始计算';

  @override
  String get results => '计算结果';

  @override
  String youWouldHave(String years) {
    return '$years后，你将拥有';
  }

  @override
  String get totalDeposited => '累计投入';

  @override
  String get interestEarned => '累计收益';

  @override
  String get feesPaid => '已付费用';

  @override
  String get taxPaid => '已缴税费';

  @override
  String get netProfit => '净收益';

  @override
  String get growthOverTime => '增长曲线';

  @override
  String get legendBalance => '总资产';

  @override
  String get legendDeposited => '本金';

  @override
  String get save => '保存';

  @override
  String get savedToHistory => '已保存到我的计算';

  @override
  String get delete => '删除';

  @override
  String get deleted => '已删除';

  @override
  String get undo => '撤销';

  @override
  String get clearAll => '全部清除';

  @override
  String get clearAllTitle => '清除全部计算？';

  @override
  String get clearAllBody => '所有已保存的计算都将被删除，且无法恢复。';

  @override
  String get cancel => '取消';

  @override
  String get disclaimer => '结果基于固定收益率的估算，不构成投资建议。';

  @override
  String get checkYourNumbers => '请检查输入内容';

  @override
  String yearShort(int count) {
    return '$count年';
  }

  @override
  String get perYear => '每年';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get appearance => '外观';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get currency => '货币';

  @override
  String get adPrivacy => '广告隐私设置';
}
