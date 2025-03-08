// lib/core/providers/premium_celebration_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/widgets/monetization/purchase_success_overlay.dart';

/// Gestiona la visualización de la celebración cuando un usuario adquiere premium
class PremiumCelebrationManager {
  static final PremiumCelebrationManager _instance =
      PremiumCelebrationManager._internal();

  factory PremiumCelebrationManager() => _instance;

  PremiumCelebrationManager._internal();

  OverlayEntry? _overlayEntry;
  bool _isShowingCelebration = false;

  /// Muestra la animación de celebración en el contexto proporcionado
  void showPremiumCelebration(BuildContext context) {
    if (_isShowingCelebration) return;
    _isShowingCelebration = true;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => PurchaseSuccessOverlay(
            onAnimationComplete: () {
              _hideCelebration();
            },
          ),
    );

    // Insertar después de un pequeño delay para permitir que cualquier diálogo se cierre
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_overlayEntry != null) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  /// Oculta la celebración si está visible
  void _hideCelebration() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowingCelebration = false;
  }
}

/// Provider para acceder al gestor de celebraciones premium
final premiumCelebrationManagerProvider = Provider<PremiumCelebrationManager>((
  ref,
) {
  return PremiumCelebrationManager();
});
