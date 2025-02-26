// lib/presentation/widgets/verb/verb_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/verb.dart';
import '../../../core/providers/app_state_notifier.dart';
import 'verb_forms.dart';

/// Tarjeta que muestra la información básica de un verbo.
///
/// Este componente muestra las formas principales de un verbo y
/// proporciona una visualización clara de la información más relevante
/// para el usuario.
class VerbCard extends ConsumerWidget {
  /// El verbo a mostrar
  final Verb verb;

  /// Callback cuando se toca la tarjeta
  final VoidCallback? onTap;

  /// Si debe mostrar la versión compacta o expandida
  final bool compact;

  const VerbCard({
    super.key,
    required this.verb,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appState = ref.watch(appStateProvider);
    final currentDialect = appState.currentDialect;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: EdgeInsets.all(
            compact ? VerbLabTheme.spacing['md']! : VerbLabTheme.spacing['lg']!,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Forma base y badge de dialecto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Forma base del verbo (destacada)
                  Expanded(
                    child: Text(
                      verb.base,
                      style: (compact
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.headlineMedium)
                          ?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Mostrar siempre el badge de dialecto para facilitar la identificación
                  _buildDialectBadge(theme, currentDialect),
                ],
              ),

              SizedBox(
                height:
                    compact
                        ? VerbLabTheme.spacing['sm']
                        : VerbLabTheme.spacing['md'],
              ),

              // Componente de formas verbales
              VerbForms(
                verb: verb,
                compact: compact,
                style: VerbFormsStyle.flat, // Estilo plano para tarjetas
              ),

              if (!compact) ...[
                SizedBox(height: VerbLabTheme.spacing['md']),

                // Significado (solo en modo expandido)
                if (verb.meaning.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        VerbLabTheme.radius['md']!,
                      ),
                    ),
                    child: Text(
                      verb.meaning,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construye un badge para mostrar el dialecto actual
  Widget _buildDialectBadge(ThemeData theme, String currentDialect) {
    final isUS = currentDialect == 'en-US';
    final label = isUS ? 'US' : 'UK';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: VerbLabTheme.spacing['sm']!,
        vertical: VerbLabTheme.spacing['xs']!,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['sm']!),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language, size: 14, color: theme.colorScheme.primary),
          SizedBox(width: VerbLabTheme.spacing['xs']!),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
