import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/models/calculation_result.dart';
import 'csv_export.dart';

/// Renders a calculation as a one-page PDF.
///
/// English only, deliberately. The `pdf` package ships Latin fonts; Hebrew,
/// Arabic, Chinese and Japanese would come out as empty boxes unless whole
/// font families were bundled, and the CJK ones alone would add several
/// megabytes to every download for a feature most people use rarely. The
/// figures and the currency are the part that has to be right, and they are.
class PdfExport {
  const PdfExport();

  static const PdfColor _ink = PdfColor.fromInt(0xFF101828);
  static const PdfColor _dim = PdfColor.fromInt(0xFF667085);
  static const PdfColor _green = PdfColor.fromInt(0xFF047857);
  static const PdfColor _line = PdfColor.fromInt(0xFFE4E7EC);

  Future<Uint8List> build(CalculationResult result) async {
    final input = result.input;
    final f = exportFormat(result);
    final doc = pw.Document(title: 'Compound calculation');

    pw.Widget row(String label, String value, {bool strong = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 11,
                    color: strong ? _ink : _dim,
                    fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11,
                    color: strong ? _green : _ink,
                    fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(46, 46, 46, 40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('COMPOUND',
                style: pw.TextStyle(
                    fontSize: 10, color: _green, letterSpacing: 2,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Investment projection',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 22),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF0FDF9),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('After ${input.years} years, you would have',
                      style: const pw.TextStyle(fontSize: 10, color: _dim)),
                  pw.SizedBox(height: 5),
                  pw.Text(f.moneyRounded(result.netFinalValue),
                      style: pw.TextStyle(
                          fontSize: 30, fontWeight: pw.FontWeight.bold, color: _green)),
                  if (input.hasInflation) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${f.moneyRounded(result.netFinalValueInTodaysMoney)} in today\'s money',
                      style: const pw.TextStyle(fontSize: 10, color: _dim),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 22),

            pw.Text('Assumptions',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 6),
            row('Currency', input.currency.code),
            row('Starting amount', f.money(input.initialAmount)),
            row('Monthly contribution', f.money(input.monthlyContribution)),
            row('Annual return', f.percent(input.annualReturn)),
            row('Time horizon', '${input.years} years'),
            if (input.hasFee) row('Annual management fee', f.percent(input.annualManagementFee)),
            if (input.hasTax) row('Capital gains tax', f.percent(input.capitalGainsTaxRate)),
            if (input.hasContributionGrowth)
              row('Contribution growth', '${f.percent(input.annualContributionGrowth)} per year'),
            if (input.hasInflation)
              row('Inflation', '${f.percent(input.annualInflation)} per year'),

            pw.SizedBox(height: 18),
            pw.Text('Breakdown',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 6),
            row('Total deposited', f.money(result.totalDeposited)),
            row('Interest earned', f.money(result.interestEarned)),
            if (result.totalFeesPaid > 0) row('Fees paid', '-${f.money(result.totalFeesPaid)}'),
            if (result.capitalGainsTax > 0) row('Tax paid', '-${f.money(result.capitalGainsTax)}'),
            pw.Divider(color: _line, height: 18),
            row('Net profit', f.money(result.netProfit), strong: true),

            pw.SizedBox(height: 22),
            pw.Text('Year by year',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Year', 'Deposited', 'Balance'],
              cellAlignment: pw.Alignment.centerRight,
              cellAlignments: const {0: pw.Alignment.centerLeft},
              headerAlignment: pw.Alignment.centerRight,
              headerStyle: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold, color: _dim),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
              cellHeight: 17,
              border: pw.TableBorder(horizontalInside: pw.BorderSide(color: _line, width: .5)),
              data: [
                for (final p in result.yearlySeries)
                  [
                    '${p.year}',
                    f.moneyRounded(p.totalDeposited),
                    f.moneyRounded(p.balance),
                  ],
              ],
            ),

            pw.Spacer(),
            pw.Text(
              'Estimates only, based on a constant rate of return. Not investment advice.',
              style: const pw.TextStyle(fontSize: 8, color: _dim),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  String fileName(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'compound-${at.year}-${two(at.month)}-${two(at.day)}'
        '-${two(at.hour)}${two(at.minute)}${two(at.second)}.pdf';
  }
}
