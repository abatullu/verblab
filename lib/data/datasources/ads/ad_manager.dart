// lib/data/datasources/ads/ad_manager.dart
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import '../../../core/error/failures.dart';

class AdManager extends ChangeNotifier {
  // Singleton
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  int _retryAttempt = 0;

  // Constantes para reintentos
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  bool get isBannerAdLoaded => _isBannerAdLoaded;
  BannerAd? get bannerAd => _bannerAd;

  // IDs de anuncios oficiales de prueba de Google
  static const Map<String, String> _testBannerAdUnitIds = {
    'android': 'ca-app-pub-3940256099942544/6300978111',
    'ios': 'ca-app-pub-3940256099942544/2934735716',
  };

  // IDs de anuncios para producción
  static const Map<String, String> _prodBannerAdUnitIds = {
    'android':
        'ca-app-pub-3940256099942544/6300978111', // Reemplaza con tu ID real
    'ios': 'ca-app-pub-3940256099942544/2934735716', // Reemplaza con tu ID real
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized successfully');
      notifyListeners();
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
    // En debug o perfil usamos IDs de prueba, en release los reales
    final isTest = kDebugMode || kProfileMode;
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

    // Seleccionar el mapa correcto según entorno
    final adIdMap = isTest ? _testBannerAdUnitIds : _prodBannerAdUnitIds;
    final id = adIdMap[platform] ?? '';

    debugPrint('Using AdMob ID: $id (isTest: $isTest, platform: $platform)');
    return id;
  }

  Future<void> loadBannerAd() async {
    if (!_isInitialized) await initialize();
    if (_bannerAd != null) return;

    try {
      final adUnitId = _getBannerAdUnitId();
      debugPrint('Loading banner ad with ID: $adUnitId');

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded successfully');
            _isBannerAdLoaded = true;
            _retryAttempt = 0;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              'Banner ad failed to load: ${error.message}, code: ${error.code}',
            );
            ad.dispose();
            _bannerAd = null;
            _retryLoadAd();
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
      _retryLoadAd();
    }
  }

  void _retryLoadAd() {
    if (_retryAttempt < maxRetryAttempts) {
      _retryAttempt++;
      debugPrint(
        'Retrying banner ad load (attempt $_retryAttempt of $maxRetryAttempts)',
      );

      Timer(retryDelay, () {
        _bannerAd = null;
        loadBannerAd();
      });
    } else {
      debugPrint('Banner ad failed after $maxRetryAttempts attempts');
      _retryAttempt = 0;
      _isBannerAdLoaded = false;
      notifyListeners();
    }
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
    notifyListeners();
  }
}
