// lib/data/datasources/ads/ad_manager.dart
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Eliminada la importación no usada de app_constants
import '../../../core/error/failures.dart';

class AdManager {
  // Singleton
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  bool get isBannerAdLoaded => _isBannerAdLoaded;
  BannerAd? get bannerAd => _bannerAd;

  // IDs de anuncios para pruebas y producción - Corregida la estructura del mapa
  static const Map<String, Map<String, String>> _bannerAdUnitIds = {
    'android': {
      'test': 'ca-app-pub-3940256099942544/6300978111',
      'prod':
          'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Reemplazar con ID real
    },
    'ios': {
      'test': 'ca-app-pub-3940256099942544/2934735716',
      'prod':
          'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Reemplazar con ID real
    },
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized successfully');
    } catch (e, stack) {
      final error = NetworkFailure(
        message: 'Failed to initialize AdMob',
        details: e.toString(),
        stackTrace: stack,
        severity: ErrorSeverity.low,
      );
      error.log();
      // No lanzamos excepción para evitar bloquear la app
    }
  }

  String _getBannerAdUnitId() {
    // En debug usamos IDs de prueba
    final isTest = kDebugMode;
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    return _bannerAdUnitIds[platform]?[isTest ? 'test' : 'prod'] ?? '';
  }

  Future<void> loadBannerAd() async {
    if (!_isInitialized) await initialize();
    if (_bannerAd != null) return;

    try {
      _bannerAd = BannerAd(
        adUnitId: _getBannerAdUnitId(),
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded successfully');
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: ${error.message}');
            ad.dispose();
            _bannerAd = null;
            _isBannerAdLoaded = false;
          },
          onAdClosed: (ad) {
            debugPrint('Banner ad closed');
          },
          onAdOpened: (ad) {
            debugPrint('Banner ad opened');
          },
        ),
      );
      await _bannerAd!.load();
    } catch (e, stack) {
      final error = NetworkFailure(
        message: 'Failed to load banner ad',
        details: e.toString(),
        stackTrace: stack,
        severity: ErrorSeverity.low,
      );
      error.log();
      _isBannerAdLoaded = false;
    }
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }
}
