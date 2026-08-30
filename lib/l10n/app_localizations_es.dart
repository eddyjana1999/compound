// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Compound';

  @override
  String get historyTitle => 'Tus cálculos';

  @override
  String get newCalculation => 'Nuevo cálculo';

  @override
  String get emptyTitle => 'Aún no hay nada';

  @override
  String get emptyBody =>
      'Haz tu primera proyección y descubre lo que logra el interés compuesto.';

  @override
  String get startingAmount => 'Importe inicial';

  @override
  String get monthlyContribution => 'Aportación mensual';

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
  String get interestEarned => 'Intereses generados';

  @override
  String get feesPaid => 'Comisiones pagadas';

  @override
  String get taxPaid => 'Impuestos pagados';

  @override
  String get netProfit => 'Beneficio neto';

  @override
  String get growthOverTime => 'Crecimiento en el tiempo';

  @override
  String get legendBalance => 'Saldo';

  @override
  String get legendDeposited => 'Aportado';

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
}
