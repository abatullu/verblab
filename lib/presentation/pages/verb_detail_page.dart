// lib/presentation/pages/verb_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import '../../core/providers/app_state_notifier.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/shimmer_loading.dart';
import '../widgets/verb/verb_forms.dart';
import '../widgets/verb/contextual_usage_section.dart';

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
    final dialectLabel = currentDialect == 'en-US' ? 'US' : 'UK';

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
      appBar: _buildAppBar(context, theme, selectedVerb, currentDialect, ref),
      body: _buildBody(context, theme, selectedVerb, currentDialect),
    );
  }

  /// Construye el AppBar refinado con mejor presentación del título
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    dynamic selectedVerb,
    String currentDialect,
    WidgetRef ref,
  ) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      centerTitle: false,
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
      actions: [_buildDialectSelector(context, currentDialect, ref)],
    );
  }

  /// Construye el cuerpo principal de la página con mejor espaciado
  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    dynamic selectedVerb,
    String currentDialect,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: VerbLabTheme.spacing['md']!,
        vertical: VerbLabTheme.spacing['md']!,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de conjugación con el componente VerbForms
          _buildConjugationCard(context, theme, selectedVerb, currentDialect),

          SizedBox(height: VerbLabTheme.spacing['lg']),

          // Tarjeta de significado
          if (selectedVerb.meaning.isNotEmpty)
            _buildMeaningCard(context, theme, selectedVerb),

          if (selectedVerb.meaning.isNotEmpty)
            SizedBox(height: VerbLabTheme.spacing['lg']),

          // Componente para usos contextuales (ya sin expansión)
          if (selectedVerb.contextualUsage != null &&
              selectedVerb.contextualUsage!.isNotEmpty)
            ContextualUsageSection(
              usages: selectedVerb.contextualUsage!,
              examples: selectedVerb.examples,
              verbForms: selectedVerb.allForms,
            ),

          // Espacio entre la sección de usos contextuales y ejemplos (si ambos están presentes)
          if (selectedVerb.contextualUsage != null &&
              selectedVerb.contextualUsage!.isNotEmpty &&
              selectedVerb.examples != null &&
              selectedVerb.examples!.isNotEmpty &&
              (selectedVerb.contextualUsage == null ||
                  selectedVerb.contextualUsage!.isEmpty))
            SizedBox(height: VerbLabTheme.spacing['lg']),

          // Tarjeta de ejemplos (ahora solo mostrada si no hay usos contextuales)
          if (selectedVerb.examples != null &&
              selectedVerb.examples!.isNotEmpty &&
              (selectedVerb.contextualUsage == null ||
                  selectedVerb.contextualUsage!.isEmpty))
            _buildExamplesCard(context, theme, selectedVerb),

          // Espacio adicional al final para mejor scrolling
          SizedBox(height: VerbLabTheme.spacing['md']),
        ],
      ),
    );
  }

  /// Construye la tarjeta de conjugación mejorada
  Widget _buildConjugationCard(
    BuildContext context,
    ThemeData theme,
    dynamic selectedVerb,
    String currentDialect,
  ) {
    final dialectLabel = currentDialect == 'en-US' ? 'US' : 'UK';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(VerbLabTheme.spacing['lg']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conjugation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                // Badge de dialecto mejorado
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: VerbLabTheme.spacing['sm']!,
                    vertical: VerbLabTheme.spacing['xs']! / 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3),
                    borderRadius: BorderRadius.circular(
                      VerbLabTheme.radius['full'] ?? 50,
                    ),
                  ),
                  child: Text(
                    dialectLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: VerbLabTheme.spacing['md']),

            // Componente de formas verbales
            VerbForms(
              verb: selectedVerb,
              compact: false,
              style: VerbFormsStyle.flat,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de significado mejorada
  Widget _buildMeaningCard(
    BuildContext context,
    ThemeData theme,
    dynamic selectedVerb,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(VerbLabTheme.spacing['lg']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meaning',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: VerbLabTheme.spacing['md']),
            Text(
              selectedVerb.meaning,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta de ejemplos mejorada
  Widget _buildExamplesCard(
    BuildContext context,
    ThemeData theme,
    dynamic selectedVerb,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(VerbLabTheme.spacing['lg']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Examples',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: VerbLabTheme.spacing['md']),

            // Lista de ejemplos mejorada
            ...selectedVerb.examples!.map(
              (example) => Padding(
                padding: EdgeInsets.only(bottom: VerbLabTheme.spacing['md']!),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_right,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: VerbLabTheme.spacing['xs']),
                    Expanded(
                      child: _buildHighlightedExample(
                        context,
                        example,
                        selectedVerb.allForms,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un selector de dialecto mejorado
  Widget _buildDialectSelector(
    BuildContext context,
    String currentDialect,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final isUS = currentDialect == 'en-US';
    final label = isUS ? 'US' : 'UK';
    final nextLabel = isUS ? 'UK' : 'US';

    return Padding(
      padding: EdgeInsets.only(right: VerbLabTheme.spacing['sm']!),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Proporcionar feedback táctil
            HapticFeedback.lightImpact();

            // Cambiar el dialecto
            final newDialect = isUS ? 'en-UK' : 'en-US';
            ref.read(appStateProvider.notifier).setDialect(newDialect);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: VerbLabTheme.spacing['sm']!,
              vertical: VerbLabTheme.spacing['xs']!,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: VerbLabTheme.spacing['xs']),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' → $nextLabel',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye un texto de ejemplo con el verbo resaltado
  Widget _buildHighlightedExample(
    BuildContext context,
    String example,
    List<String> verbForms,
  ) {
    final theme = Theme.of(context);
    final spans = <TextSpan>[];
    String remainingText = example;

    // Iterar recursivamente para encontrar y resaltar todas las ocurrencias
    while (remainingText.isNotEmpty) {
      bool found = false;

      for (final verbForm in verbForms) {
        if (verbForm.isEmpty) continue;

        final lowercaseRemaining = remainingText.toLowerCase();
        final lowercaseForm = verbForm.toLowerCase();

        if (lowercaseRemaining.contains(lowercaseForm)) {
          final index = lowercaseRemaining.indexOf(lowercaseForm);
          final endIndex = index + verbForm.length;

          // Añadir texto antes de la forma verbal
          if (index > 0) {
            spans.add(
              TextSpan(
                text: remainingText.substring(0, index),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  letterSpacing: 0.15,
                ),
              ),
            );
          }

          // Añadir la forma verbal resaltada
          spans.add(
            TextSpan(
              text: remainingText.substring(index, endIndex),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                height: 1.5,
                letterSpacing: 0.15,
              ),
            ),
          );

          // Actualizar el texto restante
          remainingText = remainingText.substring(endIndex);
          found = true;
          break;
        }
      }

      // Si no se encontró ninguna forma verbal, añadir el resto del texto
      if (!found) {
        spans.add(
          TextSpan(
            text: remainingText,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              letterSpacing: 0.15,
            ),
          ),
        );
        break;
      }
    }

    return RichText(text: TextSpan(children: spans));
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
