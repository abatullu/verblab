// lib/core/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/pages/search_page.dart';
import '../../presentation/pages/verb_detail_page.dart';
import '../../presentation/pages/settings_page.dart';
import '../../core/providers/app_state_notifier.dart';
import 'page_transitions.dart';

/// Provider para acceder al GoRouter en toda la aplicación
final routerProvider = Provider<GoRouter>((ref) {
  // Observar el estado de la aplicación para posibles redirecciones
  final appStateNotifier = ref.watch(appStateProvider.notifier);

  // Crear el router con configuración optimizada
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Ruta principal - Pantalla de búsqueda
      GoRoute(
        path: '/',
        name: 'search',
        pageBuilder: (context, state) {
          return FadeTransitionPage(
            key: state.pageKey,
            child: const SearchPage(),
          );
        },
        routes: [
          // Ruta anidada - Detalles del verbo con transición mejorada
          GoRoute(
            path: 'verb/:id',
            name: 'verb-detail',
            pageBuilder: (context, state) {
              final verbId = state.pathParameters['id'] ?? '';

              // Seleccionar el verbo en el estado
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(appStateProvider.notifier).selectVerb(verbId);
              });

              return SlideTransitionPage(
                key: state.pageKey,
                child: VerbDetailPage(verbId: verbId),
                // Leve deslizamiento horizontal para sensación de profundidad
                beginOffset: const Offset(0.08, 0.0),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        ],
      ),

      // Ruta para la página de configuraciones con transición desde abajo
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) {
          return BottomToTopTransitionPage(
            key: state.pageKey,
            child: const SettingsPage(),
          );
        },
      ),
    ],

    // Redirecciones - Preparado para futuros flujos
    redirect: (context, state) {
      return null; // Sin redirecciones por ahora
    },

    // Manejo de errores de navegación con página 404 mejorada
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The requested route "${state.uri.path}" doesn\'t exist.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
  );
});
