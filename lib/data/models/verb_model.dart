// lib/data/models/verb_model.dart
import 'dart:convert';
import '../../domain/entities/verb.dart';
import '../../core/constants/db_constants.dart';

/// Modelo de datos para representar un verbo en la capa de datos.
///
/// Esta clase se encarga de la conversión entre la entidad del dominio
/// y la representación en la base de datos. Proporciona métodos para
/// serializar y deserializar verbos.
class VerbModel {
  /// Identificador único del verbo
  final String id;

  /// Forma base (infinitivo) del verbo
  final String base;

  /// Forma de pasado general
  final String past;

  /// Forma de participio general
  final String participle;

  /// Forma de pasado en inglés británico
  final String pastUK;

  /// Forma de pasado en inglés americano
  final String pastUS;

  /// Forma de participio en inglés británico
  final String participleUK;

  /// Forma de participio en inglés americano
  final String participleUS;

  /// Significado principal del verbo
  final String meaning;

  /// Texto de pronunciación fonética (US)
  final String? pronunciationTextUS;

  /// Texto de pronunciación fonética (UK)
  final String? pronunciationTextUK;

  /// Mapa de usos contextuales
  final Map<String, String>? contextualUsage;

  /// Lista de ejemplos de uso del verbo
  final List<String>? examples;

  /// Constructor principal
  const VerbModel({
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

  /// Crea un VerbModel desde un mapa obtenido de la base de datos
  factory VerbModel.fromDatabase(Map<String, dynamic> data) {
    // Manejo seguro de JSON para campos opcionales
    Map<String, String>? contextualUsage;
    if (data[DBConstants.colContextualUsage] != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(
          data[DBConstants.colContextualUsage] as String,
        );
        contextualUsage = Map<String, String>.from(jsonMap);
      } catch (e) {
        // Si hay un error en el parsing, dejamos como null
        contextualUsage = null;
      }
    }

    List<String>? examples;
    if (data[DBConstants.colExamples] != null) {
      try {
        final List<dynamic> jsonList = json.decode(
          data[DBConstants.colExamples] as String,
        );
        examples = List<String>.from(jsonList);
      } catch (e) {
        // Si hay un error en el parsing, dejamos como null
        examples = null;
      }
    }

    return VerbModel(
      id: data[DBConstants.colId] as String,
      base: data[DBConstants.colBase] as String,
      past: data[DBConstants.colPast] as String,
      participle: data[DBConstants.colParticiple] as String,
      pastUK: data[DBConstants.colPastUK] as String? ?? '',
      pastUS: data[DBConstants.colPastUS] as String? ?? '',
      participleUK: data[DBConstants.colParticipleUK] as String? ?? '',
      participleUS: data[DBConstants.colParticipleUS] as String? ?? '',
      meaning: data[DBConstants.colMeaning] as String,
      pronunciationTextUS: data[DBConstants.colPronunciationTextUS] as String?,
      pronunciationTextUK: data[DBConstants.colPronunciationTextUK] as String?,
      contextualUsage: contextualUsage,
      examples: examples,
    );
  }

  /// Convierte el modelo a un mapa para almacenar en la base de datos
  Map<String, dynamic> toDatabase() {
    return {
      DBConstants.colId: id,
      DBConstants.colBase: base,
      DBConstants.colPast: past,
      DBConstants.colParticiple: participle,
      DBConstants.colPastUK: pastUK,
      DBConstants.colPastUS: pastUS,
      DBConstants.colParticipleUK: participleUK,
      DBConstants.colParticipleUS: participleUS,
      DBConstants.colMeaning: meaning,
      DBConstants.colPronunciationTextUS: pronunciationTextUS,
      DBConstants.colPronunciationTextUK: pronunciationTextUK,
      DBConstants.colContextualUsage:
          contextualUsage != null ? json.encode(contextualUsage) : null,
      DBConstants.colExamples: examples != null ? json.encode(examples) : null,
      DBConstants.colSearchTerms: _generateSearchTerms(),
    };
  }

  /// Genera términos de búsqueda para indexación
  String _generateSearchTerms() {
    final terms = <String>{
      base.toLowerCase(),
      past.toLowerCase(),
      participle.toLowerCase(),
      if (pastUK.isNotEmpty) pastUK.toLowerCase(),
      if (pastUS.isNotEmpty) pastUS.toLowerCase(),
      if (participleUK.isNotEmpty) participleUK.toLowerCase(),
      if (participleUS.isNotEmpty) participleUS.toLowerCase(),
      // También incluimos palabras clave del significado
      ...meaning
          .toLowerCase()
          .split(' ')
          .where((word) => word.length > 2), // Eliminamos palabras muy cortas
    };

    return terms.join(' ');
  }

  /// Convierte el modelo a una entidad de dominio
  Verb toDomain() => Verb(
    id: id,
    base: base,
    past: past,
    participle: participle,
    pastUK: pastUK,
    pastUS: pastUS,
    participleUK: participleUK,
    participleUS: participleUS,
    meaning: meaning,
    pronunciationTextUS: pronunciationTextUS,
    pronunciationTextUK: pronunciationTextUK,
    contextualUsage: contextualUsage,
    examples: examples,
  );

  /// Crea un VerbModel a partir de una entidad de dominio
  factory VerbModel.fromDomain(Verb verb) {
    return VerbModel(
      id: verb.id,
      base: verb.base,
      past: verb.past,
      participle: verb.participle,
      pastUK: verb.pastUK,
      pastUS: verb.pastUS,
      participleUK: verb.participleUK,
      participleUS: verb.participleUS,
      meaning: verb.meaning,
      pronunciationTextUS: verb.pronunciationTextUS,
      pronunciationTextUK: verb.pronunciationTextUK,
      contextualUsage: verb.contextualUsage,
      examples: verb.examples,
    );
  }

  /// Crea una copia de este VerbModel con los valores proporcionados reemplazados
  VerbModel copyWith({
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
    return VerbModel(
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
