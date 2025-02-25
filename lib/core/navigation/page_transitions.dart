// lib/core/navigation/page_transitions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_theme.dart';

/// Página con transición de desvanecimiento (fade)
///
/// Ideal para transiciones suaves entre pantallas principales
class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(
             opacity: CurveTween(curve: Curves.easeOutCubic).animate(animation),
             child: child,
           );
         },
         transitionDuration: VerbLabTheme.standard,
         reverseTransitionDuration: VerbLabTheme.quick,
       );
}

/// Página con transición de deslizamiento (slide)
///
/// Ideal para transiciones a pantallas de detalle o secundarias
class SlideTransitionPage extends CustomTransitionPage<void> {
  SlideTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    Offset? beginOffset,
    Curve? curve,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return SlideTransition(
             position: Tween<Offset>(
               begin: beginOffset ?? const Offset(1.0, 0.0),
               end: Offset.zero,
             ).animate(
               CurvedAnimation(
                 parent: animation,
                 curve: curve ?? Curves.easeOutCubic,
               ),
             ),
             child: child,
           );
         },
         transitionDuration: VerbLabTheme.standard,
         reverseTransitionDuration: VerbLabTheme.standard,
       );
}

/// Página con transición de escala y desvanecimiento
///
/// Ideal para diálogos o pantallas modales
class ScaleTransitionPage extends CustomTransitionPage<void> {
  ScaleTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(
             opacity: CurveTween(curve: Curves.easeOutCubic).animate(animation),
             child: ScaleTransition(
               scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                 CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
               ),
               child: child,
             ),
           );
         },
         transitionDuration: VerbLabTheme.standard,
         reverseTransitionDuration: VerbLabTheme.quick,
       );
}

/// Extensión con métodos helper para navegación
extension GoRouterExtension on GoRouter {
  /// Navega a la página de detalle de un verbo
  void goToVerbDetail(String verbId) => go('/verb/$verbId');

  /// Vuelve a la pantalla de búsqueda
  void goToSearch() => go('/');
}
