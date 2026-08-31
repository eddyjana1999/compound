// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Compound Lab';

  @override
  String get historyTitle => 'Tus cálculos';

  @override
  String get newCalculation => 'Nuevo cálculo';

  @override
  String get emptyTitle => 'Aún no hay cálculos guardados';

  @override
  String get emptyBody =>
      'Cuánto acumula tu dinero con los años, y cuánto te queda después de comisiones e impuestos.';

  @override
  String get startingAmount => 'Capital inicial';

  @override
  String get monthlyContribution => 'Aportación periódica';

  @override
  String get annualReturn => 'Rentabilidad anual';

  @override
  String get timeHorizon => 'Horizonte temporal';

  @override
  String yearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count años',
      one: '1 año',
    );
    return '$_temp0';
  }

  @override
  String get advanced => 'Avanzado';

  @override
  String get advancedSubtitle => 'Comisiones e impuestos';

  @override
  String get managementFee => 'Comisión de gestión anual';

  @override
  String get capitalGainsTax => 'Impuesto sobre plusvalías';

  @override
  String get optional => 'Opcional';

  @override
  String get calculate => 'Calcular';

  @override
  String get results => 'Resultados';

  @override
  String youWouldHave(String years) {
    return 'Después de $years, tendrías';
  }

  @override
  String get totalDeposited => 'Total aportado';

  @override
  String get interestEarned => 'Interés compuesto generado';

  @override
  String get feesPaid => 'Comisiones pagadas';

  @override
  String get taxPaid => 'Impuestos pagados';

  @override
  String get netProfit => 'Beneficio neto';

  @override
  String get growthOverTime => 'Evolución del capital';

  @override
  String get legendBalance => 'Saldo';

  @override
  String get legendDeposited => 'Capital aportado';

  @override
  String get save => 'Guardar';

  @override
  String get savedToHistory => 'Guardado en tus cálculos';

  @override
  String get delete => 'Eliminar';

  @override
  String get deleted => 'Eliminado';

  @override
  String get undo => 'Deshacer';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get clearAllTitle => '¿Borrar todos los cálculos?';

  @override
  String get clearAllBody =>
      'Se eliminarán todos los cálculos guardados. No se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get disclaimer =>
      'Solo estimaciones, basadas en una rentabilidad constante. No es asesoramiento financiero.';

  @override
  String get checkYourNumbers => 'Revisa tus datos';

  @override
  String yearShort(int count) {
    return 'A$count';
  }

  @override
  String get perYear => 'al año';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get appearance => 'Apariencia';

  @override
  String get systemDefault => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get currency => 'Moneda';

  @override
  String get adPrivacy => 'Privacidad de anuncios';

  @override
  String get removeAds => 'Quitar anuncios';

  @override
  String get removeAdsBody =>
      'Un solo pago. Los anuncios desaparecen para siempre.';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get purchaseThanks => 'Gracias. Los anuncios han desaparecido.';

  @override
  String get purchaseFailed => 'No se ha podido completar la compra.';

  @override
  String get nothingToRestore =>
      'No se ha encontrado ninguna compra anterior en esta cuenta.';

  @override
  String get adsRemovedTitle => 'Anuncios eliminados';

  @override
  String get addToFavourites => 'Añadir a favoritos';

  @override
  String get removeFromFavourites => 'Quitar de favoritos';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedTitle => '¿Eliminar los cálculos seleccionados?';

  @override
  String get select => 'Seleccionar';

  @override
  String get errNegativeAmount => 'Los importes no pueden ser negativos.';

  @override
  String get errHorizonTooShort => 'Elige al menos un año.';

  @override
  String get errHorizonTooLong => 'Elige 100 años o menos.';

  @override
  String get errReturnTooLow => 'La rentabilidad debe ser superior al −100 %.';

  @override
  String get errFeeRange => 'La comisión debe estar entre el 0 % y el 100 %.';

  @override
  String get errTaxRange => 'El impuesto debe estar entre el 0 % y el 100 %.';

  @override
  String get errInflationRange =>
      'La inflación debe estar entre el 0 % y el 100 %.';

  @override
  String get errGrowthRange =>
      'El aumento anual debe estar entre el 0 % y el 100 %.';

  @override
  String get errNothingInvested =>
      'Introduce un importe inicial o una aportación mensual.';

  @override
  String get share => 'Compartir';

  @override
  String get shareFailed => 'No se ha podido crear la imagen.';

  @override
  String get sharedFrom => 'Calculado con Compound Lab';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfUse => 'Términos de uso';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get assumptions => 'Supuestos';

  @override
  String get chartIsPreTax =>
      'El gráfico sigue la cartera antes del impuesto sobre plusvalías, que se descuenta una sola vez de la ganancia total al final.';

  @override
  String get errIncomplete => 'Completa la rentabilidad anual y el plazo.';

  @override
  String get chartEndsAt => 'Donde termina el gráfico';

  @override
  String get yoursAfterTax => 'Tuyo después de impuestos';

  @override
  String get rateApp => 'Valorar la app';

  @override
  String get shareApp => 'Compartir la app';

  @override
  String get shareAppMessage =>
      'Compound Lab: descubre en qué se convierte tu dinero, después de comisiones e impuestos.';

  @override
  String get home => 'Inicio';
}
