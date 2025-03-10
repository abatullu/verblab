// lib/data/models/verb_model.dart
import 'dart:convert';
import '../../domain/entities/verb.dart';
import '../../domain/models/verb_meaning.dart';
import '../../domain/models/contextual_usage.dart';
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

  /// Texto de pronunciación fonética (US)
  final String? pronunciationTextUS;

  /// Texto de pronunciación fonética (UK)
  final String? pronunciationTextUK;

  /// Lista de acepciones del verbo
  final List<VerbMeaning> meanings;

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
    this.pronunciationTextUS,
    this.pronunciationTextUK,
    required this.meanings,
  });

  /// Crea un VerbModel desde un mapa obtenido de la base de datos
  factory VerbModel.fromDatabase(Map<String, dynamic> data) {
    // Procesar acepciones desde la nueva columna
    List<VerbMeaning> meanings = [];
    if (data[DBConstants.colMeanings] != null) {
      try {
        final List<dynamic> jsonList = json.decode(
          data[DBConstants.colMeanings] as String,
        );
        meanings = jsonList
            .map((item) => VerbMeaning.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Si hay un error en el parsing, dejamos como lista vacía
        meanings = [];
      }
    }

    // Si no hay acepciones en el nuevo formato, convertir desde formato antiguo
    if (meanings.isEmpty) {
      final oldMeaning = data[DBConstants.colMeaning] as String? ?? '';
      Map<String, dynamic>? oldContextualUsage;
      
      if (data[DBConstants.colContextualUsage] != null) {
        try {
          final contextualUsageJson = data[DBConstants.colContextualUsage] as String;
          if (contextualUsageJson.isNotEmpty) {
            oldContextualUsage = json.decode(contextualUsageJson) as Map<String, dynamic>;
          }
        } catch (e) {
          // Si hay un error en el parsing, dejamos como null
          oldContextualUsage = null;
        }
      }
      
      List<String>? oldExamples;
      if (data[DBConstants.colExamples] != null) {
        try {
          final examplesJson = data[DBConstants.colExamples] as String;
          if (examplesJson.isNotEmpty) {
            oldExamples = List<String>.from(json.decode(examplesJson) as List);
          }
        } catch (e) {
          // Si hay un error en el parsing, dejamos como null
          oldExamples = null;
        }
      }

      // Migrar al nuevo formato
      meanings = _migrateToMeanings(oldMeaning, oldContextualUsage, oldExamples);
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
      pronunciationTextUS: data[DBConstants.colPronunciationTextUS] as String?,
      pronunciationTextUK: data[DBConstants.colPronunciationTextUK] as String?,
      meanings: meanings,
    );
  }

  /// Migra los datos del formato antiguo al nuevo formato de acepciones
  static List<VerbMeaning> _migrateToMeanings(
    String oldMeaning,
    Map<String, dynamic>? oldContextualUsage,
    List<String>? oldExamples,
  ) {
    // Crear la acepción principal con el significado general
    final contextualUsages = <ContextualUsage>[];
    final remainingExamples = <String>[];
    
    // Si hay ejemplos antiguos, hacer una copia para trabajar con ellos
    final workingExamples = oldExamples != null ? List<String>.from(oldExamples) : <String>[];

    // Convertir los usos contextuales antiguos a la nueva estructura
    if (oldContextualUsage != null && oldContextualUsage.isNotEmpty) {
      final int examplesPerContext = workingExamples.isNotEmpty 
          ? (workingExamples.length / oldContextualUsage.length).floor()
          : 0;

      int exampleIndex = 0;
      final usedExamples = <String>{};

      oldContextualUsage.forEach((context, description) {
        final List<String> contextExamples = [];

        // Asignar ejemplos a este contexto si hay disponibles
        if (examplesPerContext > 0 && exampleIndex < workingExamples.length) {
          for (int i = 0; i < examplesPerContext && exampleIndex < workingExamples.length; i++) {
            contextExamples.add(workingExamples[exampleIndex]);
            usedExamples.add(workingExamples[exampleIndex]);
            exampleIndex++;
          }
        }

        contextualUsages.add(ContextualUsage(
          context: context,
          description: description as String,
          examples: contextExamples,
        ));
      });

      // Recoger ejemplos no utilizados para la acepción principal
      if (workingExamples.isNotEmpty) {
        for (final example in workingExamples) {
          if (!usedExamples.contains(example)) {
            remainingExamples.add(example);
          }
        }
      }
    } else if (workingExamples.isNotEmpty) {
      // Si no hay usos contextuales, todos los ejemplos van a la acepción principal
      remainingExamples.addAll(workingExamples);
    }

    // Crear la acepción principal
    return [
      VerbMeaning(
        definition: oldMeaning,
        partOfSpeech: 'verb', // Valor predeterminado para migración
        examples: remainingExamples,
        contextualUsages: contextualUsages,
      )
    ];
  }

  /// Convierte el modelo a un mapa para almacenar en la base de datos
  Map<String, dynamic> toDatabase() {
    // Generar JSON para acepciones
    final meaningsJson = json.encode(
      meanings.map((meaning) => meaning.toJson()).toList()
    );
    
    // Preparar campos retrocompatibles
    String compatMeaning = '';
    Map<String, String>? compatContextualUsage;
    List<String>? compatExamples;
    
    if (meanings.isNotEmpty) {
      // Usar la primera acepción para retrocompatibilidad
      final firstMeaning = meanings.first;
      compatMeaning = firstMeaning.definition;
      
      // Crear mapa de usos contextuales para retrocompatibilidad
      if (firstMeaning.contextualUsages.isNotEmpty) {
        compatContextualUsage = {
          for (var usage in firstMeaning.contextualUsages)
            usage.context: usage.description
        };
      }
      
      // Reunir todos los ejemplos para retrocompatibilidad
      final allExamples = <String>[];
      allExamples.addAll(firstMeaning.examples);
      for (var usage in firstMeaning.contextualUsages) {
        allExamples.addAll(usage.examples);
      }
      
      if (allExamples.isNotEmpty) {
        compatExamples = allExamples;
      }
    }

    return {
      DBConstants.colId: id,
      DBConstants.colBase: base,
      DBConstants.colPast: past,
      DBConstants.colParticiple: participle,
      DBConstants.colPastUK: pastUK,
      DBConstants.colPastUS: pastUS,
      DBConstants.colParticipleUK: participleUK,
      DBConstants.colParticipleUS: participleUS,
      DBConstants.colPronunciationTextUS: pronunciationTextUS,
      DBConstants.colPronunciationTextUK: pronunciationTextUK,
      
      // Nuevo campo de acepciones
      DBConstants.colMeanings: meaningsJson,
      
      // Campos de retrocompatibilidad
      DBConstants.colMeaning: compatMeaning,
      DBConstants.colContextualUsage: compatContextualUsage != null 
          ? json.encode(compatContextualUsage) 
          : null,
      DBConstants.colExamples: compatExamples != null 
          ? json.encode(compatExamples) 
          : null,
      
      // Campo para búsqueda
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
    };

    // Añadir términos de las acepciones
    for (final meaning in meanings) {
      // Añadir la definición principal
      terms.addAll(
        meaning.definition
          .toLowerCase()
          .split(' ')
          .where((word) => word.length > 2) // Eliminar palabras cortas
      );
      
      // Añadir los contextos
      for (final usage in meaning.contextualUsages) {
        terms.add(usage.context.toLowerCase());
      }
    }

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
    pronunciationTextUS: pronunciationTextUS,
    pronunciationTextUK: pronunciationTextUK,
    meanings: meanings,
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
      pronunciationTextUS: verb.pronunciationTextUS,
      pronunciationTextUK: verb.pronunciationTextUK,
      meanings: verb.meanings,
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
    String? pronunciationTextUS,
    String? pronunciationTextUK,
    List<VerbMeaning>? meanings,
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
      pronunciationTextUS: pronunciationTextUS ?? this.pronunciationTextUS,
      pronunciationTextUK: pronunciationTextUK ?? this.pronunciationTextUK,
      meanings: meanings ?? this.meanings,
    );
  }
}