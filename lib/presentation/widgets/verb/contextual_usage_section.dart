// lib/presentation/widgets/verb/contextual_usage_section.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/string_utils.dart';

/// Widget que muestra los usos contextuales de un verbo.
///
/// Este componente presenta los diferentes usos contextuales del verbo
/// junto con ejemplos, permitiendo al usuario entender las diferentes
/// aplicaciones del verbo en distintos contextos.
class ContextualUsageSection extends StatelessWidget {
  /// Mapa de usos contextuales (clave: contexto, valor: descripción)
  final Map<String, String> usages;

  /// Lista de ejemplos de uso del verbo
  final List<String>? examples;

  /// Formas del verbo para resaltar en los ejemplos
  final List<String> verbForms;

  /// Título de la sección
  final String title;

  const ContextualUsageSection({
    super.key,
    required this.usages,
    this.examples,
    required this.verbForms,
    this.title = 'Contextual Usage',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageEntries = usages.entries.toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(VerbLabTheme.spacing['lg']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: VerbLabTheme.spacing['md']),

            // Mostrar todos los usos contextuales
            ...usageEntries.map(
              (entry) => _buildUsageItem(context, entry, examples),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un elemento de uso contextual
  Widget _buildUsageItem(
    BuildContext context,
    MapEntry<String, String> entry,
    List<String>? examples,
  ) {
    final theme = Theme.of(context);
    final contextKey = entry.key;
    final description = entry.value;

    // Encontrar el índice del uso contextual actual
    final usageIndex = usages.keys.toList().indexOf(contextKey);

    // Seleccionar el ejemplo correspondiente si existe
    String? relevantExample;
    if (examples != null && usageIndex < examples.length) {
      relevantExample = examples[usageIndex];
    }

    return Padding(
      padding: EdgeInsets.only(bottom: VerbLabTheme.spacing['md']!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta de contexto
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: VerbLabTheme.spacing['sm']!,
              vertical: VerbLabTheme.spacing['xs']!,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(VerbLabTheme.radius['xs']!),
            ),
            child: Text(
              contextKey,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: VerbLabTheme.spacing['xs']),

          // Descripción
          Text(description, style: theme.textTheme.bodyMedium),

          // Ejemplo (si existe)
          if (relevantExample != null) ...[
            SizedBox(height: VerbLabTheme.spacing['sm']),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(VerbLabTheme.spacing['sm']!),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(VerbLabTheme.radius['xs']!),
              ),
              child: RichText(
                text: _buildFormattedExample(relevantExample, verbForms, theme),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Resalta las formas verbales en un ejemplo
  TextSpan _buildFormattedExample(
    String example,
    List<String> verbForms,
    ThemeData theme,
  ) {
    final spans = <TextSpan>[];
    String remainingText = example;

    // Iterar recursivamente para encontrar y resaltar todas las ocurrencias
    while (remainingText.isNotEmpty) {
      bool found = false;

      for (final verbForm in verbForms) {
        if (verbForm.isEmpty) continue;

        final lowercaseRemaining = remainingText.toLowerCase();
        final lowercaseForm = verbForm.toLowerCase();

        if (lowercaseRemaining.contains(lowercaseForm)) {
          final index = lowercaseRemaining.indexOf(lowercaseForm);
          final endIndex = index + verbForm.length;

          // Añadir texto antes de la forma verbal
          if (index > 0) {
            spans.add(
              TextSpan(
                text: remainingText.substring(0, index),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          // Añadir la forma verbal resaltada
          spans.add(
            TextSpan(
              text: remainingText.substring(index, endIndex),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          );

          // Actualizar el texto restante
          remainingText = remainingText.substring(endIndex);
          found = true;
          break;
        }
      }

      // Si no se encontró ninguna forma verbal, añadir el resto del texto
      if (!found) {
        spans.add(
          TextSpan(
            text: remainingText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
        break;
      }
    }

    return TextSpan(children: spans);
  }
}
