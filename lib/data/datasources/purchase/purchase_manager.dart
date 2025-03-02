// lib/data/datasources/purchase/purchase_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../models/purchase_details_model.dart';

class PurchaseManager {
  // Singleton
  static final PurchaseManager _instance = PurchaseManager._internal();
  factory PurchaseManager() => _instance;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails>? _products;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  List<ProductDetails>? get products => _products;

  final _purchaseUpdatedController =
      StreamController<PurchaseDetailsModel>.broadcast();
  Stream<PurchaseDetailsModel> get onPurchaseUpdated =>
      _purchaseUpdatedController.stream;

  PurchaseManager._internal();

  Future<void> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        debugPrint('Store is not available');
        return;
      }

      // Configurar listener para eventos de compra
      final purchaseUpdatedSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () {
          _subscription?.cancel();
        },
        onError: (error) {
          debugPrint('Error in purchase stream: $error');
        },
      );
      _subscription = purchaseUpdatedSubscription;

      // Cargar productos disponibles
      await loadProducts();
    } catch (e, stack) {
      final error = PurchaseFailure(
        message: 'Failed to initialize in-app purchases',
        details: e.toString(),
        stackTrace: stack,
        severity: ErrorSeverity.medium,
      );
      error.log();
      _isAvailable = false;
    }
  }

  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    try {
      final productIds = <String>{AppConstants.premiumProductId};
      final response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        debugPrint('Query product error: ${response.error}');
        return;
      }

      if (response.productDetails.isEmpty) {
        debugPrint('No products found');
        return;
      }

      _products = response.productDetails;
      debugPrint('Products loaded: ${_products?.length}');
    } catch (e, stack) {
      final error = PurchaseFailure(
        message: 'Failed to load products',
        details: e.toString(),
        stackTrace: stack,
        severity: ErrorSeverity.medium,
      );
      error.log();
    }
  }

  Future<bool> purchasePremium() async {
    if (!_isAvailable || _products == null || _products!.isEmpty) {
      await initialize();
      if (!_isAvailable || _products == null || _products!.isEmpty) {
        debugPrint('Store not available or products not loaded');
        return false;
      }
    }

    // Corregido - usamos firstWhere correcto para ProductDetails
    final premiumProduct = _products!.firstWhere(
      (product) => product.id == AppConstants.premiumProductId,
      orElse: () => throw Exception('Premium product not found'),
    );

    try {
      final purchaseParam = PurchaseParam(
        productDetails: premiumProduct,
        applicationUserName: null,
      );

      return await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e, stack) {
      final error = PurchaseFailure(
        message: 'Failed to initiate purchase',
        details: e.toString(),
        stackTrace: stack,
        severity: ErrorSeverity.medium,
      );
      error.log();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (!_isAvailable) {
      await initialize();
      if (!_isAvailable) {
        debugPrint('Store not available');
        return false;
      }
    }

    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e, stack) {
      final error = PurchaseFailure(
        message: 'Failed to restore purchases',
        details: e.toString(),
        stackTrace: stack,
        severity: ErrorSeverity.medium,
      );
      error.log();
      return false;
    }
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchaseUpdatedController.add(
          PurchaseDetailsModel(
            status: purchaseDetails.status,
            productId: purchaseDetails.productID,
            message: 'Purchase pending',
          ),
        );
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _purchaseUpdatedController.add(
          PurchaseDetailsModel(
            status: purchaseDetails.status,
            productId: purchaseDetails.productID,
            message:
                'Error: ${purchaseDetails.error?.message ?? 'Unknown error'}',
          ),
        );
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _purchaseUpdatedController.add(
          PurchaseDetailsModel(
            status: purchaseDetails.status,
            productId: purchaseDetails.productID,
            message:
                purchaseDetails.status == PurchaseStatus.purchased
                    ? 'Purchase successful'
                    : 'Purchase restored',
          ),
        );
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseUpdatedController.close();
  }
}
