import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models/calculation_result.dart';
import '../l10n/app_localizations.dart';
import '../ui/formatting/money_format.dart';
import '../ui/widgets/share_card.dart';

/// Renders a calculation to an image and hands it to the system share sheet.
///
/// The sheet is the whole point: AirDrop, Messages, WhatsApp, Mail, Save to
/// Files and everything else the user has installed come from the operating
/// system. There is nothing to integrate per app, and nothing to keep up to
/// date when they install a new one.
class ShareCalculation {
  const ShareCalculation();

  /// Three times the card's logical width, which lands near 1200 pixels —
  /// sharp on any screen it lands on without being a needlessly large file.
  static const double _pixelRatio = 3;

  Future<void> share(
    BuildContext context,
    CalculationResult result, {
    required Rect? origin,
  }) async {
    final l10n = AppLocalizations.of(context);
    final bytes = await _render(context, result);
    if (bytes == null) throw StateError('render produced no image');

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${_fileName(DateTime.now())}');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: l10n.sharedFrom,
        // Without this an iPad throws instead of opening the sheet: the
        // popover has to be anchored to something.
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Paints the card off to the side of the screen and photographs it.
  ///
  /// It has to be in the tree and painted — an Offstage widget is laid out
  /// but never painted, so capturing one returns nothing. Pushing it far to
  /// the left keeps it out of sight while it is still a real, painted widget.
  Future<Uint8List?> _render(
    BuildContext context,
    CalculationResult result,
  ) async {
    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    final localeName = Localizations.localeOf(context).toString();

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -ShareCard.width * 3,
        top: 0,
        child: Directionality(
          textDirection: Directionality.of(context),
          // The overlay is only as tall as the screen and this card is
          // taller than a phone. Let it take the height it actually needs,
          // or it gets squeezed into the viewport and overflows.
          child: OverflowBox(
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: AlignmentDirectional.topStart,
            child: RepaintBoundary(
              key: boundaryKey,
              child: ShareCard(
                result: result,
                format: MoneyFormat(localeName, result.currency),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    try {
      // Two frames: one to lay the card out, one to be sure it has painted
      // before the pixels are read back.
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final object = boundaryKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return null;

      final image = await object.toImage(pixelRatio: _pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } finally {
      entry.remove();
    }
  }

  /// Sorts by date and cannot collide.
  static String _fileName(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'compound-${at.year}-${two(at.month)}-${two(at.day)}'
        '-${two(at.hour)}${two(at.minute)}${two(at.second)}.png';
  }
}
