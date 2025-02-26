// lib/presentation/widgets/common/theme_toggle.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/providers/user_preferences_provider.dart'; // Nuevo import

/// Widget para alternar entre temas claro y oscuro.
///
/// Este botón permite al usuario cambiar fácilmente entre los modos
/// claro y oscuro con animaciones suaves y feedback táctil.
class ThemeToggle extends ConsumerWidget {
  /// Tamaño del botón
  final double size;

  /// Si está en una posición integrada (en appbar) o flotante
  final bool isEmbedded;

  const ThemeToggle({super.key, this.size = 36, this.isEmbedded = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener el estado isDarkMode desde las preferencias de usuario
    final preferencesAsync = ref.watch(userPreferencesNotifierProvider);
    final isDarkMode = preferencesAsync.maybeWhen(
      data: (preferences) => preferences.isDarkMode,
      orElse: () => ThemeMode.system == ThemeMode.dark,
    );
    final theme = Theme.of(context);

    return Tooltip(
      message: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
      child: AnimatedContainer(
        duration: VerbLabTheme.standard,
        width: size,
        height: size,
        decoration:
            isEmbedded
                ? null
                : BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: VerbLabTheme.quick,
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                key: ValueKey<bool>(isDarkMode),
                color: theme.iconTheme.color,
              ),
            ),
            onPressed: () {
              // Proporcionar feedback táctil
              HapticFeedback.lightImpact();

              // Actualizar preferencia de tema (invierte el valor actual)
              ref
                  .read(userPreferencesNotifierProvider.notifier)
                  .setDarkMode(!isDarkMode);
            },
            tooltip:
                isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            splashRadius: size / 2 - 4,
          ),
        ),
      ),
    );
  }
}
