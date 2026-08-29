import 'dart:convert';

import '../domain/models/calculation_input.dart';
import '../domain/money.dart';
import '../domain/rate_conversion.dart';

/// One entry in the history on the home screen.
///
/// Only the *input* is stored. The result is recomputed on load, so a saved
/// calculation can never disagree with the engine — if the engine is fixed,
/// every entry in history is fixed with it.
class SavedCalculation {
  const SavedCalculation({
    required this.id,
    required this.createdAt,
    required this.input,
  });

  final String id;
  final DateTime createdAt;
  final CalculationInput input;

  static const int _schemaVersion = 1;

  Map<String, Object?> toJson() => {
        'v': _schemaVersion,
        'id': id,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'currencyCode': input.currency.code,
        'currencyDigits': input.currency.decimalDigits,
        'initialAmount': input.initialAmount,
        'monthlyContribution': input.monthlyContribution,
        'annualReturn': input.annualReturn,
        'years': input.years,
        'annualManagementFee': input.annualManagementFee,
        'capitalGainsTaxRate': input.capitalGainsTaxRate,
        'rateConversion': input.rateConversion.name,
      };

  /// Returns null for an entry this build cannot read, rather than throwing.
  ///
  /// History is a convenience, not the user's data of record. One malformed
  /// row — a partial write, a downgrade after a schema change — must not stop
  /// the app from opening.
  static SavedCalculation? tryFromJson(Map<String, Object?> json) {
    try {
      if (json['v'] != _schemaVersion) return null;

      final id = json['id'];
      final createdAt = json['createdAt'];
      final currencyCode = json['currencyCode'];
      if (id is! String || createdAt is! String || currencyCode is! String) {
        return null;
      }

      final conversionName = json['rateConversion'];
      final conversion = RateConversion.values.firstWhere(
        (c) => c.name == conversionName,
        orElse: () => RateConversion.geometric,
      );

      final input = CalculationInput(
        currency: CurrencySpec(
          code: currencyCode,
          decimalDigits: json['currencyDigits'] as int,
        ),
        initialAmount: json['initialAmount'] as int,
        monthlyContribution: json['monthlyContribution'] as int,
        annualReturn: json['annualReturn'] as int,
        years: json['years'] as int,
        annualManagementFee: json['annualManagementFee'] as int,
        capitalGainsTaxRate: json['capitalGainsTaxRate'] as int,
        rateConversion: conversion,
      );

      // A stored input that the engine would reject is not worth showing.
      if (!input.isValid) return null;

      return SavedCalculation(
        id: id,
        createdAt: DateTime.parse(createdAt).toLocal(),
        input: input,
      );
    } on Object {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());

  static SavedCalculation? tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return tryFromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SavedCalculation &&
      other.id == id &&
      other.createdAt == createdAt &&
      other.input == input;

  @override
  int get hashCode => Object.hash(id, createdAt, input);
}
