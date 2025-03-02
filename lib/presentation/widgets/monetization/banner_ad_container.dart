// lib/presentation/widgets/monetization/banner_ad_container.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/providers/monetization_providers.dart';

class BannerAdContainer extends ConsumerStatefulWidget {
  const BannerAdContainer({super.key});

  @override
  ConsumerState<BannerAdContainer> createState() => _BannerAdContainerState();
}

class _BannerAdContainerState extends ConsumerState<BannerAdContainer> {
  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final showAds = ref.read(showAdsProvider);
    if (!showAds) return;

    final adManager = ref.read(adManagerProvider);
    await adManager.loadBannerAd();
    // Forzar reconstrucción cuando el anuncio se carga
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final adManager = ref.read(adManagerProvider);
    adManager.disposeBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAds = ref.watch(showAdsProvider);
    final adManager = ref.watch(adManagerProvider);

    // No mostrar nada si es premium
    if (!showAds) return const SizedBox.shrink();

    // Mostrar un contenedor visible mientras se carga o después de cargar
    return Container(
      height: 50, // Altura estándar de banner
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
      ),
      alignment: Alignment.center,
      child:
          adManager.isBannerAdLoaded && adManager.bannerAd != null
              ? SizedBox(
                width: adManager.bannerAd!.size.width.toDouble(),
                height: adManager.bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: adManager.bannerAd!),
              )
              : Text(
                "Cargando anuncio...",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
    );
  }
}
