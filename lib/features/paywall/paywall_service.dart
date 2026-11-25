import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const proProductIds = <String>{
  'pro_monthly',
  'pro_yearly',
};

class PaywallService {
  PaywallService(this._iap);

  final InAppPurchase _iap;
  final _proController = StreamController<bool>.broadcast();

  Stream<bool> get isPro => _proController.stream;
  bool _isPro = false;

  Future<void> init() async {
    _iap.purchaseStream.listen(_onPurchase);
    await restorePurchases();
  }

  Future<bool> isAvailable() => _iap.isAvailable();

  Future<List<ProductDetails>> queryProducts() async {
    final response = await _iap.queryProductDetails(proProductIds);
    return response.productDetails;
  }

  Future<void> buy(ProductDetails product) async {
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchase(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        if (proProductIds.contains(p.productID)) {
          _isPro = true;
          _proController.add(true);
        }
      }
      if (p.pendingCompletePurchase) p.completePurchase();
    }
  }

  bool get pro => _isPro;

  void dispose() => _proController.close();
}

final paywallProvider = Provider<PaywallService>((ref) {
  final service = PaywallService(InAppPurchase.instance);
  service.init();
  ref.onDispose(service.dispose);
  return service;
});
