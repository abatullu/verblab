// lib/data/repositories/verb_repository_impl.dart
import '../../core/error/failures.dart';
import '../../domain/entities/verb.dart';
import '../../domain/repositories/verb_repository.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/audio/tts_player.dart';
import '../models/verb_model.dart';

/// Implementación concreta del repositorio de verbos.
///
/// Esta clase implementa la interfaz [VerbRepository] definida en el dominio,
/// proporcionando acceso a los datos de verbos a través de la base de datos local
/// y servicios como Text-to-Speech.
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
          textToSpeak = dialect.toLowerCase() == 'en-uk' 
              ? (verbModel.pastUK.isNotEmpty ? verbModel.pastUK : verbModel.past)
              : (verbModel.pastUS.isNotEmpty ? verbModel.pastUS : verbModel.past);
          break;
        case 'participle':
          textToSpeak = dialect.toLowerCase() == 'en-uk' 
              ? (verbModel.participleUK.isNotEmpty ? verbModel.participleUK : verbModel.participle)
              : (verbModel.participleUS.isNotEmpty ? verbModel.participleUS : verbModel.participle);
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
    // Esta implementación se expandiría en futuras versiones
    // para actualizar la base de datos con nuevos verbos o correcciones
    return;
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

  /// Proporciona un conjunto inicial de verbos irregulares más comunes
  List<VerbModel> _getInitialVerbs() {
    return [
      // Top 20 verbos irregulares más comunes
      const VerbModel(
        id: '1',
        base: 'be',
        past: 'was/were',
        participle: 'been',
        pastUK: 'was/were',
        pastUS: 'was/were',
        participleUK: 'been',
        participleUS: 'been',
        meaning: 'to exist or live; to have a specific quality or condition',
        pronunciationTextUS: 'bi:',
        pronunciationTextUK: 'bi:',
        contextualUsage: {
          'existence': 'To exist or live',
          'identity': 'To have a specific quality or identity',
          'location': 'To be present in a place'
        },
        examples: [
          'I am happy.',
          'They were at home yesterday.',
          'She has been working all day.'
        ],
      ),

      const VerbModel(
        id: '2',
        base: 'have',
        past: 'had',
        participle: 'had',
        pastUK: 'had',
        pastUS: 'had',
        participleUK: 'had',
        participleUS: 'had',
        meaning: 'to possess, own, or hold; to experience or undergo',
        pronunciationTextUS: 'hæv',
        pronunciationTextUK: 'hæv',
        contextualUsage: {
          'possession': 'To own or possess something',
          'experience': 'To experience something',
          'obligation': 'To express obligation'
        },
        examples: [
          'I have a car.',
          'She had a great time at the party.',
          'They have had many challenges.'
        ],
      ),
    
      const VerbModel(
        id: '3',
        base: 'do',
        past: 'did',
        participle: 'done',
        pastUK: 'did',
        pastUS: 'did',
        participleUK: 'done',
        participleUS: 'done',
        meaning: 'to perform or execute an action; to complete a task',
        pronunciationTextUS: 'du:',
        pronunciationTextUK: 'du:',
        contextualUsage: {
          'action': 'To perform an action',
          'questions': 'To form questions',
          'emphasis': 'To emphasize a statement'
        },
        examples: [
          'I do my homework every day.',
          'Did you call her?',
          'I have done all I could.'
        ],
      ),

      const VerbModel(
        id: '4',
        base: 'go',
        past: 'went',
        participle: 'gone',
        pastUK: 'went',
        pastUS: 'went',
        participleUK: 'gone',
        participleUS: 'gone',
        meaning: 'to move or travel to a place; to proceed or advance',
        pronunciationTextUS: 'goʊ',
        pronunciationTextUK: 'gəʊ',
        contextualUsage: {
          'movement': 'To move to another place',
          'progress': 'To advance or proceed',
          'transformation': 'To change from one state to another',
        },
        examples: [
          'We go to school every day.',
          'She went to the store yesterday.',
          'They have gone home.',
        ],
      ),

      const VerbModel(
        id: '5',
        base: 'say',
        past: 'said',
        participle: 'said',
        pastUK: 'said',
        pastUS: 'said',
        participleUK: 'said',
        participleUS: 'said',
        meaning: 'to express in words; to state; to communicate verbally',
        pronunciationTextUS: 'seɪ',
        pronunciationTextUK: 'seɪ',
        contextualUsage: {
          'speech': 'To speak words',
          'expression': 'To express an opinion',
          'quotation': 'To quote someone',
        },
        examples: [
          'I say what I think.',
          'He said he would come.',
          'She has said nothing about it.',
        ],
      ),

      const VerbModel(
        id: '6',
        base: 'get',
        past: 'got',
        participle: 'got/gotten',
        pastUK: 'got',
        pastUS: 'got',
        participleUK: 'got',
        participleUS: 'gotten',
        meaning: 'to obtain, receive, or acquire; to become or reach a state',
        pronunciationTextUS: 'gɛt',
        pronunciationTextUK: 'gɛt',
        contextualUsage: {
          'obtain': 'To obtain or receive something',
          'become': 'To become or reach a state',
          'understand': 'To understand something',
        },
        examples: [
          'I get a newspaper every day.',
          'She got a promotion last week.',
          'They have gotten much better at tennis.',
        ],
      ),

      const VerbModel(
        id: '7',
        base: 'make',
        past: 'made',
        participle: 'made',
        pastUK: 'made',
        pastUS: 'made',
        participleUK: 'made',
        participleUS: 'made',
        meaning: 'to create, produce, or construct; to cause to happen',
        pronunciationTextUS: 'meɪk',
        pronunciationTextUK: 'meɪk',
        contextualUsage: {
          'creation': 'To create or produce something',
          'causation': 'To cause something to happen',
          'compulsion': 'To force someone to do something',
        },
        examples: [
          'I make dinner every night.',
          'She made a mistake yesterday.',
          'They have made significant progress.',
        ],
      ),

      const VerbModel(
        id: '8',
        base: 'know',
        past: 'knew',
        participle: 'known',
        pastUK: 'knew',
        pastUS: 'knew',
        participleUK: 'known',
        participleUS: 'known',
        meaning:
            'to be aware of through observation, inquiry, or information; to be familiar with',
        pronunciationTextUS: 'noʊ',
        pronunciationTextUK: 'nəʊ',
        contextualUsage: {
          'knowledge': 'To have information in mind',
          'familiarity': 'To be familiar with something',
          'recognition': 'To recognize or identify',
        },
        examples: [
          'I know the answer.',
          'She knew he was lying.',
          'They have known each other for years.',
        ],
      ),

      const VerbModel(
        id: '9',
        base: 'take',
        past: 'took',
        participle: 'taken',
        pastUK: 'took',
        pastUS: 'took',
        participleUK: 'taken',
        participleUS: 'taken',
        meaning:
            'to carry or move to another place; to remove; to acquire possession',
        pronunciationTextUS: 'teɪk',
        pronunciationTextUK: 'teɪk',
        contextualUsage: {
          'movement': 'To move something to another place',
          'consumption': 'To consume or use something',
          'require': 'To require time or effort',
        },
        examples: [
          'I take the bus to work.',
          'She took my advice.',
          'They have taken all necessary precautions.',
        ],
      ),

      const VerbModel(
        id: '10',
        base: 'see',
        past: 'saw',
        participle: 'seen',
        pastUK: 'saw',
        pastUS: 'saw',
        participleUK: 'seen',
        participleUS: 'seen',
        meaning: 'to perceive with the eyes; to discern; to understand',
        pronunciationTextUS: 'si:',
        pronunciationTextUK: 'si:',
        contextualUsage: {
          'vision': 'To perceive with the eyes',
          'understanding': 'To understand or comprehend',
          'meeting': 'To meet or visit',
        },
        examples: [
          'I see what you mean.',
          'She saw a movie yesterday.',
          'They have seen the consequences of their actions.',
        ],
      ),

      // Aquí se añadirían más verbos hasta completar los 30 más comunes
    ];
  }
}
