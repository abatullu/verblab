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
  // ignore: unused_field
  bool _hasTriedLoading = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
      final adManager = ref.read(adManagerProvider);
      await adManager.loadBannerAd();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          top: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      alignment: Alignment.center,
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
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      onPressed: _loadAd,
                      tooltip: 'Reintentar',
                    ),
                ],
              ),
    );
  }
}
