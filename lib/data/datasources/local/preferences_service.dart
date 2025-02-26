// lib/data/datasources/local/preferences_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/models/user_preferences.dart';
import '../../../core/error/failures.dart';

class PreferencesService {
  static const String _preferencesKey = 'user_preferences';

  // Singleton pattern
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  // Cached instance para eficiencia
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<UserPreferences> getPreferences() async {
    try {
      final prefs = await _prefsInstance;
      final prefString = prefs.getString(_preferencesKey);

      if (prefString == null) {
        return UserPreferences.defaults();
      }

      final Map<String, dynamic> prefMap = json.decode(prefString);
      return UserPreferences.fromJson(prefMap);
    } catch (e, stack) {
      debugPrint('Error retrieving preferences: $e');
      // Logueo del error pero retorno valores por defecto
      final error = CacheFailure(
        message: 'Failed to retrieve preferences',
        details: e.toString(),
        stackTrace: stack,
      );
      error.log();
      return UserPreferences.defaults();
    }
  }

  Future<bool> savePreferences(UserPreferences preferences) async {
    try {
      final prefs = await _prefsInstance;
      final prefString = json.encode(preferences.toJson());

      return await prefs.setString(_preferencesKey, prefString);
    } catch (e, stack) {
      debugPrint('Error saving preferences: $e');
      final error = CacheFailure(
        message: 'Failed to save preferences',
        details: e.toString(),
        stackTrace: stack,
      );
      error.log();
      return false;
    }
  }

  // Conveniente para testing o reset
  Future<bool> clearPreferences() async {
    try {
      final prefs = await _prefsInstance;
      return await prefs.remove(_preferencesKey);
    } catch (e) {
      debugPrint('Error clearing preferences: $e');
      return false;
    }
  }
}
