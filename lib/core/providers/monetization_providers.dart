// lib/core/providers/monetization_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import '../../data/datasources/ads/ad_manager.dart';
import '../../data/datasources/purchase/purchase_manager.dart';
import '../../data/models/purchase_details_model.dart';
import 'user_preferences_provider.dart';

// Provider para AdManager con ChangeNotifierProvider para notificaciones automáticas
final adManagerProvider = ChangeNotifierProvider<AdManager>((ref) {
  return AdManager();
});

// Provider para verificar si mostrar anuncios
final showAdsProvider = Provider<bool>((ref) {
  final isPremium = ref.watch(isPremiumProvider);
  return !isPremium;
});

// Providers para PurchaseManager
final purchaseManagerProvider = Provider<PurchaseManager>((ref) {
  return PurchaseManager();
});

// Stream provider para actualizaciones de compra
final purchaseUpdatesProvider = StreamProvider<PurchaseDetailsModel>((ref) {
  final purchaseManager = ref.watch(purchaseManagerProvider);
  return purchaseManager.onPurchaseUpdated;
});

// Provider para saber si la tienda está disponible
final storeAvailableProvider = FutureProvider<bool>((ref) async {
  final purchaseManager = ref.watch(purchaseManagerProvider);
  await purchaseManager.initialize();
  return purchaseManager.isAvailable;
});

// Provider para productos disponibles
final productsProvider = FutureProvider<List<ProductDetails>?>((ref) async {
  final purchaseManager = ref.watch(purchaseManagerProvider);
  await purchaseManager.initialize();
  return purchaseManager.products;
});
