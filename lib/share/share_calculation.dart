import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models/calculation_result.dart';
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
    final bytes = await renderImage(context, result);
    if (bytes == null) throw StateError('render produced no image');

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${_fileName(DateTime.now())}');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        // The image and nothing else. Adding a caption made iOS treat the
        // share as "Plain Text and 1 Document" — two items — which both
        // clutters the sheet and stops it recognising the payload as a
        // picture, so Save Image and the photo-aware targets disappear.
        files: [XFile(file.path, mimeType: 'image/png')],
        // Without this an iPad throws instead of opening the sheet: the
        // popover has to be anchored to something.
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Paints the card for two frames and photographs it.
  ///
  /// The card has to be genuinely painted. An Offstage widget is laid out but
  /// never painted, and one pushed off the side of the screen is skipped by
  /// the overlay — either way its layer has no valid transform and `toImage`
  /// fails with "Matrix4 entries must be finite".
  ///
  /// So it is drawn where it would be seen, at an opacity low enough that
  /// nobody does. Zero would skip painting again; this does not. Because a
  /// RepaintBoundary paints its whole subtree into its own layer, the part
  /// of the card below the fold is captured too.
  @visibleForTesting
  Future<Uint8List?> renderImage(
    BuildContext context,
    CalculationResult result,
  ) async {
    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    final localeName = Localizations.localeOf(context).toString();

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        // A Positioned with only left and top hands the child unbounded
        // constraints, which is exactly what a card taller than the screen
        // needs. Wrapping it in an OverflowBox to "allow" that made the box
        // try to be infinitely large, the layout failed, nothing painted,
        // and toImage came back with a non-finite transform.
        left: 0,
        top: 0,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.004,
            child: Directionality(
              textDirection: Directionality.of(context),
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
      ),
    );

    overlay.insert(entry);
    try {
      // Two frames: one to lay the card out, one to be sure it has painted
      // before the pixels are read back.
      //
      // Each wait schedules its own frame first. `endOfFrame` waits for the
      // *next* frame, and if nothing else has changed there may not be one —
      // which hangs rather than fails, and is why the button reported that
      // the image could not be created.
      await _nextFrame();
      await _nextFrame();

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

  static Future<void> _nextFrame() async {
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Sorts by date and cannot collide.
  static String _fileName(DateTime at) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'compound-${at.year}-${two(at.month)}-${two(at.day)}'
        '-${two(at.hour)}${two(at.minute)}${two(at.second)}.png';
  }
}
