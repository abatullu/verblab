// lib/domain/entities/verb.dart
import 'package:equatable/equatable.dart';
import '../models/verb_meaning.dart';

/// Entidad principal que representa un verbo irregular en inglés.
///
/// Esta clase es inmutable y contiene todas las propiedades relevantes
/// para representar un verbo irregular, incluyendo sus formas en diferentes
/// tiempos verbales, variantes dialectales (US/UK) y acepciones.
class Verb extends Equatable {
  /// Identificador único del verbo
  final String id;

  /// Forma base (infinitivo) del verbo
  final String base;

  /// Forma de pasado general del verbo
  final String past;

  /// Forma de participio general del verbo
  final String participle;

  /// Forma de pasado específica para inglés británico (UK)
  /// Si está vacía, se usa [past]
  final String pastUK;

  /// Forma de pasado específica para inglés americano (US)
  /// Si está vacía, se usa [past]
  final String pastUS;

  /// Forma de participio específica para inglés británico (UK)
  /// Si está vacía, se usa [participle]
  final String participleUK;

  /// Forma de participio específica para inglés americano (US)
  /// Si está vacía, se usa [participle]
  final String participleUS;

  /// Texto de pronunciación fonética (US)
  final String? pronunciationTextUS;

  /// Texto de pronunciación fonética (UK)
  final String? pronunciationTextUK;

  /// Lista de acepciones del verbo
  final List<VerbMeaning> meanings;

  /// Constructor principal que crea una instancia de [Verb]
  const Verb({
    required this.id,
    required this.base,
    required this.past,
    required this.participle,
    this.pastUK = '',
    this.pastUS = '',
    this.participleUK = '',
    this.participleUS = '',
    this.pronunciationTextUS,
    this.pronunciationTextUK,
    required this.meanings,
  });

  /// Helper para obtener el pasado según el dialecto especificado
  String getPast(String dialect) {
    if (pastUK.isEmpty || pastUS.isEmpty) {
      return past; // Fallback al campo original
    }
    return dialect.toLowerCase() == 'en-uk' ? pastUK : pastUS;
  }

  /// Helper para obtener el participio según el dialecto especificado
  String getParticiple(String dialect) {
    if (participleUK.isEmpty || participleUS.isEmpty) {
      return participle; // Fallback al campo original
    }
    return dialect.toLowerCase() == 'en-uk' ? participleUK : participleUS;
  }

  /// Verifica si el verbo tiene variantes dialectales
  bool get hasDialectVariants =>
      (pastUK.isNotEmpty && pastUS.isNotEmpty && pastUK != pastUS) ||
      (participleUK.isNotEmpty &&
          participleUS.isNotEmpty &&
          participleUK != participleUS);

  /// Obtiene todas las formas del verbo como una lista
  List<String> get allForms {
    // Función para dividir formas múltiples
    List<String> splitForms(String form) {
      return form.isEmpty ? [] : form.split('/').map((f) => f.trim()).toList();
    }

    // Recopilar todas las formas, dividiendo las que tienen alternativas
    final forms = <String>[];

    forms.add(base);
    forms.addAll(splitForms(past));
    forms.addAll(splitForms(participle));

    if (pastUK.isNotEmpty) forms.addAll(splitForms(pastUK));
    if (pastUS.isNotEmpty) forms.addAll(splitForms(pastUS));
    if (participleUK.isNotEmpty) forms.addAll(splitForms(participleUK));
    if (participleUS.isNotEmpty) forms.addAll(splitForms(participleUS));

    // Eliminar duplicados que puedan surgir de formas compartidas
    return forms.toSet().toList();
  }

  /// Verifica si el verbo coincide con una consulta de búsqueda
  bool matchesSearch(String query) {
    final normalized = query.toLowerCase().trim();

    // Búsqueda en formas verbales
    if (base.toLowerCase().contains(normalized) ||
        past.toLowerCase().contains(normalized) ||
        participle.toLowerCase().contains(normalized) ||
        (pastUK.isNotEmpty && pastUK.toLowerCase().contains(normalized)) ||
        (pastUS.isNotEmpty && pastUS.toLowerCase().contains(normalized)) ||
        (participleUK.isNotEmpty &&
            participleUK.toLowerCase().contains(normalized)) ||
        (participleUS.isNotEmpty &&
            participleUS.toLowerCase().contains(normalized))) {
      return true;
    }

    // Búsqueda en acepciones
    for (final meaning in meanings) {
      if (meaning.definition.toLowerCase().contains(normalized)) {
        return true;
      }

      // Búsqueda en usos contextuales
      for (final usage in meaning.contextualUsages) {
        if (usage.context.toLowerCase().contains(normalized) ||
            usage.description.toLowerCase().contains(normalized)) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  List<Object?> get props => [
    id,
    base,
    past,
    participle,
    pastUK,
    pastUS,
    participleUK,
    participleUS,
    pronunciationTextUS,
    pronunciationTextUK,
    meanings,
  ];

  @override
  String toString() =>
      'Verb(id: $id, base: $base, past: $past, participle: $participle)';

  /// Crea una copia de este Verb con los valores proporcionados reemplazados
  Verb copyWith({
    String? id,
    String? base,
    String? past,
    String? participle,
    String? pastUK,
    String? pastUS,
    String? participleUK,
    String? participleUS,
    String? pronunciationTextUS,
    String? pronunciationTextUK,
    List<VerbMeaning>? meanings,
  }) {
    return Verb(
      id: id ?? this.id,
      base: base ?? this.base,
      past: past ?? this.past,
      participle: participle ?? this.participle,
      pastUK: pastUK ?? this.pastUK,
      pastUS: pastUS ?? this.pastUS,
      participleUK: participleUK ?? this.participleUK,
      participleUS: participleUS ?? this.participleUS,
      pronunciationTextUS: pronunciationTextUS ?? this.pronunciationTextUS,
      pronunciationTextUK: pronunciationTextUK ?? this.pronunciationTextUK,
      meanings: meanings ?? this.meanings,
    );
  }
}
