// lib/core/navigation/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/pages/search_page.dart';
import '../../presentation/pages/verb_detail_page.dart';
import '../../presentation/pages/settings_page.dart'; // Nuevo import
import '../../core/providers/app_state_notifier.dart';
import 'page_transitions.dart';

/// Provider para acceder al GoRouter en toda la aplicación
final routerProvider = Provider<GoRouter>((ref) {
  // No estamos usando appState por ahora, pero lo dejamos preparado
  // para futuras redirecciones basadas en estado

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Ruta principal - Pantalla de búsqueda
      GoRoute(
        path: '/',
        name: 'search',
        pageBuilder:
            (context, state) => FadeTransitionPage(
              key: state.pageKey,
              child: const SearchPage(),
            ),
        routes: [
          // Ruta anidada - Detalles del verbo
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
              );
            },
          ),
        ],
      ),

      // Nueva ruta para la página de configuraciones
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder:
            (context, state) => FadeTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
            ),
      ),
    ],

    // Redirecciones - Por ejemplo, si la aplicación no está inicializada
    redirect: (context, state) {
      // Si la app no está inicializada y el usuario intenta ir a otra pantalla que no sea splash,
      // redirigir a splash. Esto no es necesario ahora ya que SplashScreen es manejada en main.dart
      // pero podría ser útil para futuros flujos como onboarding, login, etc.
      return null; // Sin redirecciones por ahora
    },

    // Manejo de errores de navegación
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Text(
              'Error: ${state.error}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
  );
});
