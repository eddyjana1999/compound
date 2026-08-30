import 'package:compound/data/prefs_calculation_repository.dart';
import 'package:compound/data/saved_calculation.dart';
import 'package:compound/domain/models/calculation_input.dart';
import 'package:compound/domain/money.dart';
import 'package:compound/domain/rate_conversion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const usd = CurrencySpec(code: 'USD', decimalDigits: 2);

  CalculationInput anInput({int years = 20, int initial = 1000000}) =>
      CalculationInput(
        currency: usd,
        initialAmount: initial,
        monthlyContribution: 50000,
        annualReturn: 700,
        years: years,
        annualManagementFee: 100,
        capitalGainsTaxRate: 2500,
      );

  SavedCalculation anEntry(String id, {DateTime? at, CalculationInput? input}) =>
      SavedCalculation(
        id: id,
        createdAt: at ?? DateTime(2026, 8, 29, 12),
        input: input ?? anInput(),
      );

  Future<PrefsCalculationRepository> emptyRepo() async {
    SharedPreferences.setMockInitialValues({});
    return PrefsCalculationRepository(await SharedPreferences.getInstance());
  }

  group('serialisation', () {
    test('an entry survives a round trip unchanged', () {
      final original = anEntry('abc');
      final restored = SavedCalculation.tryDecode(original.encode());
      expect(restored, isNotNull);
      expect(restored!.id, 'abc');
      expect(restored.input, original.input);
      expect(restored.createdAt, original.createdAt);
    });

    test('a zero decimal currency round trips with its scale intact', () {
      final entry = anEntry(
        'jpy',
        input: anInput().copyWith(
          currency: const CurrencySpec(code: 'JPY', decimalDigits: 0),
        ),
      );
      final restored = SavedCalculation.tryDecode(entry.encode())!;
      expect(restored.input.currency.decimalDigits, 0);
      expect(restored.input.currency.code, 'JPY');
    });

    test('the rate convention round trips', () {
      final entry = anEntry('nom',
          input: anInput().copyWith(rateConversion: RateConversion.nominal));
      final restored = SavedCalculation.tryDecode(entry.encode())!;
      expect(restored.input.rateConversion, RateConversion.nominal);
    });

    test('malformed json is rejected instead of throwing', () {
      expect(SavedCalculation.tryDecode('not json'), isNull);
      expect(SavedCalculation.tryDecode('{"v":1}'), isNull);
      expect(SavedCalculation.tryDecode('[]'), isNull);
    });

    test('an entry from a future schema is rejected, not misread', () {
      final json = anEntry('x').toJson()..['v'] = 99;
      expect(SavedCalculation.tryFromJson(json), isNull);
    });

    test('an entry the engine would reject is not restored', () {
      final json = anEntry('x').toJson()..['years'] = 0;
      expect(SavedCalculation.tryFromJson(json), isNull);
    });
  });

  group('favourites', () {
    test('an entry starts unstarred', () {
      expect(anEntry('a').favourite, isFalse);
    });

    test('starring survives a round trip', () {
      final starred = anEntry('a').copyWith(favourite: true);
      expect(SavedCalculation.tryDecode(starred.encode())!.favourite, isTrue);
    });

    test('a version 1 row loads unstarred rather than being refused', () {
      // What sits in storage for anyone updating the app. Rejecting it would
      // silently wipe their history.
      final v1 = anEntry('old').toJson()
        ..['v'] = 1
        ..remove('favourite');
      final restored = SavedCalculation.tryFromJson(v1);
      expect(restored, isNotNull);
      expect(restored!.favourite, isFalse);
      expect(restored.input.years, 20);
    });

    test('starred entries sort above newer unstarred ones', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('new', at: DateTime(2026, 8, 1)));
      await repo.save(anEntry('old', at: DateTime(2026, 1, 1)));
      final after = await repo.setFavourite('old', true);
      expect(after.map((e) => e.id), ['old', 'new']);
    });

    test('among themselves, favourites are still newest first', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('a', at: DateTime(2026, 1, 1)));
      await repo.save(anEntry('b', at: DateTime(2026, 6, 1)));
      await repo.setFavourite('a', true);
      final after = await repo.setFavourite('b', true);
      expect(after.map((e) => e.id), ['b', 'a']);
    });

    test('unstarring puts it back in date order', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('new', at: DateTime(2026, 8, 1)));
      await repo.save(anEntry('old', at: DateTime(2026, 1, 1)));
      await repo.setFavourite('old', true);
      final after = await repo.setFavourite('old', false);
      expect(after.map((e) => e.id), ['new', 'old']);
    });

    test('starring an unknown id changes nothing', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('a'));
      final after = await repo.setFavourite('nope', true);
      expect(after.length, 1);
      expect(after.single.favourite, isFalse);
    });

    test('a favourite is never pushed out by the entry cap', () async {
      // The cap drops the oldest. A starred entry sorts above everything
      // unstarred, so pinning also protects.
      final repo = await emptyRepo();
      await repo.save(anEntry('keep', at: DateTime(2020, 1, 1)));
      await repo.setFavourite('keep', true);
      for (var i = 0; i < PrefsCalculationRepository.maxEntries + 5; i++) {
        await repo.save(
            anEntry('id$i', at: DateTime(2026, 1, 1).add(Duration(days: i))));
      }
      final loaded = await repo.load();
      expect(loaded.length, PrefsCalculationRepository.maxEntries);
      expect(loaded.first.id, 'keep');
    });
  });

  group('deleting several at once', () {
    test('removes exactly the ones named', () async {
      final repo = await emptyRepo();
      for (final id in ['a', 'b', 'c']) {
        await repo.save(anEntry(id, at: DateTime(2026, 1, 1)));
      }
      final left = await repo.deleteAll({'a', 'c'});
      expect(left.map((e) => e.id), ['b']);
    });

    test('an empty selection is a no-op, not a wipe', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('a'));
      expect((await repo.deleteAll({})).length, 1);
    });

    test('unknown ids in the selection are ignored', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('a'));
      final left = await repo.deleteAll({'a', 'ghost'});
      expect(left, isEmpty);
    });

    test('deletes favourites too when they were selected', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('a'));
      await repo.setFavourite('a', true);
      expect(await repo.deleteAll({'a'}), isEmpty);
    });
  });

  group('history', () {
    test('starts empty', () async {
      final repo = await emptyRepo();
      expect(await repo.load(), isEmpty);
    });

    test('saves and reads back', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('one'));
      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.single.id, 'one');
    });

    test('returns newest first', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('old', at: DateTime(2026, 1, 1)));
      await repo.save(anEntry('new', at: DateTime(2026, 8, 1)));
      final loaded = await repo.load();
      expect(loaded.map((e) => e.id), ['new', 'old']);
    });

    test('saving the same id replaces rather than duplicates', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('same', input: anInput(years: 10)));
      await repo.save(anEntry('same', input: anInput(years: 30)));
      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.single.input.years, 30);
    });

    test('deletes one entry and leaves the rest', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('a', at: DateTime(2026, 1, 1)));
      await repo.save(anEntry('b', at: DateTime(2026, 2, 1)));
      final left = await repo.delete('a');
      expect(left.map((e) => e.id), ['b']);
      expect((await repo.load()).map((e) => e.id), ['b']);
    });

    test('deleting an unknown id is harmless', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('a'));
      expect((await repo.delete('nope')).length, 1);
    });

    test('clear empties the history', () async {
      final repo = await emptyRepo();
      await repo.save(anEntry('a'));
      expect(await repo.clear(), isEmpty);
      expect(await repo.load(), isEmpty);
    });

    test('caps the history so it cannot grow without bound', () async {
      final repo = await emptyRepo();
      for (var i = 0; i < PrefsCalculationRepository.maxEntries + 10; i++) {
        await repo.save(
            anEntry('id$i', at: DateTime(2026, 1, 1).add(Duration(days: i))));
      }
      final loaded = await repo.load();
      expect(loaded.length, PrefsCalculationRepository.maxEntries);
      expect(loaded.first.id, 'id59');
    });

    test('a corrupt row costs that row, not the whole history', () async {
      SharedPreferences.setMockInitialValues({
        'compound.history.v1': [anEntry('good').encode(), 'garbage{{'],
      });
      final repo =
          PrefsCalculationRepository(await SharedPreferences.getInstance());
      final loaded = await repo.load();
      expect(loaded.length, 1);
      expect(loaded.single.id, 'good');
    });
  });
}
