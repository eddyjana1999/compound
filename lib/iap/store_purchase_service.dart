import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'purchase_service.dart';

/// The only file in the app that imports `in_app_purchase`.
///
/// The entitlement itself is not stored here. This class reports what the
/// store said; whoever constructs it decides what to do about it, which keeps
/// the "is it paid for" question in one place and out of the SDK.
class StorePurchaseService implements PurchaseService {
  StorePurchaseService({required this.onEntitled});

  /// Called whenever the store confirms ownership — a fresh purchase, a
  /// restore, or a deferred purchase that finally cleared. It can fire at any
  /// time, including at launch, which is why it is a callback and not a
  /// return value.
  final void Function() onEntitled;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Completed by the purchase stream, since `buyNonConsumable` returns as
  /// soon as the sheet is shown rather than when the user is done with it.
  Completer<PurchaseOutcome>? _pending;

  bool _sawRestore = false;

  @override
  Future<void> initialize() async {
    _subscription ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_) => _finish(PurchaseOutcome.failed),
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != IapConfig.removeAdsProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _sawRestore = true;
          onEntitled();
          _finish(purchase.status == PurchaseStatus.restored
              ? PurchaseOutcome.restored
              : PurchaseOutcome.purchased);
        case PurchaseStatus.canceled:
          _finish(PurchaseOutcome.cancelled);
        case PurchaseStatus.error:
          _finish(PurchaseOutcome.failed);
        case PurchaseStatus.pending:
          // Ask to Buy, or a bank that takes its time. Leave the completer
          // alone; the real answer arrives in a later stream event.
          break;
      }

      // Always acknowledge, including for errors. An unfinished transaction
      // is replayed on every launch and, on iOS, blocks every purchase after
      // it.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _finish(PurchaseOutcome outcome) {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(outcome);
  }

  @override
  Future<RemoveAdsOffer?> offer() async {
    try {
      if (!await _iap.isAvailable()) return null;

      final response =
          await _iap.queryProductDetails({IapConfig.removeAdsProductId});
      if (response.productDetails.isEmpty) return null;

      final product = response.productDetails.first;
      return RemoveAdsOffer(id: product.id, price: product.price);
    } on Object {
      return null;
    }
  }

  @override
  Future<PurchaseOutcome> buy() async {
    try {
      if (!await _iap.isAvailable()) return PurchaseOutcome.unavailable;

      final response =
          await _iap.queryProductDetails({IapConfig.removeAdsProductId});
      if (response.productDetails.isEmpty) return PurchaseOutcome.unavailable;

      final completer = Completer<PurchaseOutcome>();
      _pending = completer;

      final started = await _iap.buyNonConsumable(
        purchaseParam:
            PurchaseParam(productDetails: response.productDetails.first),
      );
      if (!started) {
        _pending = null;
        return PurchaseOutcome.failed;
      }

      // A sheet the user never dismisses must not hang the button forever.
      // No `finally` clearing _pending. In an async function it runs when the
      // return is *evaluated*, not when the returned future completes — so it
      // nulled _pending before the purchase stream could ever reach it, and
      // every purchase hung until this timeout. _finish clears it instead.
      return completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          _pending = null;
          return PurchaseOutcome.pending;
        },
      );
    } on Object {
      _pending = null;
      return PurchaseOutcome.failed;
    }
  }

  @override
  Future<PurchaseOutcome> restore() async {
    try {
      if (!await _iap.isAvailable()) return PurchaseOutcome.unavailable;

      _sawRestore = false;
      final completer = Completer<PurchaseOutcome>();
      _pending = completer;

      await _iap.restorePurchases();

      // `restorePurchases` reports nothing itself — it replays past purchases
      // through the stream, and stays silent when there are none. So a short
      // wait, then treat silence as "nothing to restore".
      return completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          _pending = null;
          return _sawRestore
              ? PurchaseOutcome.restored
              : PurchaseOutcome.nothingToRestore;
        },
      );
    } on Object {
      _pending = null;
      return PurchaseOutcome.failed;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
