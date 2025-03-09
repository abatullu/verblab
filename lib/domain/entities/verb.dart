// lib/domain/entities/verb.dart
import 'package:equatable/equatable.dart';

/// Entidad principal que representa un verbo irregular en inglés.
///
/// Esta clase es inmutable y contiene todas las propiedades relevantes
/// para representar un verbo irregular, incluyendo sus formas en diferentes
/// tiempos verbales y variantes dialectales (US/UK).
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

  /// Significado principal del verbo
  final String meaning;

  /// Texto de pronunciación fonética (US)
  final String? pronunciationTextUS;

  /// Texto de pronunciación fonética (UK)
  final String? pronunciationTextUK;

  /// Mapa de usos contextuales
  /// Clave: contexto (ej. "movimiento", "posesión")
  /// Valor: descripción del uso en ese contexto
  final Map<String, String>? contextualUsage;

  /// Lista de ejemplos de uso del verbo
  final List<String>? examples;

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
    required this.meaning,
    this.pronunciationTextUS,
    this.pronunciationTextUK,
    this.contextualUsage,
    this.examples,
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

    return base.toLowerCase().contains(normalized) ||
        past.toLowerCase().contains(normalized) ||
        participle.toLowerCase().contains(normalized) ||
        (pastUK.isNotEmpty && pastUK.toLowerCase().contains(normalized)) ||
        (pastUS.isNotEmpty && pastUS.toLowerCase().contains(normalized)) ||
        (participleUK.isNotEmpty &&
            participleUK.toLowerCase().contains(normalized)) ||
        (participleUS.isNotEmpty &&
            participleUS.toLowerCase().contains(normalized)) ||
        meaning.toLowerCase().contains(normalized);
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
    meaning,
    pronunciationTextUS,
    pronunciationTextUK,
    // Nota: No incluimos contextualUsage y examples en props para comparaciones
    // ya que son objetos complejos y podrían causar comparaciones innecesariamente complejas
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
    String? meaning,
    String? pronunciationTextUS,
    String? pronunciationTextUK,
    Map<String, String>? contextualUsage,
    List<String>? examples,
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
      meaning: meaning ?? this.meaning,
      pronunciationTextUS: pronunciationTextUS ?? this.pronunciationTextUS,
      pronunciationTextUK: pronunciationTextUK ?? this.pronunciationTextUK,
      contextualUsage: contextualUsage ?? this.contextualUsage,
      examples: examples ?? this.examples,
    );
  }
}
