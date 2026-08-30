import 'package:intl/intl.dart';

import '../domain/models/calculation_result.dart';
import '../ui/formatting/money_format.dart';

/// Turns a calculation into CSV.
///
/// Pure Dart and pure text, so it is unit tested and works in every language
/// the app ships — a spreadsheet does not care what alphabet a label is in.
/// Amounts are written as plain decimal numbers with no symbol or grouping,
/// because a spreadsheet has to be able to add them up. The currency is named
/// once, in the summary.
class CsvExport {
  const CsvExport();

  static const String _crlf = '\r\n';

  String build(CalculationResult result) {
    final input = result.input;
    final currency = result.currency;

    String money(int minor) => currency.toMajor(minor).toStringAsFixed(
          currency.decimalDigits,
        );
    String percent(int bps) => (bps / 100).toStringAsFixed(2);

    final rows = <List<String>>[
      ['Compound — investment calculation'],
      [],
      ['Currency', currency.code],
      ['Starting amount', money(input.initialAmount)],
      ['Monthly contribution', money(input.monthlyContribution)],
      ['Annual return %', percent(input.annualReturn)],
      ['Years', '${input.years}'],
      if (input.hasFee)
        ['Annual management fee %', percent(input.annualManagementFee)],
      if (input.hasTax)
        ['Capital gains tax %', percent(input.capitalGainsTaxRate)],
      if (input.hasContributionGrowth)
        ['Contribution growth % per year', percent(input.annualContributionGrowth)],
      if (input.hasInflation) ['Inflation % per year', percent(input.annualInflation)],
      [],
      ['Total deposited', money(result.totalDeposited)],
      ['Interest earned', money(result.interestEarned)],
      if (result.totalFeesPaid > 0) ['Fees paid', money(result.totalFeesPaid)],
      if (result.capitalGainsTax > 0) ['Tax paid', money(result.capitalGainsTax)],
      ['Net final value', money(result.netFinalValue)],
      ['Net profit', money(result.netProfit)],
      if (input.hasInflation)
        ["Net final value in today's money", money(result.netFinalValueInTodaysMoney)],
      [],
      ['Year', 'Total deposited', 'Balance', 'Cumulative fees', 'Gain'],
      for (final point in result.yearlySeries)
        [
          '${point.year}',
          money(point.totalDeposited),
          money(point.balance),
          money(point.cumulativeFees),
          money(point.gain),
        ],
    ];

    return rows.map((row) => row.map(_escape).join(',')).join(_crlf) + _crlf;
  }

  /// RFC 4180: quote anything containing a comma, a quote or a line break,
  /// and double the quotes inside. Without this a label with a comma in it
  /// silently shifts every column after it.
  String _escape(String field) {
    if (!field.contains(RegExp(r'[",\r\n]'))) return field;
    return '"${field.replaceAll('"', '""')}"';
  }

  /// A filename that sorts by date and cannot collide.
  String fileName(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'compound-${at.year}-${two(at.month)}-${two(at.day)}'
        '-${two(at.hour)}${two(at.minute)}${two(at.second)}.csv';
  }
}

/// The English formatter the exports use.
///
/// Deliberately not the user's locale: a file is opened elsewhere, often by
/// someone else, and a spreadsheet that has to guess whether "1.234" is one
/// or one thousand is worse than one that is plainly English.
MoneyFormat exportFormat(CalculationResult result) =>
    MoneyFormat('en_US', result.currency);

/// Money for an exported document, written as `ILS 1,234.56`.
///
/// The ISO code rather than the symbol, because the PDF is drawn with the
/// built-in Latin fonts and those contain no shekel, yen, won or rupee sign —
/// a symbol would come out as an empty box in six of the eight languages the
/// app ships. The code is also less ambiguous in a document that will be read
/// by someone who did not make it.
String exportMoney(CalculationResult result, int minor) {
  final major = result.currency.toMajor(minor);
  final digits = result.currency.decimalDigits;
  final format = NumberFormat.decimalPatternDigits(
    locale: 'en_US',
    decimalDigits: digits,
  );
  return '${result.currency.code} ${format.format(major)}';
}
