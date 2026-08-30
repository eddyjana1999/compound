import 'package:shared_preferences/shared_preferences.dart';

import 'calculation_repository.dart';
import 'saved_calculation.dart';

/// History backed by `shared_preferences`, stored as a list of JSON strings.
///
/// A list of strings rather than one blob so a single corrupt entry costs one
/// row instead of the whole history.
class PrefsCalculationRepository implements CalculationRepository {
  PrefsCalculationRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'compound.history.v1';

  /// The history is a convenience list, not an archive. Capping it keeps the
  /// home screen readable and the preference file small.
  static const int maxEntries = 50;

  @override
  Future<List<SavedCalculation>> load() async => _read();

  @override
  Future<List<SavedCalculation>> save(SavedCalculation calculation) async {
    final entries = _read()
      ..removeWhere((e) => e.id == calculation.id)
      ..insert(0, calculation);
    return _write(entries);
  }

  @override
  Future<List<SavedCalculation>> delete(String id) async {
    final entries = _read()..removeWhere((e) => e.id == id);
    return _write(entries);
  }

  @override
  Future<List<SavedCalculation>> deleteAll(Set<String> ids) async {
    if (ids.isEmpty) return _read();
    final entries = _read()..removeWhere((e) => ids.contains(e.id));
    return _write(entries);
  }

  @override
  Future<List<SavedCalculation>> setFavourite(String id, bool favourite) async {
    final entries = _read();
    final index = entries.indexWhere((e) => e.id == id);
    if (index == -1) return entries;
    entries[index] = entries[index].copyWith(favourite: favourite);
    return _write(entries);
  }

  @override
  Future<List<SavedCalculation>> clear() async {
    await _prefs.remove(_key);
    return const [];
  }

  List<SavedCalculation> _read() {
    final raw = _prefs.getStringList(_key) ?? const <String>[];
    final entries = <SavedCalculation>[];
    for (final row in raw) {
      final entry = SavedCalculation.tryDecode(row);
      if (entry != null) entries.add(entry);
    }
    _sort(entries);
    return entries;
  }

  /// Sorting rather than filtering keeps one list: a favourite is a
  /// calculation you pinned, not a separate place you have to go and look.
  static void _sort(List<SavedCalculation> entries) =>
      entries.sort(SavedCalculation.compare);

  Future<List<SavedCalculation>> _write(List<SavedCalculation> entries) async {
    _sort(entries);
    // The cap drops the oldest, and a starred entry is never the oldest by
    // this order — so pinning something also protects it from being pushed
    // out by fifty newer calculations.
    final capped = entries.take(maxEntries).toList(growable: false);
    await _prefs.setStringList(
      _key,
      capped.map((e) => e.encode()).toList(growable: false),
    );
    return capped;
  }
}
