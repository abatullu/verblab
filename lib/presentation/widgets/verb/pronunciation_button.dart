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
/// reproduciendo audio, cargando o en estado de error. Optimizado para
/// soportar tema claro y oscuro.
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

    // Detectar si estamos en modo oscuro
    final isDarkMode = theme.brightness == Brightness.dark;

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
      child: AnimatedContainer(
        duration: VerbLabTheme.quick,
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getBackgroundColor(state, theme, withBackground, isDarkMode),
          border:
              withBackground
                  ? Border.all(
                    color: _getBorderColor(state, theme, isDarkMode),
                    width: 1,
                  )
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: isEnabled ? () => _handleTap(ref) : null,
            // Colores adaptativos según el tema
            hoverColor: theme.colorScheme.primary.withOpacity(
              isDarkMode ? 0.2 : 0.1,
            ),
            splashColor: theme.colorScheme.primary.withOpacity(
              isDarkMode ? 0.3 : 0.2,
            ),
            child: AnimatedScale(
              scale: state == TTSState.playing ? 1.1 : 1.0,
              duration: VerbLabTheme.quick,
              child: Center(
                child: AnimatedSwitcher(
                  duration: VerbLabTheme.quick,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: _buildIcon(state, theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Obtiene el color de fondo según el estado y el tema
  Color _getBackgroundColor(
    TTSState state,
    ThemeData theme,
    bool withBackground,
    bool isDarkMode,
  ) {
    if (!withBackground) {
      return Colors.transparent;
    }

    switch (state) {
      case TTSState.playing:
        return theme.colorScheme.primary.withOpacity(isDarkMode ? 0.25 : 0.15);
      case TTSState.loading:
        return theme.colorScheme.primary.withOpacity(isDarkMode ? 0.15 : 0.05);
      case TTSState.error:
        return theme.colorScheme.error.withOpacity(isDarkMode ? 0.2 : 0.1);
      case TTSState.idle:
      default:
        return theme.colorScheme.primary.withOpacity(isDarkMode ? 0.15 : 0.05);
    }
  }

  /// Obtiene el color del borde según el estado y el tema
  Color _getBorderColor(TTSState state, ThemeData theme, bool isDarkMode) {
    final opacity = isDarkMode ? 0.4 : 0.3;

    switch (state) {
      case TTSState.playing:
        return theme.colorScheme.primary.withOpacity(opacity);
      case TTSState.error:
        return theme.colorScheme.error.withOpacity(opacity);
      case TTSState.idle:
      case TTSState.loading:
      default:
        return theme.colorScheme.primary.withOpacity(isDarkMode ? 0.3 : 0.1);
    }
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
