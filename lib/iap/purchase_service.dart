/// Buying the ad-free version.
///
/// No `in_app_purchase` import here on purpose: the only implementation that
/// touches the store SDK is [StorePurchaseService], so screens and tests stay
/// free of platform channels.
library;

/// What removing ads costs, exactly as the store reports it.
///
/// The price is a string from the store, never a number this app formats.
/// A hardcoded "$2.99" is wrong in every country that does not use dollars,
/// is wrong again when Apple re-tiers prices, and is grounds for rejection.
class RemoveAdsOffer {
  const RemoveAdsOffer({required this.id, required this.price});

  final String id;

  /// Already localised and already carrying its currency symbol — "$2.99",
  /// "₪10.90", "¥400". Show it as given.
  final String price;
}

/// How a purchase or restore ended.
enum PurchaseOutcome {
  /// Bought now. Ads are off.
  purchased,

  /// Already owned, restored onto this device.
  restored,

  /// The user backed out. Not an error, and must not be reported as one.
  cancelled,

  /// Sent for approval — Ask to Buy, or a slow payment method. The entitlement
  /// arrives later through the purchase stream, not from this call.
  pending,

  /// The store said no.
  failed,

  /// No store on this device, or the product is not configured yet.
  unavailable,

  /// Restore ran and found nothing to restore.
  nothingToRestore,
}

abstract class PurchaseService {
  /// Starts listening for purchases. Must be called before [buy]: a purchase
  /// that completes while nothing is listening is a purchase the user paid
  /// for and did not receive.
  Future<void> initialize();

  /// The offer, or null when the store is unreachable or the product has not
  /// been set up yet. Callers hide the upsell rather than showing a price
  /// they had to invent.
  Future<RemoveAdsOffer?> offer();

  Future<PurchaseOutcome> buy();

  /// Required by Apple for a non-consumable. An app that can sell this but
  /// cannot restore it is rejected.
  Future<PurchaseOutcome> restore();

  void dispose();
}

/// Used in tests and wherever purchasing is switched off.
class NoOpPurchaseService implements PurchaseService {
  const NoOpPurchaseService();

  @override
  Future<void> initialize() async {}

  @override
  Future<RemoveAdsOffer?> offer() async => null;

  @override
  Future<PurchaseOutcome> buy() async => PurchaseOutcome.unavailable;

  @override
  Future<PurchaseOutcome> restore() async => PurchaseOutcome.unavailable;

  @override
  void dispose() {}
}

class IapConfig {
  IapConfig._();

  /// Must match the product id created in App Store Connect and in the Play
  /// Console. The two stores are configured separately but the id is shared.
  static const String removeAdsProductId =
      'com.compoundapp.compound.remove_ads';
}
