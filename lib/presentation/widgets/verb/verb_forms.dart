// lib/presentation/widgets/verb/verb_forms.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/verb.dart';
import '../../../domain/models/tts_state.dart';
import '../../../domain/models/verb_form.dart';
import '../../../core/providers/app_state_notifier.dart';
import 'pronunciation_button.dart';

/// Widget para mostrar las formas verbales de un verbo irregular con soporte para pronunciación.
///
/// Este componente muestra las tres formas principales de un verbo (base, past, participle)
/// con sus variantes dialectales si están disponibles, y permite reproducir la pronunciación
/// de cada forma. Se adapta tanto a la versión compacta para tarjetas como a la versión
/// expandida para la vista de detalle.
class VerbForms extends ConsumerWidget {
  /// El verbo a mostrar
  final Verb verb;

  /// Si debe mostrarse en modo compacto o expandido
  final bool compact;

  /// Estilo visual: card, flat, o custom
  final VerbFormsStyle style;

  const VerbForms({
    super.key,
    required this.verb,
    this.compact = false,
    this.style = VerbFormsStyle.card,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final theme = Theme.of(context);
    final currentDialect = appState.currentDialect;

    // Obtener las formas verbales con las variantes dialectales correctas
    final baseForm = verb.base;
    final pastForm = verb.getPast(currentDialect);
    final participleForm = verb.getParticiple(currentDialect);

    // Detectar estados de pronunciación
    final verbId = verb.id;
    final baseState = _getPlayingState(appState, verbId, 'base');
    final pastState = _getPlayingState(appState, verbId, 'past');
    final participleState = _getPlayingState(appState, verbId, 'participle');

    // Contenedor principal con estilo apropiado
    return Container(
      decoration:
          style == VerbFormsStyle.card
              ? BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              )
              : null,
      padding:
          style != VerbFormsStyle.flat
              ? EdgeInsets.all(
                compact
                    ? VerbLabTheme.spacing['sm']!
                    : VerbLabTheme.spacing['md']!,
              )
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Forma base
          _buildVerbFormRow(
            context,
            label: VerbForm.base.label,
            form: baseForm,
            tense: 'base',
            state: baseState,
            isFirst: true,
            isLast: false,
          ),

          // Divisor (si no es la última)
          if (!compact) _buildDivider(theme),

          // Forma de pasado
          _buildVerbFormRow(
            context,
            label: VerbForm.past.label,
            form: pastForm,
            tense: 'past',
            state: pastState,
            isFirst: false,
            isLast: false,
          ),

          // Divisor (si no es la última)
          if (!compact) _buildDivider(theme),

          // Forma de participio
          _buildVerbFormRow(
            context,
            label: VerbForm.participle.label,
            form: participleForm,
            tense: 'participle',
            state: participleState,
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// Obtiene el estado de reproducción actual para una forma verbal
  TTSState _getPlayingState(dynamic appState, String verbId, String tense) {
    if (appState.playingStates.containsKey(verbId) &&
        appState.playingStates[verbId]!.containsKey(tense)) {
      return appState.playingStates[verbId]![tense]!;
    }
    return TTSState.idle;
  }

  /// Construye una fila para una forma verbal
  Widget _buildVerbFormRow(
    BuildContext context, {
    required String label,
    required String form,
    required String tense,
    required TTSState state,
    required bool isFirst,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final spacing =
        compact ? VerbLabTheme.spacing['xs']! : VerbLabTheme.spacing['sm']!;

    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : spacing,
        bottom: isLast ? 0 : spacing,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Columna con etiqueta y forma
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etiqueta (BASE, PAST, etc.)
                Text(
                  label,
                  style: (compact
                          ? theme.textTheme.labelSmall
                          : theme.textTheme.labelMedium)
                      ?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                SizedBox(height: spacing / 2),

                // Valor de la forma verbal
                Text(
                  form,
                  style: (compact
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleLarge)
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Botón de pronunciación
          PronunciationButton(
            verbId: verb.id,
            tense: tense,
            size: compact ? 36 : 42,
            withBackground: style != VerbFormsStyle.flat,
          ),
        ],
      ),
    );
  }

  /// Construye un divisor entre formas verbales
  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: VerbLabTheme.spacing['md']! * 2,
      thickness: 1,
      color: theme.colorScheme.outlineVariant,
    );
  }
}

/// Estilos visuales para el componente VerbForms
enum VerbFormsStyle {
  /// Estilo de tarjeta con fondo y bordes
  card,

  /// Estilo plano sin contenedor
  flat,

  /// Estilo personalizado
  custom,
}
