// lib/presentation/widgets/monetization/premium_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/providers/monetization_providers.dart';
import 'premium_button.dart';

class PremiumDialog extends ConsumerWidget {
  const PremiumDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
      ),
      child: Padding(
        padding: EdgeInsets.all(VerbLabTheme.spacing['lg']!),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con logo premium
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDarkMode ? 0.2 : 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.stars,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: VerbLabTheme.spacing['md']),

            // Título
            Text(
              'Upgrade to Premium',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: VerbLabTheme.spacing['md']),

            // Beneficios
            ..._buildBenefits(theme),
            SizedBox(height: VerbLabTheme.spacing['lg']),

            // Precio
            Text(
              'One-time payment: ${AppConstants.premiumPrice}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: VerbLabTheme.spacing['md']),

            // Botón de compra
            const PremiumButton(),
            SizedBox(height: VerbLabTheme.spacing['sm']),

            // Botón de restaurar compras
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showRestoreDialog(context, ref);
              },
              child: const Text('Restore Purchases'),
            ),

            // Botón para cerrar
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBenefits(ThemeData theme) {
    final benefits = [
      'Remove all advertisements',
      'Support independent development',
      'One-time purchase (no subscription)',
    ];

    return benefits.map((benefit) {
      return Padding(
        padding: EdgeInsets.only(bottom: VerbLabTheme.spacing['sm']!),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: VerbLabTheme.spacing['sm']),
            Expanded(child: Text(benefit, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );
    }).toList();
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restore Purchases'),
            content: const Text(
              'This will restore your premium status if you\'ve previously purchased it on this device or with the same account.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Mostrar indicador de carga
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restoring purchases...'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Llamar al método real de restauración
                  final purchaseManager = ref.read(purchaseManagerProvider);
                  final result = await purchaseManager.restorePurchases();

                  if (!result && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to start restoration process. Please try again later.',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  // Los resultados exitosos se manejarán a través del Stream de compras
                },
                child: const Text('Restore'),
              ),
            ],
          ),
    );
  }
}
