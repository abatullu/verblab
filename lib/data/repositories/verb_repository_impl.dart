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
          'I make dinner every night.', // creation
          'Her joke made everyone laugh.', // causation
          'The teacher made us stay after class.' // compulsion
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
          'I know the answer to that question.', // knowledge
          'She knew the city very well.', // familiarity
          'They have known each other since childhood.' // recognition
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
          'I take the bus to work every day.', // movement
          'She took her medicine after dinner.', // consumption
          'It will take about two hours to finish.' // require
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
          'I can see the mountains from my window.', // vision
          'I see what you mean now.', // understanding
          'She saw her doctor yesterday.' // meeting
        ],
      ),

      // Verbos con variantes dialectales UK/US
      const VerbModel(
        id: '11',
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

      const VerbModel(
        id: '12',
        base: 'spell',
        past: 'spelled/spelt',
        participle: 'spelled/spelt',
        pastUK: 'spelt',     // Más común en UK
        pastUS: 'spelled',   // Más común en US
        participleUK: 'spelt',
        participleUS: 'spelled',
        meaning: 'to name, write, or print the letters of a word in correct order',
        pronunciationTextUS: 'spɛl',
        pronunciationTextUK: 'spɛl',
        contextualUsage: {
          'literacy': 'To form a word with the correct letters in order',
          'explanation': 'To explain something in detail',
          'magic': 'To create a magical effect using words (figurative)',
        },
        examples: [
          'Can you spell your name for me?', // literacy
          'The instructions spelled/spelt out what we needed to do.', // explanation
          'The music spelled/spelt a magical atmosphere in the room.' // magic
        ],
      ),

      const VerbModel(
        id: '13',
        base: 'burn',
        past: 'burned/burnt',
        participle: 'burned/burnt',
        pastUK: 'burnt',     // Más común en UK
        pastUS: 'burned',    // Más común en US
        participleUK: 'burnt',
        participleUS: 'burned',
        meaning: 'to be on fire; to destroy or damage with fire or heat',
        pronunciationTextUS: 'bɜrn',
        pronunciationTextUK: 'bɜːn',
        contextualUsage: {
          'fire': 'To be consumed by fire',
          'cooking': 'To overcook food',
          'injury': 'To injure with heat',
          'energy': 'To use up energy or fuel',
        },
        examples: [
          'The fire burns brightly.', // fire
          'She burned/burnt the toast this morning.', // cooking
          'He has burned/burnt himself on the stove.', // injury
          'The car burns a lot of fuel on long journeys.' // energy
        ],
      ),

      const VerbModel(
        id: '14',
        base: 'dive',
        past: 'dived/dove',
        participle: 'dived',
        pastUK: 'dived',    // Forma estándar en UK
        pastUS: 'dove',     // Forma común en US (aunque dived también se usa)
        participleUK: 'dived',
        participleUS: 'dived',
        meaning: 'to jump headfirst into water; to plunge or descend sharply',
        pronunciationTextUS: 'daɪv',
        pronunciationTextUK: 'daɪv',
        contextualUsage: {
          'swimming': 'To jump headfirst into water',
          'decrease': 'To drop suddenly (prices, values)',
          'movement': 'To move quickly downward',
        },
        examples: [
          'Watch me dive into the pool.', // swimming
          'The stock prices dived/dove this week.', // decrease
          'He dived/dove under the table when he heard the explosion.' // movement
        ],
      ),

      const VerbModel(
        id: '15',
        base: 'smell',
        past: 'smelled/smelt',
        participle: 'smelled/smelt',
        pastUK: 'smelt',     // Preferido en UK
        pastUS: 'smelled',   // Preferido en US
        participleUK: 'smelt',
        participleUS: 'smelled',
        meaning: 'to perceive an odor through the nose; to have a particular odor',
        pronunciationTextUS: 'smɛl',
        pronunciationTextUK: 'smɛl',
        contextualUsage: {
          'perception': 'To detect an odor through the sense of smell',
          'emission': 'To emit an odor',
          'intuition': 'To sense or suspect something (figurative)',
        },
        examples: [
          'Can you smell the flowers?', // perception
          'The milk smelled/smelt bad.', // emission
          'I smelled/smelt trouble as soon as I walked in.' // intuition
        ],
      ),

      //
      // CATEGORÍA 3: VERBOS CON MÚLTIPLES FORMAS ACEPTADAS
      //
      const VerbModel(
        id: '16',
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

      const VerbModel(
        id: '17',
        base: 'leap',
        past: 'leaped/leapt',
        participle: 'leaped/leapt',
        pastUK: 'leapt/leaped',
        pastUS: 'leaped/leapt',
        participleUK: 'leapt/leaped',
        participleUS: 'leaped/leapt',
        meaning: 'to jump or spring a long distance with great force',
        pronunciationTextUS: 'li:p',
        pronunciationTextUK: 'li:p',
        contextualUsage: {
          'jump': 'To jump forcefully or high',
          'advancement': 'To make a sudden significant advancement',
          'time': 'To move quickly forward in time',
        },
        examples: [
          'The cat leaped/leapt onto the table.', // jump
          'Technology has leaped/leapt forward in the last decade.', // advancement
          'The story leaped/leapt ahead to twenty years in the future.' // time
        ],
      ),

      const VerbModel(
        id: '18',
        base: 'hang',
        past: 'hung/hanged',
        participle: 'hung/hanged',
        pastUK: 'hung/hanged',
        pastUS: 'hung/hanged',
        participleUK: 'hung/hanged',
        participleUS: 'hung/hanged',
        meaning: 'to suspend or be suspended from above; to attach to a wall',
        pronunciationTextUS: 'hæŋ',
        pronunciationTextUK: 'hæŋ',
        contextualUsage: {
          'suspension': 'To suspend or be suspended from above',
          'execution': 'To kill by suspending by the neck (hanged)',
          'display': 'To display on a wall',
          'usage_note': '"Hanged" is used specifically when referring to execution by hanging; "hung" is used in all other contexts',
        },
        examples: [
          'The clothes hung on the line to dry.', // suspension
          'The criminal was hanged for his crimes.', // execution
          'We hung the paintings on the wall.' // display
        ],
      ),

      const VerbModel(
        id: '19',
        base: 'kneel',
        past: 'kneeled/knelt',
        participle: 'kneeled/knelt',
        pastUK: 'knelt/kneeled',
        pastUS: 'kneeled/knelt',
        participleUK: 'knelt/kneeled',
        participleUS: 'kneeled/knelt',
        meaning: 'to position the body on one knee or both knees',
        pronunciationTextUS: 'ni:l',
        pronunciationTextUK: 'ni:l',
        contextualUsage: {
          'position': 'To rest with one or both knees on the ground',
          'respect': 'To kneel as a sign of respect or reverence',
          'submission': 'To kneel as a sign of submission',
        },
        examples: [
          'She kneeled/knelt on the floor to pick up the toy.', // position
          'The congregation kneeled/knelt in prayer.', // respect
          'He kneeled/knelt before the king to show his loyalty.' // submission
        ],
      ),

      const VerbModel(
        id: '20',
        base: 'speed',
        past: 'sped/speeded',
        participle: 'sped/speeded',
        pastUK: 'sped/speeded',
        pastUS: 'sped/speeded',
        participleUK: 'sped/speeded',
        participleUS: 'sped/speeded',
        meaning: 'to move or travel quickly; to exceed the speed limit',
        pronunciationTextUS: 'spi:d',
        pronunciationTextUK: 'spi:d',
        contextualUsage: {
          'movement': 'To move quickly',
          'traffic': 'To exceed the speed limit when driving',
          'acceleration': 'To increase in speed',
          'usage_note': '"Sped" is more common for movement; "speeded" often collocates with "up" as in "speeded up"',
        },
        examples: [
          'The car sped down the highway.', // movement
          'He was caught speeding by the police.', // traffic
          'The process has speeded up considerably since we computerized it.' // acceleration
        ],
      ),

      //
      // CATEGORÍA 4: VERBOS ARCAICOS O LITERARIOS
      //
      const VerbModel(
        id: '21',
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

      const VerbModel(
        id: '22',
        base: 'smite',
        past: 'smote',
        participle: 'smitten',
        pastUK: 'smote',
        pastUS: 'smote',
        participleUK: 'smitten',
        participleUS: 'smitten',
        meaning: 'to strike with a heavy blow; to affect suddenly and strongly',
        pronunciationTextUS: 'smaɪt',
        pronunciationTextUK: 'smaɪt',
        contextualUsage: {
          'biblical': 'To strike heavily or destructively',
          'literary': 'To affect powerfully or suddenly',
          'modern': 'To be strongly attracted to someone (smitten)',
          'usage_frequency': 'Rare in modern English except in literary or biblical contexts',
        },
        examples: [
          'The lord smote the enemy forces.', // biblical
          'The disease smote the town suddenly.', // literary
          'He was smitten with her beauty at first sight.' // modern
        ],
      ),

      const VerbModel(
        id: '23',
        base: 'behold',
        past: 'beheld',
        participle: 'beheld',
        pastUK: 'beheld',
        pastUS: 'beheld',
        participleUK: 'beheld',
        participleUS: 'beheld',
        meaning: 'to see or observe someone or something remarkable',
        pronunciationTextUS: 'bɪˈhoʊld',
        pronunciationTextUK: 'bɪˈhəʊld',
        contextualUsage: {
          'literary': 'To observe or gaze upon',
          'biblical': 'To look and see',
          'usage_frequency': 'Rare in modern English, primarily in literary contexts',
        },
        examples: [
          'She beheld a magnificent castle before her.', // literary
          'Behold, I bring you good tidings of great joy.', // biblical
          'They have beheld the greatest spectacle of their lives.' // additional literary example
        ],
      ),

      const VerbModel(
        id: '24',
        base: 'slay',
        past: 'slew',
        participle: 'slain',
        pastUK: 'slew',
        pastUS: 'slew',
        participleUK: 'slain',
        participleUS: 'slain',
        meaning: 'to kill violently; to greatly impress or amuse (informal modern usage)',
        pronunciationTextUS: 'sleɪ',
        pronunciationTextUK: 'sleɪ',
        contextualUsage: {
          'literary': 'To kill violently or in large numbers',
          'modern_slang': 'To impress greatly or do something exceptionally well',
          'usage_frequency': 'Literary meaning is rare in modern English; slang meaning is common in informal contexts',
        },
        examples: [
          'The knight slew the dragon.', // literary
          'She slayed her performance on stage last night.', // modern_slang
          'The disease slew thousands of people in the middle ages.' // additional literary example
        ],
      ),

      const VerbModel(
        id: '25',
        base: 'strive',
        past: 'strove',
        participle: 'striven',
        pastUK: 'strove',
        pastUS: 'strove',
        participleUK: 'striven',
        participleUS: 'striven',
        meaning: 'to make great efforts to achieve something; to struggle vigorously',
        pronunciationTextUS: 'straɪv',
        pronunciationTextUK: 'straɪv',
        contextualUsage: {
          'effort': 'To try very hard to do or achieve something',
          'competition': 'To compete or struggle vigorously',
          'aspiration': 'To aim earnestly',
        },
        examples: [
          'We strive for excellence in all we do.', // effort
          'She strove against her competitors.', // competition
          'They have striven to create a better world.' // aspiration
        ],
      ),

      //
      // CONTINUAR CON MÁS VERBOS COMUNES
      //
      const VerbModel(
        id: '26',
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

      const VerbModel(
        id: '27',
        base: 'give',
        past: 'gave',
        participle: 'given',
        pastUK: 'gave',
        pastUS: 'gave',
        participleUK: 'given',
        participleUS: 'given',
        meaning: 'to freely transfer the possession of something to someone',
        pronunciationTextUS: 'gɪv',
        pronunciationTextUK: 'gɪv',
        contextualUsage: {
          'transfer': 'To hand over something to someone',
          'provision': 'To provide or supply something',
          'dedication': 'To dedicate time or effort to something',
        },
        examples: [
          'I give you my word.', // transfer
          'The hospital gives medical care to everyone.', // provision
          'They have given their time to help others.' // dedication
        ],
      ),

      const VerbModel(
        id: '28',
        base: 'find',
        past: 'found',
        participle: 'found',
        pastUK: 'found',
        pastUS: 'found',
        participleUK: 'found',
        participleUS: 'found',
        meaning: 'to discover or perceive by chance or after search',
        pronunciationTextUS: 'faɪnd',
        pronunciationTextUK: 'faɪnd',
        contextualUsage: {
          'discovery': 'To discover or come upon by chance',
          'search': 'To locate something after searching',
          'realization': 'To discover a fact or realize something',
        },
        examples: [
          'I found a coin on the sidewalk.', // discovery
          'She found her keys under the sofa after searching.', // search
          'They have found that exercise improves mood.' // realization
        ],
      ),

      const VerbModel(
        id: '29',
        base: 'eat',
        past: 'ate',
        participle: 'eaten',
        pastUK: 'ate',
        pastUS: 'ate',
        participleUK: 'eaten',
        participleUS: 'eaten',
        meaning: 'to put food in the mouth, chew it, and swallow it',
        pronunciationTextUS: 'it',
        pronunciationTextUK: 'iːt',
        contextualUsage: {
          'consumption': 'To consume food',
          'corrosion': 'To corrode or destroy gradually',
          'bothering': 'To worry or bother (informal)',
        },
        examples: [
          'I eat breakfast every morning.', // consumption
          'Acid eats through metal.', // corrosion
          'What\'s eating you lately?' // bothering
        ],
      ),

      const VerbModel(
        id: '30',
        base: 'think',
        past: 'thought',
        participle: 'thought',
        pastUK: 'thought',
        pastUS: 'thought',
        participleUK: 'thought',
        participleUS: 'thought',
        meaning: 'to have a particular opinion, belief, or idea about someone or something',
        pronunciationTextUS: 'θɪŋk',
        pronunciationTextUK: 'θɪŋk',
        contextualUsage: {
          'opinion': 'To have an opinion or belief',
          'reasoning': 'To use the mind to consider something',
          'consideration': 'To consider the needs or feelings of others',
        },
        examples: [
          'I think you are right.', // opinion
          'She thought about the problem carefully.', // reasoning
          'They have thought of others\' feelings before speaking.' // consideration
        ],
      ),
      
      const VerbModel(
        id: '31',
        base: 'run',
        past: 'ran',
        participle: 'run',
        pastUK: 'ran',
        pastUS: 'ran',
        participleUK: 'run',
        participleUS: 'run',
        meaning: 'to move at a speed faster than walking, never having both feet on the ground at the same time',
        pronunciationTextUS: 'rʌn',
        pronunciationTextUK: 'rʌn',
        contextualUsage: {
          'movement': 'To move quickly on foot',
          'operation': 'To operate or function (machine)',
          'management': 'To be in charge of (business)',
        },
        examples: [
          'I run every morning for exercise.', // movement
          'The engine has run for hours without stopping.', // operation
          'She runs her own business now.' // management
        ],
      ),

      const VerbModel(
        id: '32',
        base: 'speak',
        past: 'spoke',
        participle: 'spoken',
        pastUK: 'spoke',
        pastUS: 'spoke',
        participleUK: 'spoken',
        participleUS: 'spoken',
        meaning: 'to say words in order to convey information, express feelings, or give instructions',
        pronunciationTextUS: 'spiːk',
        pronunciationTextUK: 'spiːk',
        contextualUsage: {
          'communication': 'To express thoughts through language',
          'language': 'To know and use a language',
          'expression': 'To express an opinion publicly',
        },
        examples: [
          'Can you speak more clearly, please?', // communication
          'I speak three languages fluently.', // language
          'The CEO spoke about the company\'s future plans.' // expression
        ],
      ),

      const VerbModel(
        id: '33',
        base: 'write',
        past: 'wrote',
        participle: 'written',
        pastUK: 'wrote',
        pastUS: 'wrote',
        participleUK: 'written',
        participleUS: 'written',
        meaning: 'to mark letters, words, or other symbols on a surface, typically paper, with a pen, pencil, or similar implement',
        pronunciationTextUS: 'raɪt',
        pronunciationTextUK: 'raɪt',
        contextualUsage: {
          'composition': 'To compose text or literature',
          'communication': 'To communicate in written form',
          'recording': 'To record information in text',
        },
        examples: [
          'She writes novels for a living.', // composition
          'I wrote a letter to my friend yesterday.', // communication
          'The journalist has written detailed notes of the interview.' // recording
        ],
      ),

      const VerbModel(
        id: '34',
        base: 'sleep',
        past: 'slept',
        participle: 'slept',
        pastUK: 'slept',
        pastUS: 'slept',
        participleUK: 'slept',
        participleUS: 'slept',
        meaning: 'to be in a state of rest in which consciousness is suspended',
        pronunciationTextUS: 'sliːp',
        pronunciationTextUK: 'sliːp',
        contextualUsage: {
          'rest': 'To be in a natural state of rest',
          'accommodation': 'To provide sleeping accommodation',
          'inactivity': 'To be inactive or dormant',
        },
        examples: [
          'I sleep for eight hours every night.', // rest
          'The hotel can sleep up to 200 guests.', // accommodation
          'Some animals sleep through the winter.' // inactivity
        ],
      ),

      const VerbModel(
        id: '35',
        base: 'swim',
        past: 'swam',
        participle: 'swum',
        pastUK: 'swam',
        pastUS: 'swam',
        participleUK: 'swum',
        participleUS: 'swum',
        meaning: 'to move through water by moving the body or parts of the body',
        pronunciationTextUS: 'swɪm',
        pronunciationTextUK: 'swɪm',
        contextualUsage: {
          'movement': 'To move through water',
          'sport': 'To engage in swimming as a sport',
          'floating': 'To float or drift along',
        },
        examples: [
          'Fish swim in the sea.', // movement
          'She swam competitively for ten years.', // sport
          'The leaves have swum down the stream.' // floating
        ],
      ),

      // Verbos literarios, históricos o formales adicionales
      const VerbModel(
        id: '36',
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

      const VerbModel(
        id: '37',
        base: 'rend',
        past: 'rent',
        participle: 'rent',
        pastUK: 'rent',
        pastUS: 'rent',
        participleUK: 'rent',
        participleUS: 'rent',
        meaning: 'to tear or split something apart violently or forcefully',
        pronunciationTextUS: 'rɛnd',
        pronunciationTextUK: 'rɛnd',
        contextualUsage: {
          'literary': 'To tear apart forcefully',
          'emotional': 'To cause great emotional pain',
          'usage_frequency': 'Rare in everyday English, used in literary contexts',
        },
        examples: [
          'The explosion rent the air.', // literary
          'His heart was rent with sorrow.', // emotional
          'She rent her garments in grief.' // additional literary example
        ],
      ),

      // Algunos verbos más comunes para completar la fase 1
      const VerbModel(
        id: '38',
        base: 'read',
        past: 'read',
        participle: 'read',
        pastUK: 'read',
        pastUS: 'read',
        participleUK: 'read',
        participleUS: 'read',
        meaning: 'to look at and understand the meaning of letters, words, symbols, etc.',
        pronunciationTextUS: 'riːd/rɛd',  // Presente/Pasado
        pronunciationTextUK: 'riːd/rɛd',  // Presente/Pasado
        contextualUsage: {
          'comprehension': 'To comprehend written text',
          'study': 'To study or learn by reading',
          'interpretation': 'To interpret signs or indications',
          'pronunciation_note': 'Present tense is pronounced "reed", past tense and participle are pronounced "red"',
        },
        examples: [
          'I read books every night.', // comprehension
          'She read several textbooks for her research.', // study
          'He read the signs of an impending storm.' // interpretation
        ],
      ),

      const VerbModel(
        id: '39',
        base: 'break',
        past: 'broke',
        participle: 'broken',
        pastUK: 'broke',
        pastUS: 'broke',
        participleUK: 'broken',
        participleUS: 'broken',
        meaning: 'to separate into pieces as a result of a blow, shock, or strain',
        pronunciationTextUS: 'breɪk',
        pronunciationTextUK: 'breɪk',
        contextualUsage: {
          'damage': 'To fracture or shatter',
          'interrupt': 'To interrupt or stop temporarily',
          'violation': 'To fail to observe a law, rule, or promise',
        },
        examples: [
          'Be careful not to break the glass.', // damage
          'Let\'s break for lunch and continue later.', // interrupt
          'They have broken their promise to help us.' // violation
        ],
      ),

      const VerbModel(
        id: '40',
        base: 'begin',
        past: 'began',
        participle: 'begun',
        pastUK: 'began',
        pastUS: 'began',
        participleUK: 'begun',
        participleUS: 'begun',
        meaning: 'to start or come into being',
        pronunciationTextUS: 'bɪˈgɪn',
        pronunciationTextUK: 'bɪˈgɪn',
        contextualUsage: {
          'start': 'To start a process or action',
          'origin': 'To come into existence',
          'initiation': 'To take the first step',
        },
        examples: [
          'I begin work at 9am every day.', // start
          'Life began on Earth about 3.5 billion years ago.', // origin
          'They have begun to understand the problem.' // initiation
        ],
      ),

      const VerbModel(
        id: '41',
        base: 'lose',
        past: 'lost',
        participle: 'lost',
        pastUK: 'lost',
        pastUS: 'lost',
        participleUK: 'lost',
        participleUS: 'lost',
        meaning: 'to be unable to find something or someone; to be deprived of or cease to have something',
        pronunciationTextUS: 'luːz',
        pronunciationTextUK: 'luːz',
        contextualUsage: {
          'misplacement': 'To be unable to find something',
          'deprivation': 'To be deprived of something',
          'defeat': 'To fail to win',
        },
        examples: [
          'I always lose my keys.', // misplacement
          'She lost her job during the recession.', // deprivation
          'They have lost three games this season.' // defeat
        ],
      ),

      const VerbModel(
        id: '42',
        base: 'tell',
        past: 'told',
        participle: 'told',
        pastUK: 'told',
        pastUS: 'told',
        participleUK: 'told',
        participleUS: 'told',
        meaning: 'to communicate information, facts, or news to someone in spoken or written words',
        pronunciationTextUS: 'tɛl',
        pronunciationTextUK: 'tɛl',
        contextualUsage: {
          'communication': 'To relate or narrate information',
          'instruction': 'To instruct or direct someone',
          'revelation': 'To reveal or disclose something',
        },
        examples: [
          'Let me tell you what happened.', // communication
          'The teacher told us to open our books.', // instruction
          'She told everyone the secret.' // revelation
        ],
      ),

      const VerbModel(
        id: '43',
        base: 'understand',
        past: 'understood',
        participle: 'understood',
        pastUK: 'understood',
        pastUS: 'understood',
        participleUK: 'understood',
        participleUS: 'understood',
        meaning: 'to perceive the intended meaning of words, language, or a speaker',
        pronunciationTextUS: 'ˌʌndərˈstænd',
        pronunciationTextUK: 'ˌʌndəˈstænd',
        contextualUsage: {
          'comprehension': 'To comprehend or grasp the meaning',
          'interpretation': 'To interpret correctly',
          'sympathy': 'To be sympathetic or tolerant',
        },
        examples: [
          'I understand the concept now.', // comprehension
          'She understood the instructions perfectly.', // interpretation
          'They understand your difficult situation.' // sympathy
        ],
      ),

      const VerbModel(
        id: '44',
        base: 'feel',
        past: 'felt',
        participle: 'felt',
        pastUK: 'felt',
        pastUS: 'felt',
        participleUK: 'felt',
        participleUS: 'felt',
        meaning: 'to be aware of through touch; to experience an emotion or sensation',
        pronunciationTextUS: 'fiːl',
        pronunciationTextUK: 'fiːl',
        contextualUsage: {
          'sensation': 'To perceive through touch',
          'emotion': 'To experience an emotion',
          'opinion': 'To hold an opinion or belief',
        },
        examples: [
          'She felt the soft fabric between her fingers.', // sensation
          'I feel happy today.', // emotion
          'They felt that the decision was wrong.' // opinion
        ],
      ),

      const VerbModel(
        id: '45',
        base: 'bring',
        past: 'brought',
        participle: 'brought',
        pastUK: 'brought',
        pastUS: 'brought',
        participleUK: 'brought',
        participleUS: 'brought',
        meaning: 'to carry, convey, or conduct someone or something to a place',
        pronunciationTextUS: 'brɪŋ',
        pronunciationTextUK: 'brɪŋ',
        contextualUsage: {
          'transportation': 'To carry something to a place',
          'cause': 'To cause a particular situation to occur',
          'introduction': 'To introduce a subject or topic',
        },
        examples: [
          'Please bring your ID to the meeting.', // transportation
          'Smoking can bring health problems.', // cause
          'They have brought up an interesting question.' // introduction
        ],
      ),

      const VerbModel(
        id: '46',
        base: 'keep',
        past: 'kept',
        participle: 'kept',
        pastUK: 'kept',
        pastUS: 'kept',
        participleUK: 'kept',
        participleUS: 'kept',
        meaning: 'to retain possession of; to continue to have, hold, or maintain',
        pronunciationTextUS: 'kiːp',
        pronunciationTextUK: 'kiːp',
        contextualUsage: {
          'retention': 'To retain or continue to have',
          'maintenance': 'To maintain a condition or state',
          'storage': 'To store or save something',
        },
        examples: [
          'I keep my promises.', // retention
          'She kept working despite her illness.', // maintenance
          'They have kept their valuables in a safe.' // storage
        ],
      ),

      const VerbModel(
        id: '47',
        base: 'send',
        past: 'sent',
        participle: 'sent',
        pastUK: 'sent',
        pastUS: 'sent',
        participleUK: 'sent',
        participleUS: 'sent',
        meaning: 'to cause to go or be taken to a destination',
        pronunciationTextUS: 'sɛnd',
        pronunciationTextUK: 'sɛnd',
        contextualUsage: {
          'transmission': 'To cause to be conveyed to a destination',
          'communication': 'To transmit a message or information',
          'dispatch': 'To dispatch a person on a mission',
        },
        examples: [
          'I sent the package yesterday.', // transmission
          'She sent an email to the team.', // communication
          'They have sent their best diplomat to negotiate.' // dispatch
        ],
      ),

      const VerbModel(
        id: '48',
        base: 'build',
        past: 'built',
        participle: 'built',
        pastUK: 'built',
        pastUS: 'built',
        participleUK: 'built',
        participleUS: 'built',
        meaning: 'to construct by putting parts or material together',
        pronunciationTextUS: 'bɪld',
        pronunciationTextUK: 'bɪld',
        contextualUsage: {
          'construction': 'To construct or create by putting parts together',
          'development': 'To develop or increase over time',
          'foundation': 'To establish or create as a foundation',
        },
        examples: [
          'They build houses that last generations.', // construction
          'She built her career step by step.', // development
          'We have built our relationship on trust.' // foundation
        ],
      ),

      const VerbModel(
        id: '49',
        base: 'hear',
        past: 'heard',
        participle: 'heard',
        pastUK: 'heard',
        pastUS: 'heard',
        participleUK: 'heard',
        participleUS: 'heard',
        meaning: 'to perceive with the ear the sound made by someone or something',
        pronunciationTextUS: 'hɪr',
        pronunciationTextUK: 'hɪə',
        contextualUsage: {
          'perception': 'To perceive sound with the ears',
          'listening': 'To listen to something or someone',
          'learning': 'To be told or informed about something',
        },
        examples: [
          'I can hear the birds singing.', // perception
          'She heard the lecture carefully.', // listening
          'They have heard about the upcoming changes.' // learning
        ],
      ),

      const VerbModel(
        id: '50',
        base: 'grow',
        past: 'grew',
        participle: 'grown',
        pastUK: 'grew',
        pastUS: 'grew',
        participleUK: 'grown',
        participleUS: 'grown',
        meaning: 'to increase in size or amount; to develop or mature',
        pronunciationTextUS: 'groʊ',
        pronunciationTextUK: 'grəʊ',
        contextualUsage: {
          'increase': 'To increase in size, amount, or degree',
          'development': 'To develop or mature',
          'cultivation': 'To cultivate or raise plants',
        },
        examples: [
          'The company grew rapidly last year.', // increase
          'Children grow quickly during adolescence.', // development
          'They have grown vegetables in their garden for years.' // cultivation
        ],
      ),
    ];
  }
}