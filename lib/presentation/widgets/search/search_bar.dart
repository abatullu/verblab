// lib/presentation/widgets/search/search_bar.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/providers/app_state_notifier.dart';

/// Widget de barra de búsqueda personalizada con debounce para buscar verbos.
///
/// Esta barra de búsqueda aplica un debounce a las búsquedas para evitar
/// hacer demasiadas consultas mientras el usuario está escribiendo.
/// Incluye animaciones para transiciones entre estados y feedback visual.
class VerbSearchBar extends ConsumerStatefulWidget {
  /// Placeholder text to show when empty
  final String hintText;

  /// Callback when search is submitted using keyboard
  final Function(String)? onSubmitted;

  /// Visual style: elevated or flat
  final bool elevated;

  /// Focus node para controlar el foco externamente
  final FocusNode? focusNode;

  const VerbSearchBar({
    super.key,
    this.hintText = 'Search for a verb...',
    this.onSubmitted,
    this.elevated = true,
    this.focusNode,
  });

  @override
  ConsumerState<VerbSearchBar> createState() => _VerbSearchBarState();
}

class _VerbSearchBarState extends ConsumerState<VerbSearchBar>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  bool _isActive = false;
  Timer? _debounceTimer;
  String _lastQuery = '';

  // Controlador para animar el estado de búsqueda
  late final AnimationController _animationController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Usar el focusNode proporcionado o crear uno nuevo
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);

    // Configurar animación para el indicador de búsqueda
    _animationController = AnimationController(
      vsync: this,
      duration: VerbLabTheme.quick,
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Configurar animación repetitiva cuando está buscando
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();

    // Limpiar animación
    _animationController.dispose();

    // Solo disponer el focusNode si fue creado internamente
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChanged);
      _focusNode.dispose();
    }

    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isActive = _focusNode.hasFocus || _controller.text.isNotEmpty;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _isActive = _focusNode.hasFocus || _controller.text.isNotEmpty;
    });

    _debounceTimer?.cancel();

    final query = _controller.text.trim();
    if (query.isEmpty) {
      // Si el campo está vacío, detener animación y limpiar resultados
      _animationController.stop();
      _animationController.value = 0.0;
      _lastQuery = '';
      ref.read(appStateProvider.notifier).clearResults();
      return;
    }

    // Si el query ha cambiado, iniciar búsqueda con debounce
    if (query != _lastQuery) {
      _lastQuery = query;

      // Comenzar animación de "buscando"
      _animationController.forward();

      _debounceTimer = Timer(
        Duration(milliseconds: AppConstants.searchDebounceMillis),
        () {
          if (mounted && query.isNotEmpty) {
            // Proporcionar feedback táctil sutil al buscar
            HapticFeedback.selectionClick();
            ref.read(appStateProvider.notifier).searchVerbs(query);
          }
        },
      );
    }
  }

  void _clearSearch() {
    // Proporcionar feedback táctil al limpiar
    HapticFeedback.lightImpact();

    _controller.clear();
    _focusNode.requestFocus();
    _lastQuery = '';

    // Detener animación
    _animationController.stop();
    _animationController.value = 0.0;

    ref.read(appStateProvider.notifier).clearResults();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appStateProvider);
    final isLoading = appState.isLoading;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Si la búsqueda terminó, detener animación
    if (!isLoading && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.value = 0.0;
    }

    return AnimatedContainer(
      duration: VerbLabTheme.standard,
      curve: Curves.easeOutCubic,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
        border: Border.all(
          color:
              _isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
          width: _isActive ? 2.0 : 1.0,
        ),
        boxShadow:
            widget.elevated
                ? [
                  BoxShadow(
                    color: theme.shadowColor.withValues(
                      alpha: isLoading || _isActive ? 0.12 : 0.07,
                    ),
                    blurRadius: isLoading || _isActive ? 8.0 : 4.0,
                    offset: Offset(0, isLoading || _isActive ? 2.0 : 1.0),
                    spreadRadius: isLoading || _isActive ? 1.0 : 0.0,
                  ),
                ]
                : null,
      ),
      child: Row(
        children: [
          // Icono de búsqueda o indicador de carga
          Padding(
            padding: EdgeInsets.only(left: VerbLabTheme.spacing['md']!),
            child: AnimatedSwitcher(
              duration: VerbLabTheme.quick,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child:
                  isLoading
                      ? ScaleTransition(
                        scale: _pulseAnimation,
                        child: SizedBox(
                          key: const Key('loading_icon'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                      : Icon(
                        Icons.search,
                        key: const Key('search_icon'),
                        color:
                            _isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                      ),
            ),
          ),

          // Campo de texto para búsqueda
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: VerbLabTheme.spacing['md']!,
              ),
              child: TextField(
                key: const Key('search_field'),
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  errorBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  filled: false, // Asegurarse de que no tenga fondo relleno
                  fillColor:
                      Colors.transparent, // Hacer transparente cualquier fondo
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: isDarkMode ? 0.5 : 0.6,
                    ),
                  ),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    // Proporcionar feedback táctil al enviar búsqueda
                    HapticFeedback.mediumImpact();

                    _debounceTimer?.cancel();
                    ref.read(appStateProvider.notifier).searchVerbs(value);
                    widget.onSubmitted?.call(value);

                    // Quitar foco para ocultar teclado
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ),
          ),

          // Botón para limpiar búsqueda (solo visible cuando hay texto)
          AnimatedSwitcher(
            duration: VerbLabTheme.quick,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child:
                _controller.text.isNotEmpty
                    ? Padding(
                      padding: EdgeInsets.only(
                        right: VerbLabTheme.spacing['sm']!,
                      ),
                      child: IconButton(
                        key: const Key('clear_button'),
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _clearSearch,
                        color: theme.colorScheme.onSurfaceVariant,
                        tooltip: 'Clear search',
                        visualDensity: VisualDensity.compact,
                        splashRadius: 20,
                      ),
                    )
                    : SizedBox(width: VerbLabTheme.spacing['sm']),
          ),
        ],
      ),
    );
  }
}
