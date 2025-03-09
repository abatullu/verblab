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

  // Añadir para banner de página de detalle
  BannerAd? _detailPageBannerAd;
  bool _isDetailPageBannerAdLoaded = false;
  int _detailPageRetryAttempt = 0;

  // Constantes para reintentos
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  bool get isBannerAdLoaded => _isBannerAdLoaded;
  BannerAd? get bannerAd => _bannerAd;

  // Getters para el nuevo banner
  bool get isDetailPageBannerAdLoaded => _isDetailPageBannerAdLoaded;
  BannerAd? get detailPageBannerAd => _detailPageBannerAd;

  // IDs de anuncios oficiales de prueba de Google
  static const Map<String, Map<String, String>> _testBannerAdUnitIds = {
    'search': {
      'android': 'ca-app-pub-3940256099942544/6300978111',
      'ios': 'ca-app-pub-3940256099942544/2934735716',
    },
    'detail': {
      'android': 'ca-app-pub-3940256099942544/6300978111',
      'ios': 'ca-app-pub-3940256099942544/2934735716',
    },
  };

  // IDs de anuncios para producción
  static const Map<String, Map<String, String>> _prodBannerAdUnitIds = {
    'search': {
      'android':
          'ca-app-pub-3940256099942544/6300978111', // Reemplaza con tu ID real
      'ios':
          'ca-app-pub-3940256099942544/2934735716', // Reemplaza con tu ID real
    },
    'detail': {
      'android':
          'ca-app-pub-3940256099942544/6300978111', // Reemplaza con tu ID real
      'ios':
          'ca-app-pub-3940256099942544/2934735716', // Reemplaza con tu ID real
    },
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

  String _getBannerAdUnitId(String location) {
    // En debug o perfil usamos IDs de prueba, en release los reales
    final isTest = kDebugMode || kProfileMode;
    final platform =
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

    // Seleccionar el mapa correcto según entorno
    final adIdMap = isTest ? _testBannerAdUnitIds : _prodBannerAdUnitIds;
    final id = adIdMap[location]?[platform] ?? '';

    debugPrint(
      'Using AdMob ID for $location: $id (isTest: $isTest, platform: $platform)',
    );
    return id;
  }

  Future<void> loadBannerAd() async {
    if (!_isInitialized) await initialize();
    if (_bannerAd != null) return;

    try {
      final adUnitId = _getBannerAdUnitId('search');
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

  // Método para cargar banner de detalle
  Future<void> loadDetailPageBannerAd() async {
    if (!_isInitialized) await initialize();
    if (_detailPageBannerAd != null) return;

    try {
      final adUnitId = _getBannerAdUnitId('detail');
      debugPrint('Loading detail page banner ad with ID: $adUnitId');

      _detailPageBannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Detail page banner ad loaded successfully');
            _isDetailPageBannerAdLoaded = true;
            _detailPageRetryAttempt = 0;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              'Detail page banner ad failed to load: ${error.message}, code: ${error.code}',
            );
            ad.dispose();
            _detailPageBannerAd = null;
            _retryLoadDetailAd();
          },
          onAdClosed: (ad) {
            debugPrint('Detail page banner ad closed');
          },
          onAdOpened: (ad) {
            debugPrint('Detail page banner ad opened');
          },
        ),
      );

      await _detailPageBannerAd!.load();
    } catch (e, stack) {
      final error = NetworkFailure(
        message: 'Failed to load detail page banner ad',
        details: e.toString(),
        stackTrace: stack,
        severity: ErrorSeverity.low,
      );
      error.log();
      _isDetailPageBannerAdLoaded = false;
      _retryLoadDetailAd();
    }
  }

  // Método de reintento para banner de detalle
  void _retryLoadDetailAd() {
    if (_detailPageRetryAttempt < maxRetryAttempts) {
      _detailPageRetryAttempt++;
      debugPrint(
        'Retrying detail page banner ad load (attempt $_detailPageRetryAttempt of $maxRetryAttempts)',
      );

      Timer(retryDelay, () {
        _detailPageBannerAd = null;
        loadDetailPageBannerAd();
      });
    } else {
      debugPrint(
        'Detail page banner ad failed after $maxRetryAttempts attempts',
      );
      _detailPageRetryAttempt = 0;
      _isDetailPageBannerAdLoaded = false;
      notifyListeners();
    }
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
    notifyListeners();
  }

  // Método para eliminar el banner de detalle
  void disposeDetailPageBannerAd() {
    _detailPageBannerAd?.dispose();
    _detailPageBannerAd = null;
    _isDetailPageBannerAdLoaded = false;
    notifyListeners();
  }

  // Actualizar método dispose para limpiar ambos banners
  @override
  void dispose() {
    disposeBannerAd();
    disposeDetailPageBannerAd();
    super
        .dispose(); // Debemos llamar a super.dispose() ya que ChangeNotifier sí tiene un método dispose()
  }
}
