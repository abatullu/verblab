// lib/presentation/pages/verb_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import '../../core/providers/app_state_notifier.dart';
import '../../core/providers/monetization_providers.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/shimmer_loading.dart';
import '../widgets/verb/verb_forms.dart';
import '../widgets/verb/verb_meaning_card.dart';
import '../widgets/monetization/detail_banner_ad_card.dart';

/// Página de detalle que muestra toda la información de un verbo.
///
/// Incluye todas las formas, pronunciación, significado, ejemplos, etc.
class VerbDetailPage extends ConsumerWidget {
  final String verbId;

  const VerbDetailPage({super.key, required this.verbId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appState = ref.watch(appStateProvider);
    final selectedVerb = appState.selectedVerb;
    final currentDialect = appState.currentDialect;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Verificamos si hay un verbo seleccionado
    if (appState.isLoading) {
      return _buildLoadingState(context);
    }

    // Si hay un error, mostrar vista de error
    if (appState.hasError) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            tooltip: 'Back to search',
          ),
          title: const Text('Error'),
        ),
        body: ErrorView(
          error: appState.error.toString(),
          onRetry: () {
            ref.read(appStateProvider.notifier).selectVerb(verbId);
          },
        ),
      );
    }

    // Si no hay verbo seleccionado (extraño caso), volver a cargar
    if (selectedVerb == null) {
      // Intentar cargar el verbo de nuevo si no está seleccionado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appStateProvider.notifier).selectVerb(verbId);
      });

      return _buildLoadingState(context);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(
        context,
        theme,
        selectedVerb,
        currentDialect,
        isDarkMode,
      ),
      body: _buildBody(
        context,
        theme,
        selectedVerb,
        currentDialect,
        isDarkMode,
        ref,
      ),
    );
  }

  /// Construye el AppBar refinado con mejor presentación del título
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    dynamic selectedVerb,
    String currentDialect,
    bool isDarkMode,
  ) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 2,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
        onPressed: () => context.pop(),
        tooltip: 'Back to search',
        splashRadius: 24,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              selectedVerb.base,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (selectedVerb.pronunciationTextUS != null ||
              selectedVerb.pronunciationTextUK != null)
            Padding(
              padding: EdgeInsets.only(left: VerbLabTheme.spacing['xs']!),
              child: Text(
                currentDialect == 'en-US'
                    ? selectedVerb.pronunciationTextUS ?? ''
                    : selectedVerb.pronunciationTextUK ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Construye el cuerpo principal de la página con mejor espaciado
  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    dynamic selectedVerb,
    String currentDialect,
    bool isDarkMode,
    WidgetRef ref,
  ) {
    // Creamos un ScrollController para detectar cuando el usuario hace scroll
    final scrollController = ScrollController();

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: VerbLabTheme.spacing['md']!,
        vertical: VerbLabTheme.spacing['md']!,
      ),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de conjugación con selector de dialecto integrado
          _buildConjugationCard(
            context,
            theme,
            selectedVerb,
            currentDialect,
            isDarkMode,
            ref,
          ),

          SizedBox(height: VerbLabTheme.spacing['lg']),

          // Insertar banner entre secciones (solo si no es premium)
          if (ref.watch(showAdsProvider)) const DetailBannerAdCard(),

          if (ref.watch(showAdsProvider))
            SizedBox(height: VerbLabTheme.spacing['lg']),

          // Nueva tarjeta de acepciones
          VerbMeaningCard(meanings: selectedVerb.meanings),

          // Espacio adicional al final para mejor scrolling
          SizedBox(height: VerbLabTheme.spacing['xl']),
        ],
      ),
    );
  }

  /// Construye la tarjeta de conjugación mejorada con selector de dialecto integrado
  Widget _buildConjugationCard(
    BuildContext context,
    ThemeData theme,
    dynamic selectedVerb,
    String currentDialect,
    bool isDarkMode,
    WidgetRef ref,
  ) {
    final hasVariants = selectedVerb.hasDialectVariants;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y selector de dialecto
          Padding(
            padding: EdgeInsets.only(
              left: VerbLabTheme.spacing['lg']!,
              right: VerbLabTheme.spacing['lg']!,
              top: VerbLabTheme.spacing['lg']!,
              bottom: VerbLabTheme.spacing['md']!,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Título con ícono
                Row(
                  children: [
                    Icon(
                      Icons.format_shapes_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: VerbLabTheme.spacing['xs']),
                    Text(
                      'Conjugation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                // Selector de dialecto mejorado
                _buildDialectSelector(
                  context,
                  currentDialect,
                  hasVariants,
                  theme,
                  isDarkMode,
                  ref,
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

          // Componente de formas verbales
          Padding(
            padding: EdgeInsets.all(VerbLabTheme.spacing['lg']!),
            child: VerbForms(
              verb: selectedVerb,
              compact: false,
              style: VerbFormsStyle.flat,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un selector de dialecto mejorado con animación y estado visual
  Widget _buildDialectSelector(
    BuildContext context,
    String currentDialect,
    bool hasVariants,
    ThemeData theme,
    bool isDarkMode,
    WidgetRef ref,
  ) {
    // Siempre usamos un selector interactivo, independientemente de si hay variantes
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(VerbLabTheme.radius['full']!),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: InkWell(
        onTap: () {
          // Proporcionar feedback táctil más pronunciado por ser un cambio importante
          HapticFeedback.mediumImpact();

          // Cambiar el dialecto
          final newDialect = currentDialect == 'en-US' ? 'en-UK' : 'en-US';
          ref.read(appStateProvider.notifier).setDialect(newDialect);
        },
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: VerbLabTheme.spacing['sm']!,
            vertical: VerbLabTheme.spacing['xs']!,
          ),
          decoration: BoxDecoration(
            // Cambiamos el fondo y borde según si hay variantes o no
            color:
                hasVariants
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.7,
                    ),
            borderRadius: BorderRadius.circular(VerbLabTheme.radius['full']!),
            border: Border.all(
              color:
                  hasVariants
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: hasVariants ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de dialectos
              Icon(
                Icons.language,
                size: 16,
                color:
                    hasVariants
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: VerbLabTheme.spacing['xs']),

              // Etiqueta de dialecto actual
              Text(
                currentDialect == 'en-US' ? 'US' : 'UK',
                style: theme.textTheme.labelMedium?.copyWith(
                  color:
                      hasVariants
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Flecha e indicador del otro dialecto
              Row(
                children: [
                  SizedBox(width: VerbLabTheme.spacing['xs']),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: (hasVariants
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant)
                        .withValues(alpha: 0.7),
                  ),
                  SizedBox(width: VerbLabTheme.spacing['xs']),
                  Text(
                    currentDialect == 'en-US' ? 'UK' : 'US',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: (hasVariants
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el estado de carga con shimmer mejorado
  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
          tooltip: 'Back to search',
        ),
        title: Text(
          'Loading...',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
        child: ShimmerLoading(
          isLoading: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerListItem(height: 200),
              SizedBox(height: VerbLabTheme.spacing['lg']),
              const ShimmerListItem(height: 120),
              SizedBox(height: VerbLabTheme.spacing['lg']),
              const ShimmerListItem(height: 200),
            ],
          ),
        ),
      ),
    );
  }
}
