// lib/data/datasources/ads/ad_manager.dart
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/error/failures.dart';

class AdManager extends ChangeNotifier {
  // Singleton
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  bool get isBannerAdLoaded => _isBannerAdLoaded;
  BannerAd? get bannerAd => _bannerAd;

  // IDs de anuncios oficiales de prueba de Google
  // https://developers.google.com/admob/android/test-ads
  static const Map<String, String> _testBannerAdUnitIds = {
    'android': 'ca-app-pub-3940256099942544/6300978111',
    'ios': 'ca-app-pub-3940256099942544/2934735716',
  };

  // IDs de anuncios para producción (a completar en futuro)
  static const Map<String, String> _prodBannerAdUnitIds = {
    'android': 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Pendiente
    'ios': 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX', // Pendiente
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

    // Seleccionar el mapa correcto según entorno
    final adIdMap = isTest ? _testBannerAdUnitIds : _prodBannerAdUnitIds;

    return adIdMap[platform] ?? '';
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
            notifyListeners(); // Notificar a los observadores
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: ${error.message}');
            ad.dispose();
            _bannerAd = null;
            _isBannerAdLoaded = false;
            notifyListeners(); // Notificar a los observadores
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
      notifyListeners(); // Notificar a los observadores
    }
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
    notifyListeners(); // Notificar a los observadores
  }
}
