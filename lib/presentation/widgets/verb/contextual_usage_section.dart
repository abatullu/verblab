// lib/presentation/widgets/verb/contextual_usage_section.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

/// Widget que muestra los usos contextuales de un verbo.
///
/// Este componente presenta los diferentes usos contextuales del verbo
/// junto con ejemplos, permitiendo al usuario entender las diferentes
/// aplicaciones del verbo en distintos contextos. Optimizado para soportar
/// tema claro y oscuro.
class ContextualUsageSection extends StatefulWidget {
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
  State<ContextualUsageSection> createState() => _ContextualUsageSectionState();
}

class _ContextualUsageSectionState extends State<ContextualUsageSection> {
  // Para controlar qué contextos están expandidos
  late final Map<String, bool> _expandedState;

  @override
  void initState() {
    super.initState();

    // Inicializar estado de expansión (todos expandidos por defecto)
    _expandedState = {for (var key in widget.usages.keys) key: true};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageEntries = widget.usages.entries.toList();
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título
          Padding(
            padding: EdgeInsets.only(
              left: VerbLabTheme.spacing['lg']!,
              right: VerbLabTheme.spacing['lg']!,
              top: VerbLabTheme.spacing['lg']!,
              bottom: VerbLabTheme.spacing['md']!,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: VerbLabTheme.spacing['xs']),
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Separador sutil
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
            indent: VerbLabTheme.spacing['lg']!,
            endIndent: VerbLabTheme.spacing['lg']!,
          ),

          // Lista de usos contextuales
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(
              horizontal: VerbLabTheme.spacing['lg']!,
              vertical: VerbLabTheme.spacing['md']!,
            ),
            itemCount: usageEntries.length,
            separatorBuilder:
                (context, index) => Divider(
                  height: VerbLabTheme.spacing['lg']! * 2,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
            itemBuilder:
                (context, index) => _buildUsageItem(
                  context,
                  usageEntries[index],
                  widget.examples,
                  index,
                  isDarkMode,
                ),
          ),
        ],
      ),
    );
  }

  /// Construye un elemento de uso contextual mejorado (compatible con dark mode)
  Widget _buildUsageItem(
    BuildContext context,
    MapEntry<String, String> entry,
    List<String>? examples,
    int index,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);
    final contextKey = entry.key;
    final description = entry.value;
    final isExpanded = _expandedState[contextKey] ?? true;

    // Encontrar el índice del uso contextual actual
    final usageIndex = widget.usages.keys.toList().indexOf(contextKey);

    // Seleccionar el ejemplo correspondiente si existe
    String? relevantExample;
    if (examples != null && usageIndex < examples.length) {
      relevantExample = examples[usageIndex];
    }

    // Generar color variado por índice para las etiquetas de contexto
    final hueShift = (index * 25) % 360; // 25 grados por categoría
    final labelBaseColor =
        HSLColor.fromColor(theme.colorScheme.primary)
            .withHue(
              (HSLColor.fromColor(theme.colorScheme.primary).hue + hueShift) %
                  360,
            )
            .toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta de contexto mejorada con mejor contraste
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedState[contextKey] = !isExpanded;
            });
          },
          child: Row(
            children: [
              // Etiqueta de categoría
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: VerbLabTheme.spacing['sm']!,
                  vertical: VerbLabTheme.spacing['xs']!,
                ),
                decoration: BoxDecoration(
                  color: labelBaseColor.withValues(
                    alpha: isDarkMode ? 0.15 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(
                    VerbLabTheme.radius['md']!,
                  ),
                  border: Border.all(
                    color: labelBaseColor.withValues(
                      alpha: isDarkMode ? 0.3 : 0.2,
                    ),
                    width: 1,
                  ),
                ),
                child: Text(
                  contextKey,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: labelBaseColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const Spacer(),

              // Icono de expansión
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: VerbLabTheme.quick,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // Espacio entre la etiqueta y el contenido
        SizedBox(height: VerbLabTheme.spacing['sm']),

        // Contenido del uso contextual con animación al expandir/contraer
        AnimatedCrossFade(
          firstChild: _buildExpandedContent(
            theme,
            description,
            relevantExample,
            isDarkMode,
            labelBaseColor,
          ),
          secondChild: _buildCollapsedContent(theme, description),
          crossFadeState:
              isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: VerbLabTheme.standard,
          sizeCurve: Curves.easeInOutCubic,
          firstCurve: Curves.easeOutCubic,
          secondCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }

  /// Construye el contenido expandido del uso contextual
  Widget _buildExpandedContent(
    ThemeData theme,
    String description,
    String? relevantExample,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Descripción con mejor tipografía
        Container(
          padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: isDarkMode ? 0.3 : 0.5,
            ),
            borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              letterSpacing: 0.15,
            ),
          ),
        ),

        // Ejemplo mejorado (si existe)
        if (relevantExample != null) ...[
          SizedBox(height: VerbLabTheme.spacing['md']),
          _buildExample(theme, relevantExample, accentColor, isDarkMode),
        ],
      ],
    );
  }

  /// Construye el contenido colapsado del uso contextual
  Widget _buildCollapsedContent(ThemeData theme, String description) {
    return Text(
      _truncateWithEllipsis(description, 80),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Construye un contenedor de ejemplo mejorado
  Widget _buildExample(
    ThemeData theme,
    String example,
    Color accentColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDarkMode ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
        border: Border.all(
          color: accentColor.withValues(alpha: isDarkMode ? 0.2 : 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta "Example"
          Container(
            margin: EdgeInsets.only(bottom: VerbLabTheme.spacing['xs']!),
            padding: EdgeInsets.symmetric(
              horizontal: VerbLabTheme.spacing['xs']!,
              vertical: VerbLabTheme.spacing['xxs']!,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDarkMode ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(VerbLabTheme.radius['xs']!),
            ),
            child: Text(
              'Example',
              style: theme.textTheme.labelSmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Ejemplo con formas verbales resaltadas
          RichText(
            text: _buildFormattedExample(
              example,
              widget.verbForms,
              theme,
              isDarkMode,
              accentColor,
            ),
          ),
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
    Color accentColor,
  ) {
    final spans = <TextSpan>[];
    String remainingText = example;

    // Ordenar las formas verbales por longitud (de más larga a más corta)
    final sortedVerbForms = List<String>.from(verbForms)
      ..sort((a, b) => b.length.compareTo(a.length));

    // Color para el texto normal según tema
    final normalTextColor =
        isDarkMode
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurfaceVariant;

    // Iterar recursivamente para encontrar y resaltar todas las ocurrencias
    while (remainingText.isNotEmpty) {
      bool found = false;

      for (final verbForm in sortedVerbForms) {
        if (verbForm.isEmpty) continue;

        final lowercaseRemaining = remainingText.toLowerCase();
        final lowercaseForm = verbForm.toLowerCase();

        if (lowercaseRemaining.contains(lowercaseForm)) {
          final index = lowercaseRemaining.indexOf(lowercaseForm);

          // Verificar si es una palabra completa
          if (!_isWholeWord(lowercaseRemaining, lowercaseForm, index)) continue;

          final endIndex = index + verbForm.length;

          // Añadir texto antes de la forma verbal
          if (index > 0) {
            spans.add(
              TextSpan(
                text: remainingText.substring(0, index),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: normalTextColor,
                  height: 1.6,
                  letterSpacing: 0.15,
                ),
              ),
            );
          }

          // Añadir la forma verbal resaltada
          spans.add(
            TextSpan(
              text: remainingText.substring(index, endIndex),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
                fontStyle: FontStyle.italic,
                height: 1.6,
                letterSpacing: 0.15,
                backgroundColor: accentColor.withValues(
                  alpha: isDarkMode ? 0.15 : 0.1,
                ),
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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: normalTextColor,
              height: 1.6,
              letterSpacing: 0.15,
            ),
          ),
        );
        break;
      }
    }

    return TextSpan(children: spans);
  }

  // Función auxiliar para verificar si es una palabra completa
  bool _isWholeWord(String text, String word, int startIndex) {
    final isStart = startIndex == 0 || !_isLetter(text[startIndex - 1]);
    final isEnd =
        startIndex + word.length == text.length ||
        !_isLetter(text[startIndex + word.length]);
    return isStart && isEnd;
  }

  bool _isLetter(String char) {
    return RegExp(r'[a-zA-Z]').hasMatch(char);
  }

  /// Trunca un texto con puntos suspensivos si supera cierta longitud
  String _truncateWithEllipsis(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }
}
