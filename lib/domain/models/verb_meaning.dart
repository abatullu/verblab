// lib/domain/models/verb_meaning.dart
import 'package:equatable/equatable.dart';
import 'contextual_usage.dart';

/// Representa una acepción específica de un verbo.
///
/// Contiene la definición, información gramatical y usos contextuales
/// para un significado particular del verbo.
class VerbMeaning extends Equatable {
  /// La definición o significado principal
  final String definition;

  /// Categoría gramatical (e.g., "transitive verb", "intransitive verb")
  final String partOfSpeech;

  /// Registro de uso (e.g., "formal", "informal", "archaic", "literary")
  final String? register;

  /// Ejemplos generales para esta acepción
  final List<String> examples;

  /// Usos contextuales específicos para esta acepción
  final List<ContextualUsage> contextualUsages;

  const VerbMeaning({
    required this.definition,
    required this.partOfSpeech,
    this.register,
    this.examples = const [],
    this.contextualUsages = const [],
  });

  @override
  List<Object?> get props => [
    definition,
    partOfSpeech,
    register,
    examples,
    contextualUsages,
  ];

  /// Convierte la acepción a un mapa para almacenamiento
  Map<String, dynamic> toJson() => {
    'definition': definition,
    'partOfSpeech': partOfSpeech,
    'register': register,
    'examples': examples,
    'contextualUsages':
        contextualUsages.map((usage) => usage.toJson()).toList(),
  };

  /// Crea una acepción desde un mapa de almacenamiento
  factory VerbMeaning.fromJson(Map<String, dynamic> json) {
    return VerbMeaning(
      definition: json['definition'] as String,
      partOfSpeech: json['partOfSpeech'] as String,
      register: json['register'] as String?,
      examples:
          json['examples'] != null
              ? List<String>.from(json['examples'] as List)
              : [],
      contextualUsages:
          json['contextualUsages'] != null
              ? (json['contextualUsages'] as List)
                  .map(
                    (item) =>
                        ContextualUsage.fromJson(item as Map<String, dynamic>),
                  )
                  .toList()
              : [],
    );
  }

  /// Crea una copia de esta acepción con los valores proporcionados reemplazados
  VerbMeaning copyWith({
    String? definition,
    String? partOfSpeech,
    String? register,
    List<String>? examples,
    List<ContextualUsage>? contextualUsages,
  }) {
    return VerbMeaning(
      definition: definition ?? this.definition,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      register: register ?? this.register,
      examples: examples ?? this.examples,
      contextualUsages: contextualUsages ?? this.contextualUsages,
    );
  }
}
