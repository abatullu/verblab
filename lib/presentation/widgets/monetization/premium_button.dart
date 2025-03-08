// lib/presentation/widgets/monetization/premium_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:verblab/data/models/purchase_details_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/providers/monetization_providers.dart';
import '../../../core/providers/user_preferences_provider.dart';
import '../common/error_view.dart';

class PremiumButton extends ConsumerStatefulWidget {
  final bool compact;

  const PremiumButton({super.key, this.compact = false});

  @override
  ConsumerState<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends ConsumerState<PremiumButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializar el gestor de compras
    Future.microtask(() {
      ref.read(purchaseManagerProvider).initialize();
    });
  }

  bool _isOnPremiumPage() {
    // Verificar si estamos en la página de premium
    final state = GoRouterState.of(context);
    final String currentPath = state.uri.toString(); // o state.matchedLocation
    return currentPath.startsWith('/premium');
  }

  Future<void> _purchasePremium() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final result = await ref.read(purchaseManagerProvider).purchasePremium();

    if (!result) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start purchase. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final storeAvailable = ref.watch(storeAvailableProvider);
    final isTestMode = ref.watch(purchaseTestModeProvider);

    // Mover la escucha del provider a build
    ref.listen<AsyncValue<PurchaseDetailsModel>>(purchaseUpdatesProvider, (
      _,
      next,
    ) {
      next.whenData((purchaseDetails) {
        // Actualizar UI según el estado de la compra
        setState(() => _isLoading = false);

        // Mostrar feedback según el resultado
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                purchaseDetails.message ?? 'Purchase update received',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Actualizar estado premium si la compra fue exitosa
        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          ref
              .read(userPreferencesNotifierProvider.notifier)
              .setPremiumStatus(true);
        }
      });
    });

    // Ya es premium
    if (isPremium) {
      return _buildPremiumBadge(theme);
    }

    // Error en tienda
    return storeAvailable.when(
      data: (isAvailable) {
        if (!isAvailable && !isTestMode) {
          return _buildErrorState();
        }
        return _buildPurchaseButton(theme, isTestMode);
      },
      loading:
          () => const SizedBox(
            height: 36,
            width: 36,
            child: CircularProgressIndicator(),
          ),
      error: (_, __) => _buildErrorState(),
    );
  }

  Widget _buildPremiumBadge(ThemeData theme) {
    // Determinar si debemos usar colores más vibrantes
    final isDarkMode = theme.brightness == Brightness.dark;

    // Color más distintivo para el badge premium
    final premiumGold =
        isDarkMode
            ? const Color(0xFFFFD700).withOpacity(
              0.8,
            ) // Gold con ligera transparencia para dark mode
            : const Color(0xFFFFD700); // Gold sólido para light mode

    // Color de fondo para el badge
    final backgroundColor =
        isDarkMode
            ? premiumGold.withOpacity(0.15)
            : premiumGold.withOpacity(0.1);

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: premiumGold.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(Icons.stars, color: premiumGold, size: 20),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: VerbLabTheme.spacing['md']!,
        vertical: VerbLabTheme.spacing['xs']!,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['full']!),
        border: Border.all(color: premiumGold.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: premiumGold.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, size: 16, color: premiumGold),
          SizedBox(width: VerbLabTheme.spacing['xs']),
          Text(
            'Premium',
            style: theme.textTheme.labelMedium?.copyWith(
              color: premiumGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return widget.compact
        ? Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium,
            color: Colors.orange,
            size: 20,
          ),
        )
        : const ErrorView(
          error: 'Store not available',
          compact: true,
          icon: Icons.store,
        );
  }

  Widget _buildPurchaseButton(ThemeData theme, bool isTestMode) {
    if (widget.compact) {
      return isTestMode
          ? Tooltip(
            message: 'Test Mode Active',
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon:
                      _isLoading
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                          )
                          : const Icon(Icons.workspace_premium),
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            if (!_isOnPremiumPage()) {
                              context.pushNamed('premium');
                            } else {
                              _purchasePremium();
                            }
                          },
                  tooltip: 'Remove Ads',
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          )
          : IconButton(
            icon:
                _isLoading
                    ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                    : const Icon(Icons.workspace_premium),
            onPressed:
                _isLoading
                    ? null
                    : () {
                      if (!_isOnPremiumPage()) {
                        context.pushNamed('premium');
                      } else {
                        _purchasePremium();
                      }
                    },
            tooltip: 'Remove Ads',
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: _isLoading ? null : _purchasePremium,
          icon:
              _isLoading
                  ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                  : const Icon(Icons.workspace_premium),
          label: Text('Remove Ads (${AppConstants.premiumPrice})'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size(200, 48), // Hacer el botón más prominente
            padding: EdgeInsets.symmetric(
              horizontal: VerbLabTheme.spacing['lg']!,
              vertical: VerbLabTheme.spacing['sm']!,
            ),
          ),
        ),
        if (isTestMode)
          Padding(
            padding: EdgeInsets.only(top: VerbLabTheme.spacing['xs']!),
            child: Text(
              'TEST MODE',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
