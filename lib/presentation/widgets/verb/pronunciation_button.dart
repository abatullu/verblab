// lib/presentation/widgets/verb/pronunciation_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/models/tts_state.dart';
import '../../../core/providers/app_state_notifier.dart';

/// Botón para reproducir la pronunciación de una forma verbal.
///
/// Este botón muestra diferentes estados visuales según si está
/// reproduciendo audio, cargando o en estado de error.
class PronunciationButton extends ConsumerWidget {
  /// ID del verbo a pronunciar
  final String verbId;

  /// Forma verbal a pronunciar (base, past, participle)
  final String tense;

  /// Dialecto a usar (en-US, en-UK)
  final String? dialect;

  /// Tamaño del botón
  final double size;

  /// Si debe tener un color de fondo
  final bool withBackground;

  const PronunciationButton({
    super.key,
    required this.verbId,
    required this.tense,
    this.dialect,
    this.size = 32,
    this.withBackground = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appState = ref.watch(appStateProvider);

    // Determinar el estado actual de reproducción
    TTSState state = TTSState.idle;
    if (appState.playingStates.containsKey(verbId) &&
        appState.playingStates[verbId]!.containsKey(tense)) {
      state = appState.playingStates[verbId]![tense]!;
    }

    // Determinar si el botón está habilitado
    final bool isEnabled =
        state != TTSState.loading && state != TTSState.playing;

    // Tooltip según el estado
    final String tooltipText =
        state == TTSState.playing ? 'Stop pronunciation' : 'Play pronunciation';

    return Tooltip(
      message: tooltipText,
      child: InkWell(
        onTap: isEnabled ? () => _handleTap(ref) : null,
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['full'] ?? 50),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                withBackground
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                    : Colors.transparent,
          ),
          child: AnimatedSwitcher(
            duration: VerbLabTheme.quick,
            child: _buildIcon(state, theme),
          ),
        ),
      ),
    );
  }

  /// Maneja el tap en el botón
  void _handleTap(WidgetRef ref) {
    // Proporcionar feedback táctil
    HapticFeedback.lightImpact();

    // Llamar al método de pronunciación
    ref
        .read(appStateProvider.notifier)
        .playPronunciation(verbId, tense: tense, dialect: dialect);
  }

  /// Construye el icono según el estado actual
  Widget _buildIcon(TTSState state, ThemeData theme) {
    switch (state) {
      case TTSState.idle:
        return Icon(
          Icons.volume_up,
          key: const ValueKey('icon_idle'),
          size: size * 0.6,
          color: theme.colorScheme.primary,
        );
      case TTSState.loading:
        return SizedBox(
          key: const ValueKey('icon_loading'),
          width: size * 0.6,
          height: size * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        );
      case TTSState.playing:
        return Icon(
          Icons.pause,
          key: const ValueKey('icon_playing'),
          size: size * 0.6,
          color: theme.colorScheme.primary,
        );
      case TTSState.error:
        return Icon(
          Icons.error_outline,
          key: const ValueKey('icon_error'),
          size: size * 0.6,
          color: theme.colorScheme.error,
        );
    }
  }
}
