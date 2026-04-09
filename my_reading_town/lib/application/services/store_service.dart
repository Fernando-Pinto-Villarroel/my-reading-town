import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:my_reading_town/app_constants.dart';
import 'package:my_reading_town/domain/rules/store_rules.dart';

enum StorePurchaseState { idle, pending, success, error, cancelled }

class StorePurchaseResult {
  final StorePurchaseState state;
  final String? errorMessage;

  const StorePurchaseResult({required this.state, this.errorMessage});
}

class StoreService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  bool _initialized = false;

  StorePurchaseState _purchaseState = StorePurchaseState.idle;
  String? _pendingProductId;

  bool get available => _available;
  bool get initialized => _initialized;
  StorePurchaseState get purchaseState => _purchaseState;

  Future<void> initialize() async {
    if (_initialized) return;

    if (!AppConstants.playStore) {
      _available = true;
      _initialized = true;
      notifyListeners();
      return;
    }

    _available = await _iap.isAvailable();
    if (!_available) {
      _initialized = true;
      notifyListeners();
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );

    _initialized = true;
    notifyListeners();
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _purchaseState = StorePurchaseState.pending;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        _purchaseState = StorePurchaseState.error;
        notifyListeners();
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        _purchaseState = StorePurchaseState.cancelled;
        notifyListeners();
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  void _completePurchase(PurchaseDetails purchase) {
    _pendingProductId = purchase.productID;
    _purchaseState = StorePurchaseState.success;
    notifyListeners();
    if (purchase.pendingCompletePurchase) {
      _iap.completePurchase(purchase);
    }
  }

  Future<StorePurchaseResult> purchaseGems(StoreGemsItem item) async {
    if (!AppConstants.playStore) {
      return const StorePurchaseResult(state: StorePurchaseState.success);
    }

    return _launchPurchase(item.productId);
  }

  Future<StorePurchaseResult> purchasePack(StorePack pack) async {
    if (!AppConstants.playStore) {
      return const StorePurchaseResult(state: StorePurchaseState.success);
    }

    return _launchPurchase(pack.productId);
  }

  Future<StorePurchaseResult> purchaseSpecies(String productId) async {
    if (!AppConstants.playStore) {
      return const StorePurchaseResult(state: StorePurchaseState.success);
    }

    return _launchPurchase(productId);
  }

  Future<StorePurchaseResult> _launchPurchase(String productId) async {
    if (!_available) {
      return const StorePurchaseResult(
        state: StorePurchaseState.error,
        errorMessage: 'Store not available',
      );
    }

    final response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      return const StorePurchaseResult(
        state: StorePurchaseState.error,
        errorMessage: 'Product not found',
      );
    }

    final purchaseParam = PurchaseParam(
      productDetails: response.productDetails.first,
    );

    _purchaseState = StorePurchaseState.pending;
    notifyListeners();

    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return const StorePurchaseResult(state: StorePurchaseState.pending);
    } catch (e) {
      _purchaseState = StorePurchaseState.error;
      notifyListeners();
      return StorePurchaseResult(
        state: StorePurchaseState.error,
        errorMessage: e.toString(),
      );
    }
  }

  String? consumePendingProductId() {
    final id = _pendingProductId;
    _pendingProductId = null;
    _purchaseState = StorePurchaseState.idle;
    return id;
  }

  void resetState() {
    _purchaseState = StorePurchaseState.idle;
    _pendingProductId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
