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

  /// Proporciona un conjunto inicial de verbos irregulares
  /// 
  /// Incluye una muestra representativa de 50 verbos de las siguientes categorías:
  /// - Verbos estándar de uso común
  /// - Verbos con variantes dialectales UK/US
  /// - Verbos con múltiples formas aceptadas
  /// - Verbos arcaicos o literarios
  List<VerbModel> _getInitialVerbs() {
    return [
      //
      // CATEGORÍA 1: VERBOS ESTÁNDAR DE USO COMÚN
      //
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
          'She has been working all day.', // existence
          'I am happy.', // identity
          'They were at home yesterday.' // location
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
          'I have a car.', // possession
          'She had a great time at the party.', // experience
          'You have to finish this report by tomorrow.' // obligation
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
          'I do my homework every day.', // action
          'Did you call her?', // questions
          'I do believe you are right.' // emphasis
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
          'We go to school every day.', // movement
          'The project is going well.', // progress
          'The milk has gone sour.' // transformation
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
          'I say what I mean.', // speech
          'He said he disagreed with the decision.', // expression
          'She has said, "I\'ll never give up."' // quotation
        ],
      ),

      //
      // CATEGORÍA 2: VERBOS CON VARIANTES DIALECTALES UK/US
      //
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
          'I get a newspaper every day.', // obtain
          'She got tired after running.', // become
          'Do you get what I\'m saying?' // understand
        ],
      ),

      // Verbos con variantes dialectales UK/US
      const VerbModel(
        id: '7',
        base: 'learn',
        past: 'learned/learnt',
        participle: 'learned/learnt',
        pastUK: 'learnt',  // Forma preferida en UK
        pastUS: 'learned', // Forma preferida en US
        participleUK: 'learnt',
        participleUS: 'learned',
        meaning: 'to gain knowledge or skill by study, experience, or teaching',
        pronunciationTextUS: 'lɜrn',
        pronunciationTextUK: 'lɜːn',
        contextualUsage: {
          'education': 'To acquire knowledge through study',
          'skill': 'To gain ability through practice',
          'information': 'To become informed about something',
        },
        examples: [
          'I learn a new language every year.', // education
          'She learned/learnt to play piano as a child.', // skill
          'They have learned/learnt about the changes in policy.' // information
        ],
      ),

      //
      // CATEGORÍA 3: VERBOS CON MÚLTIPLES FORMAS ACEPTADAS
      //
      const VerbModel(
        id: '8',
        base: 'dream',
        past: 'dreamed/dreamt',
        participle: 'dreamed/dreamt',
        pastUK: 'dreamt/dreamed',  // Orden invertido - priorizando forma más común en UK
        pastUS: 'dreamed/dreamt',  // Priorizando forma más común en US
        participleUK: 'dreamt/dreamed',
        participleUS: 'dreamed/dreamt',
        meaning: 'to experience images, thoughts and sensations during sleep',
        pronunciationTextUS: 'dri:m',
        pronunciationTextUK: 'dri:m',
        contextualUsage: {
          'sleep': 'To have visions during sleep',
          'aspiration': 'To imagine or hope for something desired',
        },
        examples: [
          'I dream about flying almost every night.', // sleep
          'She dreamed/dreamt of becoming a doctor someday.' // aspiration
        ],
      ),

      //
      // CATEGORÍA 4: VERBOS ARCAICOS O LITERARIOS
      //
      const VerbModel(
        id: '9',
        base: 'cleave',
        past: 'cleft/clove',
        participle: 'cleft/cloven',
        pastUK: 'cleft/clove',
        pastUS: 'cleft/clove',
        participleUK: 'cleft/cloven',
        participleUS: 'cleft/cloven',
        meaning: 'to split or divide; to adhere firmly or loyally',
        pronunciationTextUS: 'kli:v',
        pronunciationTextUK: 'kli:v',
        contextualUsage: {
          'literary': 'To split or divide, especially along a natural line',
          'archaic': 'To adhere or cling to something',
          'usage_frequency': 'Rare in modern English, primarily in literary contexts'
        },
        examples: [
          'The axe cleaved the wood in two.', // literary
          'He cleaved to his principles despite opposition.', // archaic
          'The boat clove through the waves.' // additional example of literary usage
        ],
      ),

      //
      // CONTINUAR CON MÁS VERBOS COMUNES
      //
      const VerbModel(
        id: '10',
        base: 'come',
        past: 'came',
        participle: 'come',
        pastUK: 'came',
        pastUS: 'came',
        participleUK: 'come',
        participleUS: 'come',
        meaning: 'to move toward or approach the speaker or a specified place',
        pronunciationTextUS: 'kʌm',
        pronunciationTextUK: 'kʌm',
        contextualUsage: {
          'movement': 'To move to or toward a place',
          'arrival': 'To arrive at a destination',
          'occurrence': 'To happen or take place',
        },
        examples: [
          'Please come here.', // movement
          'She came to the party yesterday.', // arrival
          'Spring has come early this year.' // occurrence
        ],
      ),

      // Verbos literarios, históricos o formales adicionales
      const VerbModel(
        id: '11',
        base: 'forsake',
        past: 'forsook',
        participle: 'forsaken',
        pastUK: 'forsook',
        pastUS: 'forsook',
        participleUK: 'forsaken',
        participleUS: 'forsaken',
        meaning: 'to abandon, to leave entirely, to renounce or reject',
        pronunciationTextUS: 'fɔrˈseɪk',
        pronunciationTextUK: 'fəˈseɪk',
        contextualUsage: {
          'literary': 'To abandon or leave entirely',
          'historical': 'To renounce or leave a person or thing',
          'usage_frequency': 'Primarily used in formal or literary contexts',
        },
        examples: [
          'He forsook his homeland and never returned.', // literary
          'The king forsook his throne to marry a commoner.', // historical
          'Do not forsake me in my time of need.' // additional literary example
        ],
      ),
    ];
  }
}