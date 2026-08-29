import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// A labelled numeric field.
///
/// Always laid out left-to-right for the number itself even in an RTL
/// language: digits and their grouping read LTR in Hebrew and Arabic too, and
/// a right-aligned amount field with a currency symbol on the wrong side is
/// the classic RTL money bug.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.label,
    required this.controller,
    this.prefix,
    this.onPrefixTap,
    this.suffix,
    this.helper,
    this.errorText,
    this.allowDecimal = true,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? prefix;

  /// Makes the prefix a button. Used for the currency code, so the thing the
  /// user wants to change is the thing they tap, rather than a separate
  /// control somewhere else on the screen.
  final VoidCallback? onPrefixTap;

  final String? suffix;
  final String? helper;
  final String? errorText;
  final bool allowDecimal;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(
            label,
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        TextField(
          controller: controller,
          autofocus: autofocus,
          textInputAction: textInputAction,
          keyboardType: TextInputType.numberWithOptions(
            decimal: allowDecimal,
            signed: false,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r"[0-9.,'٠-٩۰-۹ ]"),
            ),
            LengthLimitingTextInputFormatter(18),
          ],
          textDirection: TextDirection.ltr,
          style: context.texts.headlineMedium?.copyWith(fontSize: 22),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: '0',
            errorText: errorText,
            helperText: helper,
            prefixIcon: prefix == null
                ? null
                : _Affix(
                    text: prefix!,
                    alignment: Alignment.centerRight,
                    onTap: onPrefixTap,
                  ),
            suffixIcon: suffix == null
                ? null
                : _Affix(text: suffix!, alignment: Alignment.centerLeft),
            prefixIconConstraints: BoxConstraints(
              minWidth: onPrefixTap == null ? 46 : 74,
              minHeight: 0,
            ),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 46, minHeight: 0),
          ),
        ),
      ],
    );
  }
}

class _Affix extends StatelessWidget {
  const _Affix({required this.text, required this.alignment, this.onTap});

  final String text;
  final Alignment alignment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: context.texts.titleMedium?.copyWith(
        color: context.colors.onSurface.withValues(alpha: onTap == null ? 0.5 : 0.85),
        fontWeight: FontWeight.w600,
      ),
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Align(alignment: alignment, widthFactor: 1, child: label),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, end: 6),
      child: Align(
        alignment: alignment,
        widthFactor: 1,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  label,
                  const SizedBox(width: 2),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: context.colors.onSurface.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
