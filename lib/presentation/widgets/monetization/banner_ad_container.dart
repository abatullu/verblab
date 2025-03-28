// lib/presentation/widgets/monetization/banner_ad_container.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:verblab/core/providers/user_preferences_provider.dart';
import '../../../core/providers/monetization_providers.dart';
import '../../../data/datasources/ads/ad_manager.dart';
import '../../../core/themes/app_theme.dart';

class BannerAdContainer extends ConsumerStatefulWidget {
  // Nuevo parámetro para configurar el espacio superior
  final double topSpacing;

  const BannerAdContainer({
    super.key,
    this.topSpacing = 4.0, // Valor predeterminado de 4px
  });

  @override
  ConsumerState<BannerAdContainer> createState() => _BannerAdContainerState();
}

class _BannerAdContainerState extends ConsumerState<BannerAdContainer>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  bool _hasTriedLoading = false;
  bool _isLoading = true;
  String? _errorMessage;
  late final AdManager _adManager;

  // Añadir controlador de animación para fade-in
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Guardar referencia al AdManager durante initState
    _adManager = ref.read(adManagerProvider);

    // Configurar animación de fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: VerbLabTheme.standard, // Duración estándar definida en theme
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _loadAd();
  }

  Future<void> _loadAd() async {
    setState(() {
      _hasTriedLoading = true;
      _isLoading = true;
      _errorMessage = null;
    });

    final showAds = ref.read(showAdsProvider);
    if (!showAds) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await _adManager.loadBannerAd();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Iniciar animación de fade-in después de cargar
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();

    // Usar WidgetsBinding para retrasar la disposición hasta después
    // de que el frame se haya completado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Esto ocurrirá después de que el frame actual termine
      _adManager.disposeBannerAd();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAds = ref.watch(showAdsProvider);
    final adManager = ref.watch(adManagerProvider);

    // No mostrar nada si es premium
    if (!showAds) return const SizedBox.shrink();

    // Escuchar cambios en el estado premium
    ref.listen<bool>(isPremiumProvider, (_, isPremium) {
      if (isPremium && _fadeController.value > 0) {
        // Si acaba de cambiar a premium y el anuncio está visible
        _fadeController.reverse();
      }
    });

    // Mostrar un contenedor visible mientras se carga o después de cargar
    return Container(
      height: 50, // Altura estándar de banner
      width: double.infinity,
      margin: EdgeInsets.only(top: widget.topSpacing), // Espacio configurable
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Fondo de la app
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant, // Usar color del tema
            width: 1,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child:
            adManager.isBannerAdLoaded && adManager.bannerAd != null
                ? AdWidget(ad: adManager.bannerAd!)
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    if (_isLoading) const SizedBox(width: 8),
                    Text(
                      _errorMessage ?? "Cargando anuncio...",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            _errorMessage != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                      ),
                    ),
                    if (!_isLoading && !adManager.isBannerAdLoaded)
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          size: 16,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        onPressed: _loadAd,
                        tooltip: 'Reintentar',
                      ),
                  ],
                ),
      ),
    );
  }
}
