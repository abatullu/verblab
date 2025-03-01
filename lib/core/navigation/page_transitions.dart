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
    Duration? duration,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Curva personalizada para una sensación más refinada
           final curve = CurveTween(curve: Curves.easeOutSine);

           // Combinar fade con una sutil animación de escala para mayor profundidad
           return FadeTransition(
             opacity: curve.animate(animation),
             child: ScaleTransition(
               scale: Tween<double>(begin: 0.97, end: 1.0).animate(
                 CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
               ),
               child: child,
             ),
           );
         },
         transitionDuration: duration ?? VerbLabTheme.standard,
         reverseTransitionDuration: duration ?? VerbLabTheme.quick,
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
    Duration? duration,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Combinar deslizamiento con fade para una transición más suave
           return FadeTransition(
             opacity: CurvedAnimation(
               parent: animation,
               curve: Curves.easeOutSine,
             ),
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: beginOffset ?? const Offset(0.08, 0.0),
                 end: Offset.zero,
               ).animate(
                 CurvedAnimation(
                   parent: animation,
                   curve: curve ?? Curves.easeOutCubic,
                 ),
               ),
               child: child,
             ),
           );
         },
         transitionDuration: duration ?? VerbLabTheme.standard,
         reverseTransitionDuration: duration ?? VerbLabTheme.standard,
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
    Duration? duration,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Combinación de fade y escala con curvas personalizadas
           return FadeTransition(
             opacity: CurvedAnimation(
               parent: animation,
               curve: Curves.easeOutSine,
             ),
             child: ScaleTransition(
               scale: Tween<double>(begin: 0.93, end: 1.0).animate(
                 CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
               ),
               child: child,
             ),
           );
         },
         transitionDuration: duration ?? VerbLabTheme.standard,
         reverseTransitionDuration: duration ?? VerbLabTheme.quick,
       );
}

/// Página con transición de deslizamiento vertical desde abajo
///
/// Ideal para interfaces tipo sheet o pantallas de configuración
class BottomToTopTransitionPage extends CustomTransitionPage<void> {
  BottomToTopTransitionPage({
    required super.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    Duration? duration,
  }) : super(
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return SlideTransition(
             position: Tween<Offset>(
               begin: const Offset(0.0, 0.25),
               end: Offset.zero,
             ).animate(
               CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
             ),
             child: FadeTransition(
               opacity: CurvedAnimation(
                 parent: animation,
                 curve: Curves.easeOutSine,
               ),
               child: child,
             ),
           );
         },
         transitionDuration: duration ?? VerbLabTheme.standard,
         reverseTransitionDuration: duration ?? VerbLabTheme.quick,
       );
}

/// Extensión con métodos helper para navegación
extension GoRouterExtension on GoRouter {
  /// Navega a la página de detalle de un verbo
  void goToVerbDetail(String verbId) => go('/verb/$verbId');

  /// Vuelve a la pantalla de búsqueda
  void goToSearch() => go('/');

  /// Navega a la pantalla de configuración
  void goToSettings() => go('/settings');
}
