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
/// para el usuario. Optimizada para soportar tema claro y oscuro.
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

    // Detectar si estamos en modo oscuro
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: theme.colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          // Colores adaptativos según tema claro u oscuro
          splashColor: theme.colorScheme.primary.withOpacity(
            isDarkMode ? 0.15 : 0.08,
          ),
          highlightColor: theme.colorScheme.primary.withOpacity(
            isDarkMode ? 0.1 : 0.05,
          ),
          child: Padding(
            padding: EdgeInsets.all(
              compact
                  ? VerbLabTheme.spacing['md']!
                  : VerbLabTheme.spacing['lg']!,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: Forma base y badge de dialecto
                _buildHeaderRow(theme, isDarkMode, currentDialect),

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
                    _buildMeaningContainer(theme, isDarkMode),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la fila de encabezado con la forma base y el badge de dialecto
  Widget _buildHeaderRow(
    ThemeData theme,
    bool isDarkMode,
    String currentDialect,
  ) {
    return Row(
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
                  letterSpacing: -0.5, // Más compacto para verbos
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Badge de dialecto para facilitar la identificación
        _buildDialectBadge(theme, currentDialect, isDarkMode),
      ],
    );
  }

  /// Construye un badge para mostrar el dialecto actual con indicador de variantes dialectales
  Widget _buildDialectBadge(
    ThemeData theme,
    String currentDialect,
    bool isDarkMode,
  ) {
    final isUS = currentDialect == 'en-US';
    final label = isUS ? 'US' : 'UK';
    final hasVariants = verb.hasDialectVariants;

    // Configurar colores según si hay variantes y el tema
    final backgroundColor =
        hasVariants
            ? (isDarkMode
                ? theme.colorScheme.primary.withOpacity(0.25)
                : theme.colorScheme.primary.withOpacity(0.15))
            : (isDarkMode
                ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
                : theme.colorScheme.surfaceVariant);

    final borderColor =
        hasVariants
            ? theme.colorScheme.primary.withOpacity(isDarkMode ? 0.5 : 0.3)
            : theme.colorScheme.primary.withOpacity(isDarkMode ? 0.3 : 0.15);

    final textColor =
        hasVariants
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;

    // Construir el badge con animación sutil
    return AnimatedContainer(
      duration: VerbLabTheme.quick,
      padding: EdgeInsets.symmetric(
        horizontal: VerbLabTheme.spacing['sm']!,
        vertical: VerbLabTheme.spacing['xxs']!,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['full']!),
        border: Border.all(color: borderColor, width: hasVariants ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language, size: 14, color: textColor),
          SizedBox(width: VerbLabTheme.spacing['xxs']),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: hasVariants ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          // Indicador visual de variantes dialectales
          if (hasVariants) ...[
            SizedBox(width: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construye el contenedor para el significado del verbo
  Widget _buildMeaningContainer(ThemeData theme, bool isDarkMode) {
    return AnimatedContainer(
      duration: VerbLabTheme.quick,
      width: double.infinity,
      padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meaning',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: VerbLabTheme.spacing['xs']),
          Text(
            verb.meaning,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              letterSpacing: 0.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
