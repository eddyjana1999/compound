import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../formatting/currencies.dart';
import '../theme/app_theme.dart';

/// Asks the user which currency this calculation is in.
///
/// Returns the chosen ISO code, or null if they backed out.
Future<String?> showCurrencyPicker(
  BuildContext context, {
  required String selected,
  required String deviceCurrency,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    // Colour and shape come from bottomSheetTheme, not from here — see the
    // note in app_theme.dart.
    builder: (_) => _CurrencyPicker(
      selected: selected,
      deviceCurrency: deviceCurrency,
    ),
  );
}

class _CurrencyPicker extends StatefulWidget {
  const _CurrencyPicker({required this.selected, required this.deviceCurrency});

  final String selected;
  final String deviceCurrency;

  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();

    final all = Currencies.orderedFor(widget.deviceCurrency);
    final query = _query.trim().toUpperCase();
    final visible = query.isEmpty
        ? all
        : all.where((code) {
            final symbol = Currencies.symbolFor(code, localeName);
            return code.contains(query) || symbol.toUpperCase().contains(query);
          }).toList();

    return Padding(
      // Lifts the sheet clear of the keyboard while the search field has focus.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.currency, style: context.texts.headlineMedium),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _search,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: l10n.currency,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final code = visible[index];
                  final isSelected = code == widget.selected;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.palette.growthSoft
                            : context.colors.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      // Some currencies have no symbol distinct from their
                      // code — CHF, PLN. Printing "CHF CHF" reads like a bug,
                      // so those get a neutral glyph instead.
                      child: Builder(
                        builder: (context) {
                          final symbol =
                              Currencies.symbolFor(code, localeName);
                          final tint =
                              isSelected ? context.palette.growth : null;
                          if (symbol.toUpperCase() == code) {
                            return Icon(
                              Icons.payments_outlined,
                              size: 19,
                              color: tint ??
                                  context.colors.onSurface
                                      .withValues(alpha: 0.5),
                            );
                          }
                          return Text(
                            symbol,
                            maxLines: 1,
                            style: context.texts.titleMedium
                                ?.copyWith(color: tint),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      code,
                      style: context.texts.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? context.palette.growth : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded,
                            color: context.palette.growth)
                        : null,
                    onTap: () => Navigator.pop(context, code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
