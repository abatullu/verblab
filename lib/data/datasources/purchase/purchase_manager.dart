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
  bool get isAvailable => _isAvailable || _testMode;

  List<ProductDetails>? get products => _testMode ? [_mockProduct] : _products;

  // Nuevos atributos para modo de prueba
  bool _testMode = kDebugMode; // Por defecto activado en debug
  late ProductDetails _mockProduct;

  final _purchaseUpdatedController =
      StreamController<PurchaseDetailsModel>.broadcast();
  Stream<PurchaseDetailsModel> get onPurchaseUpdated =>
      _purchaseUpdatedController.stream;

  PurchaseManager._internal() {
    _mockProduct = _createMockProduct();
  }

  // Nuevo método para activar/desactivar modo de prueba
  void setTestMode(bool enabled) {
    _testMode = enabled;
    debugPrint('Purchase Test Mode: ${_testMode ? 'ENABLED' : 'DISABLED'}');
  }

  // Nuevo método para crear producto ficticio
  ProductDetails _createMockProduct() {
    return ProductDetails(
      id: AppConstants.premiumProductId,
      title: 'VerbLab Premium (TEST)',
      description: 'Remove ads and support development (TEST MODE)',
      price: AppConstants.premiumPrice,
      rawPrice: 6.99,
      currencyCode: 'USD',
      currencySymbol: '\$',
    );
  }

  Future<void> initialize() async {
    try {
      // Si estamos en modo de prueba, simulamos que todo está disponible
      if (_testMode) {
        debugPrint('Initializing purchase manager in TEST MODE');
        _isAvailable =
            false; // Mantenemos esto en false para reflejar la realidad,
        // pero isAvailable getter devolverá true si _testMode es true
        return;
      }

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
    if (_testMode) {
      debugPrint('Loading mock products in TEST MODE');
      _products = [_mockProduct];
      return;
    }

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

  /// Verifica si el usuario tiene compras previas
  ///
  /// Nota: En la implementación actual de in_app_purchase, no hay un método directo
  /// para consultar compras pasadas. Esta función devuelve el valor almacenado en
  /// las preferencias del usuario y realmente solo verificará en tiempo real durante
  /// el proceso de restauración.
  Future<bool> verifyPurchases() async {
    if (_testMode) {
      debugPrint('TEST MODE: Skipping purchase verification');
      return false;
    }

    if (!_isAvailable) {
      debugPrint('Store not available for purchase verification');
      return false;
    }

    try {
      // En la API actual de in_app_purchase, no hay un método directo para
      // consultar compras anteriores. En su lugar, confiamos en el estado
      // almacenado en las preferencias, que se actualiza cuando se completa una compra.
      // Las compras se verifican realmente cuando el usuario restaura compras.

      debugPrint(
        'Note: Direct purchase verification not available in current in_app_purchase API',
      );
      debugPrint('Using stored premium status from preferences');

      // Devuelve siempre false aquí - la verificación real ocurre a través de
      // las preferencias del usuario y el proceso de restauración
      return false;
    } catch (e, stack) {
      final error = PurchaseFailure(
        message: 'Failed to verify purchases',
        details: e.toString(),
        stackTrace: stack,
        severity: ErrorSeverity.medium,
      );
      error.log();
      return false;
    }
  }

  Future<bool> purchasePremium() async {
    if (_testMode) {
      debugPrint('Simulating premium purchase in TEST MODE');

      // Simular un pequeño retraso para que se sienta real
      await Future.delayed(const Duration(milliseconds: 1500));

      // Enviar evento simulado de compra exitosa
      _purchaseUpdatedController.add(
        PurchaseDetailsModel(
          status: PurchaseStatus.purchased,
          productId: AppConstants.premiumProductId,
          message: 'TEST MODE: Premium purchase successful!',
        ),
      );

      return true;
    }

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
    if (_testMode) {
      debugPrint('Simulating purchase restoration in TEST MODE');

      // Simular un pequeño retraso para que se sienta real
      await Future.delayed(const Duration(milliseconds: 2000));

      // Enviar evento simulado de restauración exitosa
      _purchaseUpdatedController.add(
        PurchaseDetailsModel(
          status: PurchaseStatus.restored,
          productId: AppConstants.premiumProductId,
          message: 'TEST MODE: Premium purchase restored!',
        ),
      );

      return true;
    }

    if (!_isAvailable) {
      await initialize();
      if (!_isAvailable) {
        debugPrint('Store not available for purchase restoration');
        return false;
      }
    }

    try {
      debugPrint('Initiating purchase restoration...');
      await _inAppPurchase.restorePurchases();

      // La restauración es asíncrona y los resultados llegarán a través
      // del Stream de compras, así que notificamos éxito del inicio
      _purchaseUpdatedController.add(
        PurchaseDetailsModel(
          status: null,
          productId: AppConstants.premiumProductId,
          message: 'Restoration process initiated',
        ),
      );

      return true;
    } catch (e, stack) {
      final error = PurchaseFailure(
        message: 'Failed to restore purchases',
        details: e.toString(),
        stackTrace: stack,
        severity: ErrorSeverity.medium,
      );
      error.log();

      _purchaseUpdatedController.add(
        PurchaseDetailsModel(
          status: PurchaseStatus.error,
          productId: AppConstants.premiumProductId,
          message: 'Failed to restore purchases: ${e.toString()}',
        ),
      );

      return false;
    }
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      // Verificar si es nuestro producto premium
      final isPremiumProduct =
          purchaseDetails.productID == AppConstants.premiumProductId;

      if (purchaseDetails.status == PurchaseStatus.pending) {
        _purchaseUpdatedController.add(
          PurchaseDetailsModel(
            status: purchaseDetails.status,
            productId: purchaseDetails.productID,
            message:
                isPremiumProduct
                    ? 'Premium purchase pending'
                    : 'Purchase pending',
          ),
        );
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _purchaseUpdatedController.add(
          PurchaseDetailsModel(
            status: purchaseDetails.status,
            productId: purchaseDetails.productID,
            message:
                isPremiumProduct
                    ? 'Premium purchase error: ${purchaseDetails.error?.message ?? 'Unknown error'}'
                    : 'Purchase error: ${purchaseDetails.error?.message ?? 'Unknown error'}',
          ),
        );
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Registrar evento de compra exitosa
        debugPrint(
          'Purchase ${purchaseDetails.status == PurchaseStatus.restored ? 'restored' : 'completed'}: ${purchaseDetails.productID}',
        );

        _purchaseUpdatedController.add(
          PurchaseDetailsModel(
            status: purchaseDetails.status,
            productId: purchaseDetails.productID,
            message:
                isPremiumProduct
                    ? purchaseDetails.status == PurchaseStatus.purchased
                        ? 'Premium purchase successful!'
                        : 'Premium purchase restored!'
                    : purchaseDetails.status == PurchaseStatus.purchased
                    ? 'Purchase successful'
                    : 'Purchase restored',
          ),
        );
      }

      // Importante: completar compras pendientes
      if (purchaseDetails.pendingCompletePurchase) {
        debugPrint('Completing pending purchase: ${purchaseDetails.productID}');
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _purchaseUpdatedController.close();
  }

  // Método para verificar si estamos en modo de prueba (para UI)
  bool isTestModeActive() => _testMode;
}
