// lib/presentation/widgets/verb/verb_meaning_card.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/models/verb_meaning.dart';
import '../../../domain/models/contextual_usage.dart';

/// Widget que muestra una acepción con sus usos contextuales expandibles.
///
/// Este componente proporciona una visualización jerárquica de cada acepción,
/// sus usos contextuales y ejemplos asociados.
class VerbMeaningCard extends StatefulWidget {
  /// Las acepciones a mostrar
  final List<VerbMeaning> meanings;

  /// Si se debe usar un diseño compacto
  final bool compact;

  /// Si se debe mostrar la nota de atribución
  final bool showAttribution;

  const VerbMeaningCard({
    super.key,
    required this.meanings,
    this.compact = false,
    this.showAttribution = true,
  });

  @override
  State<VerbMeaningCard> createState() => _VerbMeaningCardState();
}

class _VerbMeaningCardState extends State<VerbMeaningCard> {
  // Conjunto para seguir qué acepciones están expandidas
  final Set<int> _expandedMeanings = {};

  // Conjuntos para seguir qué usos contextuales están expandidos por cada acepción
  final Map<int, Set<int>> _expandedUsages = {};

  // Cache de colores para usos contextuales
  final Map<String, Color> _contextColorCache = {};

  @override
  void initState() {
    super.initState();

    // Si solo hay una acepción, expandirla automáticamente
    if (widget.meanings.length == 1) {
      _expandedMeanings.add(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          // Header con título y contador de acepciones
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
                  Icons.info_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: VerbLabTheme.spacing['xs']),
                Text(
                  'Meanings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (widget.meanings.length > 1)
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.meanings.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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

          // Lista de acepciones
          _buildMeaningsList(theme, isDarkMode),

          // Nota de atribución (opcional)
          if (widget.showAttribution)
            Padding(
              padding: EdgeInsets.all(VerbLabTheme.spacing['sm']!),
              child: Text(
                'Definitions created and curated by VerbLab language specialists.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeaningsList(ThemeData theme, bool isDarkMode) {
    // Si solo hay una acepción, mostrarla expandida automáticamente
    if (widget.meanings.length == 1) {
      return _buildMeaningContent(theme, widget.meanings[0], 0, isDarkMode);
    }

    // Para múltiples acepciones, mostrar lista con elementos expandibles
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(
        horizontal: VerbLabTheme.spacing['lg']!,
        vertical: VerbLabTheme.spacing['md']!,
      ),
      itemCount: widget.meanings.length,
      separatorBuilder:
          (context, index) => Divider(
            height: VerbLabTheme.spacing['md']! * 2,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
      itemBuilder: (context, index) {
        final meaning = widget.meanings[index];
        final isExpanded = _expandedMeanings.contains(index);

        return _buildMeaningItem(theme, meaning, index, isExpanded, isDarkMode);
      },
    );
  }

  Widget _buildMeaningItem(
    ThemeData theme,
    VerbMeaning meaning,
    int index,
    bool isExpanded,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera expandible de la acepción
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedMeanings.remove(index);
              } else {
                _expandedMeanings.add(index);
              }
            });
          },
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: VerbLabTheme.spacing['xs']!,
              horizontal: VerbLabTheme.spacing['xs']!,
            ),
            child: Row(
              children: [
                // Número de acepción
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(width: VerbLabTheme.spacing['xs']),

                // Parte del discurso
                if (meaning.partOfSpeech.isNotEmpty)
                  Text(
                    meaning.partOfSpeech,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                const Spacer(),

                // Icono de expansión
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: VerbLabTheme.quick,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: VerbLabTheme.spacing['xs']),

        // Definición (siempre visible)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: VerbLabTheme.spacing['xs']!,
          ),
          child: Text(
            meaning.definition,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ),

        // Contenido expandible de la acepción
        AnimatedCrossFade(
          firstChild: _buildMeaningContent(theme, meaning, index, isDarkMode),
          secondChild: const SizedBox(height: 0),
          crossFadeState:
              isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: VerbLabTheme.standard,
          sizeCurve: Curves.easeInOutCubic,
        ),
      ],
    );
  }

  Widget _buildMeaningContent(
    ThemeData theme,
    VerbMeaning meaning,
    int index,
    bool isDarkMode,
  ) {
    // Inicializar conjunto de usos contextuales expandidos si no existe
    if (!_expandedUsages.containsKey(index)) {
      _expandedUsages[index] = {};
    }

    final hasContextualUsages = meaning.contextualUsages.isNotEmpty;
    final hasGeneralExamples = meaning.examples.isNotEmpty;
    final hasRegister =
        meaning.register != null && meaning.register!.isNotEmpty;

    // Si no hay contenido adicional, mostrar espacio mínimo
    if (!hasContextualUsages && !hasGeneralExamples && !hasRegister) {
      return SizedBox(height: VerbLabTheme.spacing['xs']);
    }

    return Padding(
      padding: EdgeInsets.only(
        top: VerbLabTheme.spacing['sm']!,
        left: VerbLabTheme.spacing['md']!,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Registro (si existe)
          if (hasRegister)
            Text(
              meaning.register!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),

          // Ejemplos generales
          if (hasGeneralExamples) ...[
            if (hasRegister) SizedBox(height: VerbLabTheme.spacing['xs']),

            Padding(
              padding: EdgeInsets.only(top: VerbLabTheme.spacing['xs']!),
              child: Text(
                'Examples:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),

            Container(
              margin: EdgeInsets.only(top: VerbLabTheme.spacing['xxs']!),
              padding: EdgeInsets.only(
                left: VerbLabTheme.spacing['xs']!,
                top: VerbLabTheme.spacing['xs']!,
                bottom: VerbLabTheme.spacing['xs']!,
              ),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    meaning.examples
                        .map(
                          (example) => Padding(
                            padding: EdgeInsets.only(
                              bottom: VerbLabTheme.spacing['xs']!,
                            ),
                            child: Text(
                              example,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],

          // Usos contextuales
          if (hasContextualUsages) ...[
            if (hasGeneralExamples || hasRegister)
              SizedBox(height: VerbLabTheme.spacing['md']),

            Text(
              'Contextual Uses:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),

            SizedBox(height: VerbLabTheme.spacing['xs']),

            // Lista de usos contextuales
            ...meaning.contextualUsages.asMap().entries.map((entry) {
              final usageIndex = entry.key;
              final usage = entry.value;
              final isUsageExpanded = _expandedUsages[index]!.contains(
                usageIndex,
              );

              return Padding(
                padding: EdgeInsets.only(bottom: VerbLabTheme.spacing['sm']!),
                child: _buildContextualUsageItem(
                  theme,
                  usage,
                  index,
                  usageIndex,
                  isUsageExpanded,
                  isDarkMode,
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildContextualUsageItem(
    ThemeData theme,
    ContextualUsage usage,
    int meaningIndex,
    int usageIndex,
    bool isExpanded,
    bool isDarkMode,
  ) {
    // Obtener color para este contexto, usando caché
    Color contextColor = _getColorForContext(theme, usage.context, usageIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado del uso contextual
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedUsages[meaningIndex]!.remove(usageIndex);
              } else {
                _expandedUsages[meaningIndex]!.add(usageIndex);
              }
            });
          },
          splashColor: contextColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Etiqueta de contexto
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: VerbLabTheme.spacing['xs']!,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: contextColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(
                    VerbLabTheme.radius['xs']!,
                  ),
                  border: Border.all(
                    color: contextColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  usage.context,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: contextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(width: VerbLabTheme.spacing['xs']),

              // Descripción
              Expanded(
                child: Text(
                  usage.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // Icono de expansión (solo si hay ejemplos)
              if (usage.examples.isNotEmpty)
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: VerbLabTheme.quick,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),

        // Ejemplos expandibles
        if (usage.examples.isNotEmpty)
          AnimatedCrossFade(
            firstChild: _buildUsageExamples(
              theme,
              usage.examples,
              contextColor,
            ),
            secondChild: const SizedBox(height: 0),
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
            duration: VerbLabTheme.quick,
            sizeCurve: Curves.easeInOutCubic,
          ),
      ],
    );
  }

  Widget _buildUsageExamples(
    ThemeData theme,
    List<String> examples,
    Color contextColor,
  ) {
    return Container(
      margin: EdgeInsets.only(
        top: VerbLabTheme.spacing['xs']!,
        left: VerbLabTheme.spacing['md']!,
      ),
      padding: EdgeInsets.only(
        left: VerbLabTheme.spacing['xs']!,
        top: VerbLabTheme.spacing['xxs']!,
        bottom: VerbLabTheme.spacing['xxs']!,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: contextColor.withOpacity(0.3), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            examples
                .map(
                  (example) => Padding(
                    padding: EdgeInsets.only(
                      bottom: VerbLabTheme.spacing['xs']!,
                    ),
                    child: Text(
                      example,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  /// Obtener color para un contexto, usando caché para optimización
  Color _getColorForContext(ThemeData theme, String context, int index) {
    if (_contextColorCache.containsKey(context)) {
      return _contextColorCache[context]!;
    }

    final hueShift = (index * 25) % 360;
    final baseColor = theme.colorScheme.primary;
    final contextColor =
        HSLColor.fromColor(baseColor)
            .withHue((HSLColor.fromColor(baseColor).hue + hueShift) % 360)
            .toColor();

    _contextColorCache[context] = contextColor;
    return contextColor;
  }
}
