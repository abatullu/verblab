// lib/presentation/widgets/monetization/detail_banner_ad_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:verblab/core/providers/user_preferences_provider.dart';
import '../../../core/providers/monetization_providers.dart';
import '../../../core/themes/app_theme.dart';

class DetailBannerAdCard extends ConsumerStatefulWidget {
  const DetailBannerAdCard({super.key});

  @override
  ConsumerState<DetailBannerAdCard> createState() => _DetailBannerAdCardState();
}

class _DetailBannerAdCardState extends ConsumerState<DetailBannerAdCard>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animación de fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: VerbLabTheme.standard,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    // Cargar el anuncio
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adManager = ref.read(adManagerProvider);
    setState(() => _isLoading = true);

    try {
      await adManager.loadDetailPageBannerAd();

      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adManagerProvider).disposeDetailPageBannerAd();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adManager = ref.watch(adManagerProvider);

    // Escuchar cambios en el estado premium
    ref.listen<bool>(isPremiumProvider, (_, isPremium) {
      if (isPremium && _fadeController.value > 0) {
        // Si acaba de cambiar a premium y el anuncio está visible
        _fadeController.reverse();
      }
    });

    // No mostrar nada si no hay anuncio cargado o está en proceso pero tardando demasiado
    if (!adManager.isDetailPageBannerAdLoaded && !_isLoading) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta Ad
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(
                top: VerbLabTheme.spacing['xs']!,
                right: VerbLabTheme.spacing['xs']!,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: VerbLabTheme.spacing['xs']!,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    VerbLabTheme.radius['xs']!,
                  ),
                ),
                child: Text(
                  'Ad',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),

          // Contenedor del anuncio
          SizedBox(
            height: 70, // Altura para banner
            child:
                _isLoading
                    ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                    : FadeTransition(
                      opacity: _fadeAnimation,
                      child:
                          adManager.detailPageBannerAd != null
                              ? AdWidget(ad: adManager.detailPageBannerAd!)
                              : const SizedBox.shrink(),
                    ),
          ),

          SizedBox(height: VerbLabTheme.spacing['xs']!),
        ],
      ),
    );
  }
}
