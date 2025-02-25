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
class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section con título y barra de búsqueda
            Padding(
              padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VerbLab',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
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

    return Center(
      child: Padding(
        padding: EdgeInsets.all(VerbLabTheme.spacing['xl']!),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(
                128,
              ), // Usando withAlpha en lugar de withOpacity
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
                color: theme.colorScheme.onSurfaceVariant.withAlpha(
                  179,
                ), // Usando withAlpha en lugar de withOpacity
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
