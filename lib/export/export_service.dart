import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models/calculation_result.dart';
import 'csv_export.dart';
import 'pdf_export.dart';

enum ExportFormat { pdf, csv }

/// Writes an export to a temporary file and hands it to the system share
/// sheet.
///
/// Temporary on purpose: the app has no business keeping a copy. Whatever the
/// user does with it — mail it, save it to Files, drop it in a spreadsheet —
/// is the platform's job, and the file is disposable once they have.
class ExportService {
  const ExportService();

  /// [origin] positions the iPad share popover. Without it, sharing from an
  /// iPad throws rather than opening.
  Future<void> share(
    CalculationResult result,
    ExportFormat format, {
    Rect? origin,
  }) async {
    final now = DateTime.now();
    final directory = await getTemporaryDirectory();

    final File file;
    switch (format) {
      case ExportFormat.pdf:
        const export = PdfExport();
        file = File('${directory.path}/${export.fileName(now)}');
        await file.writeAsBytes(await export.build(result));
      case ExportFormat.csv:
        const export = CsvExport();
        file = File('${directory.path}/${export.fileName(now)}');
        await file.writeAsString(export.build(result));
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        sharePositionOrigin: origin,
      ),
    );
  }
}
