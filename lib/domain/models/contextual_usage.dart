// lib/domain/models/contextual_usage.dart
import 'package:equatable/equatable.dart';

/// Representa un uso contextual específico para una acepción de un verbo.
///
/// Contiene el contexto, su descripción y ejemplos específicos para ese contexto.
class ContextualUsage extends Equatable {
  /// La categoría o contexto (e.g., "movement", "possession")
  final String context;

  /// Descripción del uso en ese contexto específico
  final String description;

  /// Ejemplos específicos para este uso contextual
  final List<String> examples;

  const ContextualUsage({
    required this.context,
    required this.description,
    required this.examples,
  });

  @override
  List<Object> get props => [context, description, examples];

  /// Convierte el uso contextual a un mapa para almacenamiento
  Map<String, dynamic> toJson() => {
    'context': context,
    'description': description,
    'examples': examples,
  };

  /// Crea un uso contextual desde un mapa de almacenamiento
  factory ContextualUsage.fromJson(Map<String, dynamic> json) {
    return ContextualUsage(
      context: json['context'] as String,
      description: json['description'] as String,
      examples: List<String>.from(json['examples'] as List),
    );
  }

  /// Crea una copia de este uso contextual con los valores proporcionados reemplazados
  ContextualUsage copyWith({
    String? context,
    String? description,
    List<String>? examples,
  }) {
    return ContextualUsage(
      context: context ?? this.context,
      description: description ?? this.description,
      examples: examples ?? this.examples,
    );
  }
}
