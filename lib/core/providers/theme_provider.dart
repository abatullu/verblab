// lib/core/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave usada para almacenar la preferencia de tema en SharedPreferences
const String _kThemePrefsKey = 'is_dark_mode';

/// Notifier para gestionar el estado del tema (claro/oscuro)
class ThemeNotifier extends StateNotifier<bool> {
  final SharedPreferences? _prefs;

  /// Constructor que recibe SharedPreferences para persistencia
  /// Si no se proporciona, los cambios no serán persistentes entre sesiones
  ThemeNotifier(this._prefs)
    : super(
        _prefs?.getBool(_kThemePrefsKey) ??
            // Valor inicial basado en el brillo del sistema si no hay preferencia guardada
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark,
      );

  /// Cambia al tema oscuro
  Future<void> setDarkMode() async {
    state = true;
    await _saveThemePreference();
  }

  /// Cambia al tema claro
  Future<void> setLightMode() async {
    state = false;
    await _saveThemePreference();
  }

  /// Alterna entre los temas claro y oscuro
  Future<void> toggleTheme() async {
    state = !state;
    await _saveThemePreference();
  }

  /// Establece el tema basado en el brillo del sistema
  Future<void> setSystemTheme() async {
    final isDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    state = isDark;
    await _saveThemePreference();
  }

  /// Guarda la preferencia de tema en SharedPreferences
  Future<void> _saveThemePreference() async {
    if (_prefs != null) {
      await _prefs.setBool(_kThemePrefsKey, state);
    }
  }
}

/// Provider para el estado del tema (isDarkMode)
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  // Obtenemos SharedPreferences de forma asíncrona
  // Como esto es un provider síncrono, usamos un enfoque con try/catch
  try {
    // final prefs = SharedPreferences.getInstance(); // Variable no usada
    return ThemeNotifier(null); // Temporalmente sin persistencia

    // En la implementación final, este código sería:
    // final prefsInstance = await prefs;
    // return ThemeNotifier(prefsInstance);
  } catch (e) {
    // Si hay un error al obtener SharedPreferences, continuamos sin persistencia
    return ThemeNotifier(null);
  }
});

/// Provider para obtener el ThemeMode basado en el estado del tema
final themeModeProvider = Provider<ThemeMode>((ref) {
  final isDarkMode = ref.watch(themeProvider);

  // Convertimos el booleano al enum ThemeMode
  return isDarkMode ? ThemeMode.dark : ThemeMode.light;
});
