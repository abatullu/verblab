// lib/domain/models/user_preferences.dart
import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  final String dialect;
  final bool isDarkMode;
  // Futuras preferencias (para monetización/características premium)

  const UserPreferences({this.dialect = 'en-UK', this.isDarkMode = false});

  // Constructor para valores por defecto
  factory UserPreferences.defaults() => const UserPreferences();

  // Métodos para serialización
  Map<String, dynamic> toJson() => {
    'dialect': dialect,
    'isDarkMode': isDarkMode,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      dialect: json['dialect'] as String? ?? 'en-US',
      isDarkMode: json['isDarkMode'] as bool? ?? false,
    );
  }

  // Pattern match para copyWith
  UserPreferences copyWith({String? dialect, bool? isDarkMode}) {
    return UserPreferences(
      dialect: dialect ?? this.dialect,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  @override
  List<Object> get props => [dialect, isDarkMode];
}
