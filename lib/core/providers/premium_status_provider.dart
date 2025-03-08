// lib/core/providers/premium_status_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_preferences_provider.dart';

/// Clase que gestiona y notifica cambios en el estado premium
class PremiumStatusNotifier extends StateNotifier<bool> {
  PremiumStatusNotifier(bool initialValue) : super(initialValue);

  /// Variable para determinar si acaba de completar una compra premium
  /// Esto se utiliza para mostrar efectos visuales de celebración
  bool _hasJustUpgraded = false;

  /// Verifica si el usuario acaba de actualizar a premium
  bool get hasJustUpgraded => _hasJustUpgraded;

  /// Actualiza el estado premium
  void updatePremiumStatus(bool isPremium) {
    if (!state && isPremium) {
      _hasJustUpgraded = true;
    }
    state = isPremium;
  }

  /// Reinicia el indicador de actualización reciente
  void acknowledgeUpgrade() {
    _hasJustUpgraded = false;
  }
}

/// Provider para notificador de estado premium que incluye información sobre upgrades recientes
final premiumStatusNotifierProvider =
    StateNotifierProvider<PremiumStatusNotifier, bool>((ref) {
      // Obtener el estado inicial desde las preferencias del usuario
      final isPremium = ref.watch(isPremiumProvider);
      return PremiumStatusNotifier(isPremium);
    });

/// Provider para verificar si el usuario acaba de actualizar a premium
/// Esto es útil para mostrar celebraciones o mensajes de bienvenida
final hasJustUpgradedProvider = Provider<bool>((ref) {
  final premiumStatusNotifier = ref.watch(
    premiumStatusNotifierProvider.notifier,
  );
  return premiumStatusNotifier.hasJustUpgraded;
});
