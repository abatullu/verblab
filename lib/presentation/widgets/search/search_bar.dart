// lib/presentation/widgets/search/search_bar.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/providers/app_state_notifier.dart';

/// Widget de barra de búsqueda personalizada con debounce para buscar verbos.
///
/// Esta barra de búsqueda aplica un debounce a las búsquedas para evitar
/// hacer demasiadas consultas mientras el usuario está escribiendo.
class VerbSearchBar extends ConsumerStatefulWidget {
  /// Placeholder text to show when empty
  final String hintText;

  /// Callback when search is submitted using keyboard
  final Function(String)? onSubmitted;

  /// Visual style: elevated or flat
  final bool elevated;

  const VerbSearchBar({
    super.key,
    this.hintText = 'Search for a verb...',
    this.onSubmitted,
    this.elevated = true,
  });

  @override
  ConsumerState<VerbSearchBar> createState() => _VerbSearchBarState();
}

class _VerbSearchBarState extends ConsumerState<VerbSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isActive = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      setState(
        () => _isActive = _focusNode.hasFocus || _controller.text.isNotEmpty,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(
      () => _isActive = _focusNode.hasFocus || _controller.text.isNotEmpty,
    );
    _debounceTimer?.cancel();

    final query = _controller.text.trim();
    if (query.isEmpty) {
      ref.read(appStateProvider.notifier).clearResults();
      return;
    }

    _debounceTimer = Timer(
      Duration(milliseconds: AppConstants.searchDebounceMillis),
      () {
        if (mounted && query.isNotEmpty) {
          ref.read(appStateProvider.notifier).searchVerbs(query);
        }
      },
    );
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.requestFocus();
    ref.read(appStateProvider.notifier).clearResults();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appStateProvider);
    final isLoading = appState.isLoading;

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
                    color: theme.shadowColor.withOpacity(
                      isLoading ? 0.08 : 0.05,
                    ),
                    blurRadius: isLoading ? 8.0 : 4.0,
                    offset: Offset(0, isLoading ? 2.0 : 1.0),
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
              child:
                  isLoading
                      ? SizedBox(
                        key: const Key('loading_icon'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
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
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7),
                  ),
                ),
                style: theme.textTheme.bodyLarge,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _debounceTimer?.cancel();
                    ref.read(appStateProvider.notifier).searchVerbs(value);
                    widget.onSubmitted?.call(value);
                  }
                },
              ),
            ),
          ),

          // Botón para limpiar búsqueda (solo visible cuando hay texto)
          if (_controller.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: VerbLabTheme.spacing['sm']!),
              child: IconButton(
                key: const Key('clear_button'),
                icon: const Icon(Icons.close, size: 20),
                onPressed: _clearSearch,
                color: theme.colorScheme.onSurfaceVariant,
                tooltip: 'Clear search',
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
