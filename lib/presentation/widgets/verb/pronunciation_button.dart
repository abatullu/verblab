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
/// soportar tema claro y oscuro, con animaciones sutiles para mejorar
/// la experiencia del usuario.
class PronunciationButton extends ConsumerStatefulWidget {
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

  /// Color de acento para el botón (opcional)
  final Color? accentColor;

  const PronunciationButton({
    super.key,
    required this.verbId,
    required this.tense,
    this.dialect,
    this.size = 32,
    this.withBackground = false,
    this.accentColor,
  });

  @override
  ConsumerState<PronunciationButton> createState() =>
      _PronunciationButtonState();
}

class _PronunciationButtonState extends ConsumerState<PronunciationButton>
    with SingleTickerProviderStateMixin {
  // Animación para el efecto de pulso durante reproducción
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animación de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    // Configurar repetición de animación
    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reset();
        _pulseController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appStateProvider);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Obtener color de acento para usar en los efectos
    final Color accentColor = widget.accentColor ?? theme.colorScheme.primary;

    // Determinar el estado actual de reproducción
    TTSState state = TTSState.idle;
    if (appState.playingStates.containsKey(widget.verbId) &&
        appState.playingStates[widget.verbId]!.containsKey(widget.tense)) {
      state = appState.playingStates[widget.verbId]![widget.tense]!;
    }

    // Gestionar animación según estado
    if (state == TTSState.playing) {
      if (!_pulseController.isAnimating) {
        _pulseController.forward();
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    // Determinar si el botón está habilitado
    final bool isEnabled = state.isInteractive;

    // Tooltip según el estado
    final String tooltipText =
        state == TTSState.playing
            ? 'Stop pronunciation'
            : state == TTSState.error
            ? 'Error playing pronunciation'
            : 'Play pronunciation';

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: state == TTSState.playing ? _pulseAnimation.value : 1.0,
          child: Tooltip(
            message: tooltipText,
            waitDuration: const Duration(milliseconds: 500),
            child: AnimatedContainer(
              duration: VerbLabTheme.quick,
              curve: Curves.easeOutCubic,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getBackgroundColor(
                  state,
                  theme,
                  isDarkMode,
                  accentColor,
                ),
                border:
                    widget.withBackground
                        ? Border.all(
                          color: _getBorderColor(
                            state,
                            theme,
                            isDarkMode,
                            accentColor,
                          ),
                          width: 1.5,
                        )
                        : null,
                boxShadow:
                    state == TTSState.playing
                        ? [
                          BoxShadow(
                            color: accentColor.withOpacity(
                              isDarkMode ? 0.3 : 0.2,
                            ),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                        : null,
              ),
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isEnabled ? () => _handleTap(ref) : null,
                  hoverColor: accentColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                  splashColor: accentColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: VerbLabTheme.quick,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _buildIcon(state, theme, accentColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Obtiene el color de fondo según el estado, tema y color de acento
  Color _getBackgroundColor(
    TTSState state,
    ThemeData theme,
    bool isDarkMode,
    Color accentColor,
  ) {
    if (!widget.withBackground) {
      return Colors.transparent;
    }

    switch (state) {
      case TTSState.playing:
        return accentColor.withOpacity(isDarkMode ? 0.25 : 0.15);
      case TTSState.loading:
        return accentColor.withOpacity(isDarkMode ? 0.15 : 0.05);
      case TTSState.error:
        return theme.colorScheme.error.withOpacity(isDarkMode ? 0.2 : 0.1);
      case TTSState.idle:
        return accentColor.withOpacity(isDarkMode ? 0.15 : 0.05);
    }
  }

  /// Obtiene el color del borde según el estado, tema y color de acento
  Color _getBorderColor(
    TTSState state,
    ThemeData theme,
    bool isDarkMode,
    Color accentColor,
  ) {
    switch (state) {
      case TTSState.playing:
        return accentColor.withOpacity(isDarkMode ? 0.6 : 0.4);
      case TTSState.error:
        return theme.colorScheme.error;
      case TTSState.idle:
      case TTSState.loading:
        return accentColor.withOpacity(isDarkMode ? 0.4 : 0.25);
    }
  }

  /// Maneja el tap en el botón con feedback apropiado
  void _handleTap(WidgetRef ref) {
    // Proporcionar feedback táctil adaptado al estado
    if (ref.read(appStateProvider).playingStates.containsKey(widget.verbId) &&
        ref
                .read(appStateProvider)
                .playingStates[widget.verbId]
                ?.containsKey(widget.tense) ==
            true) {
      // Si está reproduciendo, proporcionar feedback de detención
      HapticFeedback.mediumImpact();
    } else {
      // Si va a comenzar reproducción, proporcionar feedback más sutil
      HapticFeedback.selectionClick();
    }

    // Llamar al método de pronunciación
    ref
        .read(appStateProvider.notifier)
        .playPronunciation(
          widget.verbId,
          tense: widget.tense,
          dialect: widget.dialect,
        );
  }

  /// Construye el icono según el estado actual con tamaños optimizados
  Widget _buildIcon(TTSState state, ThemeData theme, Color accentColor) {
    final iconSize = widget.size * 0.55;

    switch (state) {
      case TTSState.idle:
        return Icon(
          Icons.volume_up_rounded,
          key: const ValueKey('icon_idle'),
          size: iconSize,
          color: accentColor,
        );
      case TTSState.loading:
        return SizedBox(
          key: const ValueKey('icon_loading'),
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        );
      case TTSState.playing:
        return Stack(
          key: const ValueKey('icon_playing'),
          alignment: Alignment.center,
          children: [
            Container(
              width: iconSize * 0.8,
              height: iconSize * 0.8,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            Icon(Icons.pause_rounded, size: iconSize, color: accentColor),
          ],
        );
      case TTSState.error:
        return Icon(
          Icons.error_outline_rounded,
          key: const ValueKey('icon_error'),
          size: iconSize,
          color: theme.colorScheme.error,
        );
    }
  }
}
