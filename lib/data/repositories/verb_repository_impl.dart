// lib/data/repositories/verb_repository_impl.dart
import 'package:flutter/foundation.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/verb.dart';
import '../../domain/models/verb_meaning.dart';
import '../../domain/models/contextual_usage.dart';
import '../../domain/repositories/verb_repository.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/audio/tts_player.dart';
import '../models/verb_model.dart';

/// Implementación completamente rediseñada del repositorio de verbos.
///
/// Esta implementación soporta la nueva estructura de múltiples acepciones
/// y mantiene retrocompatibilidad con datos en formato antiguo.
class VerbRepositoryImpl implements VerbRepository {
  final DatabaseHelper _databaseHelper;
  final TTSPlayer _ttsPlayer;

  /// Constructor que recibe las dependencias necesarias
  VerbRepositoryImpl(this._databaseHelper, this._ttsPlayer);

  @override
  Future<Verb?> getVerb(String id) async {
    try {
      final verbModel = await _databaseHelper.getVerb(id);
      return verbModel?.toDomain();
    } catch (e, stack) {
      final error = DatabaseFailure(
        message: 'Failed to get verb',
        details: e.toString(),
        severity: ErrorSeverity.medium,
        stackTrace: stack,
        originalError: e is Exception ? e : null,
      );
      error.log();
      throw error;
    }
  }

  @override
  Future<List<Verb>> searchVerbs(String query) async {
    try {
      final verbModels = await _databaseHelper.searchVerbs(query);
      return verbModels.map((model) => model.toDomain()).toList();
    } catch (e, stack) {
      final error = DatabaseFailure(
        message: 'Failed to search verbs',
        details: e.toString(),
        severity: ErrorSeverity.medium,
        stackTrace: stack,
        originalError: e is Exception ? e : null,
      );
      error.log();
      throw error;
    }
  }

  @override
  Future<void> playPronunciation(
    String verbId, {
    required String tense,
    String dialect = "en-US",
  }) async {
    try {
      final verbModel = await _databaseHelper.getVerb(verbId);
      if (verbModel == null) {
        throw TTSException('Verb not found: $verbId');
      }

      String textToSpeak;
      switch (tense.toLowerCase()) {
        case 'base':
          textToSpeak = verbModel.base;
          break;
        case 'past':
          textToSpeak =
              dialect.toLowerCase() == 'en-uk'
                  ? (verbModel.pastUK.isNotEmpty
                      ? verbModel.pastUK
                      : verbModel.past)
                  : (verbModel.pastUS.isNotEmpty
                      ? verbModel.pastUS
                      : verbModel.past);
          break;
        case 'participle':
          textToSpeak =
              dialect.toLowerCase() == 'en-uk'
                  ? (verbModel.participleUK.isNotEmpty
                      ? verbModel.participleUK
                      : verbModel.participle)
                  : (verbModel.participleUS.isNotEmpty
                      ? verbModel.participleUS
                      : verbModel.participle);
          break;
        default:
          textToSpeak = verbModel.base;
      }

      await _ttsPlayer.speak(textToSpeak, dialect: dialect);
    } catch (e, stack) {
      final error = TTSFailure(
        message: 'Failed to play pronunciation',
        details: e.toString(),
        severity: ErrorSeverity.low,
        stackTrace: stack,
        originalError: e is Exception ? e : null,
      );
      error.log();
      throw error;
    }
  }

  @override
  Future<void> stopPronunciation() async {
    try {
      await _ttsPlayer.stop();
    } catch (e, stack) {
      final error = TTSFailure(
        message: 'Failed to stop pronunciation',
        details: e.toString(),
        severity: ErrorSeverity.low,
        stackTrace: stack,
        originalError: e is Exception ? e : null,
      );
      error.log();
      throw error;
    }
  }

  @override
  Future<void> initializeDatabase() async {
    try {
      // Verificar si necesitamos insertar datos iniciales
      final count = await _databaseHelper.getVerbCount();

      if (count == 0) {
        await _databaseHelper.insertVerbs(_getInitialVerbs());
        await _databaseHelper.optimize();
      } else {
        // Migrar la base de datos existente para soportar múltiples acepciones
        await _databaseHelper.migrateToMultipleMeanings();
      }
    } catch (e, stack) {
      final error = DatabaseFailure(
        message: 'Failed to initialize database',
        details: e.toString(),
        severity: ErrorSeverity.high,
        stackTrace: stack,
        originalError: e is Exception ? e : null,
      );
      error.log();
      throw error;
    }
  }

  @override
  Future<int> getVerbCount() async {
    try {
      return await _databaseHelper.getVerbCount();
    } catch (e, stack) {
      final error = DatabaseFailure(
        message: 'Failed to get verb count',
        details: e.toString(),
        severity: ErrorSeverity.medium,
        stackTrace: stack,
        originalError: e is Exception ? e : null,
      );
      error.log();
      throw error;
    }
  }

  @override
  Future<void> updateDatabaseIfNeeded() async {
    try {
      // Verificar y realizar actualizaciones incrementales de la base de datos
      await _databaseHelper.migrateToMultipleMeanings();

      // Aquí podrían añadirse futuras actualizaciones
    } catch (e, stack) {
      final error = DatabaseFailure(
        message: 'Failed to update database',
        details: e.toString(),
        severity: ErrorSeverity.high,
        stackTrace: stack,
        originalError: e is Exception ? e : null,
      );
      error.log();
      throw error;
    }
  }

  @override
  Future<void> optimizeDatabase() async {
    try {
      await _databaseHelper.optimize();
    } catch (e, stack) {
      final error = DatabaseFailure(
        message: 'Failed to optimize database',
        details: e.toString(),
        severity: ErrorSeverity.low,
        stackTrace: stack,
        originalError: e is Exception ? e : null,
      );
      error.log();
      throw error;
    }
  }

  /// Proporciona un conjunto inicial de verbos irregulares con acepciones enriquecidas
  List<VerbModel> _getInitialVerbs() {
    // Implementación actualizada que usa la nueva estructura
    return [
      // Ejemplo de verbo con acepciones completas
      VerbModel(
        id: '1',
        base: 'go',
        past: 'went',
        participle: 'gone',
        pastUK: 'went',
        pastUS: 'went',
        participleUK: 'gone',
        participleUS: 'gone',
        pronunciationTextUS: 'goʊ',
        pronunciationTextUK: 'gəʊ',
        meanings: [
          VerbMeaning(
            definition: 'To move or travel to a place',
            partOfSpeech: 'intransitive verb',
            examples: [
              'They went to the beach yesterday.',
              'I go to work by train.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Movement',
                description: 'Physical movement from one place to another',
                examples: [
                  'We go to school every day.',
                  'She went home after the party.',
                ],
              ),
              ContextualUsage(
                context: 'Transportation',
                description: 'Movement using a specific method',
                examples: [
                  'He goes by bike whenever possible.',
                  'They went by airplane to Spain.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To function or work properly',
            partOfSpeech: 'intransitive verb',
            register: 'informal',
            examples: ['My watch has stopped going.', 'The engine won\'t go.'],
            contextualUsages: [
              ContextualUsage(
                context: 'Operation',
                description: 'Functioning of machines or mechanisms',
                examples: [
                  'The old car still goes well.',
                  'This watch has been going for 50 years.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To proceed or progress',
            partOfSpeech: 'intransitive verb',
            examples: [
              'How is your new project going?',
              'Everything went according to plan.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Development',
                description: 'Progress or development of situations',
                examples: [
                  'The negotiations are going well.',
                  'My studies went better than expected.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To become or change state',
            partOfSpeech: 'linking verb',
            examples: [
              'The milk has gone sour.',
              'She went pale when she heard the news.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Transformation',
                description: 'Change from one state to another',
                examples: [
                  'Her hair went gray at a young age.',
                  'The bread has gone moldy.',
                ],
              ),
            ],
          ),
        ],
      ),

      // Ejemplo de otro verbo con múltiples acepciones
      VerbModel(
        id: '2',
        base: 'have',
        past: 'had',
        participle: 'had',
        pastUK: 'had',
        pastUS: 'had',
        participleUK: 'had',
        participleUS: 'had',
        pronunciationTextUS: 'hæv',
        pronunciationTextUK: 'hæv',
        meanings: [
          VerbMeaning(
            definition: 'To possess, own, or hold',
            partOfSpeech: 'transitive verb',
            examples: ['I have a car.', 'She has a beautiful house.'],
            contextualUsages: [
              ContextualUsage(
                context: 'Possession',
                description: 'Ownership or control of objects',
                examples: [
                  'They have several properties.',
                  'He had a collection of rare books.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To experience or undergo',
            partOfSpeech: 'transitive verb',
            examples: [
              'We had a great time at the party.',
              'She had a difficult childhood.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Experience',
                description: 'Going through events or feelings',
                examples: [
                  'They had an argument yesterday.',
                  'I had a strange dream last night.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To be obligated or required',
            partOfSpeech: 'modal verb',
            examples: [
              'I have to finish this report by tomorrow.',
              'You have to follow the rules.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Obligation',
                description: 'Expressing necessity or requirement',
                examples: [
                  'She had to study for her exam.',
                  'We have to be there by 8 p.m.',
                ],
              ),
            ],
          ),
        ],
      ),

      // Ejemplo de verbo que ilustra variación dialectal
      VerbModel(
        id: '3',
        base: 'dream',
        past: 'dreamed/dreamt',
        participle: 'dreamed/dreamt',
        pastUK: 'dreamt',
        pastUS: 'dreamed',
        participleUK: 'dreamt',
        participleUS: 'dreamed',
        pronunciationTextUS: 'driːm',
        pronunciationTextUK: 'driːm',
        meanings: [
          VerbMeaning(
            definition: 'To experience images and sensations during sleep',
            partOfSpeech: 'intransitive verb',
            examples: [
              'I dream about flying almost every night.',
              'He dreamed of strange creatures.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Sleep',
                description: 'Mental activity during sleep',
                examples: [
                  'She dreamed that she was swimming in the ocean.',
                  'Children often dream of fantastic adventures.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To aspire to or hope for',
            partOfSpeech: 'transitive verb',
            examples: [
              'She dreams of becoming a doctor someday.',
              'They dream about owning their own business.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Aspiration',
                description: 'Having goals or ambitions',
                examples: [
                  'He has always dreamed of visiting Paris.',
                  'We dream of a world without war.',
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
