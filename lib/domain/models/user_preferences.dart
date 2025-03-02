// lib/domain/models/user_preferences.dart
import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  final String dialect;
  final bool isDarkMode;
  final bool isPremium; // Nuevo campo para estado premium

  const UserPreferences({
    this.dialect = 'en-UK',
    this.isDarkMode = false,
    this.isPremium = false, // Por defecto no es premium
  });

  // Actualizar métodos
  factory UserPreferences.defaults() => const UserPreferences();

  Map<String, dynamic> toJson() => {
    'dialect': dialect,
    'isDarkMode': isDarkMode,
    'isPremium': isPremium,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      dialect: json['dialect'] as String? ?? 'en-US',
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  UserPreferences copyWith({
    String? dialect,
    bool? isDarkMode,
    bool? isPremium,
  }) {
    return UserPreferences(
      dialect: dialect ?? this.dialect,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  List<Object> get props => [dialect, isDarkMode, isPremium];
}
