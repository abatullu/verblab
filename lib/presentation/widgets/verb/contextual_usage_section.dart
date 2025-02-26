// lib/presentation/widgets/verb/contextual_usage_section.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

/// Widget que muestra los usos contextuales de un verbo.
///
/// Este componente presenta los diferentes usos contextuales del verbo
/// junto con ejemplos, permitiendo al usuario entender las diferentes
/// aplicaciones del verbo en distintos contextos. Optimizado para soportar
/// tema claro y oscuro.
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

    // Detectar si estamos en modo oscuro
    final isDarkMode = theme.brightness == Brightness.dark;

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
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: VerbLabTheme.spacing['md']),

            // Mostrar todos los usos contextuales con mejor espaciado
            ...usageEntries.map(
              (entry) => _buildUsageItem(context, entry, examples, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un elemento de uso contextual mejorado (compatible con dark mode)
  Widget _buildUsageItem(
    BuildContext context,
    MapEntry<String, String> entry,
    List<String>? examples,
    bool isDarkMode,
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
      padding: EdgeInsets.only(bottom: VerbLabTheme.spacing['lg']!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta de contexto mejorada con mejor contraste
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: VerbLabTheme.spacing['sm']!,
              vertical: VerbLabTheme.spacing['xs']!,
            ),
            decoration: BoxDecoration(
              // Color adaptativo según el tema
              color:
                  isDarkMode
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(VerbLabTheme.radius['sm']!),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              contextKey,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          SizedBox(height: VerbLabTheme.spacing['sm']),

          // Descripción con mejor tipografía
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              letterSpacing: 0.15,
            ),
          ),

          // Ejemplo mejorado (si existe)
          if (relevantExample != null) ...[
            SizedBox(height: VerbLabTheme.spacing['md']),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
              decoration: BoxDecoration(
                // Color adaptativo según el tema
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(VerbLabTheme.radius['sm']!),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: RichText(
                text: _buildFormattedExample(
                  relevantExample,
                  verbForms,
                  theme,
                  isDarkMode,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Resalta las formas verbales en un ejemplo con mejor contraste (compatible con dark mode)
  TextSpan _buildFormattedExample(
    String example,
    List<String> verbForms,
    ThemeData theme,
    bool isDarkMode,
  ) {
    final spans = <TextSpan>[];
    String remainingText = example;

    // Color para el texto normal según tema
    final normalTextColor =
        isDarkMode
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurfaceVariant;

    // Color para las palabras resaltadas según tema
    final highlightedTextColor = theme.colorScheme.primary;

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
                  color: normalTextColor,
                  height: 1.5,
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
                color: highlightedTextColor,
                fontStyle: FontStyle.italic,
                height: 1.5,
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
              color: normalTextColor,
              height: 1.5,
            ),
          ),
        );
        break;
      }
    }

    return TextSpan(children: spans);
  }
}
