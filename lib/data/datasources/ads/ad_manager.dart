// lib/data/datasources/ads/ad_manager.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'dart:io'; // Importado para usar Platform
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
      // Pequeño delay antes de la inicialización para iOS
      if (Platform.isIOS) {
        debugPrint('iOS platform detected, adding initialization delay');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Configuración para anuncios más adecuada
      final RequestConfiguration config = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      );

      debugPrint('Updating ad request configuration');
      await MobileAds.instance.updateRequestConfiguration(config);

      debugPrint('Initializing MobileAds');
      final initStatus = await MobileAds.instance.initialize();

      // Log detallado del estado de inicialización
      debugPrint('AdMob SDK initialized successfully');
      initStatus.adapterStatuses.forEach((adapter, status) {
        debugPrint('Adapter status for $adapter: ${status.state}');
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('Error initializing AdMob: $e');
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

      // Pequeño delay antes de cargar el anuncio (especialmente útil en iOS)
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

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
            // No llamar a dispose() inmediatamente para evitar errores en iOS
            _bannerAd = null;
            _isBannerAdLoaded = false;
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

      // Utilizar Future.delayed para evitar problemas en iOS
      await Future.delayed(const Duration(milliseconds: 100));
      await _bannerAd!.load();
    } catch (e, stack) {
      debugPrint('Error loading banner ad: $e');
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

      // Mayor delay para iOS
      final delay = Platform.isIOS ? const Duration(seconds: 6) : retryDelay;

      Timer(delay, () {
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

      // Pequeño delay antes de cargar el anuncio (especialmente útil en iOS)
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

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
            // No llamar a dispose() inmediatamente para evitar errores en iOS
            _detailPageBannerAd = null;
            _isDetailPageBannerAdLoaded = false;
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

      // Utilizar Future.delayed para evitar problemas en iOS
      await Future.delayed(const Duration(milliseconds: 100));
      await _detailPageBannerAd!.load();
    } catch (e, stack) {
      debugPrint('Error loading detail page banner ad: $e');
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

      // Mayor delay para iOS
      final delay = Platform.isIOS ? const Duration(seconds: 6) : retryDelay;

      Timer(delay, () {
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
    // Usar Future.delayed para iOS para evitar problemas de sincronización
    if (Platform.isIOS) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _bannerAd?.dispose();
        _bannerAd = null;
        _isBannerAdLoaded = false;
        notifyListeners();
      });
    } else {
      _bannerAd?.dispose();
      _bannerAd = null;
      _isBannerAdLoaded = false;
      notifyListeners();
    }
  }

  // Método para eliminar el banner de detalle
  void disposeDetailPageBannerAd() {
    // Usar Future.delayed para iOS para evitar problemas de sincronización
    if (Platform.isIOS) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _detailPageBannerAd?.dispose();
        _detailPageBannerAd = null;
        _isDetailPageBannerAdLoaded = false;
        notifyListeners();
      });
    } else {
      _detailPageBannerAd?.dispose();
      _detailPageBannerAd = null;
      _isDetailPageBannerAdLoaded = false;
      notifyListeners();
    }
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
