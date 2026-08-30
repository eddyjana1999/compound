import 'saved_calculation.dart';

/// Where the home screen's history comes from.
///
/// An interface so the UI can be tested without a platform channel, and so
/// the storage backend can change without the UI noticing.
abstract class CalculationRepository {
  /// Newest first.
  Future<List<SavedCalculation>> load();

  /// Adds an entry and returns the resulting history, newest first.
  Future<List<SavedCalculation>> save(SavedCalculation calculation);

  Future<List<SavedCalculation>> delete(String id);

  /// Removes several at once, for the selection mode on the home screen.
  Future<List<SavedCalculation>> deleteAll(Set<String> ids);

  /// Stars or unstars one entry.
  Future<List<SavedCalculation>> setFavourite(String id, bool favourite);

  Future<List<SavedCalculation>> clear();
}
