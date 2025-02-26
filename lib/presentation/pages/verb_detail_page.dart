// lib/presentation/pages/verb_detail_page.dart
import 'package:flutter/material.dart';
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
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          selectedVerb.base,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Siempre mostrar el selector de dialecto para permitir cambio de pronunciación
          _buildDialectBadge(context, currentDialect, ref),
          SizedBox(width: VerbLabTheme.spacing['sm']),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de conjugación con el componente VerbForms
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
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
                          ),
                        ),
                        // Badge de dialecto
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: VerbLabTheme.spacing['sm']!,
                            vertical: VerbLabTheme.spacing['xs']! / 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
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
            ),

            SizedBox(height: VerbLabTheme.spacing['md']),

            // Tarjeta de significado
            if (selectedVerb.meaning.isNotEmpty) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    VerbLabTheme.radius['lg']!,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
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
                        ),
                      ),
                      SizedBox(height: VerbLabTheme.spacing['md']),
                      Text(
                        selectedVerb.meaning,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: VerbLabTheme.spacing['md']),

            // Componente para usos contextuales (ya sin expansión)
            if (selectedVerb.contextualUsage != null &&
                selectedVerb.contextualUsage!.isNotEmpty)
              ContextualUsageSection(
                usages: selectedVerb.contextualUsage!,
                examples: selectedVerb.examples,
                verbForms: selectedVerb.allForms,
              ),

            SizedBox(height: VerbLabTheme.spacing['md']),

            // Tarjeta de ejemplos (ahora solo mostrada si no hay usos contextuales)
            if (selectedVerb.examples != null &&
                selectedVerb.examples!.isNotEmpty &&
                (selectedVerb.contextualUsage == null ||
                    selectedVerb.contextualUsage!.isEmpty)) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    VerbLabTheme.radius['lg']!,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
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
                        ),
                      ),
                      SizedBox(height: VerbLabTheme.spacing['md']),
                      ...selectedVerb.examples!.map(
                        (example) => Padding(
                          padding: EdgeInsets.only(
                            bottom: VerbLabTheme.spacing['sm']!,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.arrow_right,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              SizedBox(width: 4),
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
              ),
            ],
          ],
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
                style: theme.textTheme.bodyMedium,
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
          TextSpan(text: remainingText, style: theme.textTheme.bodyMedium),
        );
        break;
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  /// Construye un badge para cambiar entre dialectos
  Widget _buildDialectBadge(
    BuildContext context,
    String currentDialect,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final isUS = currentDialect == 'en-US';
    final label = isUS ? 'US' : 'UK';
    final nextLabel = isUS ? 'UK' : 'US';

    return Padding(
      padding: EdgeInsets.only(right: VerbLabTheme.spacing['xs']!),
      child: InkWell(
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['full'] ?? 50),
        onTap: () {
          // Cambiar el dialecto
          final newDialect = isUS ? 'en-UK' : 'en-US';
          ref.read(appStateProvider.notifier).setDialect(newDialect);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: VerbLabTheme.spacing['sm']!,
            vertical: VerbLabTheme.spacing['xs']!,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, size: 18, color: theme.colorScheme.primary),
              SizedBox(width: VerbLabTheme.spacing['xs']),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: VerbLabTheme.spacing['xs']),
              Text(
                '→ $nextLabel',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el estado de carga
  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Loading...'),
      ),
      body: Padding(
        padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
        child: ShimmerLoading(
          isLoading: true,
          child: Column(
            children: [
              const ShimmerListItem(height: 200),
              SizedBox(height: VerbLabTheme.spacing['md']),
              const ShimmerListItem(height: 120),
              SizedBox(height: VerbLabTheme.spacing['md']),
              const ShimmerListItem(height: 150),
            ],
          ),
        ),
      ),
    );
  }
}
