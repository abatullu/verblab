// lib/presentation/pages/search_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import '../../core/providers/app_state_notifier.dart';
import '../widgets/search/search_bar.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/shimmer_loading.dart';
import '../widgets/verb/verb_card.dart';

/// Pantalla principal de búsqueda de verbos.
///
/// Esta pantalla permite al usuario buscar verbos y muestra
/// los resultados con opciones para ver detalles.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  // Controlador de scroll para detectar cuando el usuario hace scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Añadir listener para detectar cuando el usuario hace scroll
    _scrollController.addListener(_dismissKeyboardOnScroll);
  }

  @override
  void dispose() {
    // Limpiar el controlador de scroll
    _scrollController.removeListener(_dismissKeyboardOnScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Método para ocultar el teclado cuando el usuario hace scroll
  void _dismissKeyboardOnScroll() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  // Método para ocultar el teclado cuando el usuario toca fuera del campo de búsqueda
  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appStateProvider);

    // Envolvemos todo el contenido con un GestureDetector para detectar toques
    return GestureDetector(
      // Ocultar teclado cuando el usuario toca fuera del campo de búsqueda
      onTap: _dismissKeyboard,
      // Importante: usar behavior opaco para interceptar todos los toques
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section con título, barra de búsqueda y selector de tema
              Padding(
                padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila con título y botón de configuración (sin ThemeToggle)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VerbLab',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Solo botón de configuración
                        IconButton(
                          icon: Icon(
                            Icons.settings_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => context.pushNamed('settings'),
                          tooltip: 'Settings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search any irregular verb form',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: VerbLabTheme.spacing['md']),
                    const VerbSearchBar(),
                  ],
                ),
              ),

              // Mensaje de error (si existe)
              if (appState.hasError)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: VerbLabTheme.spacing['md']!,
                  ),
                  child: ErrorView(
                    error: appState.error.toString(),
                    compact: true,
                    onRetry: () {
                      ref.read(appStateProvider.notifier).clearError();
                    },
                  ),
                ),

              // Área de resultados
              Expanded(child: _buildResultsArea(context, ref, appState)),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el área de resultados según el estado actual
  Widget _buildResultsArea(
    BuildContext context,
    WidgetRef ref,
    dynamic appState,
  ) {
    // Si está cargando y no hay resultados previos, mostrar shimmer
    if (appState.isLoading && !appState.hasResults) {
      return _buildLoadingState();
    }

    // Si hay resultados, mostrar lista de verbos
    if (appState.hasResults) {
      return _buildResultsList(context, ref, appState);
    }

    // Estado vacío (sin búsqueda)
    return _buildEmptyState(context);
  }

  /// Construye el estado de carga con shimmer
  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: VerbLabTheme.spacing['md']!),
      child: ShimmerLoading(
        isLoading: true,
        child: ListView.separated(
          itemCount: 3,
          padding: EdgeInsets.only(bottom: VerbLabTheme.spacing['md']!),
          separatorBuilder:
              (context, index) => SizedBox(height: VerbLabTheme.spacing['md']!),
          itemBuilder: (context, index) => const ShimmerListItem(),
        ),
      ),
    );
  }

  /// Construye la lista de resultados
  Widget _buildResultsList(
    BuildContext context,
    WidgetRef ref,
    dynamic appState,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: VerbLabTheme.spacing['md']!),
      child: ListView.separated(
        controller: _scrollController, // Asignar el controlador de scroll
        itemCount: appState.searchResults.length,
        padding: EdgeInsets.only(bottom: VerbLabTheme.spacing['md']!),
        separatorBuilder:
            (context, index) => SizedBox(height: VerbLabTheme.spacing['md']!),
        itemBuilder: (context, index) {
          final verb = appState.searchResults[index];

          // Usar Hero para animar la transición entre pantallas
          return Hero(
            tag: 'verb-card-${verb.id}',
            child: Material(
              // Necesario para que Hero funcione correctamente
              type: MaterialType.transparency,
              child: VerbCard(
                verb: verb,
                onTap: () {
                  // Ocultar teclado al navegar
                  _dismissKeyboard();
                  // Usar el contexto para navegar con GoRouter
                  context.push('/verb/${verb.id}');
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye el estado vacío (sin búsqueda)
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    // Detectar si estamos en modo oscuro para ajustar la opacidad
    final isDarkMode = theme.brightness == Brightness.dark;
    final iconOpacity = isDarkMode ? 0.7 : 0.5;

    return Center(
      child: SingleChildScrollView(
        // Añadido SingleChildScrollView para solucionar el overflow
        child: Padding(
          padding: EdgeInsets.all(VerbLabTheme.spacing['xl']!),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                MainAxisSize.min, // Añadido para minimizar el tamaño vertical
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: iconOpacity,
                ),
              ),
              SizedBox(height: VerbLabTheme.spacing['md']),
              Text(
                'Start typing to search verbs',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: VerbLabTheme.spacing['sm']),
              Text(
                'Search by base form, past tense or participle',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: isDarkMode ? 0.6 : 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
