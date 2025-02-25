// lib/presentation/widgets/common/error_view.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

/// Widget para mostrar errores de manera elegante con posibilidad de reintentar.
///
/// Ofrece dos modos de visualización:
/// - Compacto: Para mostrar errores en elementos UI pequeños
/// - Estándar: Para páginas completas o secciones grandes
class ErrorView extends StatelessWidget {
  /// Mensaje de error a mostrar
  final String error;

  /// Callback opcional para reintentar la acción que falló
  final VoidCallback? onRetry;

  /// Si es true, muestra una versión compacta (banner)
  final bool compact;

  /// Icono a mostrar (opcional, por defecto es error_outline)
  final IconData icon;

  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompactView(theme);
    } else {
      return _buildFullView(theme);
    }
  }

  /// Construye una vista compacta tipo banner/snackbar
  Widget _buildCompactView(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: VerbLabTheme.spacing['md']!,
        vertical: VerbLabTheme.spacing['sm']!,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
        border: Border.all(color: theme.colorScheme.errorContainer, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.error),
          SizedBox(width: VerbLabTheme.spacing['sm']),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              color: theme.colorScheme.error,
              onPressed: onRetry,
              tooltip: 'Try again',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  /// Construye una vista completa centrada
  Widget _buildFullView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(VerbLabTheme.spacing['lg']!),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.error),
            SizedBox(height: VerbLabTheme.spacing['md']),
            Text(
              error,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: VerbLabTheme.spacing['lg']),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
