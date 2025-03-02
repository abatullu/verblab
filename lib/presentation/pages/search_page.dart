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

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  // Controlador de scroll para detectar cuando el usuario hace scroll
  final ScrollController _scrollController = ScrollController();

  // Controlador para animaciones
  late final AnimationController _animationController;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _slideUpAnimation;

  @override
  void initState() {
    super.initState();
    // Añadir listener para detectar cuando el usuario hace scroll
    _scrollController.addListener(_dismissKeyboardOnScroll);

    // Configurar animaciones para elementos de UI
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Animación para fade in de elementos
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // Animación para deslizamiento hacia arriba
    _slideUpAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Iniciar animaciones después de que el frame se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    // Limpiar el controlador de scroll
    _scrollController.removeListener(_dismissKeyboardOnScroll);
    _scrollController.dispose();

    // Limpiar controlador de animación
    _animationController.dispose();

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
    final isDarkMode = theme.brightness == Brightness.dark;

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
              _buildHeaderSection(theme, isDarkMode),

              // Mensaje de error (si existe)
              if (appState.hasError) _buildErrorSection(appState),

              // Área de resultados
              Expanded(
                child: _buildResultsArea(context, ref, appState, isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la sección de cabecera de la página
  Widget _buildHeaderSection(ThemeData theme, bool isDarkMode) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Transform.translate(
        offset: Offset(0, _slideUpAnimation.value),
        child: Padding(
          padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila con título y botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VerbLab',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Settings button
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
      ),
    );
  }

  /// Construye la sección de error si es necesario
  Widget _buildErrorSection(dynamic appState) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: VerbLabTheme.spacing['md']!),
      child: ErrorView(
        error: appState.error.toString(),
        compact: true,
        onRetry: () {
          ref.read(appStateProvider.notifier).clearError();
        },
      ),
    );
  }

  /// Construye el área de resultados según el estado actual
  Widget _buildResultsArea(
    BuildContext context,
    WidgetRef ref,
    dynamic appState,
    bool isDarkMode,
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
    return _buildEmptyState(context, isDarkMode);
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

                  // Navegar a la página de detalle del verbo
                  context.push('/verb/${verb.id}');
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye el estado vacío (sin búsqueda) con visuales mejorados
  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    // Efectos visuales mejorados para el estado vacío
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(VerbLabTheme.spacing['xl']!),
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: Transform.translate(
              offset: Offset(0, _slideUpAnimation.value),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono con animación de pulso sutil
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.9, end: 1.05),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeInOutSine,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: isDarkMode ? 0.15 : 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: VerbLabTheme.spacing['md']),
                  Text(
                    'Start typing to search verbs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: VerbLabTheme.spacing['sm']),

                  // Instrucciones mejoradas
                  Container(
                    padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: isDarkMode ? 0.5 : 0.7),
                      borderRadius: BorderRadius.circular(
                        VerbLabTheme.radius['md']!,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSearchTip(
                          theme,
                          icon: Icons.text_fields_rounded,
                          text: 'Search by base form, past tense or participle',
                        ),
                        SizedBox(height: VerbLabTheme.spacing['sm']),
                        _buildSearchTip(
                          theme,
                          icon: Icons.travel_explore_rounded,
                          text: 'Find US/UK variations and pronunciations',
                        ),
                        SizedBox(height: VerbLabTheme.spacing['sm']),
                        _buildSearchTip(
                          theme,
                          icon: Icons.volume_up_rounded,
                          text:
                              'Listen to correct pronunciation in both dialects',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye un tip individual para la búsqueda
  Widget _buildSearchTip(
    ThemeData theme, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        SizedBox(width: VerbLabTheme.spacing['sm']),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
