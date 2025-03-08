// lib/core/providers/user_preferences_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/preferences_service.dart';
import '../../domain/models/user_preferences.dart';

class UserPreferencesNotifier
    extends StateNotifier<AsyncValue<UserPreferences>> {
  final PreferencesService _preferencesService;

  UserPreferencesNotifier(this._preferencesService)
    : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = const AsyncValue.loading();

    try {
      final preferences = await _preferencesService.getPreferences();
      state = AsyncValue.data(preferences);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setDialect(String dialect) async {
    state.whenData((preferences) async {
      final newPrefs = preferences.copyWith(dialect: dialect);
      await _preferencesService.savePreferences(newPrefs);
      state = AsyncValue.data(newPrefs);
    });
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    state.whenData((preferences) async {
      final newPrefs = preferences.copyWith(isDarkMode: isDarkMode);
      await _preferencesService.savePreferences(newPrefs);
      state = AsyncValue.data(newPrefs);
    });
  }

  Future<void> setPremiumStatus(bool isPremium) async {
    state.whenData((preferences) async {
      final newPrefs = preferences.copyWith(isPremium: isPremium);
      await _preferencesService.savePreferences(newPrefs);
      state = AsyncValue.data(newPrefs);
    });
  }

  Future<void> resetToDefaults() async {
    // Preservar estado premium mientras se restablecen otras preferencias
    bool currentPremiumStatus = false;

    // Capturar el estado premium actual
    state.whenData((preferences) {
      currentPremiumStatus = preferences.isPremium;
    });

    // Crear objeto de preferencias por defecto manteniendo el estado premium
    final defaults = UserPreferences.defaults().copyWith(
      isPremium: currentPremiumStatus, // Preservar estado premium
    );

    // Guardar las preferencias
    await _preferencesService.savePreferences(defaults);
    state = AsyncValue.data(defaults);
  }
}

// Providers
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

final userPreferencesNotifierProvider =
    StateNotifierProvider<UserPreferencesNotifier, AsyncValue<UserPreferences>>(
      (ref) {
        final preferencesService = ref.watch(preferencesServiceProvider);
        return UserPreferencesNotifier(preferencesService);
      },
    );

// Providers más específicos para conveniencia

// Dialect provider
final dialectProvider = Provider<String>((ref) {
  final preferencesAsync = ref.watch(userPreferencesNotifierProvider);
  return preferencesAsync.when(
    data: (preferences) => preferences.dialect,
    loading: () => 'en-US', // Default
    error: (_, __) => 'en-US', // Default on error
  );
});

// ThemeMode provider con nombre único para evitar conflictos
final userPreferenceThemeModeProvider = Provider<ThemeMode>((ref) {
  final preferencesAsync = ref.watch(userPreferencesNotifierProvider);
  return preferencesAsync.when(
    data:
        (preferences) =>
            preferences.isDarkMode ? ThemeMode.dark : ThemeMode.light,
    loading: () => ThemeMode.system, // Default
    error: (_, __) => ThemeMode.system, // Default on error
  );
});

// Premium status provider
final isPremiumProvider = Provider<bool>((ref) {
  final preferencesAsync = ref.watch(userPreferencesNotifierProvider);
  return preferencesAsync.when(
    data: (preferences) => preferences.isPremium,
    loading: () => false, // Default no premium
    error: (_, __) => false, // Default on error
  );
});
