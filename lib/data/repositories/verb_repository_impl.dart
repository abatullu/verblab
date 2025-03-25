// lib/data/repositories/verb_repository_impl.dart
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
        id: 'be',
        base: 'be',
        past: 'was/were',
        participle: 'been',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'bi',
        pronunciationTextUK: 'biː',
        meanings: [
          VerbMeaning(
            definition: 'To exist or live',
            partOfSpeech: 'intransitive verb',
            examples: [
              'I think, therefore I am.',
              'These creatures were on Earth before humans.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Existence',
                description:
                    'Indicating the presence or existence of something',
                examples: [
                  'There are fifty people at the party.',
                  'Once upon a time, there was a princess in a castle.',
                ],
              ),
              ContextualUsage(
                context: 'Identity',
                description: 'Expressing nature or identity',
                examples: [
                  'He is a doctor at the local hospital.',
                  'They were students at Oxford University.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To occupy a position in space or time',
            partOfSpeech: 'intransitive verb',
            examples: [
              'The book is on the table.',
              'The meeting was at three o\'clock.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Location',
                description: 'Indicating position or location',
                examples: [
                  'She is in the garden picking flowers.',
                  'We were at the cinema when it happened.',
                ],
              ),
              ContextualUsage(
                context: 'Time',
                description: 'Expressing a point in time',
                examples: [
                  'The concert is next Friday evening.',
                  'His birthday was last week.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To have a particular quality or condition',
            partOfSpeech: 'linking verb',
            examples: ['The soup is hot.', 'They were happy with the results.'],
            contextualUsages: [
              ContextualUsage(
                context: 'State',
                description: 'Describing a state or condition',
                examples: [
                  'She is tired after the long journey.',
                  'The children were excited about Christmas.',
                ],
              ),
              ContextualUsage(
                context: 'Quality',
                description: 'Expressing characteristics or qualities',
                examples: [
                  'The film was interesting but too long.',
                  'These apples are delicious and organic.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'do',
        base: 'do',
        past: 'did',
        participle: 'done',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'du',
        pronunciationTextUK: 'duː',
        meanings: [
          VerbMeaning(
            definition: 'To perform or carry out an action or task',
            partOfSpeech: 'transitive verb',
            examples: [
              'She did her homework last night.',
              'They do volunteer work at the hospital.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Tasks',
                description:
                    'Completing specific activities or responsibilities',
                examples: [
                  'I need to do the laundry today.',
                  'He did the dishes after dinner.',
                ],
              ),
              ContextualUsage(
                context: 'Work',
                description: 'Engaging in professional or academic activities',
                examples: [
                  'She does research on climate change.',
                  'They did a project on renewable energy.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To create, produce, or make something',
            partOfSpeech: 'transitive verb',
            examples: [
              'The chef did a special menu for the event.',
              'She does beautiful paintings of landscapes.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Creation',
                description: 'Making or producing something',
                examples: [
                  'He did a sketch of the harbor.',
                  'They did a documentary about wildlife conservation.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To be sufficient or adequate',
            partOfSpeech: 'intransitive verb',
            examples: [
              'This amount of food will do for everyone.',
              'A simple explanation will do.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Adequacy',
                description: 'Being sufficient for a purpose',
                examples: [
                  'These shoes will do for the party.',
                  'The temporary solution did until we found a permanent fix.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'go',
        base: 'go',
        past: 'went',
        participle: 'gone',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'goʊ',
        pronunciationTextUK: 'gəʊ',
        meanings: [
          VerbMeaning(
            definition: 'To move or travel to a place',
            partOfSpeech: 'intransitive verb',
            examples: [
              'We go to the beach every summer.',
              'She went to Paris last year.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Travel',
                description: 'Movement from one location to another',
                examples: [
                  'They went to Spain for their honeymoon.',
                  'I go to work by train every day.',
                ],
              ),
              ContextualUsage(
                context: 'Direction',
                description: 'Moving in a specified direction',
                examples: [
                  'Go straight ahead and then turn right.',
                  'The path goes around the lake.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To function or operate',
            partOfSpeech: 'intransitive verb',
            examples: [
              'My watch has stopped going.',
              'This old car still goes well.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Operation',
                description: 'Functioning of machines or mechanisms',
                examples: [
                  'The clock goes for about a week before needing rewinding.',
                  'This engine doesn\'t go as smoothly as it used to.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To proceed or progress',
            partOfSpeech: 'intransitive verb',
            examples: [
              'How is your new project going?',
              'The negotiations went better than expected.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Progress',
                description: 'Development or advancement of a situation',
                examples: [
                  'The meeting went well despite initial concerns.',
                  'Her recovery is going slowly but steadily.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'have',
        base: 'have',
        past: 'had',
        participle: 'had',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'hæv',
        pronunciationTextUK: 'hæv',
        meanings: [
          VerbMeaning(
            definition: 'To possess, own, or hold',
            partOfSpeech: 'transitive verb',
            examples: [
              'She has a large collection of books.',
              'They had a beautiful house by the lake.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Possession',
                description: 'Ownership of physical items',
                examples: [
                  'He has three cars and a motorcycle.',
                  'We had a dog when I was growing up.',
                ],
              ),
              ContextualUsage(
                context: 'Attributes',
                description: 'Possessing qualities or characteristics',
                examples: [
                  'She has a great sense of humor.',
                  'He had remarkable patience with children.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To experience or undergo',
            partOfSpeech: 'transitive verb',
            examples: [
              'We had a wonderful time at the party.',
              'I had a strange dream last night.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Experiences',
                description: 'Going through events or situations',
                examples: [
                  'They had an argument about politics.',
                  'She had a difficult childhood.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To consume food or drink',
            partOfSpeech: 'transitive verb',
            examples: [
              'Let\'s have lunch together tomorrow.',
              'We had coffee and cake for dessert.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Consumption',
                description: 'Eating or drinking',
                examples: [
                  'He has cereal for breakfast every morning.',
                  'They had a glass of wine with dinner.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'make',
        base: 'make',
        past: 'made',
        participle: 'made',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'meɪk',
        pronunciationTextUK: 'meɪk',
        meanings: [
          VerbMeaning(
            definition: 'To create, form, or produce something',
            partOfSpeech: 'transitive verb',
            examples: [
              'She makes her own clothes.',
              'They made a documentary about climate change.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Creation',
                description: 'Producing or constructing something new',
                examples: [
                  'He made a cake for her birthday.',
                  'The company makes luxury cars.',
                ],
              ),
              ContextualUsage(
                context: 'Preparation',
                description: 'Preparing food or drink',
                examples: [
                  'I\'ll make dinner tonight.',
                  'She made coffee for everyone.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To cause something to happen or exist',
            partOfSpeech: 'transitive verb',
            examples: [
              'The joke made everyone laugh.',
              'His comment made her angry.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Causation',
                description: 'Causing a state, condition, or reaction',
                examples: [
                  'The news made him very happy.',
                  'Her performance made the audience cry.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To earn or gain',
            partOfSpeech: 'transitive verb',
            examples: [
              'He makes a good salary as a programmer.',
              'They made a profit from selling the house.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Financial',
                description: 'Earning money or achieving profit',
                examples: [
                  'She makes a living as a freelance writer.',
                  'The business made millions in revenue last year.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'take',
        base: 'take',
        past: 'took',
        participle: 'taken',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'teɪk',
        pronunciationTextUK: 'teɪk',
        meanings: [
          VerbMeaning(
            definition:
                'To move something or someone from one place to another',
            partOfSpeech: 'transitive verb',
            examples: [
              'She took the books from the shelf.',
              'He took his daughter to school.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Transport',
                description: 'Moving people or objects to a location',
                examples: [
                  'I\'ll take you to the airport tomorrow.',
                  'He took the package to the post office.',
                ],
              ),
              ContextualUsage(
                context: 'Removal',
                description: 'Removing something from a place',
                examples: [
                  'She took the key from her pocket.',
                  'They took their luggage from the car.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To use, consume, or require',
            partOfSpeech: 'transitive verb',
            examples: [
              'She takes medication for her condition.',
              'It took three hours to complete the task.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Consumption',
                description: 'Consuming food, medicine, or substances',
                examples: [
                  'He takes vitamins every morning.',
                  'She took two aspirins for her headache.',
                ],
              ),
              ContextualUsage(
                context: 'Time',
                description: 'Requiring a specific amount of time',
                examples: [
                  'The journey took longer than expected.',
                  'It takes about 20 minutes to bake the cake.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To accept or receive something offered',
            partOfSpeech: 'transitive verb',
            examples: [
              'She took my advice and applied for the job.',
              'He took the gift with gratitude.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Acceptance',
                description: 'Accepting offers, opportunities, or suggestions',
                examples: [
                  'Will you take the job if they offer it to you?',
                  'She took the opportunity to study abroad.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'come',
        base: 'come',
        past: 'came',
        participle: 'come',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'kʌm',
        pronunciationTextUK: 'kʌm',
        meanings: [
          VerbMeaning(
            definition:
                'To move toward or approach the speaker or a specified place',
            partOfSpeech: 'intransitive verb',
            examples: [
              'She came to my house for dinner.',
              'Winter is coming soon.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Movement',
                description: 'Moving toward a person or place',
                examples: [
                  'Please come to the office as soon as possible.',
                  'He came running when he heard the news.',
                ],
              ),
              ContextualUsage(
                context: 'Arrival',
                description: 'Reaching a destination',
                examples: [
                  'When did you come to this country?',
                  'They came to the end of the road.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To occur or happen',
            partOfSpeech: 'intransitive verb',
            examples: [
              'Opportunities come and go.',
              'Her birthday comes in April.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Events',
                description: 'The happening or occurrence of events',
                examples: [
                  'Spring comes after winter.',
                  'Success came to her later in life.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To reach a particular state or condition',
            partOfSpeech: 'intransitive verb',
            examples: [
              'She came to understand the importance of education.',
              'The water came to a boil after five minutes.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'State change',
                description: 'Transition into a new state',
                examples: [
                  'He finally came to his senses.',
                  'The solution came clear to her suddenly.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'see',
        base: 'see',
        past: 'saw',
        participle: 'seen',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'si',
        pronunciationTextUK: 'siː',
        meanings: [
          VerbMeaning(
            definition: 'To perceive with the eyes',
            partOfSpeech: 'transitive verb',
            examples: [
              'I can see a boat on the horizon.',
              'She saw a deer in the forest.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Visual perception',
                description: 'Using eyesight to observe objects or events',
                examples: [
                  'He saw the accident happen right in front of him.',
                  'We could see the mountains from our hotel room.',
                ],
              ),
              ContextualUsage(
                context: 'Witnessing',
                description: 'Being present when something happens',
                examples: [
                  'I saw her leave the building an hour ago.',
                  'They saw the concert from the front row.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To understand or comprehend',
            partOfSpeech: 'transitive verb',
            examples: [
              'I see what you mean now.',
              'She couldn\'t see the point of the exercise.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Comprehension',
                description: 'Grasping concepts or meanings',
                examples: [
                  'I finally see how to solve this problem.',
                  'He couldn\'t see the connection between the two events.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To meet or visit someone',
            partOfSpeech: 'transitive verb',
            examples: [
              'I\'m seeing my doctor tomorrow.',
              'She sees her grandchildren every weekend.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Meeting',
                description: 'Having an appointment or social interaction',
                examples: [
                  'He\'s seeing a specialist about his knee injury.',
                  'They saw their old friends at the reunion.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'know',
        base: 'know',
        past: 'knew',
        participle: 'known',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'noʊ',
        pronunciationTextUK: 'nəʊ',
        meanings: [
          VerbMeaning(
            definition:
                'To be aware of through observation, inquiry, or information',
            partOfSpeech: 'transitive verb',
            examples: [
              'I know the answer to your question.',
              'She knew about the plan all along.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Information',
                description: 'Having facts or information in mind',
                examples: [
                  'He knows the capital of every country in Europe.',
                  'They know the details of the agreement.',
                ],
              ),
              ContextualUsage(
                context: 'Awareness',
                description: 'Being conscious of facts or situations',
                examples: [
                  'I know that the meeting starts at 9 AM.',
                  'She knows about the changes to the schedule.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To be familiar or acquainted with a person, place, or thing',
            partOfSpeech: 'transitive verb',
            examples: [
              'Do you know that man over there?',
              'I\'ve known her since we were children.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Acquaintance',
                description: 'Being familiar with people',
                examples: [
                  'He knows many influential people in the industry.',
                  'She knows the teacher from her previous school.',
                ],
              ),
              ContextualUsage(
                context: 'Familiarity',
                description: 'Being familiar with places or things',
                examples: [
                  'I know Paris very well after living there for five years.',
                  'He knows that restaurant because he used to work there.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To have a good understanding or practical experience of something',
            partOfSpeech: 'transitive verb',
            examples: [
              'She knows how to play the piano.',
              'He knows several programming languages.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Skills',
                description: 'Having practical knowledge or abilities',
                examples: [
                  'I know how to fix this type of engine.',
                  'She knows three foreign languages fluently.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'think',
        base: 'think',
        past: 'thought',
        participle: 'thought',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'θɪŋk',
        pronunciationTextUK: 'θɪŋk',
        meanings: [
          VerbMeaning(
            definition:
                'To have a particular opinion, belief, or idea about something',
            partOfSpeech: 'transitive verb',
            examples: [
              'I think the blue one looks better.',
              'She thought the movie was boring.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Opinion',
                description: 'Holding a view or judgment',
                examples: [
                  'What do you think about the new government policy?',
                  'He thinks we should wait until tomorrow.',
                ],
              ),
              ContextualUsage(
                context: 'Belief',
                description: 'Considering something to be true or likely',
                examples: [
                  'I think it will rain later today.',
                  'They thought she was the right person for the job.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To use the mind to reason about something',
            partOfSpeech: 'intransitive verb',
            examples: [
              'Let me think about this problem for a moment.',
              'She sat quietly, thinking deeply.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Reasoning',
                description: 'Using mental processes to consider or analyze',
                examples: [
                  'He thought carefully before making his decision.',
                  'I need to think about all the possible consequences.',
                ],
              ),
              ContextualUsage(
                context: 'Problem-solving',
                description: 'Mental effort directed toward finding solutions',
                examples: [
                  'They\'re thinking of ways to improve efficiency.',
                  'She thought of a brilliant solution to the problem.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To recall or remember something',
            partOfSpeech: 'intransitive verb',
            examples: [
              'I can\'t think of his name right now.',
              'Let me think where I put my keys.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Memory',
                description: 'Attempting to recall information',
                examples: [
                  'Try to think of any details that might help the investigation.',
                  'I\'m thinking back to our conversation last week.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'say',
        base: 'say',
        past: 'said',
        participle: 'said',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'seɪ',
        pronunciationTextUK: 'seɪ',
        meanings: [
          VerbMeaning(
            definition:
                'To utter words so as to express or convey information, an opinion, a feeling or intention',
            partOfSpeech: 'transitive verb',
            examples: [
              'He said he was hungry.',
              'She didn\'t say a word during the meeting.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Communication',
                description: 'Verbal expression of information or thoughts',
                examples: [
                  'The teacher said that the test would be on Friday.',
                  'They said goodbye and left quickly.',
                ],
              ),
              ContextualUsage(
                context: 'Statement',
                description: 'Making formal or official declarations',
                examples: [
                  'The company said they would investigate the matter.',
                  'The government has said it will introduce new regulations.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To indicate or show',
            partOfSpeech: 'transitive verb',
            examples: [
              'The clock says it\'s 3 o\'clock.',
              'My instinct says we should be cautious.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Indication',
                description: 'Displaying or showing information',
                examples: [
                  'The thermometer says it\'s 30 degrees outside.',
                  'The sign says no parking is allowed here.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To recite or pronounce',
            partOfSpeech: 'transitive verb',
            examples: [
              'They said their prayers before bed.',
              'She said her lines perfectly in the play.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Recitation',
                description: 'Speaking memorized or prepared text',
                examples: [
                  'The children said the pledge of allegiance.',
                  'He said his speech without looking at his notes.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'get',
        base: 'get',
        past: 'got',
        participle: 'got/gotten',
        pastUK: '',
        pastUS: '',
        participleUK: 'got',
        participleUS: 'gotten',
        pronunciationTextUS: 'gɛt',
        pronunciationTextUK: 'get',
        meanings: [
          VerbMeaning(
            definition: 'To obtain, receive, or acquire',
            partOfSpeech: 'transitive verb',
            examples: [
              'I got a new job last month.',
              'She got a letter from her cousin yesterday.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Acquisition',
                description: 'Coming into possession of something',
                examples: [
                  'He got tickets for the concert next week.',
                  'They got permission to build an extension.',
                ],
              ),
              ContextualUsage(
                context: 'Reception',
                description: 'Receiving or being given something',
                examples: [
                  'She got flowers for her birthday.',
                  'We got good news from the doctor.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To reach or arrive at a place or state',
            partOfSpeech: 'intransitive verb',
            examples: [
              'What time did you get home?',
              'We got to the station just as the train was leaving.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Arrival',
                description: 'Reaching a destination',
                examples: [
                  'What time will we get to the airport?',
                  'He got home late last night.',
                ],
              ),
              ContextualUsage(
                context: 'State change',
                description: 'Reaching a particular condition',
                examples: [
                  'She got angry when she heard the news.',
                  'The situation got worse over time.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To cause someone or something to move or change state',
            partOfSpeech: 'transitive verb',
            examples: [
              'I need to get my car repaired.',
              'She got her daughter dressed for school.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Causation',
                description: 'Making something happen or change',
                examples: [
                  'Can you get this package delivered by tomorrow?',
                  'He got the computer working again.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'give',
        base: 'give',
        past: 'gave',
        participle: 'given',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'gɪv',
        pronunciationTextUK: 'gɪv',
        meanings: [
          VerbMeaning(
            definition:
                'To freely transfer the possession of something to someone',
            partOfSpeech: 'transitive verb',
            examples: [
              'She gave me a book for my birthday.',
              'He gave all his money to charity.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Donation',
                description: 'Providing something as a gift or contribution',
                examples: [
                  'They gave food and clothing to the homeless shelter.',
                  'She gave a generous donation to the hospital.',
                ],
              ),
              ContextualUsage(
                context: 'Transfer',
                description: 'Handing over physical items',
                examples: [
                  'He gave the waiter a tip.',
                  'The teacher gave homework to all the students.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To provide or supply',
            partOfSpeech: 'transitive verb',
            examples: [
              'The tree gives shade in summer.',
              'This plant gives a beautiful scent.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Provision',
                description: 'Supplying something needed or desired',
                examples: [
                  'The small engine gives enough power for everyday use.',
                  'Her presence gave comfort to the family.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To perform or deliver',
            partOfSpeech: 'transitive verb',
            examples: [
              'She gave a speech at the conference.',
              'The orchestra gave a wonderful performance.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Performance',
                description: 'Delivering presentations or performances',
                examples: [
                  'He gave a lecture on modern architecture.',
                  'They gave a concert at the local theater.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'find',
        base: 'find',
        past: 'found',
        participle: 'found',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'faɪnd',
        pronunciationTextUK: 'faɪnd',
        meanings: [
          VerbMeaning(
            definition: 'To discover or come upon by searching or by accident',
            partOfSpeech: 'transitive verb',
            examples: [
              'I found my keys under the sofa.',
              'They found gold in the mountains.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Discovery',
                description: 'Locating something that was lost or unknown',
                examples: [
                  'The hikers found a hidden waterfall in the forest.',
                  'She found her missing earring in the bathroom.',
                ],
              ),
              ContextualUsage(
                context: 'Search',
                description: 'Locating through deliberate effort',
                examples: [
                  'The police found evidence at the crime scene.',
                  'They found the information they needed in the archives.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To determine or decide after consideration',
            partOfSpeech: 'transitive verb',
            examples: [
              'The jury found him guilty of all charges.',
              'I find this argument convincing.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Judgment',
                description: 'Reaching a conclusion after consideration',
                examples: [
                  'The committee found her proposal to be the most promising.',
                  'The court found in favor of the plaintiff.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To experience or perceive oneself to be in a particular place or situation',
            partOfSpeech: 'reflexive verb',
            examples: [
              'He found himself in a difficult situation.',
              'She found herself becoming more confident.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Realization',
                description: 'Becoming aware of one\'s state or situation',
                examples: [
                  'After graduation, he found himself without a clear direction.',
                  'She found herself thinking about her childhood more often.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'put',
        base: 'put',
        past: 'put',
        participle: 'put',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'pʊt',
        pronunciationTextUK: 'pʊt',
        meanings: [
          VerbMeaning(
            definition: 'To move or place something in a particular position',
            partOfSpeech: 'transitive verb',
            examples: [
              'She put the book on the shelf.',
              'He put his keys in his pocket.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Placement',
                description: 'Moving objects to specific locations',
                examples: [
                  'Put your coat on the hook by the door.',
                  'She put the dishes in the cupboard.',
                ],
              ),
              ContextualUsage(
                context: 'Arrangement',
                description: 'Organizing or arranging items',
                examples: [
                  'He put the files in alphabetical order.',
                  'They put the furniture against the wall.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To express or present in a particular way',
            partOfSpeech: 'transitive verb',
            examples: [
              'How can I put this tactfully?',
              'She put her case forward convincingly.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Expression',
                description: 'Formulating or phrasing thoughts',
                examples: [
                  'Let me put it another way to make it clearer.',
                  'He put his concerns in writing to the manager.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To cause someone or something to be in a particular state or situation',
            partOfSpeech: 'transitive verb',
            examples: [
              'The decision put us in a difficult position.',
              'The experience put her off flying forever.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Causation',
                description: 'Creating a situation or condition',
                examples: [
                  'The new law put many small businesses at risk.',
                  'His behavior put additional strain on their relationship.',
                ],
              ),
            ],
          ),
        ],
      ),
      VerbModel(
        id: 'tell',
        base: 'tell',
        past: 'told',
        participle: 'told',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'tɛl',
        pronunciationTextUK: 'tel',
        meanings: [
          VerbMeaning(
            definition:
                'To communicate information, facts, or news to someone in spoken or written words',
            partOfSpeech: 'transitive verb',
            examples: [
              'She told me about her new job.',
              'Can you tell us what happened next?',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Information sharing',
                description: 'Conveying knowledge or facts to others',
                examples: [
                  'The witness told the police everything she saw.',
                  'He told his family about the promotion at dinner.',
                ],
              ),
              ContextualUsage(
                context: 'Narration',
                description: 'Relating stories or accounts of events',
                examples: [
                  'Grandma told us stories about her childhood.',
                  'She told the entire story from beginning to end.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To instruct or order someone to do something',
            partOfSpeech: 'transitive verb',
            examples: [
              'The teacher told the students to open their books.',
              'My boss told me to finish the report by Friday.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Instructions',
                description: 'Giving directions or commands',
                examples: [
                  'The doctor told him to rest for a few days.',
                  'She told her daughter to clean her room.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To discern or recognize',
            partOfSpeech: 'transitive verb',
            examples: [
              'I could tell she was upset by her expression.',
              'Can you tell the difference between these two colors?',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Discernment',
                description: 'Perceiving or detecting something',
                examples: [
                  'It\'s hard to tell if he\'s being serious or joking.',
                  'I can tell genuine antiques from reproductions.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'write',
        base: 'write',
        past: 'wrote',
        participle: 'written',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'raɪt',
        pronunciationTextUK: 'raɪt',
        meanings: [
          VerbMeaning(
            definition:
                'To mark letters, words, or other symbols on a surface, typically paper',
            partOfSpeech: 'transitive verb',
            examples: [
              'She wrote her name at the top of the page.',
              'He wrote a letter to his friend.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Handwriting',
                description: 'Creating text by hand',
                examples: [
                  'The doctor wrote a prescription for antibiotics.',
                  'She wrote her address on the back of the envelope.',
                ],
              ),
              ContextualUsage(
                context: 'Typing',
                description: 'Creating text using a keyboard or digital device',
                examples: [
                  'He wrote the email in a hurry.',
                  'She wrote her thesis on her laptop.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To compose or create written material',
            partOfSpeech: 'transitive verb',
            examples: [
              'She writes children\'s books for a living.',
              'He wrote an article about climate change.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Authorship',
                description: 'Creating literary or written works',
                examples: [
                  'She wrote her first novel when she was only 19.',
                  'He writes poetry in his spare time.',
                ],
              ),
              ContextualUsage(
                context: 'Professional writing',
                description: 'Creating content as an occupation',
                examples: [
                  'She writes for a major newspaper.',
                  'He writes technical documentation for software companies.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To communicate in writing',
            partOfSpeech: 'intransitive verb',
            examples: [
              'Please write to me when you arrive.',
              'She hasn\'t written for months.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Correspondence',
                description: 'Communicating through letters or messages',
                examples: [
                  'He writes to his parents every week.',
                  'She wrote back immediately after receiving my letter.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'leave',
        base: 'leave',
        past: 'left',
        participle: 'left',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'liv',
        pronunciationTextUK: 'liːv',
        meanings: [
          VerbMeaning(
            definition: 'To go away from a place or person',
            partOfSpeech: 'transitive verb',
            examples: [
              'We left the party early.',
              'She left home when she was eighteen.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Departure',
                description: 'Going away from a location',
                examples: [
                  'The train leaves the station at 8:30.',
                  'They left the beach before it started to rain.',
                ],
              ),
              ContextualUsage(
                context: 'Separation',
                description: 'Moving away from a person or group',
                examples: [
                  'He left his wife after twenty years of marriage.',
                  'She left her colleagues and started her own business.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To allow to remain in a place or condition',
            partOfSpeech: 'transitive verb',
            examples: [
              'I left my umbrella at the office.',
              'She left the window open all night.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Remaining',
                description:
                    'Keeping something in a specific location or state',
                examples: [
                  'He left his car in the parking garage.',
                  'They left the lights on when they went out.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To cause to be in a specified state or position',
            partOfSpeech: 'transitive verb',
            examples: [
              'The accident left him with a permanent limp.',
              'Her speech left the audience inspired.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Result',
                description: 'Creating a lasting effect or outcome',
                examples: [
                  'The hurricane left the town in ruins.',
                  'Their conversation left me feeling confused.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'become',
        base: 'become',
        past: 'became',
        participle: 'become',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'bɪˈkʌm',
        pronunciationTextUK: 'bɪˈkʌm',
        meanings: [
          VerbMeaning(
            definition: 'To begin to be or develop into',
            partOfSpeech: 'linking verb',
            examples: [
              'She became a doctor after years of study.',
              'The weather became colder as winter approached.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Development',
                description: 'Changing or evolving into something different',
                examples: [
                  'The caterpillar becomes a butterfly.',
                  'Their friendship became a deep partnership over time.',
                ],
              ),
              ContextualUsage(
                context: 'State change',
                description: 'Transition from one condition to another',
                examples: [
                  'He became ill during the trip.',
                  'The situation became serious after the explosion.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To start to have a role or position',
            partOfSpeech: 'linking verb',
            examples: [
              'He became CEO of the company last year.',
              'She became chairperson of the committee.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Role transition',
                description: 'Taking on a new function or position',
                examples: [
                  'She became the team leader after the previous one resigned.',
                  'He became king following his father\'s death.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To suit or be appropriate for',
            partOfSpeech: 'transitive verb',
            examples: [
              'That dress becomes you very well.',
              'His new confidence becomes him.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Suitability',
                description: 'Being appropriate or flattering',
                examples: [
                  'The color blue becomes her complexion.',
                  'Humility becomes a person of such achievements.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'begin',
        base: 'begin',
        past: 'began',
        participle: 'begun',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'bɪˈgɪn',
        pronunciationTextUK: 'bɪˈgɪn',
        meanings: [
          VerbMeaning(
            definition: 'To start or initiate an action or process',
            partOfSpeech: 'transitive verb',
            examples: [
              'They began the meeting with a brief introduction.',
              'He began his career as a teacher.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Initiation',
                description: 'Starting a process or activity',
                examples: [
                  'Let\'s begin the project as soon as possible.',
                  'She began her research by reviewing existing literature.',
                ],
              ),
              ContextualUsage(
                context: 'Commencement',
                description: 'Starting a period or phase',
                examples: [
                  'The company began operations in 1998.',
                  'They began construction on the new building last month.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To come into existence or appear',
            partOfSpeech: 'intransitive verb',
            examples: [
              'The rain began just as we were leaving.',
              'Problems began to emerge after the merger.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Emergence',
                description: 'Coming into being or becoming apparent',
                examples: [
                  'Cracks began to appear in the wall.',
                  'A new chapter in history began with that discovery.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To perform or undergo the first part of an action',
            partOfSpeech: 'intransitive verb',
            examples: [
              'The orchestra began to play.',
              'She began to feel uncomfortable.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Initial action',
                description: 'The first stage of a longer process',
                examples: [
                  'He began to understand the complexity of the situation.',
                  'The audience began to applaud enthusiastically.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'bring',
        base: 'bring',
        past: 'brought',
        participle: 'brought',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'brɪŋ',
        pronunciationTextUK: 'brɪŋ',
        meanings: [
          VerbMeaning(
            definition:
                'To take or carry someone or something to a place or person',
            partOfSpeech: 'transitive verb',
            examples: [
              'Please bring your passport to the meeting.',
              'She brought a bottle of wine to the dinner party.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Transportation',
                description: 'Carrying objects from one place to another',
                examples: [
                  'He brought his tools to fix the broken shelf.',
                  'Could you bring me a glass of water, please?',
                ],
              ),
              ContextualUsage(
                context: 'Accompaniment',
                description: 'Having someone or something come with you',
                examples: [
                  'She brought her children to the doctor\'s appointment.',
                  'They brought their dog to the park.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To cause a particular situation or feeling to occur',
            partOfSpeech: 'transitive verb',
            examples: [
              'The news brought tears to her eyes.',
              'Their actions brought shame to the organization.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Causation',
                description: 'Creating an effect or result',
                examples: [
                  'The scandal brought down the government.',
                  'His jokes always bring laughter to the room.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To lead or guide someone to a particular condition or action',
            partOfSpeech: 'transitive verb',
            examples: [
              'Nothing could bring her to change her mind.',
              'The crisis brought people together.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Influence',
                description: 'Guiding toward a specific outcome',
                examples: [
                  'What brought you to that conclusion?',
                  'The evidence brought the jury to a unanimous verdict.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'speak',
        base: 'speak',
        past: 'spoke',
        participle: 'spoken',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'spik',
        pronunciationTextUK: 'spiːk',
        meanings: [
          VerbMeaning(
            definition:
                'To say words in order to convey information, express feelings, or have a conversation',
            partOfSpeech: 'intransitive verb',
            examples: [
              'He spoke quietly so as not to wake the baby.',
              'She spoke about her experiences during the war.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Communication',
                description: 'Verbal expression of thoughts or information',
                examples: [
                  'The president will speak at the conference tomorrow.',
                  'She spoke to her neighbor about the noise.',
                ],
              ),
              ContextualUsage(
                context: 'Public speaking',
                description: 'Addressing an audience formally',
                examples: [
                  'He speaks regularly at industry events.',
                  'The professor spoke for an hour on climate change.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To know and be able to use a language',
            partOfSpeech: 'transitive verb',
            examples: [
              'She speaks three languages fluently.',
              'Do you speak Spanish?',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Language ability',
                description: 'Having knowledge and competence in a language',
                examples: [
                  'He speaks Japanese because he lived in Tokyo for ten years.',
                  'Many Swiss citizens speak several languages.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To indicate, signify, or express something without words',
            partOfSpeech: 'intransitive verb',
            examples: [
              'His actions speak louder than his words.',
              'The statistics speak for themselves.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Expression',
                description: 'Conveying meaning without verbal communication',
                examples: [
                  'Her eyes spoke of deep sadness.',
                  'His confidence speaks to years of experience in the field.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'run',
        base: 'run',
        past: 'ran',
        participle: 'run',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'rʌn',
        pronunciationTextUK: 'rʌn',
        meanings: [
          VerbMeaning(
            definition:
                'To move at a speed faster than walking by taking quick steps',
            partOfSpeech: 'intransitive verb',
            examples: [
              'She runs five miles every morning.',
              'The children ran across the playground.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Physical activity',
                description: 'Moving quickly by foot',
                examples: [
                  'He runs marathons for charity.',
                  'They ran to catch the bus.',
                ],
              ),
              ContextualUsage(
                context: 'Sports',
                description: 'Moving quickly as part of athletic activity',
                examples: [
                  'The player ran with the ball toward the goal.',
                  'She ran the final lap in record time.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To operate or function',
            partOfSpeech: 'intransitive verb',
            examples: [
              'The engine is running smoothly.',
              'This software runs on most computers.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Operation',
                description: 'Functioning of machines or systems',
                examples: [
                  'The factory runs 24 hours a day.',
                  'My car runs on diesel fuel.',
                ],
              ),
              ContextualUsage(
                context: 'Software',
                description: 'Executing computer programs',
                examples: [
                  'This program runs in the background.',
                  'The app runs on both Android and iOS.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To manage or be in charge of',
            partOfSpeech: 'transitive verb',
            examples: [
              'She runs her own business.',
              'He runs the marketing department.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Management',
                description: 'Being responsible for operations or organization',
                examples: [
                  'They run a successful hotel in the city center.',
                  'She runs the project with remarkable efficiency.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To flow or move in a steady stream',
            partOfSpeech: 'intransitive verb',
            examples: [
              'Tears ran down her cheeks.',
              'The river runs through the valley.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Fluid movement',
                description: 'Continuous flowing of liquids',
                examples: [
                  'The tap has been running all night.',
                  'Paint ran down the wall.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'read',
        base: 'read',
        past: 'read',
        participle: 'read',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'rid',
        pronunciationTextUK: 'riːd',
        meanings: [
          VerbMeaning(
            definition:
                'To look at and comprehend the meaning of written or printed matter',
            partOfSpeech: 'transitive verb',
            examples: [
              'She reads the newspaper every morning.',
              'He read the instructions carefully before assembling the furniture.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Comprehension',
                description: 'Understanding written text',
                examples: [
                  'The student read the textbook before the lecture.',
                  'I\'ve read this novel three times.',
                ],
              ),
              ContextualUsage(
                context: 'Study',
                description: 'Examining text for academic purposes',
                examples: [
                  'She reads history at Oxford University.',
                  'He reads widely in the field of psychology.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To speak aloud written or printed words',
            partOfSpeech: 'transitive verb',
            examples: [
              'The teacher read the story to the class.',
              'He read the poem at the wedding ceremony.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Recitation',
                description: 'Speaking text aloud for others to hear',
                examples: [
                  'She read the minutes from the previous meeting.',
                  'The actor read his lines with great emotion.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To interpret or understand something in a particular way',
            partOfSpeech: 'transitive verb',
            examples: [
              'I think you\'re reading too much into his comment.',
              'How do you read the current political situation?',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Interpretation',
                description: 'Analyzing and drawing meaning from information',
                examples: [
                  'The lawyer read between the lines of the contract.',
                  'Analysts are reading the data as a positive sign for the economy.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To discern or observe signs, features, or information',
            partOfSpeech: 'transitive verb',
            examples: [
              'He can read people\'s emotions very well.',
              'The fortune teller claimed to read the future in a crystal ball.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Perception',
                description:
                    'Detecting or discerning information from observation',
                examples: [
                  'Experienced sailors can read the weather from cloud patterns.',
                  'She could read his mood from his body language.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'meet',
        base: 'meet',
        past: 'met',
        participle: 'met',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'mit',
        pronunciationTextUK: 'miːt',
        meanings: [
          VerbMeaning(
            definition:
                'To come into the presence or company of someone by arrangement or chance',
            partOfSpeech: 'transitive verb',
            examples: [
              'I\'m meeting Sarah for lunch tomorrow.',
              'We met an old friend at the concert last night.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Planned encounter',
                description: 'Pre-arranged coming together of people',
                examples: [
                  'She\'s meeting her supervisor at 3 PM.',
                  'They met their tour guide at the hotel lobby.',
                ],
              ),
              ContextualUsage(
                context: 'Chance encounter',
                description: 'Unplanned interaction with someone',
                examples: [
                  'I met my wife at a friend\'s party.',
                  'We met by chance in the supermarket.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To be introduced to someone for the first time',
            partOfSpeech: 'transitive verb',
            examples: [
              'I\'d like you to meet my parents.',
              'Have you met the new manager yet?',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Introduction',
                description: 'First-time encounters between people',
                examples: [
                  'She met her boyfriend\'s family at Christmas.',
                  'I met many interesting people at the conference.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To fulfill or satisfy requirements, expectations, or needs',
            partOfSpeech: 'transitive verb',
            examples: [
              'The product doesn\'t meet our quality standards.',
              'His performance met all our expectations.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Satisfaction',
                description: 'Fulfilling criteria or standards',
                examples: [
                  'The company met its sales targets for the quarter.',
                  'Her essay met all the requirements for the assignment.',
                ],
              ),
              ContextualUsage(
                context: 'Provision',
                description: 'Satisfying needs or demands',
                examples: [
                  'The new service meets the needs of elderly residents.',
                  'This solution meets both our short and long-term objectives.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'send',
        base: 'send',
        past: 'sent',
        participle: 'sent',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'sɛnd',
        pronunciationTextUK: 'send',
        meanings: [
          VerbMeaning(
            definition: 'To cause something to go or be taken to a destination',
            partOfSpeech: 'transitive verb',
            examples: [
              'She sent a letter to her grandmother.',
              'We sent the package by courier.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Dispatch',
                description: 'Arranging for items to be delivered',
                examples: [
                  'The company sends products to customers worldwide.',
                  'He sent flowers to his wife for their anniversary.',
                ],
              ),
              ContextualUsage(
                context: 'Electronic transmission',
                description: 'Transmitting information digitally',
                examples: [
                  'She sent an email to the entire team.',
                  'Please send me the document as an attachment.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To arrange for someone to go somewhere',
            partOfSpeech: 'transitive verb',
            examples: [
              'They sent their daughter to a private school.',
              'The company sends employees abroad for training.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Delegation',
                description: 'Directing someone to a place for a purpose',
                examples: [
                  'The boss sent her to represent the company at the conference.',
                  'They sent a team of experts to investigate the problem.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To cause someone or something to be in a particular state',
            partOfSpeech: 'transitive verb',
            examples: [
              'The movie sent the audience into fits of laughter.',
              'The loud noise sent the birds flying away.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Effect',
                description: 'Creating a reaction or response',
                examples: [
                  'The news sent shock waves through the community.',
                  'His comment sent her into a rage.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'buy',
        base: 'buy',
        past: 'bought',
        participle: 'bought',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'baɪ',
        pronunciationTextUK: 'baɪ',
        meanings: [
          VerbMeaning(
            definition: 'To obtain something by paying money for it',
            partOfSpeech: 'transitive verb',
            examples: [
              'She bought a new car last month.',
              'We need to buy groceries for dinner.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Purchasing',
                description: 'Acquiring goods through payment',
                examples: [
                  'He bought a house in the suburbs.',
                  'I bought these shoes on sale.',
                ],
              ),
              ContextualUsage(
                context: 'Investment',
                description: 'Purchasing assets or financial instruments',
                examples: [
                  'They bought shares in the company before the price increased.',
                  'She bought gold as a hedge against inflation.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To obtain the loyalty, support, or silence of someone by giving them money or advantages',
            partOfSpeech: 'transitive verb',
            examples: [
              'The corporation tried to buy political influence through donations.',
              'You can\'t buy my loyalty with promises.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Persuasion',
                description: 'Using resources to gain favor or compliance',
                examples: [
                  'The defendant attempted to buy the witness\'s silence.',
                  'No amount of money can buy true friendship.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To accept or believe something',
            partOfSpeech: 'transitive verb',
            examples: [
              'I don\'t buy his excuse for being late.',
              'The jury didn\'t buy the defendant\'s story.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Acceptance',
                description: 'Believing or accepting claims or explanations',
                examples: [
                  'The public isn\'t buying the government\'s explanation.',
                  'I\'m not sure I buy that theory about climate change.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'understand',
        base: 'understand',
        past: 'understood',
        participle: 'understood',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'ˌʌndərˈstænd',
        pronunciationTextUK: 'ˌʌndəˈstænd',
        meanings: [
          VerbMeaning(
            definition:
                'To perceive the intended meaning of words, language, or a speaker',
            partOfSpeech: 'transitive verb',
            examples: [
              'I don\'t understand what you\'re trying to say.',
              'She understands Spanish but doesn\'t speak it well.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Comprehension',
                description:
                    'Grasping the meaning of language or communication',
                examples: [
                  'He didn\'t fully understand the instructions.',
                  'She understands technical jargon better than most people.',
                ],
              ),
              ContextualUsage(
                context: 'Language skills',
                description: 'Comprehending spoken or written language',
                examples: [
                  'Do you understand what this sentence means?',
                  'I understand most of what they say when they speak slowly.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To perceive the significance, explanation, or cause of something',
            partOfSpeech: 'transitive verb',
            examples: [
              'I understand the problem now.',
              'She understands complex mathematical concepts.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Insight',
                description:
                    'Grasping the nature or meaning of concepts or situations',
                examples: [
                  'Scientists are trying to understand how the universe began.',
                  'He understands the economic factors affecting the market.',
                ],
              ),
              ContextualUsage(
                context: 'Learning',
                description: 'Comprehending subject matter or processes',
                examples: [
                  'Students must understand the theory before applying it.',
                  'I finally understand how this machine works.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To be sympathetically or knowledgeably aware of the character or nature of',
            partOfSpeech: 'transitive verb',
            examples: [
              'Parents don\'t always understand their teenagers.',
              'She really understands what I\'m going through.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Empathy',
                description: 'Having insight into feelings or circumstances',
                examples: [
                  'He understands her anxiety about public speaking.',
                  'They understand the challenges faced by immigrant families.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'feel',
        base: 'feel',
        past: 'felt',
        participle: 'felt',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'fil',
        pronunciationTextUK: 'fiːl',
        meanings: [
          VerbMeaning(
            definition: 'To be aware of a physical sensation or emotion',
            partOfSpeech: 'transitive verb',
            examples: [
              'I feel pain in my shoulder.',
              'She felt a deep sense of joy at the news.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Physical sensation',
                description: 'Experiencing tactile or bodily sensations',
                examples: [
                  'He felt a sharp pain in his chest.',
                  'I can feel the heat from the fire.',
                ],
              ),
              ContextualUsage(
                context: 'Emotion',
                description: 'Experiencing affective states',
                examples: [
                  'She felt disappointed by the outcome.',
                  'They felt excited about the upcoming trip.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To perceive through physical contact or touch',
            partOfSpeech: 'transitive verb',
            examples: [
              'Feel how soft this fabric is.',
              'I felt something move under my hand.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Touch',
                description: 'Using the sense of touch to examine',
                examples: [
                  'The doctor felt the patient\'s pulse.',
                  'She felt the wall in the dark to find the light switch.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To believe or think in a specified way',
            partOfSpeech: 'linking verb',
            examples: [
              'I feel that we should wait before making a decision.',
              'He feels strongly about environmental issues.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Opinion',
                description: 'Having a belief or impression',
                examples: [
                  'She feels the proposal needs more work.',
                  'Many people feel the new law is unfair.',
                ],
              ),
              ContextualUsage(
                context: 'Intuition',
                description: 'Having an instinctive sense about something',
                examples: [
                  'I feel something is wrong with this situation.',
                  'He felt the interview went well.',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'show',
        base: 'show',
        past: 'showed',
        participle: 'shown',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'ʃoʊ',
        pronunciationTextUK: 'ʃəʊ',
        meanings: [
          VerbMeaning(
            definition: 'To make visible or cause to be seen',
            partOfSpeech: 'transitive verb',
            examples: [
              'She showed her artwork at the gallery.',
              'He showed me the photos from his vacation.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Display',
                description: 'Making something visible for viewing',
                examples: [
                  'The museum is showing a collection of Impressionist paintings.',
                  'She showed him her new dress.',
                ],
              ),
              ContextualUsage(
                context: 'Presentation',
                description:
                    'Presenting items or information for others to see',
                examples: [
                  'The salesperson showed us several different models.',
                  'He showed his identification to the security guard.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To demonstrate or prove',
            partOfSpeech: 'transitive verb',
            examples: [
              'The experiment showed that the theory was correct.',
              'Her actions showed her commitment to the cause.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Evidence',
                description: 'Providing proof or demonstration',
                examples: [
                  'The data shows a clear correlation between the variables.',
                  'The results showed significant improvement after treatment.',
                ],
              ),
              ContextualUsage(
                context: 'Revelation',
                description: 'Revealing qualities, feelings, or traits',
                examples: [
                  'His response showed his lack of understanding.',
                  'She showed great courage in the face of danger.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To guide or direct',
            partOfSpeech: 'transitive verb',
            examples: [
              'The usher showed us to our seats.',
              'Can you show me how to use this machine?',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Instruction',
                description: 'Teaching or demonstrating how to do something',
                examples: [
                  'The instructor showed the class how to solve the equation.',
                  'My father showed me how to change a tire.',
                ],
              ),
              ContextualUsage(
                context: 'Direction',
                description: 'Guiding someone to a location or position',
                examples: [
                  'The host showed the guests to the dining room.',
                  'Could you show me where the bathroom is?',
                ],
              ),
            ],
          ),
        ],
      ),

      VerbModel(
        id: 'hear',
        base: 'hear',
        past: 'heard',
        participle: 'heard',
        pastUK: '',
        pastUS: '',
        participleUK: '',
        participleUS: '',
        pronunciationTextUS: 'hɪr',
        pronunciationTextUK: 'hɪə',
        meanings: [
          VerbMeaning(
            definition: 'To perceive sound with the ears',
            partOfSpeech: 'transitive verb',
            examples: [
              'I can hear music playing in the distance.',
              'She heard a noise outside her window.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Auditory perception',
                description: 'Detecting sounds through the ears',
                examples: [
                  'I couldn\'t hear what she said because of the traffic.',
                  'They heard the thunder rumbling in the distance.',
                ],
              ),
              ContextualUsage(
                context: 'Listening',
                description: 'Paying attention to sounds',
                examples: [
                  'I heard every word of their conversation.',
                  'Have you heard the latest album by that band?',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition: 'To be told or informed about something',
            partOfSpeech: 'transitive verb',
            examples: [
              'I heard that she got a new job.',
              'We haven\'t heard anything about the test results yet.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Information',
                description: 'Receiving news or information',
                examples: [
                  'I heard about the accident on the news.',
                  'Have you heard from your sister lately?',
                ],
              ),
              ContextualUsage(
                context: 'Rumors',
                description: 'Being informed of unofficial information',
                examples: [
                  'I heard they\'re planning to close the factory.',
                  'She heard through the grapevine that he was getting promoted.',
                ],
              ),
            ],
          ),
          VerbMeaning(
            definition:
                'To listen to and consider a case, a request, evidence, etc.',
            partOfSpeech: 'transitive verb',
            examples: [
              'The court will hear the case next month.',
              'The committee heard arguments from both sides.',
            ],
            contextualUsages: [
              ContextualUsage(
                context: 'Judicial',
                description: 'Officially listening to legal proceedings',
                examples: [
                  'The judge heard testimony from several witnesses.',
                  'The appeal will be heard by the Supreme Court.',
                ],
              ),
              ContextualUsage(
                context: 'Consideration',
                description:
                    'Listening to and considering opinions or complaints',
                examples: [
                  'The manager will hear your complaint personally.',
                  'The board meets monthly to hear proposals from employees.',
                ],
              ),
            ],
          ),
        ],
      ),VerbModel(
  id: 'hold',
  base: 'hold',
  past: 'held',
  participle: 'held',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'hoʊld',
  pronunciationTextUK: 'həʊld',
  meanings: [
    VerbMeaning(
      definition: 'To keep or maintain in a specified position',
      partOfSpeech: 'transitive verb',
      examples: [
        'She held the baby in her arms.',
        'He held onto the railing for support.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical grasp',
          description: 'Keeping something in place with hands or arms',
          examples: [
            'Please hold this bag while I find my keys.',
            'He held the door open for the person behind him.',
          ],
        ),
        ContextualUsage(
          context: 'Support',
          description: 'Providing physical support or stability',
          examples: [
            'The brackets hold the shelf securely in place.',
            'These pillars hold up the entire structure.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To possess or contain',
      partOfSpeech: 'transitive verb',
      examples: [
        'The box holds all my childhood memories.',
        'The stadium holds up to 50,000 people.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Capacity',
          description: 'Having space or room for a specific amount',
          examples: [
            'This bottle holds exactly one liter.',
            'The closet holds all of her clothes.',
          ],
        ),
        ContextualUsage(
          context: 'Possession',
          description: 'Owning or keeping something',
          examples: [
            'The bank holds the deed to the property.',
            'He holds the world record for the 100-meter dash.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To arrange and conduct an event',
      partOfSpeech: 'transitive verb',
      examples: [
        'They held the conference in the new convention center.',
        'The school holds a science fair every spring.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Organization',
          description: 'Arranging and managing formal events',
          examples: [
            'The committee holds monthly meetings to discuss progress.',
            'They held the ceremony in the town square.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To maintain or sustain a particular state, attitude, or position',
      partOfSpeech: 'transitive verb',
      examples: [
        'She held her composure despite the difficult situation.',
        'The team held their lead until the final whistle.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Persistence',
          description: 'Maintaining a condition or state',
          examples: [
            'The building has held its color well despite the harsh weather.',
            'He held his breath for nearly two minutes.',
          ],
        ),
        ContextualUsage(
          context: 'Opinion',
          description: 'Maintaining beliefs or viewpoints',
          examples: [
            'She holds strong views on environmental protection.',
            'They held that education should be free for everyone.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'stand',
  base: 'stand',
  past: 'stood',
  participle: 'stood',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'stænd',
  pronunciationTextUK: 'stænd',
  meanings: [
    VerbMeaning(
      definition: 'To be in an upright position on the feet',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The children stood quietly during the ceremony.',
        'She stood by the window watching the rain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical position',
          description: 'Being upright on feet',
          examples: [
            'He stood at the back of the room during the presentation.',
            'We stood in line for over an hour.',
          ],
        ),
        ContextualUsage(
          context: 'Posture',
          description: 'Maintaining a particular standing position',
          examples: [
            'Stand straight with your shoulders back.',
            'The soldier stood at attention.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be placed or situated in a specified position',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The old oak tree stands at the end of the garden.',
        'A magnificent cathedral stands in the city center.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Location',
          description: 'Being positioned in a specific place',
          examples: [
            'The statue stands in the main square.',
            'Their house stands on the hill overlooking the valley.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To tolerate or endure something',
      partOfSpeech: 'transitive verb',
      examples: [
        'I can\'t stand the noise from the construction site.',
        'She can\'t stand people who talk during movies.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Tolerance',
          description: 'Enduring or accepting situations or behaviors',
          examples: [
            'He couldn\'t stand the thought of leaving his hometown.',
            'How do you stand working in such conditions?',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To maintain a particular position in relation to something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She stands firm in her beliefs.',
        'The agreement still stands despite recent objections.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Status',
          description: 'The current state or condition of things',
          examples: [
            'As it stands, we won\'t be able to meet the deadline.',
            'The world record has stood for over ten years.',
          ],
        ),
        ContextualUsage(
          context: 'Support',
          description: 'Remaining loyal or supportive',
          examples: [
            'Her friends stood by her during the difficult time.',
            'He stood up for his colleagues against unfair criticism.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'pay',
  base: 'pay',
  past: 'paid',
  participle: 'paid',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'peɪ',
  pronunciationTextUK: 'peɪ',
  meanings: [
    VerbMeaning(
      definition: 'To give money in exchange for goods or services',
      partOfSpeech: 'transitive verb',
      examples: [
        'I paid the electricity bill yesterday.',
        'She paid \$50 for that dress.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Purchases',
          description: 'Giving money for products or items',
          examples: [
            'He paid for everyone\'s dinner at the restaurant.',
            'I usually pay with my credit card rather than cash.',
          ],
        ),
        ContextualUsage(
          context: 'Bills',
          description: 'Settling financial obligations',
          examples: [
            'Remember to pay your taxes before the deadline.',
            'They pay their mortgage at the beginning of each month.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To give or bestow something as compensation or return',
      partOfSpeech: 'transitive verb',
      examples: [
        'They paid their respects to the deceased.',
        'She paid him a compliment on his presentation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Attention',
          description: 'Giving consideration or acknowledgment',
          examples: [
            'You should pay attention to the warning signs.',
            'He paid tribute to his former mentor in his speech.',
          ],
        ),
        ContextualUsage(
          context: 'Consequence',
          description: 'Suffering a penalty or punishment',
          examples: [
            'Criminals must pay for their crimes.',
            'She paid dearly for her mistake.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be profitable or worthwhile',
      partOfSpeech: 'intransitive verb',
      examples: [
        'It pays to be cautious in such situations.',
        'Hard work always pays in the end.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Benefit',
          description: 'Producing advantageous results',
          examples: [
            'Investing in quality equipment pays off in the long run.',
            'It doesn\'t pay to cut corners on safety measures.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To provide someone with money for work',
      partOfSpeech: 'transitive verb',
      examples: [
        'The company pays its employees monthly.',
        'They pay well for skilled workers.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Employment',
          description: 'Compensating for work or services rendered',
          examples: [
            'The job pays \$20 an hour plus benefits.',
            'He gets paid every two weeks.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sit',
  base: 'sit',
  past: 'sat',
  participle: 'sat',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sɪt',
  pronunciationTextUK: 'sɪt',
  meanings: [
    VerbMeaning(
      definition: 'To rest with the upper body upright and the weight supported by the buttocks',
      partOfSpeech: 'intransitive verb',
      examples: [
        'They sat on the bench watching the sunset.',
        'She sat at her desk working on the report.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Position',
          description: 'Being in a seated posture',
          examples: [
            'He sat cross-legged on the floor during meditation.',
            'We sat in the back row of the theater.',
          ],
        ),
        ContextualUsage(
          context: 'Posture',
          description: 'Manner of sitting',
          examples: [
            'Sit up straight and don\'t slouch.',
            'The child sat quietly during the entire ceremony.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be located or situated',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The house sits on top of a hill.',
        'A large statue sits in the center of the square.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Location',
          description: 'Being positioned or placed in a particular spot',
          examples: [
            'The village sits at the foot of the mountain.',
            'An impressive chandelier sits above the dining table.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To hold a session or be engaged in a function',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The committee sits once a month.',
        'Parliament will sit until the legislation is passed.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Official proceedings',
          description: 'Conducting formal meetings or sessions',
          examples: [
            'The court sits from Monday to Friday.',
            'The board of directors will sit to discuss the new proposal.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take care of someone else\'s home or pets temporarily',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She agreed to sit for their children while they went out.',
        'He sits for their dog whenever they travel.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Childcare',
          description: 'Looking after children temporarily',
          examples: [
            'My neighbor sits for my kids after school.',
            'She sits for several families in the neighborhood.',
          ],
        ),
        ContextualUsage(
          context: 'Pet care',
          description: 'Taking care of animals in the owner\'s absence',
          examples: [
            'We need someone to sit for our cat this weekend.',
            'He sits for pets as a part-time job.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'lose',
  base: 'lose',
  past: 'lost',
  participle: 'lost',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'luz',
  pronunciationTextUK: 'luːz',
  meanings: [
    VerbMeaning(
      definition: 'To be deprived of or cease to have or retain something',
      partOfSpeech: 'transitive verb',
      examples: [
        'I lost my wallet on the bus yesterday.',
        'She lost her job during the economic downturn.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Misplacement',
          description: 'Being unable to find something',
          examples: [
            'He lost his keys and couldn\'t get into his apartment.',
            'I\'m always losing my glasses somewhere in the house.',
          ],
        ),
        ContextualUsage(
          context: 'Deprivation',
          description: 'Having something taken away',
          examples: [
            'The company lost its license to operate in the region.',
            'She lost custody of her children after the divorce.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To fail to win, be defeated',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Our team lost the championship game.',
        'He lost the election by a small margin.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Competition',
          description: 'Being defeated in games or contests',
          examples: [
            'They lost three matches in a row.',
            'She lost to a better player in the final round.',
          ],
        ),
        ContextualUsage(
          context: 'Failure',
          description: 'Failing to achieve a desired outcome',
          examples: [
            'The company lost the contract to a competitor.',
            'We lost the bid for the Olympic Games.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To suffer the loss of a person through death, separation, or estrangement',
      partOfSpeech: 'transitive verb',
      examples: [
        'She lost her husband to cancer last year.',
        'They lost touch with each other after college.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Bereavement',
          description: 'Experiencing the death of someone',
          examples: [
            'He lost both parents in a car accident.',
            'The community lost a beloved leader.',
          ],
        ),
        ContextualUsage(
          context: 'Connection',
          description: 'Ceasing to be in contact with someone',
          examples: [
            'We lost contact with our old neighbors after moving.',
            'She lost many friends when she changed careers.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To decrease in amount, magnitude, or degree',
      partOfSpeech: 'transitive verb',
      examples: [
        'He has lost a lot of weight recently.',
        'The car lost speed as it climbed the hill.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Reduction',
          description: 'Becoming less in quantity or intensity',
          examples: [
            'The battery loses power quickly in cold weather.',
            'She lost interest in the project over time.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'win',
  base: 'win',
  past: 'won',
  participle: 'won',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'wɪn',
  pronunciationTextUK: 'wɪn',
  meanings: [
    VerbMeaning(
      definition: 'To be successful or victorious in a contest, competition, or conflict',
      partOfSpeech: 'transitive verb',
      examples: [
        'Our team won the championship.',
        'She won the race by a narrow margin.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Competition',
          description: 'Achieving victory in organized contests',
          examples: [
            'He won the chess tournament three years in a row.',
            'They won the debate against the defending champions.',
          ],
        ),
        ContextualUsage(
          context: 'Elections',
          description: 'Being successful in political contests',
          examples: [
            'The candidate won the election by appealing to rural voters.',
            'Their party won a majority in parliament.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To obtain or secure as a result of a contest, conflict, bet, or other endeavor',
      partOfSpeech: 'transitive verb',
      examples: [
        'She won a scholarship to study abroad.',
        'He won \$1000 in the lottery.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Prizes',
          description: 'Receiving awards or rewards',
          examples: [
            'The film won three Academy Awards.',
            'They won a free vacation to Hawaii.',
          ],
        ),
        ContextualUsage(
          context: 'Achievements',
          description: 'Securing positions or opportunities',
          examples: [
            'She won a place at a prestigious university.',
            'The company won the contract to build the new stadium.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To gain the favor, support, or acceptance of someone',
      partOfSpeech: 'transitive verb',
      examples: [
        'Her sincerity won the trust of her colleagues.',
        'The candidate\'s policies won many voters.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Persuasion',
          description: 'Gaining agreement or approval',
          examples: [
            'The argument won support from skeptical board members.',
            'His honesty won the respect of everyone in the room.',
          ],
        ),
        ContextualUsage(
          context: 'Affection',
          description: 'Earning emotional attachment',
          examples: [
            'Her kindness won the hearts of the children.',
            'The rescue dog won his owner\'s devotion immediately.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'teach',
  base: 'teach',
  past: 'taught',
  participle: 'taught',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'titʃ',
  pronunciationTextUK: 'tiːtʃ',
  meanings: [
    VerbMeaning(
      definition: 'To impart knowledge or skill through instruction or example',
      partOfSpeech: 'transitive verb',
      examples: [
        'She teaches mathematics at the local high school.',
        'My father taught me how to fish.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Education',
          description: 'Instructing in an academic subject',
          examples: [
            'He teaches chemistry to undergraduate students.',
            'She has taught English in several countries.',
          ],
        ),
        ContextualUsage(
          context: 'Skills',
          description: 'Training in practical abilities',
          examples: [
            'The coach taught the team new strategies.',
            'My grandmother taught me how to bake bread from scratch.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause to learn by example or experience',
      partOfSpeech: 'transitive verb',
      examples: [
        'Failure teaches us valuable lessons.',
        'Travel teaches you about different cultures.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Life lessons',
          description: 'Learning through real-life experiences',
          examples: [
            'Hardship taught him to appreciate what he had.',
            'Parenthood teaches patience and selflessness.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To work as a teacher',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She has been teaching for over twenty years.',
        'He teaches at the university level.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Profession',
          description: 'Working in education as an occupation',
          examples: [
            'She teaches part-time while raising her children.',
            'He taught abroad before returning to his home country.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To advocate as a principle or guide',
      partOfSpeech: 'transitive verb',
      examples: [
        'The church teaches forgiveness and compassion.',
        'This philosophy teaches respect for all living beings.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Doctrine',
          description: 'Promoting specific beliefs or principles',
          examples: [
            'The ancient text teaches moderation in all things.',
            'Their religion teaches daily prayer and meditation.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'grow',
  base: 'grow',
  past: 'grew',
  participle: 'grown',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'groʊ',
  pronunciationTextUK: 'grəʊ',
  meanings: [
    VerbMeaning(
      definition: 'To increase in size or amount through a natural process',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Children grow quickly during their teenage years.',
        'The tree has grown several feet since last year.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Development',
          description: 'Physical increase in size or height',
          examples: [
            'Her hair grows very quickly.',
            'The plant grew toward the sunlight.',
          ],
        ),
        ContextualUsage(
          context: 'Expansion',
          description: 'Becoming larger or more numerous',
          examples: [
            'The company has grown significantly over the past decade.',
            'Their savings grew through careful investment.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cultivate and care for plants',
      partOfSpeech: 'transitive verb',
      examples: [
        'They grow organic vegetables in their garden.',
        'The farmer grows wheat and corn.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Cultivation',
          description: 'Raising plants for food or decoration',
          examples: [
            'She grows roses in her backyard.',
            'The region grows some of the best grapes for winemaking.',
          ],
        ),
        ContextualUsage(
          context: 'Agriculture',
          description: 'Commercial production of crops',
          examples: [
            'The country grows enough rice to export to neighboring nations.',
            'They grow coffee beans at high elevation for better flavor.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To develop or change gradually into a different state',
      partOfSpeech: 'intransitive verb',
      examples: [
        'They have grown closer over the years.',
        'She has grown more confident in her abilities.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Transition',
          description: 'Changing from one state to another',
          examples: [
            'The crowd grew restless waiting for the concert to begin.',
            'Their friendship grew into something more romantic.',
          ],
        ),
        ContextualUsage(
          context: 'Maturation',
          description: 'Developing emotionally or mentally',
          examples: [
            'He has grown wiser with age.',
            'The experience helped her grow as a person.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To come to be by degrees; to become',
      partOfSpeech: 'linking verb',
      examples: [
        'It grew dark as the sun set.',
        'The music grew louder as we approached the venue.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Intensification',
          description: 'Increasing in intensity or strength',
          examples: [
            'Their concern grew as they waited for news.',
            'The problem has grown worse over time.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'build',
  base: 'build',
  past: 'built',
  participle: 'built',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɪld',
  pronunciationTextUK: 'bɪld',
  meanings: [
    VerbMeaning(
      definition: 'To construct by putting parts or materials together',
      partOfSpeech: 'transitive verb',
      examples: [
        'They built a new house last year.',
        'The company built the bridge in record time.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Construction',
          description: 'Creating physical structures',
          examples: [
            'The ancient Egyptians built enormous pyramids.',
            'They built the entire cabin by hand.',
          ],
        ),
        ContextualUsage(
          context: 'Manufacturing',
          description: 'Assembling products or devices',
          examples: [
            'The factory builds cars for the European market.',
            'He builds custom furniture in his workshop.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To develop or form by assembling individuals or constituents',
      partOfSpeech: 'transitive verb',
      examples: [
        'She has built a successful business from scratch.',
        'They built a coalition of environmental groups.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Creation',
          description: 'Forming organizations or systems',
          examples: [
            'The entrepreneur built an empire of restaurants.',
            'They built a network of supporters across the country.',
          ],
        ),
        ContextualUsage(
          context: 'Development',
          description: 'Constructing non-physical things',
          examples: [
            'The coach built a championship team over several seasons.',
            'They built a strong case against the defendant.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To establish, increase, or strengthen',
      partOfSpeech: 'transitive verb',
      examples: [
        'The company built its reputation on quality service.',
        'She built her confidence through practice and experience.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Enhancement',
          description: 'Increasing or improving qualities',
          examples: [
            'The exercise program helps build muscle strength.',
            'Regular saving builds wealth over time.',
          ],
        ),
        ContextualUsage(
          context: 'Relationships',
          description: 'Developing trust or connections',
          examples: [
            'It takes time to build trust in a relationship.',
            'They built strong partnerships with local businesses.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To base or ground something on a foundation',
      partOfSpeech: 'transitive verb',
      examples: [
        'His theory is built on years of research.',
        'Their strategy was built around customer feedback.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Foundation',
          description: 'Creating a basis for something',
          examples: [
            'The curriculum is built on progressive learning principles.',
            'Their success was built on innovation and persistence.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'keep',
  base: 'keep',
  past: 'kept',
  participle: 'kept',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kip',
  pronunciationTextUK: 'kiːp',
  meanings: [
    VerbMeaning(
      definition: 'To retain possession of; to have or maintain',
      partOfSpeech: 'transitive verb',
      examples: [
        'She keeps all her old photographs in a box.',
        'They decided to keep their house when they moved abroad.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Possession',
          description: 'Continuing to own or hold something',
          examples: [
            'I\'ll keep this book as a souvenir of my trip.',
            'He keeps his grandfather\'s watch in a safe place.',
          ],
        ),
        ContextualUsage(
          context: 'Storage',
          description: 'Storing or maintaining items in a location',
          examples: [
            'They keep their winter clothes in the attic.',
            'Where do you keep your spare keys?',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To continue or maintain in a specified state, position, or activity',
      partOfSpeech: 'transitive verb',
      examples: [
        'Please keep quiet during the performance.',
        'Try to keep a positive attitude despite the challenges.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Maintenance',
          description: 'Maintaining a state or condition',
          examples: [
            'The nurse kept the patient comfortable.',
            'She keeps her desk very organized.',
          ],
        ),
        ContextualUsage(
          context: 'Continuation',
          description: 'Persisting with an action or state',
          examples: [
            'Keep walking until you reach the bridge.',
            'They kept working despite the power outage.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To observe or honor',
      partOfSpeech: 'transitive verb',
      examples: [
        'They keep all the traditional holidays.',
        'She keeps her promises without fail.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Commitment',
          description: 'Honoring agreements or obligations',
          examples: [
            'He always keeps his appointments.',
            'The company keeps its warranty commitments.',
          ],
        ),
        ContextualUsage(
          context: 'Tradition',
          description: 'Observing customs or practices',
          examples: [
            'The family keeps the Sabbath strictly.',
            'They keep old traditions alive in their community.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To raise and care for animals',
      partOfSpeech: 'transitive verb',
      examples: [
        'They keep chickens in their backyard.',
        'Her grandfather kept bees for honey production.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Animal husbandry',
          description: 'Raising animals for practical purposes',
          examples: [
            'The farm keeps sheep for wool and meat.',
            'Many families in rural areas keep goats for milk.',
          ],
        ),
        ContextualUsage(
          context: 'Pets',
          description: 'Caring for animals as companions',
          examples: [
            'They keep several cats and dogs as pets.',
            'You\'re not allowed to keep exotic animals in this apartment building.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'break',
  base: 'break',
  past: 'broke',
  participle: 'broken',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'breɪk',
  pronunciationTextUK: 'breɪk',
  meanings: [
    VerbMeaning(
      definition: 'To separate into pieces as a result of a blow, shock, or strain',
      partOfSpeech: 'transitive verb',
      examples: [
        'He accidentally broke the window with the baseball.',
        'The plate broke when it fell on the floor.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Damage',
          description: 'Physical destruction of objects',
          examples: [
            'She broke her glasses when she sat on them.',
            'The storm broke several branches off the tree.',
          ],
        ),
        ContextualUsage(
          context: 'Fracture',
          description: 'Breaking bones or hard materials',
          examples: [
            'He broke his arm in two places during the fall.',
            'The earthquake broke water pipes throughout the city.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To interrupt or stop',
      partOfSpeech: 'transitive verb',
      examples: [
        'Let\'s break for lunch at noon.',
        'He broke the silence with an unexpected announcement.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Interruption',
          description: 'Disrupting continuity or flow',
          examples: [
            'The teacher broke the class into small discussion groups.',
            'A loud noise broke her concentration.',
          ],
        ),
        ContextualUsage(
          context: 'Pause',
          description: 'Taking a temporary stop',
          examples: [
            'They broke from their work to celebrate a colleague\'s birthday.',
            'The negotiations broke for the weekend.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To violate or disobey',
      partOfSpeech: 'transitive verb',
      examples: [
        'She broke the speed limit on the highway.',
        'He broke his promise to call her.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Rules',
          description: 'Failing to comply with regulations',
          examples: [
            'The player broke the rules and was penalized.',
            'The company broke environmental protection laws.',
          ],
        ),
        ContextualUsage(
          context: 'Commitments',
          description: 'Failing to honor agreements',
          examples: [
            'They broke the contract by not delivering on time.',
            'He broke his word about keeping the information confidential.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To overcome or surpass',
      partOfSpeech: 'transitive verb',
      examples: [
        'The athlete broke the world record in the 100-meter sprint.',
        'Their new product broke all previous sales records.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Achievement',
          description: 'Exceeding previous limits or standards',
          examples: [
            'The film broke box office records worldwide.',
            'She broke the company\'s sales record for the third year running.',
          ],
        ),
        ContextualUsage(
          context: 'Barriers',
          description: 'Overcoming obstacles or limitations',
          examples: [
            'The discovery broke new ground in cancer research.',
            'Their technology broke through previous performance barriers.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sell',
  base: 'sell',
  past: 'sold',
  participle: 'sold',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sɛl',
  pronunciationTextUK: 'sel',
  meanings: [
    VerbMeaning(
      definition: 'To give or transfer ownership of something to someone else in exchange for money',
      partOfSpeech: 'transitive verb',
      examples: [
        'They sold their house last month.',
        'The store sells organic vegetables.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Commerce',
          description: 'Transferring goods for payment',
          examples: [
            'She sells handmade jewelry at the local market.',
            'The company sells its products in over 50 countries.',
          ],
        ),
        ContextualUsage(
          context: 'Real estate',
          description: 'Transferring property ownership',
          examples: [
            'They sold their vacation home for a profit.',
            'The developer sold all the new apartments before construction was completed.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To persuade someone of the merits of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The politician failed to sell his ideas to the voters.',
        'She really sold me on the benefits of regular exercise.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Persuasion',
          description: 'Convincing others to accept ideas or proposals',
          examples: [
            'The presenter sold the concept brilliantly to the board.',
            'He couldn\'t sell his colleagues on the new approach.',
          ],
        ),
        ContextualUsage(
          context: 'Promotion',
          description: 'Advocating for something effectively',
          examples: [
            'The campaign sold the candidate as a man of the people.',
            'You need to sell yourself more effectively in job interviews.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be purchased or find buyers',
      partOfSpeech: 'intransitive verb',
      examples: [
        'These books sell well during the holiday season.',
        'The new model is selling better than expected.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Market performance',
          description: 'Success in attracting buyers',
          examples: [
            'Their latest album sold a million copies in the first week.',
            'Luxury goods sell even during economic downturns.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To betray someone for personal gain',
      partOfSpeech: 'transitive verb',
      examples: [
        'He sold out his friends for a promotion.',
        'She wouldn\'t sell her principles for any amount of money.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Betrayal',
          description: 'Compromising loyalty or principles for advantage',
          examples: [
            'The informant sold information to rival companies.',
            'Some believe the artist sold out by changing their style for commercial success.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'fall',
  base: 'fall',
  past: 'fell',
  participle: 'fallen',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fɔl',
  pronunciationTextUK: 'fɔːl',
  meanings: [
    VerbMeaning(
      definition: 'To move downward, typically rapidly and freely without control, from a higher to a lower level',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The apple fell from the tree.',
        'She fell down the stairs and broke her arm.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical descent',
          description: 'Moving downward due to gravity',
          examples: [
            'The book fell off the shelf during the earthquake.',
            'Snow fell heavily throughout the night.',
          ],
        ),
        ContextualUsage(
          context: 'Accident',
          description: 'Losing balance and dropping down',
          examples: [
            'The child fell while learning to ride a bicycle.',
            'Elderly people often worry about falling on icy sidewalks.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To decline or decrease in value, number, rate, or intensity',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Temperatures fell below freezing last night.',
        'The company\'s profits have fallen in recent years.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Reduction',
          description: 'Decreasing in value or amount',
          examples: [
            'Housing prices fell sharply during the recession.',
            'His popularity fell after the scandal.',
          ],
        ),
        ContextualUsage(
          context: 'Decline',
          description: 'Diminishing in power or status',
          examples: [
            'The ancient empire fell after centuries of dominance.',
            'Their market share has fallen due to new competition.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be captured or defeated',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The city fell to enemy forces after a long siege.',
        'The government fell following a vote of no confidence.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Conquest',
          description: 'Being overtaken or defeated militarily',
          examples: [
            'The fortress fell after a three-month battle.',
            'Rome fell to barbarian invaders in the 5th century.',
          ],
        ),
        ContextualUsage(
          context: 'Political defeat',
          description: 'Losing power or position',
          examples: [
            'The dictator fell after decades in power.',
            'Their political party fell from power in the last election.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To occur at a specific time or in a specific way',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Her birthday falls on a Sunday this year.',
        'The responsibility falls on the project manager.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Timing',
          description: 'Occurring at a particular time',
          examples: [
            'The deadline falls at the end of the month.',
            'The holiday fell during our vacation period.',
          ],
        ),
        ContextualUsage(
          context: 'Categorization',
          description: 'Being classified or included in a category',
          examples: [
            'This example falls under the exception to the rule.',
            'The task falls within your area of responsibility.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'set',
  base: 'set',
  past: 'set',
  participle: 'set',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sɛt',
  pronunciationTextUK: 'set',
  meanings: [
    VerbMeaning(
      definition: 'To put or place in a specified position',
      partOfSpeech: 'transitive verb',
      examples: [
        'She set the book on the table.',
        'He set the ladder against the wall.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Placement',
          description: 'Putting objects in specific locations',
          examples: [
            'The waiter set a glass of water before each guest.',
            'She set the vase in the center of the table.',
          ],
        ),
        ContextualUsage(
          context: 'Arrangement',
          description: 'Organizing or positioning items',
          examples: [
            'They set chairs in rows for the audience.',
            'He set the pieces on the chessboard.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To establish or prescribe as a rule or example',
      partOfSpeech: 'transitive verb',
      examples: [
        'The judge set a legal precedent with her ruling.',
        'The company sets high standards for quality control.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Standards',
          description: 'Establishing levels of performance or behavior',
          examples: [
            'The teacher set clear expectations for the assignment.',
            'The new record set a benchmark for future athletes.',
          ],
        ),
        ContextualUsage(
          context: 'Regulation',
          description: 'Creating rules or guidelines',
          examples: [
            'The government set restrictions on imports.',
            'They set policies to ensure workplace safety.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To adjust or fix at a specific level or state',
      partOfSpeech: 'transitive verb',
      examples: [
        'Please set your phone to silent mode during the meeting.',
        'She set the alarm for 6:30 AM.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Configuration',
          description: 'Adjusting settings or parameters',
          examples: [
            'Set the thermostat to 70 degrees.',
            'You need to set the correct date and time on your device.',
          ],
        ),
        ContextualUsage(
          context: 'Preparation',
          description: 'Getting something ready for use',
          examples: [
            'She set the table for dinner.',
            'The stage was set for the evening performance.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move below the horizon',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The sun sets earlier during winter months.',
        'We watched as the moon set behind the mountains.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Celestial movement',
          description: 'The disappearance of heavenly bodies below the horizon',
          examples: [
            'The sun set in a blaze of orange and red.',
            'In arctic regions, the sun doesn\'t set for several months in summer.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'drive',
  base: 'drive',
  past: 'drove',
  participle: 'driven',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'draɪv',
  pronunciationTextUK: 'draɪv',
  meanings: [
    VerbMeaning(
      definition: 'To operate and control a motor vehicle',
      partOfSpeech: 'transitive verb',
      examples: [
        'She drives a hybrid car.',
        'He drove the truck across the country.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Transportation',
          description: 'Operating vehicles for travel',
          examples: [
            'I drive to work every day.',
            'She\'s learning to drive at the moment.',
          ],
        ),
        ContextualUsage(
          context: 'Vehicle control',
          description: 'Maneuvering or steering vehicles',
          examples: [
            'Be careful driving in bad weather.',
            'He drives a delivery van for a living.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To force or compel to move in a particular direction',
      partOfSpeech: 'transitive verb',
      examples: [
        'The wind drove the rain against the windows.',
        'The shepherd drove the sheep into the pen.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Causing something to move in a direction',
          examples: [
            'The storm drove the ship toward the rocks.',
            'He drove the nail into the wall with a hammer.',
          ],
        ),
        ContextualUsage(
          context: 'Herding',
          description: 'Directing animals to move together',
          examples: [
            'Cowboys drove the cattle across the plains.',
            'They drove the ducks back to the pond.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To motivate or cause a particular action or state',
      partOfSpeech: 'transitive verb',
      examples: [
        'Curiosity drove her to investigate further.',
        'What drives you to succeed?',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Motivation',
          description: 'Providing incentive or impetus',
          examples: [
            'Fear drove them to flee the country.',
            'His ambition drives him to work sixteen hours a day.',
          ],
        ),
        ContextualUsage(
          context: 'Causation',
          description: 'Being the force behind changes',
          examples: [
            'Competition drives innovation in the industry.',
            'High costs drove the company out of business.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To operate machinery or equipment',
      partOfSpeech: 'transitive verb',
      examples: [
        'Steam drives the old factory\'s machines.',
        'A powerful motor drives the conveyor belt.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Power',
          description: 'Providing energy to operate mechanisms',
          examples: [
            'Solar panels drive the irrigation system.',
            'A small engine drives the generator.',
          ],
        ),
        ContextualUsage(
          context: 'Technology',
          description: 'Powering computer systems or processes',
          examples: [
            'The new software drives the company\'s analytics.',
            'These processors drive the most advanced AI systems.',
          ],
        ),
      ],
    ),
  ],
),VerbModel(
  id: 'rise',
  base: 'rise',
  past: 'rose',
  participle: 'risen',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'raɪz',
  pronunciationTextUK: 'raɪz',
  meanings: [
    VerbMeaning(
      definition: 'To move upward from a lower position to a higher one',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The sun rises in the east.',
        'Hot air rises because it\'s less dense than cold air.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical movement',
          description: 'Moving from lower to higher position',
          examples: [
            'The balloon rose steadily into the sky.',
            'Smoke rose from the chimney into the clear winter air.',
          ],
        ),
        ContextualUsage(
          context: 'Celestial objects',
          description: 'Appearing above the horizon',
          examples: [
            'The moon rises later each night this week.',
            'We watched as Venus rose in the early morning sky.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To increase in amount, level, or degree',
      partOfSpeech: 'intransitive verb',
      examples: [
        'House prices continue to rise in the city center.',
        'Her temperature rose during the night.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Increase',
          description: 'Growing in number, value, or volume',
          examples: [
            'Oil prices have risen sharply this month.',
            'The river rose several feet after the heavy rain.',
          ],
        ),
        ContextualUsage(
          context: 'Elevation',
          description: 'Increasing in height or level',
          examples: [
            'The water in the bath continued to rise.',
            'The dough will rise as it ferments.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To get up from a lying, sitting, or kneeling position',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She rose from her chair to greet the visitors.',
        'He rises early every morning to exercise.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Standing up',
          description: 'Moving from seated to standing position',
          examples: [
            'The audience rose for the national anthem.',
            'He rose from the table and left without a word.',
          ],
        ),
        ContextualUsage(
          context: 'Waking',
          description: 'Getting out of bed',
          examples: [
            'She rises at dawn to prepare for the day.',
            'They rose with the sun during their camping trip.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reach a higher position in status or importance',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He rose through the ranks to become CEO.',
        'Her career has risen steadily over the past decade.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Advancement',
          description: 'Progressing in career or status',
          examples: [
            'She rose from intern to department manager in just three years.',
            'The politician rose to prominence during the economic crisis.',
          ],
        ),
        ContextualUsage(
          context: 'Power',
          description: 'Gaining influence or control',
          examples: [
            'New economic powers are rising in Asia.',
            'The dynasty rose to power in the 14th century.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'lead',
  base: 'lead',
  past: 'led',
  participle: 'led',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'lid',
  pronunciationTextUK: 'liːd',
  meanings: [
    VerbMeaning(
      definition: 'To guide or direct someone or something along a way by going in front',
      partOfSpeech: 'transitive verb',
      examples: [
        'The guide led us through the forest.',
        'She led her team to victory in the championship.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Direction',
          description: 'Showing the way by going ahead',
          examples: [
            'The captain led the expedition to the North Pole.',
            'He led his horse by the reins across the stream.',
          ],
        ),
        ContextualUsage(
          context: 'Management',
          description: 'Directing people as a leader',
          examples: [
            'She led the department through a difficult restructuring period.',
            'The conductor led the orchestra with great passion.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be in charge or command of',
      partOfSpeech: 'transitive verb',
      examples: [
        'He leads a team of thirty researchers.',
        'General Smith led the army during the conflict.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Leadership',
          description: 'Being in a position of authority',
          examples: [
            'She leads one of the country\'s largest corporations.',
            'He led the political party for over a decade.',
          ],
        ),
        ContextualUsage(
          context: 'Responsibility',
          description: 'Taking charge of projects or initiatives',
          examples: [
            'Who will lead the new marketing campaign?',
            'She was chosen to lead the international relief effort.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause or result in',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Poor diet can lead to health problems.',
        'Her research led to an important discovery.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Causation',
          description: 'Creating a particular outcome or result',
          examples: [
            'These policies could lead to higher unemployment.',
            'Misunderstandings often lead to conflicts.',
          ],
        ),
        ContextualUsage(
          context: 'Progression',
          description: 'Moving from one situation to another',
          examples: [
            'One question led to another during the interview.',
            'Their conversation eventually led to a business partnership.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be in front or ahead of others',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Our team is leading by ten points.',
        'She\'s leading in the polls ahead of the election.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Competition',
          description: 'Being ahead in a contest or race',
          examples: [
            'The runner led for most of the marathon.',
            'Their company is leading in market share.',
          ],
        ),
        ContextualUsage(
          context: 'Ranking',
          description: 'Being first in a measured category',
          examples: [
            'This university leads in scientific research funding.',
            'He leads the league in assists this season.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'draw',
  base: 'draw',
  past: 'drew',
  participle: 'drawn',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'drɔ',
  pronunciationTextUK: 'drɔː',
  meanings: [
    VerbMeaning(
      definition: 'To produce a picture or diagram by making lines on a surface',
      partOfSpeech: 'transitive verb',
      examples: [
        'The child drew a picture of her family.',
        'He drew a map to show me the way.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Art',
          description: 'Creating visual representations using lines',
          examples: [
            'She drew a beautiful landscape in charcoal.',
            'The architect drew detailed plans for the building.',
          ],
        ),
        ContextualUsage(
          context: 'Sketching',
          description: 'Creating quick or informal drawings',
          examples: [
            'He drew a rough sketch of his idea on a napkin.',
            'The police artist drew a composite based on the witness description.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pull or move something in a specified direction',
      partOfSpeech: 'transitive verb',
      examples: [
        'She drew the curtains to let in more light.',
        'He drew his chair closer to the fire.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Pulling objects toward oneself or in a direction',
          examples: [
            'The magnet drew the iron filings toward it.',
            'He drew the sword from its sheath.',
          ],
        ),
        ContextualUsage(
          context: 'Extraction',
          description: 'Taking out or pulling from a source',
          examples: [
            'She drew water from the well.',
            'The dentist drew the infected tooth.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To attract or cause to move in a particular direction',
      partOfSpeech: 'transitive verb',
      examples: [
        'The festival draws thousands of tourists each year.',
        'His speech drew a large crowd.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Attraction',
          description: 'Creating interest that brings people or things',
          examples: [
            'The museum exhibition drew record numbers of visitors.',
            'Low prices drew customers to the store.',
          ],
        ),
        ContextualUsage(
          context: 'Attention',
          description: 'Causing focus or notice',
          examples: [
            'Her unusual behavior drew attention from everyone in the room.',
            'The scandal drew unwanted publicity to the company.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reach a conclusion or make a deduction',
      partOfSpeech: 'transitive verb',
      examples: [
        'I drew my own conclusions from the evidence.',
        'What inferences can we draw from these results?',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Inference',
          description: 'Making logical connections or deductions',
          examples: [
            'The detective drew a connection between the two cases.',
            'It\'s difficult to draw meaningful conclusions from such limited data.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'fly',
  base: 'fly',
  past: 'flew',
  participle: 'flown',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'flaɪ',
  pronunciationTextUK: 'flaɪ',
  meanings: [
    VerbMeaning(
      definition: 'To move through the air using wings',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Birds fly by flapping their wings.',
        'The butterfly flew from flower to flower.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Animal movement',
          description: 'Natural aerial locomotion',
          examples: [
            'Eagles can fly at very high altitudes.',
            'Bats fly at night using echolocation.',
          ],
        ),
        ContextualUsage(
          context: 'Insects',
          description: 'Wing-powered flight of small creatures',
          examples: [
            'Bees fly between flowers collecting pollen.',
            'Dragonflies can fly backward and hover in place.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To travel through the air in an aircraft',
      partOfSpeech: 'intransitive verb',
      examples: [
        'We flew to Paris for our anniversary.',
        'The pilot flew through the storm with great skill.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Air travel',
          description: 'Moving by airplane or helicopter',
          examples: [
            'They flew from New York to Tokyo in twelve hours.',
            'He flies regularly for business meetings.',
          ],
        ),
        ContextualUsage(
          context: 'Aviation',
          description: 'Operating aircraft',
          examples: [
            'She\'s learning to fly a small plane.',
            'The test pilot flew the experimental aircraft.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or be sent through the air',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The ball flew over the fence.',
        'Papers flew everywhere when the window opened.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Motion',
          description: 'Moving rapidly through air',
          examples: [
            'Sparks flew from the grinding wheel.',
            'The flag flew proudly in the breeze.',
          ],
        ),
        ContextualUsage(
          context: 'Projectiles',
          description: 'Objects moving through air with force',
          examples: [
            'Bullets flew overhead during the battle.',
            'The frisbee flew across the park.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pass quickly or suddenly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Time flies when you\'re having fun.',
        'The rumor flew through the office.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Time',
          description: 'Passing rapidly or seemingly faster than normal',
          examples: [
            'The years have flown by since graduation.',
            'The vacation flew by too quickly.',
          ],
        ),
        ContextualUsage(
          context: 'Communication',
          description: 'Rapid spread of information',
          examples: [
            'News of their engagement flew around town.',
            'Information flies across the internet instantly.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'forget',
  base: 'forget',
  past: 'forgot',
  participle: 'forgotten',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fərˈgɛt',
  pronunciationTextUK: 'fəˈget',
  meanings: [
    VerbMeaning(
      definition: 'To be unable to remember or recall information, facts, or experiences',
      partOfSpeech: 'transitive verb',
      examples: [
        'I forgot her phone number.',
        'He often forgets where he puts his keys.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Memory failure',
          description: 'Inability to recall specific information',
          examples: [
            'She forgot the answer during the exam.',
            'I completely forgot the directions to your house.',
          ],
        ),
        ContextualUsage(
          context: 'Names',
          description: 'Being unable to recall people\'s names',
          examples: [
            'I\'m terrible with names—I always forget them right after being introduced.',
            'He forgot his new colleague\'s name three times during the meeting.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To fail to remember to do something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She forgot to lock the door when she left.',
        'Don\'t forget to call your mother on her birthday.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Omission',
          description: 'Unintentionally not doing something',
          examples: [
            'He forgot to pay the electricity bill last month.',
            'I forgot to mention that the meeting was rescheduled.',
          ],
        ),
        ContextualUsage(
          context: 'Tasks',
          description: 'Not remembering planned activities',
          examples: [
            'She forgot to pick up the dry cleaning on her way home.',
            'They forgot to make a reservation at the restaurant.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To put out of mind; cease to think of or consider',
      partOfSpeech: 'transitive verb',
      examples: [
        'Try to forget the incident and move on.',
        'I\'ll never forget what you did for me.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Letting go',
          description: 'Intentionally dismissing from thought',
          examples: [
            'He tried to forget his embarrassing mistake.',
            'Just forget what I said earlier—it wasn\'t important.',
          ],
        ),
        ContextualUsage(
          context: 'Memories',
          description: 'Inability to dismiss significant experiences',
          examples: [
            'She couldn\'t forget the trauma she experienced.',
            'You never forget your first love.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To inadvertently leave behind or in a place',
      partOfSpeech: 'transitive verb',
      examples: [
        'I forgot my umbrella on the bus.',
        'She forgot her glasses at the restaurant.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Items',
          description: 'Accidentally leaving belongings somewhere',
          examples: [
            'He forgot his wallet at home and couldn\'t pay for lunch.',
            'I forgot my laptop at the office and had to go back for it.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'choose',
  base: 'choose',
  past: 'chose',
  participle: 'chosen',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'tʃuz',
  pronunciationTextUK: 'tʃuːz',
  meanings: [
    VerbMeaning(
      definition: 'To select from a number of possibilities; pick by preference',
      partOfSpeech: 'transitive verb',
      examples: [
        'She chose the red dress for the party.',
        'We chose a hotel close to the beach.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Selection',
          description: 'Deciding between alternatives',
          examples: [
            'He carefully chose his words during the difficult conversation.',
            'They chose the most economical option for their vacation.',
          ],
        ),
        ContextualUsage(
          context: 'Preference',
          description: 'Selecting based on personal taste',
          examples: [
            'I would choose chocolate over vanilla any day.',
            'She chose comfort over style when buying shoes.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To decide on a course of action',
      partOfSpeech: 'transitive verb',
      examples: [
        'She chose to ignore his rude comments.',
        'We chose to drive rather than fly.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Decision',
          description: 'Making a deliberate choice about actions',
          examples: [
            'He chose to resign rather than accept the transfer.',
            'They chose to adopt a child after years of trying to conceive.',
          ],
        ),
        ContextualUsage(
          context: 'Path',
          description: 'Selecting a direction or approach',
          examples: [
            'She chose to pursue art instead of medicine.',
            'Many graduates choose to continue their education.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To select someone for a role, position, or responsibility',
      partOfSpeech: 'transitive verb',
      examples: [
        'The committee chose her as chairperson.',
        'He was chosen to represent his country in the competition.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Appointment',
          description: 'Selecting someone for a position',
          examples: [
            'The board chose a new CEO from within the company.',
            'She was chosen from hundreds of applicants for the scholarship.',
          ],
        ),
        ContextualUsage(
          context: 'Delegation',
          description: 'Selecting someone for a task',
          examples: [
            'The teacher chose three students to help with the project.',
            'He was chosen to deliver the keynote address at the conference.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To desire or want',
      partOfSpeech: 'transitive verb',
      examples: [
        'If I could choose, I would live by the ocean.',
        'Given the choice, most people would choose health over wealth.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Desire',
          description: 'Expressing preferences about hypothetical situations',
          examples: [
            'If I could choose any superpower, I would choose invisibility.',
            'She would choose to live in a different era if possible.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'swim',
  base: 'swim',
  past: 'swam',
  participle: 'swum',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'swɪm',
  pronunciationTextUK: 'swɪm',
  meanings: [
    VerbMeaning(
      definition: 'To propel oneself through water using the limbs, fins, or tail',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The children swam in the lake all afternoon.',
        'Fish swim by moving their tails from side to side.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Recreation',
          description: 'Swimming for pleasure or exercise',
          examples: [
            'We swam at the beach during our vacation.',
            'She swims laps every morning before work.',
          ],
        ),
        ContextualUsage(
          context: 'Aquatic movement',
          description: 'Natural locomotion in water',
          examples: [
            'Dolphins swim with incredible speed and grace.',
            'The ducks swam across the pond looking for food.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cross or travel through water by swimming',
      partOfSpeech: 'transitive verb',
      examples: [
        'She swam the English Channel in record time.',
        'The athlete swam the length of the pool in under 25 seconds.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Achievement',
          description: 'Completing specific swimming challenges',
          examples: [
            'He swam the strait between the two islands.',
            'Very few people have swum that dangerous river crossing.',
          ],
        ),
        ContextualUsage(
          context: 'Sport',
          description: 'Competitive swimming',
          examples: [
            'She swam the 100-meter freestyle in under a minute.',
            'He swam butterfly stroke in the Olympic trials.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be filled or flooded with liquid',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Her eyes swam with tears.',
        'The fields swam with floodwater after the heavy rain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Abundance',
          description: 'Being covered or suffused with liquid',
          examples: [
            'The basement swam with water from the burst pipe.',
            'The rice paddies swam with irrigation water.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To appear to move or float before one\'s eyes',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The room swam before her eyes as she felt faint.',
        'The words on the page swam together when he tried to read without his glasses.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Dizziness',
          description: 'Visual disturbance during disorientation',
          examples: [
            'The landscape swam around her after she stood up too quickly.',
            'Everything swam before his eyes just before he fainted.',
          ],
        ),
        ContextualUsage(
          context: 'Visual distortion',
          description: 'Unclear or unstable visual perception',
          examples: [
            'The numbers swam on the page as she grew tired.',
            'His vision swam due to the high fever.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'wear',
  base: 'wear',
  past: 'wore',
  participle: 'worn',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'wɛr',
  pronunciationTextUK: 'weə',
  meanings: [
    VerbMeaning(
      definition: 'To have on one\'s body as clothing, decoration, or protection',
      partOfSpeech: 'transitive verb',
      examples: [
        'She wore a red dress to the party.',
        'He always wears a hat when it\'s sunny.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Clothing',
          description: 'Having garments on the body',
          examples: [
            'The bride wore a beautiful white gown.',
            'Soldiers wear uniforms while on duty.',
          ],
        ),
        ContextualUsage(
          context: 'Accessories',
          description: 'Having decorative or functional items on the body',
          examples: [
            'She wears her grandmother\'s pearl necklace on special occasions.',
            'He wears glasses for reading and driving.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To show or exhibit an appearance, expression, or characteristic',
      partOfSpeech: 'transitive verb',
      examples: [
        'He wore a worried expression throughout the meeting.',
        'She wears her success lightly.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Expression',
          description: 'Displaying facial or emotional states',
          examples: [
            'The child wore a huge smile after receiving the gift.',
            'The candidate wore a look of determination during the debate.',
          ],
        ),
        ContextualUsage(
          context: 'Demeanor',
          description: 'Exhibiting particular attitudes or characteristics',
          examples: [
            'He wears his authority with dignity.',
            'She wears her knowledge without arrogance.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deteriorate or diminish through use or exposure',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The carpet has worn thin in places.',
        'The letters on the keyboard have worn off.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Erosion',
          description: 'Physical deterioration through friction or use',
          examples: [
            'The stone steps have worn smooth over centuries of use.',
            'The tires wore down quickly on the rough roads.',
          ],
        ),
        ContextualUsage(
          context: 'Durability',
          description: 'How materials stand up to continued use',
          examples: [
            'This fabric wears well even after many washings.',
            'Leather shoes wear better than synthetic ones in wet conditions.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To endure or persist over time',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Their friendship has worn well over the years.',
        'Some jokes don\'t wear well with repeated telling.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Endurance',
          description: 'Lasting quality or impact',
          examples: [
            'The novel\'s theme wears well despite changing social attitudes.',
            'His enthusiasm wore thin after months of setbacks.',
          ],
        ),
        ContextualUsage(
          context: 'Time',
          description: 'How something is affected by the passage of time',
          examples: [
            'Their arguments wore on throughout the night.',
            'The day wore away as they waited for news.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sing',
  base: 'sing',
  past: 'sang',
  participle: 'sung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sɪŋ',
  pronunciationTextUK: 'sɪŋ',
  meanings: [
    VerbMeaning(
      definition: 'To produce musical sounds with the voice',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She sings in the church choir.',
        'The birds sing at dawn.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Music',
          description: 'Producing vocal music by humans',
          examples: [
            'He sings in the shower every morning.',
            'They sang around the campfire in the evening.',
          ],
        ),
        ContextualUsage(
          context: 'Nature',
          description: 'Animal vocalizations, especially birds',
          examples: [
            'The nightingales sing most beautifully in spring.',
            'Whales sing complex songs that can travel for miles underwater.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To perform a song or piece of music vocally',
      partOfSpeech: 'transitive verb',
      examples: [
        'The choir sang a hymn for the special occasion.',
        'She sang her new hit song at the concert.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Performance',
          description: 'Performing specific musical compositions',
          examples: [
            'The soloist sang an aria from La Traviata.',
            'They sang the national anthem before the game.',
          ],
        ),
        ContextualUsage(
          context: 'Expression',
          description: 'Using song to convey emotions or stories',
          examples: [
            'The folk singer sang tales of old traditions.',
            'She sang lullabies to her baby each night.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make a high-pitched whistling or buzzing sound',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The kettle is singing on the stove.',
        'The arrow sang as it flew through the air.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Objects',
          description: 'Sounds made by inanimate things',
          examples: [
            'The wind sang through the trees during the storm.',
            'The violin strings sang under the bow\'s pressure.',
          ],
        ),
        ContextualUsage(
          context: 'Movement',
          description: 'Sounds caused by rapid motion',
          examples: [
            'The bullet sang past his head.',
            'The ropes sang as they tensioned in the strong wind.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To tell on someone; inform to authorities (slang)',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The suspect sang when the police offered him a deal.',
        'They were afraid he would sing if caught.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Confession',
          description: 'Revealing information to authorities',
          examples: [
            'The captured criminal sang like a canary about the entire operation.',
            'His former partner sang to the investigators about their illegal scheme.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'seek',
  base: 'seek',
  past: 'sought',
  participle: 'sought',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sik',
  pronunciationTextUK: 'siːk',
  meanings: [
    VerbMeaning(
      definition: 'To attempt to find or obtain',
      partOfSpeech: 'transitive verb',
      examples: [
        'She is seeking a new job.',
        'They sought shelter from the storm.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Search',
          description: 'Looking for something needed or wanted',
          examples: [
            'He\'s seeking funding for his new business venture.',
            'They sought information about their family history.',
          ],
        ),
        ContextualUsage(
          context: 'Pursuit',
          description: 'Actively trying to obtain something',
          examples: [
            'Many immigrants seek a better life in other countries.',
            'The company is seeking qualified applicants for the position.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To try to reach or arrive at a place',
      partOfSpeech: 'transitive verb',
      examples: [
        'Animals seek water in times of drought.',
        'We sought the summit before nightfall.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Destination',
          description: 'Moving toward a specific location',
          examples: [
            'They sought the nearest hospital after the accident.',
            'Pilgrims seek sacred sites for religious purposes.',
          ],
        ),
        ContextualUsage(
          context: 'Refuge',
          description: 'Looking for safety or protection',
          examples: [
            'The refugees sought asylum in neighboring countries.',
            'During the thunderstorm, the hikers sought shelter in a cave.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To ask for or request assistance, advice, or support',
      partOfSpeech: 'transitive verb',
      examples: [
        'He sought advice from a financial expert.',
        'They sought legal counsel before proceeding.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Consultation',
          description: 'Requesting professional guidance',
          examples: [
            'She sought medical help for her persistent symptoms.',
            'The company sought expert opinion on the environmental impact.',
          ],
        ),
        ContextualUsage(
          context: 'Assistance',
          description: 'Asking for help in difficult situations',
          examples: [
            'They sought support from the community after losing their home.',
            'He sought his friend\'s help with the difficult project.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To strive or aim for a goal or result',
      partOfSpeech: 'transitive verb',
      examples: [
        'The organization seeks to eliminate poverty in the region.',
        'He seeks only to understand the truth.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ambition',
          description: 'Working toward specific objectives',
          examples: [
            'Scientists seek breakthroughs in cancer treatment.',
            'The negotiators sought a peaceful resolution to the conflict.',
          ],
        ),
        ContextualUsage(
          context: 'Purpose',
          description: 'Having specific aims or intentions',
          examples: [
            'She seeks to improve education in underprivileged areas.',
            'The policy seeks to balance economic growth with environmental protection.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'wake',
  base: 'wake',
  past: 'woke',
  participle: 'woken',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'weɪk',
  pronunciationTextUK: 'weɪk',
  meanings: [
    VerbMeaning(
      definition: 'To stop sleeping and become conscious',
      partOfSpeech: 'intransitive verb',
      examples: [
        'I woke at six o\'clock this morning.',
        'She often wakes during the night.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sleep cycle',
          description: 'Emerging from sleep naturally',
          examples: [
            'He wakes with the sunrise every morning.',
            'I woke feeling refreshed after a good night\'s sleep.',
          ],
        ),
        ContextualUsage(
          context: 'Interruption',
          description: 'Becoming conscious due to disturbance',
          examples: [
            'She woke when she heard the baby crying.',
            'I woke to the sound of thunder during the storm.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause someone to stop sleeping',
      partOfSpeech: 'transitive verb',
      examples: [
        'Please wake me at seven tomorrow.',
        'The noise woke the neighbors.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Intentional',
          description: 'Deliberately rousing someone from sleep',
          examples: [
            'The mother woke her children for school.',
            'The alarm clock woke him every weekday at 6:30 AM.',
          ],
        ),
        ContextualUsage(
          context: 'Accidental',
          description: 'Unintentionally disturbing someone\'s sleep',
          examples: [
            'The dog barking woke the entire household.',
            'Sorry I woke you when I came in late.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become active or alert after a period of inactivity',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The town wakes to life during the summer tourist season.',
        'The volcano had been dormant for centuries before it woke.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Activation',
          description: 'Becoming active after dormancy',
          examples: [
            'The garden wakes in spring with new growth.',
            'The old feelings woke within her when she saw him again.',
          ],
        ),
        ContextualUsage(
          context: 'Awareness',
          description: 'Becoming conscious of something',
          examples: [
            'The public is slowly waking to the environmental crisis.',
            'He finally woke to the reality of his situation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To hold a vigil over a dead body before burial',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The family woke all night with their deceased grandfather.',
        'It\'s traditional in some cultures to wake with the body before the funeral.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Cultural practice',
          description: 'Maintaining traditional death rituals',
          examples: [
            'They woke for three days according to their traditions.',
            'Friends and neighbors came to wake with the grieving family.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'hurt',
  base: 'hurt',
  past: 'hurt',
  participle: 'hurt',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'hɜrt',
  pronunciationTextUK: 'hɜːt',
  meanings: [
    VerbMeaning(
      definition: 'To cause physical pain or injury',
      partOfSpeech: 'transitive verb',
      examples: [
        'She hurt her ankle while running.',
        'Be careful not to hurt yourself with that knife.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Injury',
          description: 'Causing physical damage or harm',
          examples: [
            'He hurt his back lifting heavy furniture.',
            'The fall hurt several passengers on the bus.',
          ],
        ),
        ContextualUsage(
          context: 'Pain',
          description: 'Creating physical discomfort',
          examples: [
            'These new shoes are hurting my feet.',
            'The bright light hurts my eyes.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause emotional pain or distress',
      partOfSpeech: 'transitive verb',
      examples: [
        'His critical remarks hurt her feelings.',
        'It hurts me to see you so unhappy.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional pain',
          description: 'Causing sadness, grief, or mental suffering',
          examples: [
            'The betrayal hurt him deeply.',
            'Her rejection hurt his pride.',
          ],
        ),
        ContextualUsage(
          context: 'Relationships',
          description: 'Damaging interpersonal connections',
          examples: [
            'Your lies have hurt our friendship.',
            'She never meant to hurt anyone with her decision to leave.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To experience physical pain',
      partOfSpeech: 'intransitive verb',
      examples: [
        'My throat hurts when I swallow.',
        'His leg still hurts from the old football injury.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sensation',
          description: 'Feeling physical discomfort or pain',
          examples: [
            'My head hurts after staring at the computer all day.',
            'The wound hurts less today than yesterday.',
          ],
        ),
        ContextualUsage(
          context: 'Healing',
          description: 'Pain during recovery process',
          examples: [
            'The stitches will hurt for a few days after surgery.',
            'His muscles hurt from the intense workout.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To impair or damage; to have a detrimental effect',
      partOfSpeech: 'transitive verb',
      examples: [
        'The scandal hurt the politician\'s reputation.',
        'Higher taxes will hurt small businesses.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Damage',
          description: 'Causing negative impact on abstract things',
          examples: [
            'The negative reviews hurt the film\'s box office performance.',
            'The late frost hurt this year\'s apple crop.',
          ],
        ),
        ContextualUsage(
          context: 'Economic impact',
          description: 'Creating financial or market disadvantage',
          examples: [
            'Rising oil prices hurt the transportation industry.',
            'The trade war is hurting exports to key markets.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'lie',
  base: 'lie',
  past: 'lay',
  participle: 'lain',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'laɪ',
  pronunciationTextUK: 'laɪ',
  meanings: [
    VerbMeaning(
      definition: 'To be in or assume a horizontal position on a surface',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She lay on the beach, enjoying the sun.',
        'The book lies on the table where I left it.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Position',
          description: 'Being in a horizontal position',
          examples: [
            'He lies in bed reading every night before sleep.',
            'The cat lay by the fire all afternoon.',
          ],
        ),
        ContextualUsage(
          context: 'Rest',
          description: 'Reclining for relaxation or sleep',
          examples: [
            'She lay down for a quick nap.',
            'The patient has been lying in the hospital for two weeks.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be located or situated',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The village lies at the foot of the mountain.',
        'Their property lies on the border between two counties.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Location',
          description: 'Being positioned in a particular place',
          examples: [
            'The solution lies in a compromise between the two positions.',
            'The island lies 200 miles off the coast.',
          ],
        ),
        ContextualUsage(
          context: 'Direction',
          description: 'Being in a specific direction',
          examples: [
            'The trail lies to the east of the camp.',
            'Your future lies ahead of you.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To exist or be found in a particular state or condition',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The problem lies in our approach to the issue.',
        'The document lay forgotten in a drawer for years.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'State',
          description: 'Existing in a particular condition',
          examples: [
            'The field lay abandoned for decades.',
            'Their hopes lay shattered after the defeat.',
          ],
        ),
        ContextualUsage(
          context: 'Potential',
          description: 'Having possibilities or capabilities',
          examples: [
            'Her strength lies in her analytical abilities.',
            'The danger lies in acting too quickly without sufficient information.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To remain in a specified state',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The matter can lie until our next meeting.',
        'Let the issue lie; there\'s nothing we can do about it now.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Inaction',
          description: 'Staying without change or activity',
          examples: [
            'The project has lain dormant for months.',
            'The case lay unresolved for years.',
          ],
        ),
        ContextualUsage(
          context: 'Delay',
          description: 'Being postponed or deferred',
          examples: [
            'The decision will lie with the committee when they meet next month.',
            'Let the question lie until we have more information.',
          ],
        ),
      ],
    ),
  ],
),VerbModel(
  id: 'throw',
  base: 'throw',
  past: 'threw',
  participle: 'thrown',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'θroʊ',
  pronunciationTextUK: 'θrəʊ',
  meanings: [
    VerbMeaning(
      definition: 'To propel something through the air with force using the hand',
      partOfSpeech: 'transitive verb',
      examples: [
        'She threw the ball to her teammate.',
        'He threw his jacket over the back of the chair.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Projection',
          description: 'Launching objects through space',
          examples: [
            'The pitcher threw a perfect strike.',
            'She threw her keys across the room to her roommate.',
          ],
        ),
        ContextualUsage(
          context: 'Sports',
          description: 'Propelling objects in athletic activities',
          examples: [
            'The quarterback threw a 50-yard pass.',
            'She threw the javelin farther than any other competitor.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or position with quick or sudden movements',
      partOfSpeech: 'transitive verb',
      examples: [
        'He threw his arms around her in a hug.',
        'She threw herself onto the sofa, exhausted.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Body movement',
          description: 'Rapid positioning of body or limbs',
          examples: [
            'He threw his head back and laughed.',
            'She threw her hands up in frustration.',
          ],
        ),
        ContextualUsage(
          context: 'Positioning',
          description: 'Quick placement of objects',
          examples: [
            'He threw a blanket over the sleeping child.',
            'She threw her clothes into the suitcase hurriedly.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To hold or organize an event, especially a party or celebration',
      partOfSpeech: 'transitive verb',
      examples: [
        'They threw a surprise party for his 50th birthday.',
        'The company throws an annual holiday dinner for all employees.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Hosting',
          description: 'Organizing social gatherings',
          examples: [
            'They throw the best New Year\'s Eve parties.',
            'The university throws a reception for new faculty members.',
          ],
        ),
        ContextualUsage(
          context: 'Events',
          description: 'Creating or staging occasions',
          examples: [
            'The charity throws a fundraising gala every spring.',
            'They threw together a last-minute dinner for unexpected guests.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause confusion, surprise, or difficulty',
      partOfSpeech: 'transitive verb',
      examples: [
        'The unexpected question threw him completely.',
        'The power outage threw our plans into disarray.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Disruption',
          description: 'Causing disorder or interruption',
          examples: [
            'The late delivery threw the entire production schedule off.',
            'Her absence threw the team into confusion.',
          ],
        ),
        ContextualUsage(
          context: 'Challenge',
          description: 'Creating obstacles or difficulties',
          examples: [
            'The new regulations threw a wrench in our expansion plans.',
            'The storm threw doubt on whether the outdoor event could proceed.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'steal',
  base: 'steal',
  past: 'stole',
  participle: 'stolen',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'stil',
  pronunciationTextUK: 'stiːl',
  meanings: [
    VerbMeaning(
      definition: 'To take something from someone without permission or legal right',
      partOfSpeech: 'transitive verb',
      examples: [
        'Someone stole my wallet on the subway.',
        'The painting was stolen from the museum last night.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Theft',
          description: 'Taking property that belongs to others',
          examples: [
            'The thieves stole jewelry and cash from the house.',
            'Her identity was stolen, and fraudulent accounts were opened in her name.',
          ],
        ),
        ContextualUsage(
          context: 'Crime',
          description: 'Criminal taking of possessions',
          examples: [
            'He was arrested for stealing a car.',
            'Shoplifters steal millions of dollars of merchandise annually.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move quietly or secretly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She stole away from the party without saying goodbye.',
        'The cat stole silently through the grass toward the bird.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Stealth',
          description: 'Moving without being noticed',
          examples: [
            'He stole into the room while everyone was sleeping.',
            'The thief stole away in the darkness.',
          ],
        ),
        ContextualUsage(
          context: 'Furtiveness',
          description: 'Acting secretly or cautiously',
          examples: [
            'She stole a glance at him across the room.',
            'The children stole quietly downstairs on Christmas morning.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take or appropriate ideas, concepts, or works without acknowledgment',
      partOfSpeech: 'transitive verb',
      examples: [
        'The songwriter was accused of stealing the melody from an older song.',
        'He stole her idea and presented it as his own.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Plagiarism',
          description: 'Taking credit for others\' intellectual property',
          examples: [
            'The student stole passages from published works for his essay.',
            'The competing company stole our design concept.',
          ],
        ),
        ContextualUsage(
          context: 'Appropriation',
          description: 'Using others\' ideas without permission',
          examples: [
            'The artist was criticized for stealing indigenous cultural symbols.',
            'Politicians often steal talking points from each other\'s speeches.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To accomplish something in a game in a way that surprises the opponent',
      partOfSpeech: 'transitive verb',
      examples: [
        'The player stole second base while the pitcher wasn\'t looking.',
        'He stole the ball from the opposing team\'s forward.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sports',
          description: 'Strategic taking of advantage in games',
          examples: [
            'The basketball player stole the ball and scored a lay-up.',
            'She stole a point with a perfectly placed drop shot.',
          ],
        ),
        ContextualUsage(
          context: 'Competition',
          description: 'Gaining unexpected advantage',
          examples: [
            'The underdog stole the championship from the favored team.',
            'They stole the victory in the final seconds of the match.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'mean',
  base: 'mean',
  past: 'meant',
  participle: 'meant',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'min',
  pronunciationTextUK: 'miːn',
  meanings: [
    VerbMeaning(
      definition: 'To express or indicate a particular sense or intention',
      partOfSpeech: 'transitive verb',
      examples: [
        'What exactly do you mean by "soon"?',
        'The red light means you should stop.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Definition',
          description: 'Conveying specific significance',
          examples: [
            'The word "apathetic" means showing no interest or enthusiasm.',
            'What did she mean when she said she was "fine"?',
          ],
        ),
        ContextualUsage(
          context: 'Indication',
          description: 'Signaling or denoting something',
          examples: [
            'Dark clouds mean rain is likely.',
            'A flashing check engine light means you should have your car examined.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To intend to express or convey',
      partOfSpeech: 'transitive verb',
      examples: [
        'I didn\'t mean to offend you with my comment.',
        'She meant to call you, but she forgot.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Intention',
          description: 'Having a specific purpose in mind',
          examples: [
            'I meant to return your book sooner.',
            'He didn\'t mean any harm by his joke.',
          ],
        ),
        ContextualUsage(
          context: 'Clarification',
          description: 'Explaining actual intentions',
          examples: [
            'What I meant was that we should consider all options.',
            'She meant that as a compliment, not a criticism.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To have as a purpose or intention',
      partOfSpeech: 'transitive verb',
      examples: [
        'We mean to finish this project by Friday.',
        'She means to become a doctor someday.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Determination',
          description: 'Having firm intentions to accomplish something',
          examples: [
            'I mean business when I say this behavior must stop.',
            'They mean to succeed despite the obstacles.',
          ],
        ),
        ContextualUsage(
          context: 'Planning',
          description: 'Intending future actions',
          examples: [
            'We mean to visit Italy next summer.',
            'The company means to expand into Asian markets.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To signify, portend, or presage',
      partOfSpeech: 'transitive verb',
      examples: [
        'This discovery could mean a breakthrough in cancer treatment.',
        'Higher interest rates mean increased mortgage payments.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Significance',
          description: 'Indicating importance or consequences',
          examples: [
            'A rise in unemployment means hardship for many families.',
            'This contract means financial security for our company.',
          ],
        ),
        ContextualUsage(
          context: 'Implications',
          description: 'Suggesting logical outcomes',
          examples: [
            'Decreased sales mean we\'ll need to reduce our expenses.',
            'These test results mean you\'ll need further examination.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'catch',
  base: 'catch',
  past: 'caught',
  participle: 'caught',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kætʃ',
  pronunciationTextUK: 'kætʃ',
  meanings: [
    VerbMeaning(
      definition: 'To intercept and hold a moving object, especially with the hands',
      partOfSpeech: 'transitive verb',
      examples: [
        'He caught the ball with one hand.',
        'She caught the keys when I tossed them to her.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sports',
          description: 'Capturing balls or objects in games',
          examples: [
            'The outfielder caught the fly ball for the final out.',
            'She caught the frisbee between two fingers.',
          ],
        ),
        ContextualUsage(
          context: 'Reflexes',
          description: 'Grabbing falling or thrown items',
          examples: [
            'He caught the vase just before it hit the floor.',
            'The juggler caught six balls without dropping any.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To capture or trap someone or something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The police caught the thief as he was leaving the store.',
        'We caught several fish during our trip to the lake.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Apprehension',
          description: 'Capturing people who have done wrong',
          examples: [
            'Security cameras helped catch the shoplifter.',
            'They caught the escaped prisoner near the state border.',
          ],
        ),
        ContextualUsage(
          context: 'Hunting/Fishing',
          description: 'Capturing animals for food or sport',
          examples: [
            'The cat caught a mouse in the garden.',
            'They caught enough trout for dinner.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become infected with an illness or disease',
      partOfSpeech: 'transitive verb',
      examples: [
        'I caught a cold from my son.',
        'She caught the flu despite getting vaccinated.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Infection',
          description: 'Contracting communicable diseases',
          examples: [
            'Many students caught the stomach virus that was going around.',
            'He caught pneumonia after being out in the rain.',
          ],
        ),
        ContextualUsage(
          context: 'Contagion',
          description: 'Becoming sick through exposure',
          examples: [
            'You won\'t catch a cold just from being in cold weather.',
            'Several family members caught COVID-19 at the gathering.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To notice or discover, especially something wrong or secretive',
      partOfSpeech: 'transitive verb',
      examples: [
        'She caught him cheating on the exam.',
        'The teacher caught the mistake in my calculation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Detection',
          description: 'Discovering misconduct or errors',
          examples: [
            'The auditor caught several discrepancies in the financial records.',
            'They caught him stealing supplies from the office.',
          ],
        ),
        ContextualUsage(
          context: 'Perception',
          description: 'Noticing something subtle or quick',
          examples: [
            'I caught a glimpse of the celebrity as she entered the restaurant.',
            'Did you catch what she said about the project deadline?',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spend',
  base: 'spend',
  past: 'spent',
  participle: 'spent',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'spɛnd',
  pronunciationTextUK: 'spend',
  meanings: [
    VerbMeaning(
      definition: 'To pay out money in exchange for goods or services',
      partOfSpeech: 'transitive verb',
      examples: [
        'She spent \$200 on a new dress.',
        'We spent too much money on dinner last night.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Purchasing',
          description: 'Using money for buying things',
          examples: [
            'He spends thousands of dollars on rare books each year.',
            'The company spent millions developing the new product.',
          ],
        ),
        ContextualUsage(
          context: 'Financial decisions',
          description: 'Allocating monetary resources',
          examples: [
            'They spent their savings on a down payment for a house.',
            'The government spends tax dollars on infrastructure projects.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To use up, consume, or exhaust a resource',
      partOfSpeech: 'transitive verb',
      examples: [
        'He spent all his energy on the first half of the race.',
        'The company has spent its entire budget for the year.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Resources',
          description: 'Using available supplies or reserves',
          examples: [
            'The hikers had spent all their water by midday.',
            'She spent her political capital on a controversial bill.',
          ],
        ),
        ContextualUsage(
          context: 'Depletion',
          description: 'Exhausting limited quantities',
          examples: [
            'The battery spent its charge quickly in the cold weather.',
            'They spent all their ammunition in the first hour of battle.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pass or use time in a particular way',
      partOfSpeech: 'transitive verb',
      examples: [
        'We spent the weekend at the beach.',
        'She spends her free time reading books.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Duration',
          description: 'Occupying time with activities',
          examples: [
            'He spent three hours fixing the computer.',
            'They spent the evening discussing politics.',
          ],
        ),
        ContextualUsage(
          context: 'Life choices',
          description: 'Allocating personal time',
          examples: [
            'She spent her twenties traveling around the world.',
            'I don\'t want to spend my life doing something I hate.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To drain of energy or strength; to exhaust',
      partOfSpeech: 'transitive verb',
      examples: [
        'The long illness had spent his strength.',
        'The marathon completely spent the runners.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Fatigue',
          description: 'Causing exhaustion or depletion',
          examples: [
            'The heat spent their energy quickly during the hike.',
            'Years of hard labor had spent his physical capabilities.',
          ],
        ),
        ContextualUsage(
          context: 'Reduction',
          description: 'Diminishing vigor or power',
          examples: [
            'The storm spent its fury overnight.',
            'His anger was spent after the heated argument.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'ring',
  base: 'ring',
  past: 'rang',
  participle: 'rung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'rɪŋ',
  pronunciationTextUK: 'rɪŋ',
  meanings: [
    VerbMeaning(
      definition: 'To produce a resonant sound, especially by striking a bell or similar object',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The church bells rang at noon.',
        'The phone is ringing; can you answer it?',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sound',
          description: 'Making clear, resonating tones',
          examples: [
            'The doorbell rang just as I was about to leave.',
            'Alarm bells rang throughout the building during the fire drill.',
          ],
        ),
        ContextualUsage(
          context: 'Communication',
          description: 'Sounds from communication devices',
          examples: [
            'My cellphone rang in the middle of the meeting.',
            'The old-fashioned telephone rang with a mechanical bell sound.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To call someone by telephone',
      partOfSpeech: 'transitive verb',
      examples: [
        'I\'ll ring you tomorrow with the details.',
        'Can you ring the doctor for an appointment?',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Contact',
          description: 'Initiating telephone communication',
          examples: [
            'She rang her mother every Sunday evening.',
            'Ring me back when you have more information.',
          ],
        ),
        ContextualUsage(
          context: 'Arrangements',
          description: 'Calling to make plans or appointments',
          examples: [
            'I\'ll ring the restaurant to book a table.',
            'He rang his friend to arrange a meeting.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To surround completely',
      partOfSpeech: 'transitive verb',
      examples: [
        'Trees ring the small lake.',
        'Police officers rang the building to prevent escape.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Encirclement',
          description: 'Forming a circle around something',
          examples: [
            'Mountains ring the valley on all sides.',
            'A fence rings the entire property for security.',
          ],
        ),
        ContextualUsage(
          context: 'Surrounding',
          description: 'Positioning around a central point',
          examples: [
            'Supporters rang the stage during the politician\'s speech.',
            'Tall skyscrapers ring the central park in the city.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To resound or reverberate with sound',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Her voice rang through the empty hall.',
        'The gunshot rang out in the quiet forest.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Acoustics',
          description: 'Sounds echoing or filling a space',
          examples: [
            'The singer\'s high note rang throughout the concert hall.',
            'Children\'s laughter rang across the playground.',
          ],
        ),
        ContextualUsage(
          context: 'Impact',
          description: 'Powerful or lasting auditory effect',
          examples: [
            'His words of warning rang in her ears for days.',
            'The explosion rang across the valley, alerting everyone.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shake',
  base: 'shake',
  past: 'shook',
  participle: 'shaken',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʃeɪk',
  pronunciationTextUK: 'ʃeɪk',
  meanings: [
    VerbMeaning(
      definition: 'To move or cause to move with short, quick, irregular vibratory movements',
      partOfSpeech: 'transitive verb',
      examples: [
        'She shook the bottle of salad dressing before pouring it.',
        'He shook the present to guess what was inside.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Motion',
          description: 'Moving objects back and forth rapidly',
          examples: [
            'The wind shook the branches of the trees.',
            'He shook the dice before rolling them onto the table.',
          ],
        ),
        ContextualUsage(
          context: 'Mixing',
          description: 'Agitating to combine contents',
          examples: [
            'The bartender shook the cocktail vigorously.',
            'She shook the paint can to mix the contents properly.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To tremble or quiver from emotional or physical causes',
      partOfSpeech: 'intransitive verb',
      examples: [
        'His hands shook from nervousness during the speech.',
        'The whole building shook during the earthquake.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotion',
          description: 'Physical reaction to strong feelings',
          examples: [
            'She shook with anger after the argument.',
            'He was shaking with laughter at the comedian\'s jokes.',
          ],
        ),
        ContextualUsage(
          context: 'Physical reaction',
          description: 'Involuntary trembling',
          examples: [
            'The old man shook from Parkinson\'s disease.',
            'The child shook with cold after falling into the icy water.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To disturb or weaken the stability; to undermine confidence or resolve',
      partOfSpeech: 'transitive verb',
      examples: [
        'The scandal shook the public\'s trust in the government.',
        'The tragedy shook her faith in humanity.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Confidence',
          description: 'Affecting belief or certainty',
          examples: [
            'The poor performance shook investor confidence in the company.',
            'The evidence shook his certainty about what happened.',
          ],
        ),
        ContextualUsage(
          context: 'Stability',
          description: 'Disrupting established structures or systems',
          examples: [
            'The protests shook the foundations of the regime.',
            'The financial crisis shook the global banking system.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To get rid of or free oneself from someone or something',
      partOfSpeech: 'transitive verb',
      examples: [
        'I can\'t shake this cold I\'ve had for weeks.',
        'She tried to shake her pursuers in the crowded market.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Evasion',
          description: 'Avoiding or escaping from someone',
          examples: [
            'The celebrity couldn\'t shake the persistent paparazzi.',
            'He shook his opponent with a quick change of direction.',
          ],
        ),
        ContextualUsage(
          context: 'Liberation',
          description: 'Freeing oneself from problems or constraints',
          examples: [
            'It took years for her to shake her addiction.',
            'The company is trying to shake its reputation for poor customer service.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'cut',
  base: 'cut',
  past: 'cut',
  participle: 'cut',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kʌt',
  pronunciationTextUK: 'kʌt',
  meanings: [
    VerbMeaning(
      definition: 'To penetrate or divide with a sharp-edged instrument or object',
      partOfSpeech: 'transitive verb',
      examples: [
        'She cut the bread into thin slices.',
        'He cut his finger on the broken glass.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Division',
          description: 'Separating into pieces with a sharp tool',
          examples: [
            'The tailor cut the fabric according to the pattern.',
            'Use scissors to cut along the dotted line.',
          ],
        ),
        ContextualUsage(
          context: 'Food preparation',
          description: 'Slicing or chopping ingredients',
          examples: [
            'He cut the vegetables for the salad.',
            'She cut the cake into equal portions for the guests.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reduce in amount, length, or duration',
      partOfSpeech: 'transitive verb',
      examples: [
        'The editor cut several scenes from the film.',
        'We need to cut expenses to stay within budget.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Reduction',
          description: 'Decreasing quantity or size',
          examples: [
            'The company cut its workforce by 15 percent.',
            'The director cut the play to fit a two-hour time slot.',
          ],
        ),
        ContextualUsage(
          context: 'Editing',
          description: 'Removing portions of text, film, or audio',
          examples: [
            'They cut the offensive language from the broadcast.',
            'The author cut several chapters from the final manuscript.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To stop doing something; to end an association or relationship',
      partOfSpeech: 'transitive verb',
      examples: [
        'She cut all ties with her former business partner.',
        'The coach cut the player from the team.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Termination',
          description: 'Ending relationships or connections',
          examples: [
            'He cut contact with his childhood friends after moving away.',
            'The celebrity cut professional ties with her long-time agent.',
          ],
        ),
        ContextualUsage(
          context: 'Elimination',
          description: 'Removing someone from a group or position',
          examples: [
            'Three contestants were cut from the competition in the first round.',
            'The director cut several actors during the casting process.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or pass quickly or directly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He cut across the field to reach the school faster.',
        'The ship cut through the rough waves.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Taking a direct or shorter path',
          examples: [
            'She cut through the alley as a shortcut.',
            'The taxi cut in front of us at the intersection.',
          ],
        ),
        ContextualUsage(
          context: 'Penetration',
          description: 'Moving forcefully through something',
          examples: [
            'The skates cut smoothly across the ice.',
            'The knife cut easily through the soft butter.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'hide',
  base: 'hide',
  past: 'hid',
  participle: 'hidden',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'haɪd',
  pronunciationTextUK: 'haɪd',
  meanings: [
    VerbMeaning(
      definition: 'To put or keep something out of sight or so that it cannot be found',
      partOfSpeech: 'transitive verb',
      examples: [
        'She hid the birthday presents in the closet.',
        'He hid his wallet under the mattress.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Concealment',
          description: 'Placing objects where they won\'t be seen',
          examples: [
            'The squirrel hid nuts throughout the garden for winter.',
            'They hid the key under a fake rock near the door.',
          ],
        ),
        ContextualUsage(
          context: 'Protection',
          description: 'Securing valuable items from others',
          examples: [
            'During the invasion, they hid family heirlooms in the cellar.',
            'She hid her diary from her nosy siblings.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To conceal oneself so that one cannot be seen or found',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The children hid behind the sofa during the game.',
        'The fugitive hid in the woods for days.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Games',
          description: 'Concealing oneself for recreation',
          examples: [
            'Let\'s play hide and seek; you hide first.',
            'The children giggled as they hid from their father.',
          ],
        ),
        ContextualUsage(
          context: 'Safety',
          description: 'Concealing oneself due to danger',
          examples: [
            'The civilians hid in basements during the bombing.',
            'The witness hid from the criminal organization.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To keep a fact or feeling secret or prevent it from being known',
      partOfSpeech: 'transitive verb',
      examples: [
        'She tried to hide her disappointment when she didn\'t get the job.',
        'The company hid the true cost of the project from investors.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotions',
          description: 'Concealing personal feelings',
          examples: [
            'He couldn\'t hide his excitement about the surprise party.',
            'She hid her grief behind a cheerful facade.',
          ],
        ),
        ContextualUsage(
          context: 'Deception',
          description: 'Deliberately concealing information',
          examples: [
            'The politician hid his connections to the corrupt businessman.',
            'They hid the risks of the investment from potential clients.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To prevent something from being seen or noticed by covering or screening it',
      partOfSpeech: 'transitive verb',
      examples: [
        'The tall fence hides the factory from view.',
        'She used makeup to hide the scar on her cheek.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Visual obstruction',
          description: 'Blocking something from sight',
          examples: [
            'The curtains hide the unattractive view of the parking lot.',
            'Trees hide the cell tower from nearby homes.',
          ],
        ),
        ContextualUsage(
          context: 'Camouflage',
          description: 'Making something blend into surroundings',
          examples: [
            'The animal\'s coloring hides it perfectly among the leaves.',
            'The wallpaper pattern hides the small imperfections in the wall.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'cast',
  base: 'cast',
  past: 'cast',
  participle: 'cast',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kæst',
  pronunciationTextUK: 'kɑːst',
  meanings: [
    VerbMeaning(
      definition: 'To throw or send forth, especially in a particular direction',
      partOfSpeech: 'transitive verb',
      examples: [
        'The fisherman cast his line into the river.',
        'She cast a stone into the pond.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Fishing',
          description: 'Throwing fishing line into water',
          examples: [
            'He cast his net into the deeper part of the lake.',
            'The angler cast repeatedly, trying to reach the spot where fish were jumping.',
          ],
        ),
        ContextualUsage(
          context: 'Projection',
          description: 'Throwing or directing something',
          examples: [
            'The magician cast the dice across the table.',
            'She cast the ball to her teammate.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To select actors for roles in a play, film, or program',
      partOfSpeech: 'transitive verb',
      examples: [
        'The director cast a famous actress in the leading role.',
        'He was cast as the villain in the new superhero movie.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Entertainment',
          description: 'Assigning roles to performers',
          examples: [
            'They cast unknown actors to keep the film\'s budget low.',
            'She was cast against type as a ruthless businesswoman.',
          ],
        ),
        ContextualUsage(
          context: 'Production',
          description: 'Assembling performers for a show',
          examples: [
            'The musical was brilliantly cast with talented singers.',
            'The director cast his friends in minor roles.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause light, shadow, or a reflection to appear on a surface',
      partOfSpeech: 'transitive verb',
      examples: [
        'The tree cast a long shadow in the afternoon sun.',
        'The lamp cast a warm glow over the room.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Light',
          description: 'Creating illumination patterns',
          examples: [
            'The candles cast flickering shadows on the walls.',
            'The stained glass window cast colorful patterns on the floor.',
          ],
        ),
        ContextualUsage(
          context: 'Shadow',
          description: 'Creating areas of darkness',
          examples: [
            'The tall buildings cast the street into shadow.',
            'His figure cast an imposing shadow against the wall.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To shape or form by pouring liquid material into a mold',
      partOfSpeech: 'transitive verb',
      examples: [
        'The sculptor cast the statue in bronze.',
        'They cast a new bell for the church tower.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Manufacturing',
          description: 'Creating objects using molds',
          examples: [
            'The factory casts engine blocks from aluminum.',
            'Jewelers cast precious metals into rings and pendants.',
          ],
        ),
        ContextualUsage(
          context: 'Art',
          description: 'Creating sculptural works through casting',
          examples: [
            'The artist cast her sculpture in resin.',
            'Ancient civilizations cast ceremonial objects in gold and silver.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'stick',
  base: 'stick',
  past: 'stuck',
  participle: 'stuck',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'stɪk',
  pronunciationTextUK: 'stɪk',
  meanings: [
    VerbMeaning(
      definition: 'To attach something to a surface with glue or another adhesive substance',
      partOfSpeech: 'transitive verb',
      examples: [
        'She stuck the photo to the refrigerator with a magnet.',
        'He stuck a note on her desk before leaving.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Adhesion',
          description: 'Attaching items with sticky substances',
          examples: [
            'The child stuck stickers all over her bedroom wall.',
            'I stuck the torn page back into the book with tape.',
          ],
        ),
        ContextualUsage(
          context: 'Posting',
          description: 'Placing notices or information',
          examples: [
            'They stuck posters around town advertising the concert.',
            'He stuck his business card on the community bulletin board.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be or become fixed in a particular position or unable to move or be moved',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The drawer stuck and wouldn\'t open properly.',
        'Her car got stuck in the mud after the rain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Immobility',
          description: 'Being unable to move from a position',
          examples: [
            'The key stuck in the lock and wouldn\'t turn.',
            'The window is stuck; can you help me open it?',
          ],
        ),
        ContextualUsage(
          context: 'Obstruction',
          description: 'Being caught or trapped',
          examples: [
            'The boat stuck on a sandbar in the shallow water.',
            'His sleeve stuck on a nail as he walked past.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To remain loyal or faithful to someone or something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She stuck with her husband through difficult times.',
        'I\'m going to stick to my original plan.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Loyalty',
          description: 'Maintaining commitment to people',
          examples: [
            'Friends stick together when times get tough.',
            'He stuck by his colleague when everyone else abandoned her.',
          ],
        ),
        ContextualUsage(
          context: 'Perseverance',
          description: 'Continuing with plans or decisions',
          examples: [
            'She stuck to her diet despite the holiday temptations.',
            'We need to stick with the strategy we agreed upon.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pierce or penetrate something with a pointed object',
      partOfSpeech: 'transitive verb',
      examples: [
        'He stuck a pin in the map to mark his hometown.',
        'She accidentally stuck herself with the sewing needle.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Insertion',
          description: 'Putting pointed objects into something',
          examples: [
            'The nurse stuck the needle into his arm to draw blood.',
            'He stuck his key in the lock and turned it.',
          ],
        ),
        ContextualUsage(
          context: 'Puncturing',
          description: 'Making holes with sharp objects',
          examples: [
            'She stuck pins into the fabric to hold the pattern in place.',
            'The thorn stuck me when I was pruning the roses.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'cost',
  base: 'cost',
  past: 'cost',
  participle: 'cost',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kɔst',
  pronunciationTextUK: 'kɒst',
  meanings: [
    VerbMeaning(
      definition: 'To have a particular price',
      partOfSpeech: 'transitive verb',
      examples: [
        'The dress costs fifty dollars.',
        'How much did your new car cost?',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Price',
          description: 'Having a specific monetary value',
          examples: [
            'The concert tickets cost more than we expected.',
            'Fresh seafood costs a lot in inland areas.',
          ],
        ),
        ContextualUsage(
          context: 'Expense',
          description: 'Requiring payment of an amount',
          examples: [
            'College textbooks cost hundreds of dollars each semester.',
            'The repairs cost twice what we had budgeted.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To require the expenditure, loss, or sacrifice of something valuable',
      partOfSpeech: 'transitive verb',
      examples: [
        'The mistake cost him his job.',
        'Smoking costs many people their health.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Consequence',
          description: 'Resulting in loss or negative outcome',
          examples: [
            'His carelessness cost the team the championship.',
            'The scandal cost the politician public trust.',
          ],
        ),
        ContextualUsage(
          context: 'Sacrifice',
          description: 'Requiring giving up something valuable',
          examples: [
            'The project cost her many sleepless nights.',
            'Achieving success costs time and effort.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause harm, suffering, or loss',
      partOfSpeech: 'transitive verb',
      examples: [
        'The war cost thousands of lives.',
        'His addiction cost his family years of pain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Human toll',
          description: 'Resulting in human suffering or death',
          examples: [
            'The pandemic cost millions of lives worldwide.',
            'The delay cost patients vital treatment time.',
          ],
        ),
        ContextualUsage(
          context: 'Damage',
          description: 'Creating negative impact on wellbeing',
          examples: [
            'The natural disaster cost the region billions in damage.',
            'Their argument cost them their friendship of twenty years.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To estimate or determine the cost of producing or providing something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The accountant cost the project at \$2 million.',
        'We need to cost the renovation before making a decision.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Calculation',
          description: 'Computing expenses or expenditure',
          examples: [
            'The consultants cost the expansion plans for the board meeting.',
            'They cost each phase of the construction separately.',
          ],
        ),
        ContextualUsage(
          context: 'Budgeting',
          description: 'Planning financial requirements',
          examples: [
            'We\'ve costed the marketing campaign for the next fiscal year.',
            'Has anyone costed the staff training program yet?',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shoot',
  base: 'shoot',
  past: 'shot',
  participle: 'shot',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʃut',
  pronunciationTextUK: 'ʃuːt',
  meanings: [
    VerbMeaning(
      definition: 'To fire a weapon or projectile',
      partOfSpeech: 'transitive verb',
      examples: [
        'The hunter shot the deer.',
        'He shot an arrow at the target.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Firearms',
          description: 'Discharging guns or similar weapons',
          examples: [
            'The soldier shot three times at the enemy position.',
            'She shot at the intruder but missed.',
          ],
        ),
        ContextualUsage(
          context: 'Projectiles',
          description: 'Launching arrows, balls, or other objects',
          examples: [
            'The archer shot arrows with remarkable accuracy.',
            'The basketball player shot from the three-point line.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To capture on film or video',
      partOfSpeech: 'transitive verb',
      examples: [
        'They shot the movie in New Zealand.',
        'The photographer shot the wedding ceremony.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Film production',
          description: 'Recording moving images',
          examples: [
            'They shot the documentary over three months in Africa.',
            'The director shot the scene in one continuous take.',
          ],
        ),
        ContextualUsage(
          context: 'Photography',
          description: 'Taking still pictures',
          examples: [
            'She shoots portraits for a living.',
            'We shot the landscape at sunrise for optimal lighting.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or travel very quickly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The car shot around the corner.',
        'Prices shot up after the supply shortage.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Motion',
          description: 'Moving rapidly from one place to another',
          examples: [
            'The child shot across the playground.',
            'The rocket shot into the sky.',
          ],
        ),
        ContextualUsage(
          context: 'Change',
          description: 'Rapid increase or alteration',
          examples: [
            'The company\'s stock shot up after the product announcement.',
            'His temperature shot to 104 degrees during the night.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To send forth or extend suddenly or rapidly',
      partOfSpeech: 'transitive verb',
      examples: [
        'The plant shot new leaves in the spring.',
        'He shot his hand up to answer the question.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Growth',
          description: 'Sudden biological extension',
          examples: [
            'The seedlings shot up after the rain.',
            'The child has shot up several inches this year.',
          ],
        ),
        ContextualUsage(
          context: 'Communication',
          description: 'Quick verbal exchanges',
          examples: [
            'He shot a quick glance at his watch during the meeting.',
            'She shot back a sharp reply to his criticism.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bite',
  base: 'bite',
  past: 'bit',
  participle: 'bitten',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'baɪt',
  pronunciationTextUK: 'baɪt',
  meanings: [
    VerbMeaning(
      definition: 'To cut, grip, or tear with the teeth',
      partOfSpeech: 'transitive verb',
      examples: [
        'The dog bit the postman on the leg.',
        'She bit into the apple with a satisfying crunch.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Eating',
          description: 'Using teeth to cut food',
          examples: [
            'He bit a large chunk from the sandwich.',
            'She bit off a piece of chocolate from the bar.',
          ],
        ),
        ContextualUsage(
          context: 'Animals',
          description: 'Attacking with teeth',
          examples: [
            'The snake bit the researcher during the field study.',
            'Their cat bit the veterinarian during the examination.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause sharp pain, discomfort, or injury',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The cold wind bit into her exposed skin.',
        'The antiseptic bit when applied to the cut.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sensation',
          description: 'Creating sharp physical feeling',
          examples: [
            'The frost bit at his fingers and toes.',
            'The spicy food bit the back of my throat.',
          ],
        ),
        ContextualUsage(
          context: 'Weather',
          description: 'Harsh climatic effects',
          examples: [
            'The bitter cold bit through their inadequate clothing.',
            'A biting wind came off the North Sea.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take or accept something offered, especially in a metaphorical sense',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The fish aren\'t biting today.',
        'None of the investors bit when we presented our proposal.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Response',
          description: 'Reacting to an opportunity or offer',
          examples: [
            'The public didn\'t bite when the company launched its new product.',
            'He finally bit on her suggestion to try couples therapy.',
          ],
        ),
        ContextualUsage(
          context: 'Fishing',
          description: 'Fish taking bait',
          examples: [
            'The trout weren\'t biting in the cold water.',
            'We got lucky—the bass were biting all afternoon.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To grip or hold firmly with or as if with teeth',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The gears of the machine bit into each other.',
        'The brakes bit suddenly, throwing everyone forward.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mechanical',
          description: 'Parts engaging firmly',
          examples: [
            'The anchor bit into the seabed, holding the ship steady.',
            'The drill bit into the hard wood slowly.',
          ],
        ),
        ContextualUsage(
          context: 'Grip',
          description: 'Creating friction or traction',
          examples: [
            'The tires bit into the soft mud, gaining traction.',
            'The climber\'s piton bit securely into the rock face.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shut',
  base: 'shut',
  past: 'shut',
  participle: 'shut',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʃʌt',
  pronunciationTextUK: 'ʃʌt',
  meanings: [
    VerbMeaning(
      definition: 'To move something into a position that closes or covers an opening',
      partOfSpeech: 'transitive verb',
      examples: [
        'Please shut the door when you leave.',
        'She shut her book and put it away.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Doors/Windows',
          description: 'Closing access points to buildings',
          examples: [
            'He shut the window to keep out the cold.',
            'She shut the garage door with the remote control.',
          ],
        ),
        ContextualUsage(
          context: 'Containers',
          description: 'Closing boxes, cases, or other objects',
          examples: [
            'I shut my suitcase after packing everything.',
            'He shut the lid of the trash can.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To close or fold together',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The automatic doors shut with a hiss.',
        'My umbrella won\'t shut properly.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Automatic',
          description: 'Self-closing mechanisms',
          examples: [
            'The elevator doors shut before he could exit.',
            'This model of laptop shuts without making a sound.',
          ],
        ),
        ContextualUsage(
          context: 'Function',
          description: 'Proper operation of closing mechanisms',
          examples: [
            'The cabinet drawer doesn\'t shut all the way.',
            'Make sure the safety gate shuts completely behind you.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To stop operating or cause to stop operating',
      partOfSpeech: 'transitive verb',
      examples: [
        'They shut the factory due to falling demand.',
        'We had to shut our business during the pandemic.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Ceasing commercial operations',
          examples: [
            'The restaurant shut after twenty years in business.',
            'They shut the mining operation when resources were depleted.',
          ],
        ),
        ContextualUsage(
          context: 'Machinery',
          description: 'Turning off equipment or systems',
          examples: [
            'Remember to shut the computer before leaving.',
            'They shut the power plant for maintenance.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To block access to or prevent communication with',
      partOfSpeech: 'transitive verb',
      examples: [
        'The government shut social media sites during the protests.',
        'She shut him out of her life after the argument.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Exclusion',
          description: 'Preventing participation or involvement',
          examples: [
            'He felt shut out of the decision-making process.',
            'The team shut their opponents out of the game completely.',
          ],
        ),
        ContextualUsage(
          context: 'Emotional',
          description: 'Blocking emotional connection',
          examples: [
            'After the trauma, she shut herself off from friends and family.',
            'He shut down emotionally when the subject was raised.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bet',
  base: 'bet',
  past: 'bet',
  participle: 'bet',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɛt',
  pronunciationTextUK: 'bet',
  meanings: [
    VerbMeaning(
      definition: 'To risk money on the outcome of an event or game',
      partOfSpeech: 'transitive verb',
      examples: [
        'He bet \$50 on the horse race.',
        'I wouldn\'t bet money on that team winning.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Gambling',
          description: 'Wagering money on games of chance',
          examples: [
            'She bet heavily on blackjack at the casino.',
            'They bet on sports matches every weekend.',
          ],
        ),
        ContextualUsage(
          context: 'Racing',
          description: 'Placing wagers on competitive races',
          examples: [
            'He bet on the underdog in the derby.',
            'Many people bet millions on the championship race.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be certain or confident about something',
      partOfSpeech: 'transitive verb',
      examples: [
        'I bet she\'ll be late as usual.',
        'You can bet that he\'ll complain about the decision.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Certainty',
          description: 'Expressing strong belief or confidence',
          examples: [
            'I bet you anything he\'s going to propose this weekend.',
            'You can bet your life she won\'t forget this insult.',
          ],
        ),
        ContextualUsage(
          context: 'Prediction',
          description: 'Forecasting outcomes with confidence',
          examples: [
            'I bet it will rain before the day is over.',
            'I bet they\'ll announce the merger next week.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make an agreement to pay if a certain event occurs',
      partOfSpeech: 'intransitive verb',
      examples: [
        'We bet on who would win the election.',
        'Let\'s bet on whether it will snow tomorrow.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Informal wager',
          description: 'Making casual agreements about outcomes',
          examples: [
            'They bet a dinner on the outcome of the game.',
            'I bet my brother five dollars that I could swim faster than him.',
          ],
        ),
        ContextualUsage(
          context: 'Challenge',
          description: 'Using bets to motivate or challenge',
          examples: [
            'I bet you can\'t eat ten hot dogs in one sitting.',
            'She bet him he couldn\'t go a week without social media.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To rely confidently on someone or something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'You can bet on me to get the job done.',
        'I\'m betting on your expertise to solve this problem.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Trust',
          description: 'Having confidence in someone\'s abilities',
          examples: [
            'The coach is betting on the rookie quarterback this season.',
            'We\'re betting on your leadership to get us through this crisis.',
          ],
        ),
        ContextualUsage(
          context: 'Investment',
          description: 'Committing resources based on expected outcomes',
          examples: [
            'The company is betting big on artificial intelligence technology.',
            'They\'re betting their future on expanding into Asian markets.',
          ],
        ),
      ],
    ),
  ],
),
VerbModel(
  id: 'light',
  base: 'light',
  past: 'lit',
  participle: 'lit',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'laɪt',
  pronunciationTextUK: 'laɪt',
  meanings: [
    VerbMeaning(
      definition: 'To set fire to or cause to start burning',
      partOfSpeech: 'transitive verb',
      examples: [
        'He lit a cigarette and took a deep drag.',
        'She lit the candles on the birthday cake.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Fire',
          description: 'Starting a controlled flame',
          examples: [
            'The campers lit a fire to keep warm during the night.',
            'She lit the fireplace before her guests arrived.',
          ],
        ),
        ContextualUsage(
          context: 'Celebration',
          description: 'Igniting ceremonial flames',
          examples: [
            'They lit fireworks to celebrate the new year.',
            'The priest lit incense during the ceremony.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To illuminate or provide light for',
      partOfSpeech: 'transitive verb',
      examples: [
        'The street lamps lit the sidewalk.',
        'A single bulb lit the entire room.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Illumination',
          description: 'Providing artificial light',
          examples: [
            'The chandelier lit the ballroom brilliantly.',
            'Emergency flares lit the crash site for the rescue workers.',
          ],
        ),
        ContextualUsage(
          context: 'Ambiance',
          description: 'Creating mood through lighting',
          examples: [
            'Soft lamps lit the restaurant, creating a romantic atmosphere.',
            'Spotlights lit the stage for the performance.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To brighten with animation, joy, or hope',
      partOfSpeech: 'transitive verb',
      examples: [
        'His face lit up when he saw his daughter.',
        'The news lit a spark of hope in the community.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional reaction',
          description: 'Showing sudden happiness or excitement',
          examples: [
            'Her eyes lit up when she opened the surprise gift.',
            'The child\'s face lit with delight at the sight of the puppies.',
          ],
        ),
        ContextualUsage(
          context: 'Inspiration',
          description: 'Stimulating enthusiasm or creativity',
          examples: [
            'The professor\'s lecture lit a fire of curiosity in his students.',
            'The movement lit the way for social change.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To descend or land after flight',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The bird lit on the branch.',
        'The butterfly lit on the flower.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Animals',
          description: 'Birds or insects landing after flight',
          examples: [
            'The eagle lit gracefully on the cliff edge.',
            'The dragonfly lit briefly on the surface of the pond.',
          ],
        ),
        ContextualUsage(
          context: 'Arrival',
          description: 'Coming to rest in a location',
          examples: [
            'After wandering for years, he finally lit in a small coastal town.',
            'Her gaze lit on the strange object in the corner of the room.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'quit',
  base: 'quit',
  past: 'quit',
  participle: 'quit',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kwɪt',
  pronunciationTextUK: 'kwɪt',
  meanings: [
    VerbMeaning(
      definition: 'To leave a job or position permanently',
      partOfSpeech: 'transitive verb',
      examples: [
        'She quit her job to start her own business.',
        'He quit the team after disagreements with the coach.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Employment',
          description: 'Resigning from professional positions',
          examples: [
            'After ten years, she quit the company without another job lined up.',
            'He quit his position as manager due to stress.',
          ],
        ),
        ContextualUsage(
          context: 'Activities',
          description: 'Leaving organized groups or commitments',
          examples: [
            'She quit the choir when rehearsals conflicted with her new work schedule.',
            'Many students quit the program before completing it.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To stop or discontinue an action, habit, or practice',
      partOfSpeech: 'transitive verb',
      examples: [
        'He quit smoking after thirty years.',
        'They quit talking when the teacher entered the room.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Habits',
          description: 'Ceasing regular behaviors or addictions',
          examples: [
            'She quit drinking alcohol for health reasons.',
            'It took several attempts before he could quit gambling.',
          ],
        ),
        ContextualUsage(
          context: 'Activities',
          description: 'Stopping ongoing actions',
          examples: [
            'Quit wasting time on social media and focus on your studies.',
            'The children quit playing when it started to rain.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To leave or depart from a place',
      partOfSpeech: 'transitive verb',
      examples: [
        'We quit the city for a quieter life in the countryside.',
        'They quit the building when the fire alarm sounded.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Location',
          description: 'Departing or moving away from places',
          examples: [
            'The hikers quit the trail before reaching the summit due to bad weather.',
            'She quit her apartment at the end of the lease.',
          ],
        ),
        ContextualUsage(
          context: 'Evacuation',
          description: 'Leaving places for safety reasons',
          examples: [
            'Residents were advised to quit the area before the hurricane hit.',
            'Workers quit the site when the structure became unstable.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To give up or admit defeat',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Don\'t quit when things get difficult.',
        'The team never quits, even when they\'re far behind.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Perseverance',
          description: 'Surrendering versus continuing effort',
          examples: [
            'Winners never quit and quitters never win.',
            'She refused to quit despite multiple setbacks.',
          ],
        ),
        ContextualUsage(
          context: 'Challenges',
          description: 'Responding to difficult situations',
          examples: [
            'Many students quit when faced with advanced mathematics.',
            'Don\'t quit at the first sign of difficulty.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'let',
  base: 'let',
  past: 'let',
  participle: 'let',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'lɛt',
  pronunciationTextUK: 'let',
  meanings: [
    VerbMeaning(
      definition: 'To allow or permit someone to do something',
      partOfSpeech: 'transitive verb',
      examples: [
        'Her parents let her stay out until midnight.',
        'They won\'t let anyone leave until the meeting is over.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Permission',
          description: 'Giving authorization to act',
          examples: [
            'The teacher let the students use calculators during the test.',
            'My brother let me borrow his car for the weekend.',
          ],
        ),
        ContextualUsage(
          context: 'Parenting',
          description: 'Allowing children certain freedoms',
          examples: [
            'They let their children choose their own activities.',
            'I don\'t let my kids eat candy before dinner.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make available for rent or lease',
      partOfSpeech: 'transitive verb',
      examples: [
        'They let their vacation home during the summer months.',
        'The company lets office space to small businesses.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Real estate',
          description: 'Renting out property',
          examples: [
            'She lets rooms in her house to university students.',
            'The building is let to a technology startup for five years.',
          ],
        ),
        ContextualUsage(
          context: 'Contracts',
          description: 'Formal rental agreements',
          examples: [
            'They let the land to farmers for agricultural use.',
            'The commercial property was let on a long-term lease.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause or allow something to happen or exist',
      partOfSpeech: 'transitive verb',
      examples: [
        'Let\'s not let this opportunity pass us by.',
        'Don\'t let your fear stop you from trying.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Prevention',
          description: 'Allowing or preventing states or situations',
          examples: [
            'Don\'t let the food get cold.',
            'She didn\'t let her disability limit her achievements.',
          ],
        ),
        ContextualUsage(
          context: 'Emotions',
          description: 'Managing emotional states',
          examples: [
            'Let your anger go; it\'s not worth it.',
            'He lets his enthusiasm show in everything he does.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To express a suggestion for action',
      partOfSpeech: 'auxiliary verb',
      examples: [
        'Let\'s go to the park this afternoon.',
        'Let us consider all the options before deciding.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Proposals',
          description: 'Suggesting joint activities or decisions',
          examples: [
            'Let\'s take a break and continue later.',
            'Let\'s not argue about this anymore.',
          ],
        ),
        ContextualUsage(
          context: 'Imperatives',
          description: 'Giving commands or instructions',
          examples: [
            'Let him know when you arrive.',
            'Let the mixture cool before adding the eggs.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'hit',
  base: 'hit',
  past: 'hit',
  participle: 'hit',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'hɪt',
  pronunciationTextUK: 'hɪt',
  meanings: [
    VerbMeaning(
      definition: 'To bring a part of the body or an object into contact with something else with force or impact',
      partOfSpeech: 'transitive verb',
      examples: [
        'She hit the ball over the fence.',
        'He hit his head on the low doorway.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sports',
          description: 'Striking balls or objects in games',
          examples: [
            'The batter hit a home run in the ninth inning.',
            'She hit the tennis ball with perfect technique.',
          ],
        ),
        ContextualUsage(
          context: 'Contact',
          description: 'Forceful impact between objects',
          examples: [
            'The car hit a tree when the driver lost control.',
            'He hit the nail with the hammer.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To attack or strike someone deliberately',
      partOfSpeech: 'transitive verb',
      examples: [
        'The boxer hit his opponent with a powerful right hook.',
        'He was arrested for hitting a police officer.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Violence',
          description: 'Physical assault or combat',
          examples: [
            'One student hit another during a playground fight.',
            'She hit her attacker in self-defense.',
          ],
        ),
        ContextualUsage(
          context: 'Military',
          description: 'Attacking targets with weapons',
          examples: [
            'The missiles hit strategic locations around the city.',
            'The air force hit enemy supply lines.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reach or achieve a specified point, level, or state',
      partOfSpeech: 'transitive verb',
      examples: [
        'Temperatures hit record highs last summer.',
        'The company\'s stock hit an all-time low yesterday.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Measurements',
          description: 'Reaching numerical values or thresholds',
          examples: [
            'Unemployment hit 10% during the recession.',
            'Their fundraising campaign hit the target a month early.',
          ],
        ),
        ContextualUsage(
          context: 'Milestones',
          description: 'Achieving significant points or accomplishments',
          examples: [
            'The video hit one million views overnight.',
            'She hit her personal best time in the marathon.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To affect suddenly or severely',
      partOfSpeech: 'transitive verb',
      examples: [
        'The hurricane hit the coastal area with devastating force.',
        'The financial crisis hit middle-class families particularly hard.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Disasters',
          description: 'Impact of sudden catastrophic events',
          examples: [
            'The earthquake hit the region without warning.',
            'Drought hit farmers across the southwestern states.',
          ],
        ),
        ContextualUsage(
          context: 'Realization',
          description: 'Sudden understanding or awareness',
          examples: [
            'The truth hit him like a ton of bricks.',
            'The implications of her decision finally hit her.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spread',
  base: 'spread',
  past: 'spread',
  participle: 'spread',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sprɛd',
  pronunciationTextUK: 'spred',
  meanings: [
    VerbMeaning(
      definition: 'To extend over a larger area or distance',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The fire spread quickly through the dry forest.',
        'Oil from the damaged tanker spread across the surface of the water.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Natural phenomena',
          description: 'Expansion of natural elements',
          examples: [
            'The flood waters spread throughout the low-lying areas.',
            'Cracks spread across the ceiling over time.',
          ],
        ),
        ContextualUsage(
          context: 'Growth',
          description: 'Expansion of living things',
          examples: [
            'The ivy spread along the wall of the old building.',
            'The cancer had spread to neighboring tissues.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To arrange something over an area, especially to cover it',
      partOfSpeech: 'transitive verb',
      examples: [
        'She spread butter on her toast.',
        'They spread a blanket on the grass for the picnic.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Coverage',
          description: 'Applying substances over surfaces',
          examples: [
            'The farmers spread fertilizer over their fields.',
            'He spread paint evenly with a roller.',
          ],
        ),
        ContextualUsage(
          context: 'Arrangement',
          description: 'Laying out items over an area',
          examples: [
            'She spread the documents across the table to review them.',
            'The vendor spread his merchandise on the sidewalk.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become or make widely known or prevalent',
      partOfSpeech: 'transitive verb',
      examples: [
        'News of his resignation spread throughout the company.',
        'The rumor spread like wildfire through the small town.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Information',
          description: 'Dissemination of news or knowledge',
          examples: [
            'Social media helped spread awareness of the campaign.',
            'The story spread across national news outlets.',
          ],
        ),
        ContextualUsage(
          context: 'Disease',
          description: 'Transmission of illnesses',
          examples: [
            'The virus spread rapidly in crowded areas.',
            'Measures were taken to prevent the disease from spreading further.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To extend or distribute over a period of time or among a group',
      partOfSpeech: 'transitive verb',
      examples: [
        'We can spread the payments over six months.',
        'The work was spread among all team members.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Financial',
          description: 'Distributing costs or expenses',
          examples: [
            'The company spread its investments across different sectors.',
            'They spread the financial risk by diversifying their portfolio.',
          ],
        ),
        ContextualUsage(
          context: 'Workload',
          description: 'Distributing tasks or responsibilities',
          examples: [
            'We need to spread the responsibilities more evenly.',
            'The project was spread across multiple departments.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'fit',
  base: 'fit',
  past: 'fit',
  participle: 'fit',
  pastUK: 'fitted',
  pastUS: '',
  participleUK: 'fitted',
  participleUS: '',
  pronunciationTextUS: 'fɪt',
  pronunciationTextUK: 'fɪt',
  meanings: [
    VerbMeaning(
      definition: 'To be the right size and shape for someone or something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The key doesn\'t fit the lock.',
        'This sweater fits you perfectly.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Clothing',
          description: 'Garments being appropriate for body shape and size',
          examples: [
            'The dress fits her like it was made for her.',
            'These shoes don\'t fit properly; they\'re too tight.',
          ],
        ),
        ContextualUsage(
          context: 'Objects',
          description: 'Physical compatibility between items',
          examples: [
            'The furniture wouldn\'t fit through the doorway.',
            'The plug won\'t fit into this socket; we need an adapter.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be suitable or appropriate for something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'His skills fit the job requirements perfectly.',
        'The punishment should fit the crime.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Compatibility',
          description: 'Being appropriate for situations or roles',
          examples: [
            'Her experience fits well with our team\'s needs.',
            'This solution doesn\'t fit with our company\'s values.',
          ],
        ),
        ContextualUsage(
          context: 'Suitability',
          description: 'Meeting specific requirements',
          examples: [
            'His teaching style fits the needs of advanced students.',
            'That explanation doesn\'t fit the observed facts.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To install or place something in position',
      partOfSpeech: 'transitive verb',
      examples: [
        'The electrician fitted a new light switch in the bathroom.',
        'They fitted the car with a new engine.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Installation',
          description: 'Putting components or parts in place',
          examples: [
            'The carpenter fitted the new kitchen cabinets yesterday.',
            'They fitted security cameras throughout the building.',
          ],
        ),
        ContextualUsage(
          context: 'Equipment',
          description: 'Adding functional components to systems',
          examples: [
            'The ship was fitted with the latest navigation technology.',
            'All new cars are fitted with airbags as standard.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To adjust or make something the right size or shape',
      partOfSpeech: 'transitive verb',
      examples: [
        'The tailor fitted the suit to his measurements.',
        'The optician fitted her with new glasses.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Customization',
          description: 'Adjusting items for individuals',
          examples: [
            'The dentist fitted the patient with a custom mouth guard.',
            'The prosthetic limb was carefully fitted to ensure comfort.',
          ],
        ),
        ContextualUsage(
          context: 'Tailoring',
          description: 'Altering garments for better fit',
          examples: [
            'The bridal shop fitted her wedding dress to perfection.',
            'He had his new trousers fitted at the waist.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'burst',
  base: 'burst',
  past: 'burst',
  participle: 'burst',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɜrst',
  pronunciationTextUK: 'bɜːst',
  meanings: [
    VerbMeaning(
      definition: 'To break open or apart suddenly and violently, especially from internal pressure',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The balloon burst when it touched the sharp edge.',
        'The pipe burst during the cold snap, flooding the basement.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Pressure',
          description: 'Rupturing due to internal force',
          examples: [
            'The dam burst after days of heavy rain.',
            'The boiler burst because of excessive pressure.',
          ],
        ),
        ContextualUsage(
          context: 'Containment failure',
          description: 'Breaking of vessels or containers',
          examples: [
            'The water main burst, creating a sinkhole in the street.',
            'The overripe fruit burst, spilling juice everywhere.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To emerge, arrive, or depart suddenly and energetically',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She burst into the room with exciting news.',
        'The sun burst through the clouds after the rain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Entrance',
          description: 'Arriving suddenly or dramatically',
          examples: [
            'The children burst into the house after school.',
            'Tears burst from her eyes when she heard the sad news.',
          ],
        ),
        ContextualUsage(
          context: 'Natural phenomena',
          description: 'Sudden appearance or emergence',
          examples: [
            'Flowers burst into bloom after the spring rains.',
            'The storm burst upon them with little warning.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To give way to or be unable to contain a strong emotion',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The audience burst into applause at the end of the performance.',
        'She burst into tears when she heard the news.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotions',
          description: 'Sudden expression of feelings',
          examples: [
            'He burst out laughing at the absurd situation.',
            'They burst into cheers when the results were announced.',
          ],
        ),
        ContextualUsage(
          context: 'Speech',
          description: 'Sudden verbal expression',
          examples: [
            'She couldn\'t contain herself and burst out with the secret.',
            'He burst into song in the middle of the meeting.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be extremely full or overflowing',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The suitcase was bursting with clothes.',
        'The stadium was bursting with excited fans.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Capacity',
          description: 'Being filled beyond comfortable limits',
          examples: [
            'The folder was bursting with documents.',
            'The restaurant was bursting with lunchtime customers.',
          ],
        ),
        ContextualUsage(
          context: 'Abundance',
          description: 'Containing excessive amounts',
          examples: [
            'Their garden was bursting with colorful flowers.',
            'The market stalls were bursting with fresh produce.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'split',
  base: 'split',
  past: 'split',
  participle: 'split',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'splɪt',
  pronunciationTextUK: 'splɪt',
  meanings: [
    VerbMeaning(
      definition: 'To divide or separate into parts or pieces, especially by force',
      partOfSpeech: 'transitive verb',
      examples: [
        'He split the log with an axe.',
        'The impact split the rock in two.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical division',
          description: 'Breaking objects into separate pieces',
          examples: [
            'The earthquake split the ground open.',
            'She split the apple in half to share it.',
          ],
        ),
        ContextualUsage(
          context: 'Materials',
          description: 'Separating physical substances',
          examples: [
            'The cold weather split the wooden fence posts.',
            'The chef split the vanilla pod to extract the seeds.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To divide into different groups, opinions, or directions',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The committee split on whether to approve the proposal.',
        'The path splits into two trails at the old oak tree.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Decisions',
          description: 'Divergence of opinions or votes',
          examples: [
            'The jury split along gender lines in their initial vote.',
            'The board split over the future direction of the company.',
          ],
        ),
        ContextualUsage(
          context: 'Routes',
          description: 'Paths or roads dividing',
          examples: [
            'The river splits into several channels in the delta.',
            'The highway splits north of the city.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To divide something between people or groups',
      partOfSpeech: 'transitive verb',
      examples: [
        'They split the profits equally among all partners.',
        'Let\'s split the bill for dinner.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sharing',
          description: 'Dividing resources or expenses',
          examples: [
            'The siblings split the inheritance three ways.',
            'We split the cost of the vacation rental.',
          ],
        ),
        ContextualUsage(
          context: 'Division',
          description: 'Allocating responsibilities or items',
          examples: [
            'They split the household chores between them.',
            'The coach split the team into defensive and offensive units.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To leave a place, especially quickly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Let\'s split before the traffic gets heavy.',
        'She split as soon as the meeting ended.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Informal departure',
          description: 'Leaving quickly or suddenly',
          examples: [
            'We should split now if we want to catch the last train.',
            'He split when he saw his ex-girlfriend enter the restaurant.',
          ],
        ),
        ContextualUsage(
          context: 'Escape',
          description: 'Departing to avoid something',
          examples: [
            'They split when they heard the police sirens.',
            'Let\'s split before someone asks us to volunteer.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'deal',
  base: 'deal',
  past: 'dealt',
  participle: 'dealt',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'dil',
  pronunciationTextUK: 'diːl',
  meanings: [
    VerbMeaning(
      definition: 'To distribute or give out to a number of people',
      partOfSpeech: 'transitive verb',
      examples: [
        'The teacher dealt the test papers to the students.',
        'He dealt cards to each player at the table.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Cards',
          description: 'Distributing playing cards in games',
          examples: [
            'She dealt three cards to each player.',
            'In poker, the dealer deals clockwise around the table.',
          ],
        ),
        ContextualUsage(
          context: 'Distribution',
          description: 'Giving out items to multiple recipients',
          examples: [
            'The aid workers dealt food packages to the refugees.',
            'He dealt responsibilities to different team members.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take action in response to someone or something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The committee will deal with your complaint next week.',
        'She knows how to deal with difficult customers.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Problems',
          description: 'Handling challenging situations',
          examples: [
            'The manager dealt effectively with the crisis.',
            'We need to deal with this issue before it gets worse.',
          ],
        ),
        ContextualUsage(
          context: 'People',
          description: 'Interacting with or responding to others',
          examples: [
            'He deals well with pressure from his supervisors.',
            'Parents must learn to deal with children\'s tantrums calmly.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be involved in buying or selling a particular product',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The shop deals in rare books and manuscripts.',
        'Her family has dealt in antiques for generations.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Commerce',
          description: 'Trading in specific goods',
          examples: [
            'The company deals primarily in organic produce.',
            'These merchants deal in imported textiles.',
          ],
        ),
        ContextualUsage(
          context: 'Illicit trade',
          description: 'Selling illegal or controlled items',
          examples: [
            'He was arrested for dealing in stolen goods.',
            'The gang deals in counterfeit currency.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deliver a blow, action, or treatment to someone',
      partOfSpeech: 'transitive verb',
      examples: [
        'The boxer dealt his opponent a knockout punch.',
        'The scandal dealt a severe blow to his reputation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Impact',
          description: 'Causing significant effects on someone',
          examples: [
            'The news dealt a crushing blow to the family.',
            'The storm dealt extensive damage to coastal properties.',
          ],
        ),
        ContextualUsage(
          context: 'Consequences',
          description: 'Administering outcomes or results',
          examples: [
            'The judge dealt him a harsh sentence.',
            'The market dealt severe losses to investors that day.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'swing',
  base: 'swing',
  past: 'swung',
  participle: 'swung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'swɪŋ',
  pronunciationTextUK: 'swɪŋ',
  meanings: [
    VerbMeaning(
      definition: 'To move backward and forward or from side to side while suspended or on an axis',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The pendulum swung back and forth hypnotically.',
        'Her arms swung as she walked down the street.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Regular oscillating motion',
          examples: [
            'The child\'s legs swung happily as she sat on the high bench.',
            'The rope bridge swung alarmingly in the strong wind.',
          ],
        ),
        ContextualUsage(
          context: 'Mechanics',
          description: 'Motion around a fixed point',
          examples: [
            'The crane\'s arm swung around to pick up another load.',
            'The gate swung open when the latch was released.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move with a smooth, curving motion',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The car swung around the corner at high speed.',
        'She swung into action as soon as she heard the news.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Direction',
          description: 'Curved movement or turning',
          examples: [
            'The ship swung into port on the morning tide.',
            'He swung the flashlight beam across the dark room.',
          ],
        ),
        ContextualUsage(
          context: 'Transition',
          description: 'Moving from one state or activity to another',
          examples: [
            'The conversation swung from politics to sports.',
            'Public opinion swung dramatically after the scandal.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To hit or try to hit something with a sweeping motion',
      partOfSpeech: 'transitive verb',
      examples: [
        'The batter swung at the ball but missed.',
        'She swung her racket with perfect timing.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sports',
          description: 'Athletic striking motions',
          examples: [
            'The golfer swung the club with perfect form.',
            'He swung wildly at the incoming pitch.',
          ],
        ),
        ContextualUsage(
          context: 'Combat',
          description: 'Fighting or attacking motions',
          examples: [
            'The boxer swung a powerful right hook.',
            'He swung the axe, splitting the log in one strike.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or change rapidly from one position, condition, or direction to another',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The market swung between optimism and pessimism throughout the day.',
        'Her mood swung from depression to elation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Fluctuation',
          description: 'Variation between extremes',
          examples: [
            'Temperatures can swing dramatically in the desert between day and night.',
            'The political polls swung wildly in the weeks before the election.',
          ],
        ),
        ContextualUsage(
          context: 'Voting',
          description: 'Changes in political support',
          examples: [
            'The district swung from Republican to Democratic control.',
            'Key demographics swung toward the challenger in the final debate.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'tear',
  base: 'tear',
  past: 'tore',
  participle: 'torn',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'tɛr',
  pronunciationTextUK: 'teə',
  meanings: [
    VerbMeaning(
      definition: 'To pull or rip something apart or to pieces with force',
      partOfSpeech: 'transitive verb',
      examples: [
        'She tore the letter into tiny pieces.',
        'He accidentally tore his pants climbing over the fence.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Destruction',
          description: 'Deliberately damaging materials',
          examples: [
            'The protesters tore down the posters.',
            'She tore the contract in half after the deal fell through.',
          ],
        ),
        ContextualUsage(
          context: 'Fabric',
          description: 'Damaging cloth or textiles',
          examples: [
            'The child tore his new shirt on a nail.',
            'The curtains tore when she pulled them too roughly.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become ripped or split',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The paper bag tore when it got wet.',
        'This fabric tears easily along the seams.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Materials',
          description: 'Natural splitting or separating',
          examples: [
            'The sail tore during the storm at sea.',
            'The ancient document tore where it had been folded for centuries.',
          ],
        ),
        ContextualUsage(
          context: 'Weakness',
          description: 'Breaking at vulnerable points',
          examples: [
            'The thin plastic tore as soon as pressure was applied.',
            'The old map tore along its creases when unfolded.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pull or drag forcefully or with effort',
      partOfSpeech: 'transitive verb',
      examples: [
        'She tore herself away from the fascinating book.',
        'He tore the trapped child from the burning car.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Separation',
          description: 'Removing with force or effort',
          examples: [
            'The mother tore her child away from the dangerous edge.',
            'He tore the keys from her hand.',
          ],
        ),
        ContextualUsage(
          context: 'Emotional',
          description: 'Difficult or painful partings',
          examples: [
            'She was torn from her homeland as a refugee.',
            'The decision tore him between loyalty and ambition.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move with great speed and force',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The car tore down the highway at dangerous speed.',
        'He tore through the house looking for his lost keys.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Speed',
          description: 'Moving rapidly with urgency',
          examples: [
            'The children tore across the playground.',
            'The ambulance tore through traffic with sirens blaring.',
          ],
        ),
        ContextualUsage(
          context: 'Urgency',
          description: 'Hurried activity or search',
          examples: [
            'She tore through her closet looking for something to wear.',
            'The dog tore after the rabbit that had entered the yard.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'beat',
  base: 'beat',
  past: 'beat',
  participle: 'beaten',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bit',
  pronunciationTextUK: 'biːt',
  meanings: [
    VerbMeaning(
      definition: 'To strike repeatedly with an implement or against a surface',
      partOfSpeech: 'transitive verb',
      examples: [
        'She beat the rug to remove the dust.',
        'The chef beat the eggs until they were frothy.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Cooking',
          description: 'Mixing ingredients with force',
          examples: [
            'Beat the butter and sugar until light and fluffy.',
            'He beat the cream until it formed stiff peaks.',
          ],
        ),
        ContextualUsage(
          context: 'Percussion',
          description: 'Striking musical instruments',
          examples: [
            'The drummer beat a steady rhythm on the snare.',
            'She beat the tambourine in time with the music.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To defeat or overcome in a contest, competition, or battle',
      partOfSpeech: 'transitive verb',
      examples: [
        'Our team beat the champions in the final match.',
        'She beat all other candidates for the job.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sports',
          description: 'Winning against opponents',
          examples: [
            'They beat the home team by three goals.',
            'The underdog beat the champion in a surprising upset.',
          ],
        ),
        ContextualUsage(
          context: 'Competition',
          description: 'Surpassing rivals or challengers',
          examples: [
            'Her project beat all others to win first prize.',
            'The new smartphone beat its competitors in performance tests.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or strike with rhythmic motion',
      partOfSpeech: 'intransitive verb',
      examples: [
        'His heart beat faster as he approached the stage.',
        'Rain beat against the windows during the storm.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Biological',
          description: 'Rhythmic bodily functions',
          examples: [
            'Her pulse beat strongly after the exercise.',
            'Wings beating rapidly, the hummingbird hovered by the flower.',
          ],
        ),
        ContextualUsage(
          context: 'Weather',
          description: 'Repeated impact of natural elements',
          examples: [
            'The waves beat relentlessly against the shore.',
            'Hail beat down on the car roof with alarming force.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To surpass or exceed a mark, record, or expectation',
      partOfSpeech: 'transitive verb',
      examples: [
        'The new design beat all previous sales records.',
        'He beat his personal best time in the marathon.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Achievement',
          description: 'Surpassing established standards',
          examples: [
            'The athlete beat the world record by two seconds.',
            'Their production beat quarterly targets by 15 percent.',
          ],
        ),
        ContextualUsage(
          context: 'Probability',
          description: 'Overcoming unfavorable odds',
          examples: [
            'She beat the odds to survive a rare form of cancer.',
            'The small company beat expectations with its innovative product.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sink',
  base: 'sink',
  past: 'sank',
  participle: 'sunk',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sɪŋk',
  pronunciationTextUK: 'sɪŋk',
  meanings: [
    VerbMeaning(
      definition: 'To go down below the surface of a liquid or soft substance',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The ship sank after hitting an iceberg.',
        'His feet sank into the soft mud.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Water',
          description: 'Submersion of objects in liquid',
          examples: [
            'The stone sank quickly to the bottom of the pond.',
            'The damaged boat gradually sank beneath the waves.',
          ],
        ),
        ContextualUsage(
          context: 'Submersion',
          description: 'Entering soft materials',
          examples: [
            'Her high heels sank into the lawn during the garden party.',
            'The fence post sank deeper into the ground with each rainfall.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To decline or deteriorate in condition, quality, or value',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The company\'s stock sank to a record low.',
        'His reputation sank after the scandal.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Status',
          description: 'Decreasing in standing or position',
          examples: [
            'The once-mighty empire gradually sank into obscurity.',
            'Her spirits sank when she heard the disappointing news.',
          ],
        ),
        ContextualUsage(
          context: 'Financial',
          description: 'Declining in economic value',
          examples: [
            'Property values sank during the recession.',
            'The currency sank to its lowest level in a decade.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause something to submerge or descend',
      partOfSpeech: 'transitive verb',
      examples: [
        'The torpedo sank the enemy vessel.',
        'She sank the eight ball to win the game.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Destruction',
          description: 'Deliberately causing submersion',
          examples: [
            'The navy sank three enemy ships during the battle.',
            'Holes were drilled to sink the old ferry for an artificial reef.',
          ],
        ),
        ContextualUsage(
          context: 'Sports',
          description: 'Successfully completing a shot',
          examples: [
            'He sank a 30-foot putt to win the tournament.',
            'She sank the basketball through the hoop without touching the rim.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To insert, drive, or place downward or deeply',
      partOfSpeech: 'transitive verb',
      examples: [
        'They sank a well to access the underground water.',
        'He sank his teeth into the juicy apple.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Construction',
          description: 'Creating deep structures',
          examples: [
            'The company sank pillars deep into the bedrock to support the bridge.',
            'They sank a mine shaft over 1000 meters into the mountain.',
          ],
        ),
        ContextualUsage(
          context: 'Investment',
          description: 'Committing resources deeply',
          examples: [
            'She sank all her savings into the new business.',
            'The developer sank millions into the restoration project.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'freeze',
  base: 'freeze',
  past: 'froze',
  participle: 'frozen',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'friz',
  pronunciationTextUK: 'friːz',
  meanings: [
    VerbMeaning(
      definition: 'To become hardened into ice or similar solid due to extreme cold',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The lake froze over during the harsh winter.',
        'The water pipes froze and burst during the cold snap.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Weather',
          description: 'Natural solidification due to temperature',
          examples: [
            'The puddles froze overnight when temperatures dropped below zero.',
            'The fountain in the park froze solid in January.',
          ],
        ),
        ContextualUsage(
          context: 'Physical change',
          description: 'Liquids becoming solid',
          examples: [
            'The ice cream mixture froze in the ice cream maker.',
            'Their breath froze in the air on the coldest day of the year.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To feel extremely cold',
      partOfSpeech: 'intransitive verb',
      examples: [
        'I\'m freezing without my coat in this weather.',
        'They froze while waiting for the bus in the snow.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical sensation',
          description: 'Experiencing extreme coldness',
          examples: [
            'My hands are freezing after shoveling snow without gloves.',
            'The hikers were freezing in their wet clothes after falling in the stream.',
          ],
        ),
        ContextualUsage(
          context: 'Discomfort',
          description: 'Suffering from cold temperatures',
          examples: [
            'We were freezing in the poorly heated apartment all winter.',
            'The audience was freezing in the outdoor theater on that December night.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To preserve food by subjecting it to extreme cold',
      partOfSpeech: 'transitive verb',
      examples: [
        'She froze the berries for use during winter.',
        'I always freeze leftover soup in individual portions.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Food preservation',
          description: 'Storing food at low temperatures',
          examples: [
            'They freeze fresh vegetables from their garden every autumn.',
            'The fishermen freeze their catch immediately to maintain freshness.',
          ],
        ),
        ContextualUsage(
          context: 'Preparation',
          description: 'Readying food for storage',
          examples: [
            'Blanch the vegetables before you freeze them for best results.',
            'You should freeze the meat in airtight containers to prevent freezer burn.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become suddenly motionless or immobilized',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She froze when she heard a noise behind her.',
        'The deer froze in the headlights of the approaching car.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Fear response',
          description: 'Becoming immobile due to fear',
          examples: [
            'The rabbit froze when the hawk circled overhead.',
            'He froze on stage when he saw the size of the audience.',
          ],
        ),
        ContextualUsage(
          context: 'Surprise',
          description: 'Stopping suddenly due to unexpected events',
          examples: [
            'The children froze when their mother caught them taking cookies.',
            'Everyone in the office froze when the CEO unexpectedly walked in.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bend',
  base: 'bend',
  past: 'bent',
  participle: 'bent',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɛnd',
  pronunciationTextUK: 'bend',
  meanings: [
    VerbMeaning(
      definition: 'To cause to curve or become angular rather than straight or flat',
      partOfSpeech: 'transitive verb',
      examples: [
        'He bent the wire into a circle.',
        'She bent down to pick up the fallen book.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical alteration',
          description: 'Changing shape of objects',
          examples: [
            'The craftsman bent the metal rod to form the chair\'s armrest.',
            'You need to bend the pipe slightly to fit it around the corner.',
          ],
        ),
        ContextualUsage(
          context: 'Body movement',
          description: 'Folding parts of the body',
          examples: [
            'Bend your knees slightly when lifting heavy objects.',
            'The yoga instructor asked us to bend forward at the waist.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To turn or change direction',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The road bends sharply to the right after the bridge.',
        'The river bends around the small town.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Geography',
          description: 'Natural or constructed curves in landscape',
          examples: [
            'The path bends through the woods before reaching the lake.',
            'The coastline bends inward to form a protected bay.',
          ],
        ),
        ContextualUsage(
          context: 'Direction',
          description: 'Changing course or trajectory',
          examples: [
            'Light bends when it passes through water.',
            'The track bends around the mountain rather than going over it.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To adapt or make exceptions to rules or standards',
      partOfSpeech: 'transitive verb',
      examples: [
        'The school bent the rules to accommodate the student\'s special needs.',
        'We had to bend our schedule to fit in the unexpected meeting.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Flexibility',
          description: 'Adapting principles or policies',
          examples: [
            'The manager bent company policy in this exceptional case.',
            'They refused to bend their ethical standards despite the pressure.',
          ],
        ),
        ContextualUsage(
          context: 'Compromise',
          description: 'Making adjustments to accommodate others',
          examples: [
            'Both sides had to bend a little to reach the agreement.',
            'She won\'t bend on this issue—it\'s too important to her.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To direct or exert energy or attention toward a particular goal or purpose',
      partOfSpeech: 'transitive verb',
      examples: [
        'She bent all her efforts toward winning the competition.',
        'They bent their minds to solving the difficult problem.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Focus',
          description: 'Concentrating energy on specific objectives',
          examples: [
            'The team bent their collective will toward completing the project on time.',
            'He bent his considerable talents to writing a symphony.',
          ],
        ),
        ContextualUsage(
          context: 'Determination',
          description: 'Directing resolve toward goals',
          examples: [
            'The scientist bent her intellect to finding a cure for the disease.',
            'They bent their resources toward educational reform.',
          ],
        ),
      ],
    ),
  ],
),
VerbModel(
  id: 'feed',
  base: 'feed',
  past: 'fed',
  participle: 'fed',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fid',
  pronunciationTextUK: 'fiːd',
  meanings: [
    VerbMeaning(
      definition: 'To give food to someone or something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She feeds her cat twice a day.',
        'He fed the baby with a small spoon.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Care',
          description: 'Providing nourishment to dependents',
          examples: [
            'The nurse fed the elderly patient who couldn\'t manage alone.',
            'The zoo staff feeds the animals on a strict schedule.',
          ],
        ),
        ContextualUsage(
          context: 'Responsibility',
          description: 'Regular provision of meals',
          examples: [
            'She has to feed a family of six on a limited budget.',
            'The charity feeds hundreds of homeless people every day.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To supply or provide with something needed or desired',
      partOfSpeech: 'transitive verb',
      examples: [
        'The river feeds several small lakes.',
        'Solar panels feed electricity to the grid.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Supply',
          description: 'Providing essential resources',
          examples: [
            'Underground springs feed the town\'s water system.',
            'The power station feeds energy to three neighboring counties.',
          ],
        ),
        ContextualUsage(
          context: 'Input',
          description: 'Supplying data or materials to systems',
          examples: [
            'The sensors feed information to the central computer.',
            'They feed raw materials to the factory from local suppliers.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To eat or take food',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Cows feed on grass.',
        'The baby is feeding well.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Animals',
          description: 'Natural consumption of food',
          examples: [
            'Birds feed at dawn and dusk.',
            'The predators feed on smaller mammals in the ecosystem.',
          ],
        ),
        ContextualUsage(
          context: 'Nutrition',
          description: 'Process of taking nourishment',
          examples: [
            'The infant feeds every three hours.',
            'Some insects feed exclusively on nectar.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To gratify, encourage, or stimulate',
      partOfSpeech: 'transitive verb',
      examples: [
        'The media feeds people\'s curiosity about celebrities.',
        'Such comments only feed his ego.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotions',
          description: 'Intensifying emotional responses',
          examples: [
            'His praise fed her confidence before the performance.',
            'Sensationalist news feeds people\'s fears and anxieties.',
          ],
        ),
        ContextualUsage(
          context: 'Conflict',
          description: 'Sustaining or escalating disagreements',
          examples: [
            'Their arguments fed the tension between the two groups.',
            'Don\'t feed the conflict by repeating those rumors.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'learn',
  base: 'learn',
  past: 'learned',
  participle: 'learned',
  pastUK: 'learnt',
  pastUS: '',
  participleUK: 'learnt',
  participleUS: '',
  pronunciationTextUS: 'lɜrn',
  pronunciationTextUK: 'lɜːn',
  meanings: [
    VerbMeaning(
      definition: 'To gain knowledge or skill through study, experience, or being taught',
      partOfSpeech: 'transitive verb',
      examples: [
        'She learned French at school.',
        'He\'s learning to play the guitar.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Education',
          description: 'Formal acquisition of knowledge',
          examples: [
            'Students learn mathematics and science in high school.',
            'She learned advanced programming techniques at university.',
          ],
        ),
        ContextualUsage(
          context: 'Skills',
          description: 'Developing practical abilities',
          examples: [
            'He learned to swim when he was five years old.',
            'They\'re learning sign language to communicate with their deaf colleague.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become aware of something by information or observation',
      partOfSpeech: 'transitive verb',
      examples: [
        'I learned about her promotion from a colleague.',
        'We learned of his death through a newspaper article.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Information',
          description: 'Receiving and processing news',
          examples: [
            'She learned the truth about her adoption when she was eighteen.',
            'We learned about the changes to the schedule via email.',
          ],
        ),
        ContextualUsage(
          context: 'Discovery',
          description: 'Finding out previously unknown facts',
          examples: [
            'Researchers learned that the treatment had unexpected side effects.',
            'He learned his ancestry through DNA testing.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To commit to memory',
      partOfSpeech: 'transitive verb',
      examples: [
        'The actors had to learn their lines before rehearsals.',
        'She learned the poem by heart.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Memorization',
          description: 'Deliberately committing information to memory',
          examples: [
            'Children learn the alphabet through repetition and songs.',
            'Musicians learn complex pieces by practicing sections repeatedly.',
          ],
        ),
        ContextualUsage(
          context: 'Performance',
          description: 'Memorizing for presentation purposes',
          examples: [
            'She learned her speech for the competition.',
            'The choir learned the entire oratorio for the concert.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become conditioned or able to do something as a result of experience',
      partOfSpeech: 'transitive verb',
      examples: [
        'After getting caught in traffic several times, he learned to take an earlier bus.',
        'Dogs can learn to respond to dozens of different commands.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Adaptation',
          description: 'Changing behavior based on experience',
          examples: [
            'She quickly learned not to mention politics around her uncle.',
            'He learned to live with chronic pain after the accident.',
          ],
        ),
        ContextualUsage(
          context: 'Training',
          description: 'Behavioral conditioning through repetition',
          examples: [
            'The athlete learned to pace herself during long races.',
            'Children learn social behaviors by observing others.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'wind',
  base: 'wind',
  past: 'wound',
  participle: 'wound',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'waɪnd',
  pronunciationTextUK: 'waɪnd',
  meanings: [
    VerbMeaning(
      definition: 'To turn or twist something around a core or center',
      partOfSpeech: 'transitive verb',
      examples: [
        'She wound the thread around the spool.',
        'He wound the clock before going to bed.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Materials',
          description: 'Coiling flexible items around objects',
          examples: [
            'The electrician wound insulating tape around the exposed wires.',
            'She wound the yarn into a ball after finishing her knitting.',
          ],
        ),
        ContextualUsage(
          context: 'Mechanics',
          description: 'Turning mechanical components',
          examples: [
            'You need to wind the watch stem to keep it running accurately.',
            'He wound the music box to play a melody for his daughter.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move in a curving or twisting course',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The path winds through the forest.',
        'The river winds around the mountains.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Geography',
          description: 'Natural features with curved paths',
          examples: [
            'The road winds dangerously along the coastal cliffs.',
            'A small stream winds through the property.',
          ],
        ),
        ContextualUsage(
          context: 'Movement',
          description: 'Following a non-linear route',
          examples: [
            'The procession wound its way through the narrow streets.',
            'The hiking trail winds up the mountain to the summit.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To tighten the spring of a clockwork mechanism',
      partOfSpeech: 'transitive verb',
      examples: [
        'Don\'t forget to wind the alarm clock.',
        'He wound his watch before putting it on.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Timepieces',
          description: 'Preparing clocks or watches to run',
          examples: [
            'She winds the grandfather clock once a week.',
            'Automatic watches don\'t need to be wound by hand.',
          ],
        ),
        ContextualUsage(
          context: 'Toys',
          description: 'Preparing mechanical toys for operation',
          examples: [
            'The child wound up the toy car before placing it on the floor.',
            'He wound the mechanical bird until it started to sing.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To bring to a conclusion or gradually end',
      partOfSpeech: 'transitive verb',
      examples: [
        'It\'s time to wind up this meeting.',
        'The company is winding down its operations in that region.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Concluding commercial activities',
          examples: [
            'They\'re winding up the affairs of the bankrupt company.',
            'The project is winding down as it approaches completion.',
          ],
        ),
        ContextualUsage(
          context: 'Events',
          description: 'Bringing activities to a close',
          examples: [
            'The festival wound up with a spectacular fireworks display.',
            'She wound up her speech with a call to action.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'dig',
  base: 'dig',
  past: 'dug',
  participle: 'dug',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'dɪg',
  pronunciationTextUK: 'dɪg',
  meanings: [
    VerbMeaning(
      definition: 'To break up, turn over, or remove earth or soil with a tool or machine',
      partOfSpeech: 'transitive verb',
      examples: [
        'They dug a hole for the fence post.',
        'The archaeologists are digging for ancient artifacts.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Construction',
          description: 'Creating holes or trenches for building purposes',
          examples: [
            'Workers dug a trench for the new water pipe.',
            'We need to dig foundations before building the house.',
          ],
        ),
        ContextualUsage(
          context: 'Gardening',
          description: 'Preparing soil for planting',
          examples: [
            'He dug the vegetable beds every spring.',
            'She dug around the rosebush to add fertilizer.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To search for or extract something from beneath a surface',
      partOfSpeech: 'transitive verb',
      examples: [
        'They dug for gold in the mountains.',
        'The dog dug for the buried bone in the garden.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mining',
          description: 'Excavating for minerals or resources',
          examples: [
            'Miners dug coal from the seam deep underground.',
            'Companies are digging for rare earth minerals in remote areas.',
          ],
        ),
        ContextualUsage(
          context: 'Archaeology',
          description: 'Excavating for historical artifacts',
          examples: [
            'The team has been digging at the Roman site for three seasons.',
            'They dug up pottery fragments dating back thousands of years.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To investigate or research deeply',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The journalist dug into the politician\'s past.',
        'You\'ll need to dig deeper to find the root cause of the problem.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Research',
          description: 'Thorough investigation of information',
          examples: [
            'The detective dug through old case files looking for connections.',
            'Scientists are digging into the genetic causes of the disease.',
          ],
        ),
        ContextualUsage(
          context: 'Analysis',
          description: 'Examining issues thoroughly',
          examples: [
            'The auditors dug through financial records to uncover the fraud.',
            'Let\'s dig into these statistics to understand what they mean.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To like, appreciate, or understand something (informal)',
      partOfSpeech: 'transitive verb',
      examples: [
        'I really dig this new album.',
        'She doesn\'t dig classical music.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Appreciation',
          description: 'Enjoying or approving of things',
          examples: [
            'The audience really dug his performance last night.',
            'I dig your new haircut—it looks great!',
          ],
        ),
        ContextualUsage(
          context: 'Understanding',
          description: 'Comprehending or relating to concepts',
          examples: [
            'Do you dig what I\'m saying about this approach?',
            'He didn\'t dig the abstract art exhibition at all.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'hang',
  base: 'hang',
  past: 'hung',
  participle: 'hung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'hæŋ',
  pronunciationTextUK: 'hæŋ',
  meanings: [
    VerbMeaning(
      definition: 'To suspend or be suspended from above with the lower part dangling free',
      partOfSpeech: 'transitive verb',
      examples: [
        'He hung the painting on the wall.',
        'Christmas stockings were hung by the fireplace.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Decoration',
          description: 'Placing objects on vertical surfaces',
          examples: [
            'She hung curtains in all the windows.',
            'They hung family photographs throughout the hallway.',
          ],
        ),
        ContextualUsage(
          context: 'Storage',
          description: 'Suspending items for organization',
          examples: [
            'He hung his clothes neatly in the closet.',
            'The chef hung copper pots from the ceiling rack.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be suspended or poised; remain floating, supported, or attached in some way',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Mist hung over the valley in the early morning.',
        'The spider hung on its web.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Position',
          description: 'Remaining in a suspended state',
          examples: [
            'The chandelier hung elegantly from the high ceiling.',
            'Icicles hung from the edge of the roof all winter.',
          ],
        ),
        ContextualUsage(
          context: 'Atmosphere',
          description: 'Air or mood permeating a space',
          examples: [
            'Tension hung in the air during the difficult meeting.',
            'The scent of jasmine hung in the garden at dusk.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To spend time idly; loiter or linger',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Teenagers often hang around the shopping mall after school.',
        'She hung back as the others entered the room.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Socializing',
          description: 'Spending time casually with others',
          examples: [
            'We hung out at the beach all afternoon.',
            'They\'ve been hanging together since childhood.',
          ],
        ),
        ContextualUsage(
          context: 'Hesitation',
          description: 'Delaying or remaining behind',
          examples: [
            'He hung back from the group, unsure if he was welcome.',
            'She hung around after class to speak with the professor.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To attach or depend on something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'His future hangs on the outcome of the interview.',
        'The case hangs on one key piece of evidence.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Dependency',
          description: 'Being contingent on factors or outcomes',
          examples: [
            'The success of the project hangs on securing adequate funding.',
            'Our vacation plans hang on whether she can get time off work.',
          ],
        ),
        ContextualUsage(
          context: 'Unresolved',
          description: 'Remaining in an uncertain state',
          examples: [
            'The question hung unanswered throughout the discussion.',
            'Accusations hung over his career for years.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'lend',
  base: 'lend',
  past: 'lent',
  participle: 'lent',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'lɛnd',
  pronunciationTextUK: 'lend',
  meanings: [
    VerbMeaning(
      definition: 'To grant the use of something temporarily on the understanding that it will be returned',
      partOfSpeech: 'transitive verb',
      examples: [
        'She lent me her car for the weekend.',
        'Could you lend me some money until payday?',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Personal',
          description: 'Sharing possessions with friends or family',
          examples: [
            'He lent his brother his laptop to complete the assignment.',
            'I\'d be happy to lend you my umbrella for your walk home.',
          ],
        ),
        ContextualUsage(
          context: 'Financial',
          description: 'Providing money temporarily',
          examples: [
            'The bank lent them money to buy their first home.',
            'My parents lent me the down payment for my car.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To contribute or add a quality to something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The pianist\'s skill lends depth to the performance.',
        'The old buildings lend character to the neighborhood.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Enhancement',
          description: 'Adding positive attributes',
          examples: [
            'His experience lends credibility to the project.',
            'The spices lend flavor to an otherwise plain dish.',
          ],
        ),
        ContextualUsage(
          context: 'Atmosphere',
          description: 'Creating mood or ambiance',
          examples: [
            'The candles lent a romantic atmosphere to the dinner.',
            'Historical artifacts lend authenticity to the museum exhibition.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To provide assistance or support',
      partOfSpeech: 'transitive verb',
      examples: [
        'Would you lend me a hand with these boxes?',
        'She lent her support to the charity campaign.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Help',
          description: 'Offering practical assistance',
          examples: [
            'He lent his strength to moving the heavy furniture.',
            'The community lent assistance to those affected by the flood.',
          ],
        ),
        ContextualUsage(
          context: 'Endorsement',
          description: 'Providing backing or approval',
          examples: [
            'The celebrity lent her name to the environmental cause.',
            'Several experts lent their voices to the debate.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make available for use',
      partOfSpeech: 'reflexive verb',
      examples: [
        'The situation lends itself to various interpretations.',
        'This material lends itself well to draping.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Suitability',
          description: 'Being appropriate for particular purposes',
          examples: [
            'The open floor plan lends itself to casual entertaining.',
            'The novel lends itself perfectly to film adaptation.',
          ],
        ),
        ContextualUsage(
          context: 'Versatility',
          description: 'Having multiple potential applications',
          examples: [
            'This theoretical framework lends itself to various research areas.',
            'The software lends itself to both professional and amateur users.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sweep',
  base: 'sweep',
  past: 'swept',
  participle: 'swept',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'swip',
  pronunciationTextUK: 'swiːp',
  meanings: [
    VerbMeaning(
      definition: 'To clean or clear a surface with a brush or broom',
      partOfSpeech: 'transitive verb',
      examples: [
        'He swept the kitchen floor.',
        'She swept the fallen leaves off the patio.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Cleaning',
          description: 'Removing dirt or debris from surfaces',
          examples: [
            'The janitor swept the hallways every evening.',
            'I need to sweep the garage after woodworking projects.',
          ],
        ),
        ContextualUsage(
          context: 'Maintenance',
          description: 'Regular cleaning of areas',
          examples: [
            'Shopkeepers sweep the sidewalk in front of their stores.',
            'She swept the chimney before winter to prevent fires.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move swiftly and smoothly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The dancers swept across the ballroom floor.',
        'She swept into the room wearing an elegant gown.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Fluid, graceful motion',
          examples: [
            'The queen swept past the crowd of onlookers.',
            'Birds swept through the sky in perfect formation.',
          ],
        ),
        ContextualUsage(
          context: 'Entrance',
          description: 'Making dramatic or impressive arrivals',
          examples: [
            'He swept through the door with his usual confidence.',
            'The celebrity swept into the event surrounded by bodyguards.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To extend or move in a wide curve or range',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The road sweeps around the mountain.',
        'His gaze swept across the crowd, searching for a familiar face.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Landscape',
          description: 'Geographical features with curved shapes',
          examples: [
            'The bay sweeps in a gentle arc along the coastline.',
            'The mountain range sweeps from north to south.',
          ],
        ),
        ContextualUsage(
          context: 'Vision',
          description: 'Looking across a wide area',
          examples: [
            'The lighthouse beam swept across the dark water.',
            'Her eyes swept the room for potential threats.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To win completely or overwhelmingly',
      partOfSpeech: 'transitive verb',
      examples: [
        'The candidate swept the election with a large majority.',
        'Our team swept all the awards at the competition.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Competition',
          description: 'Winning all parts of a contest',
          examples: [
            'The baseball team swept the series, winning all four games.',
            'She swept the swimming events, taking gold in every race.',
          ],
        ),
        ContextualUsage(
          context: 'Dominance',
          description: 'Gaining comprehensive victory',
          examples: [
            'The film swept the Academy Awards that year.',
            'The new policy swept away all previous regulations.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'weave',
  base: 'weave',
  past: 'wove',
  participle: 'woven',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'wiv',
  pronunciationTextUK: 'wiːv',
  meanings: [
    VerbMeaning(
      definition: 'To form fabric by interlacing threads on a loom or by hand',
      partOfSpeech: 'transitive verb',
      examples: [
        'She weaves beautiful tapestries by hand.',
        'Traditional artisans weave intricate patterns into their rugs.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Textiles',
          description: 'Creating fabric through interlaced threads',
          examples: [
            'The community has woven baskets using this technique for generations.',
            'They weave silk fabrics using traditional methods.',
          ],
        ),
        ContextualUsage(
          context: 'Crafts',
          description: 'Making items through interlacing materials',
          examples: [
            'She wove the ribbons into a decorative wreath.',
            'Indigenous people weave palm leaves into practical household items.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To create a complex narrative or structure',
      partOfSpeech: 'transitive verb',
      examples: [
        'The author weaves multiple storylines into a coherent novel.',
        'He wove historical facts into his fictional account.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Storytelling',
          description: 'Constructing complex narratives',
          examples: [
            'The director wove together different time periods in the film.',
            'She wove her personal experiences into her poetry.',
          ],
        ),
        ContextualUsage(
          context: 'Integration',
          description: 'Combining diverse elements harmoniously',
          examples: [
            'The composer wove various musical themes throughout the symphony.',
            'He wove scientific data into his persuasive presentation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move in a twisting or zigzag manner',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The car weaved through the heavy traffic.',
        'She weaved her way through the crowded marketplace.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Navigation',
          description: 'Moving through obstacles with changing directions',
          examples: [
            'The motorcycle weaved dangerously between lanes.',
            'The runner weaved through the other competitors to take the lead.',
          ],
        ),
        ContextualUsage(
          context: 'Path',
          description: 'Following an indirect route',
          examples: [
            'The path weaves through the garden, revealing new views at every turn.',
            'The river weaves across the valley floor.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To sway or move unsteadily from side to side',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The drunk man was weaving as he walked down the street.',
        'The boxer weaved to avoid his opponent\'s punches.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Balance',
          description: 'Unsteady movement due to instability',
          examples: [
            'She was weaving from exhaustion after the marathon.',
            'The ship weaved in the heavy seas.',
          ],
        ),
        ContextualUsage(
          context: 'Sports',
          description: 'Deliberate evasive movements',
          examples: [
            'The basketball player weaved around defenders to reach the basket.',
            'Boxers weave to make themselves harder targets.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bleed',
  base: 'bleed',
  past: 'bled',
  participle: 'bled',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'blid',
  pronunciationTextUK: 'bliːd',
  meanings: [
    VerbMeaning(
      definition: 'To lose blood from the body as a result of injury or illness',
      partOfSpeech: 'intransitive verb',
      examples: [
        'His knee was bleeding after he fell off his bike.',
        'She cut her finger and it bled for several minutes.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Injury',
          description: 'Blood loss from physical trauma',
          examples: [
            'The wound bled profusely until pressure was applied.',
            'His nose started bleeding in the dry air.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Blood loss in clinical contexts',
          examples: [
            'The surgical site continued to bleed after the operation.',
            'Patients with hemophilia can bleed excessively from minor cuts.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To draw or extract money, resources, or people from a source',
      partOfSpeech: 'transitive verb',
      examples: [
        'High taxes are bleeding the company dry.',
        'The organization has been bled of its most talented employees.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Financial',
          description: 'Depleting monetary resources',
          examples: [
            'The failing division is bleeding the company\'s profits.',
            'Emergency expenses have been bleeding their savings account.',
          ],
        ),
        ContextualUsage(
          context: 'Resources',
          description: 'Gradual loss of assets or capabilities',
          examples: [
            'The ongoing conflict is bleeding the country of its resources.',
            'The brain drain is bleeding the region of skilled professionals.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To allow a liquid or gas to escape or leak out',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The radiator is bleeding water onto the floor.',
        'You need to bleed the air from the heating system.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mechanical',
          description: 'Releasing unwanted fluids from systems',
          examples: [
            'The mechanic bled the brake lines to remove air bubbles.',
            'You should bleed the radiator to improve heating efficiency.',
          ],
        ),
        ContextualUsage(
          context: 'Leakage',
          description: 'Unintentional escape of substances',
          examples: [
            'The damaged pipe bled water into the basement.',
            'The tank was bleeding fuel, creating a hazardous situation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To merge or run together, especially of colors or sounds',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The watercolors bled together, creating new shades.',
        'The music from different stages bled into each other at the festival.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Art',
          description: 'Colors merging or spreading',
          examples: [
            'The ink bled through the thin paper.',
            'Use special paper to prevent colors from bleeding in watercolor paintings.',
          ],
        ),
        ContextualUsage(
          context: 'Audio',
          description: 'Sounds mixing or interfering',
          examples: [
            'Sound from the headphones bled into the microphone recording.',
            'Different musical elements bleed together in this experimental piece.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sling',
  base: 'sling',
  past: 'slung',
  participle: 'slung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'slɪŋ',
  pronunciationTextUK: 'slɪŋ',
  meanings: [
    VerbMeaning(
      definition: 'To throw or hurl something with force',
      partOfSpeech: 'transitive verb',
      examples: [
        'He slung the backpack over his shoulder.',
        'She slung the ball across the field.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Forceful action',
          description: 'Throwing with significant energy',
          examples: [
            'The angry customer slung the defective product onto the counter.',
            'Children slung snowballs at each other during recess.',
          ],
        ),
        ContextualUsage(
          context: 'Movement',
          description: 'Rapid or casual placement',
          examples: [
            'He slung his jacket over the back of the chair.',
            'She slung her purse across her body before running to catch the bus.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To suspend or hang something so that it is supported from above',
      partOfSpeech: 'transitive verb',
      examples: [
        'They slung a hammock between two trees.',
        'The injured arm was slung in a bandage.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Support',
          description: 'Suspending items with support',
          examples: [
            'The workers slung a platform beneath the bridge for repairs.',
            'She slung the guitar across her back for the hike.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Supporting injured body parts',
          examples: [
            'The doctor slung his broken arm to immobilize it.',
            'Her sprained wrist was slung in a fabric support.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deliver or say something casually or aggressively',
      partOfSpeech: 'transitive verb',
      examples: [
        'He slung insults at his opponents.',
        'The critic slung harsh words about the performance.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Communication',
          description: 'Delivering words forcefully',
          examples: [
            'Politicians often sling accusations during heated debates.',
            'Don\'t sling blame around without knowing all the facts.',
          ],
        ),
        ContextualUsage(
          context: 'Criticism',
          description: 'Expressing negative opinions',
          examples: [
            'The rival companies slung mud at each other in their advertising.',
            'Critics slung disparaging remarks about the controversial artwork.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or go somewhere in a casual or careless manner',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He slung into the room late, disrupting the meeting.',
        'We were just slinging around town with no particular destination.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Moving in a relaxed or informal way',
          examples: [
            'Teenagers slung around the mall on Saturday afternoons.',
            'He slung into the chair, exhausted after the long day.',
          ],
        ),
        ContextualUsage(
          context: 'Casual activity',
          description: 'Spending time without specific purpose',
          examples: [
            'They were just slinging around, killing time before the concert.',
            'Instead of working, he was slinging around on social media all day.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'slide',
  base: 'slide',
  past: 'slid',
  participle: 'slid',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'slaɪd',
  pronunciationTextUK: 'slaɪd',
  meanings: [
    VerbMeaning(
      definition: 'To move smoothly along a surface while maintaining contact with it',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The drawer slides open easily.',
        'Children were sliding on the ice.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Smooth motion along surfaces',
          examples: [
            'The book slid off my lap onto the floor.',
            'The car slid on the wet road and nearly hit a tree.',
          ],
        ),
        ContextualUsage(
          context: 'Recreation',
          description: 'Deliberate sliding for fun',
          examples: [
            'Kids slide down the hill on cardboard boxes.',
            'She slid down the water slide with a splash.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or pass smoothly, quietly, or imperceptibly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The snake slid through the grass.',
        'Time seems to slide by quickly during vacation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Stealth',
          description: 'Moving without attracting notice',
          examples: [
            'He slid out of the meeting without anyone noticing.',
            'The thief slid into the room through the open window.',
          ],
        ),
        ContextualUsage(
          context: 'Transitions',
          description: 'Gradual changes or movements',
          examples: [
            'The conversation slid from casual chat to serious discussion.',
            'The sun slid behind the mountains at dusk.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move something along a smooth surface',
      partOfSpeech: 'transitive verb',
      examples: [
        'She slid the key across the table to him.',
        'He slid the box under the bed.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Transfer',
          description: 'Moving objects without lifting',
          examples: [
            'The bartender slid the drink toward the customer.',
            'I slid the note under her door.',
          ],
        ),
        ContextualUsage(
          context: 'Positioning',
          description: 'Placing objects with smooth motion',
          examples: [
            'She slid the bookmark between the pages.',
            'He slid the drawer shut quietly.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To decline or deteriorate gradually',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The company\'s stock price has been sliding for months.',
        'Her grades began to slide when she joined too many extracurricular activities.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Deterioration',
          description: 'Worsening of conditions or performance',
          examples: [
            'The economy continued to slide into recession.',
            'His health has been sliding since the diagnosis.',
          ],
        ),
        ContextualUsage(
          context: 'Failure',
          description: 'Progressive decline in success',
          examples: [
            'The once-successful restaurant has been sliding toward bankruptcy.',
            'Their relationship started sliding after the trust was broken.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'creep',
  base: 'creep',
  past: 'crept',
  participle: 'crept',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'krip',
  pronunciationTextUK: 'kriːp',
  meanings: [
    VerbMeaning(
      definition: 'To move slowly, quietly, and carefully, usually to avoid being noticed',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The cat crept toward the bird.',
        'He crept downstairs, trying not to wake anyone.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Stealth',
          description: 'Moving to avoid detection',
          examples: [
            'The burglar crept through the house in the darkness.',
            'She crept past her parents\' bedroom on her way out.',
          ],
        ),
        ContextualUsage(
          context: 'Caution',
          description: 'Moving carefully in difficult situations',
          examples: [
            'The soldiers crept through the minefield.',
            'He crept along the narrow ledge against the cliff face.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or develop gradually and steadily',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Fog crept over the hills.',
        'Doubt began to creep into her mind.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Progression',
          description: 'Slow, incremental advancement',
          examples: [
            'Urban development has been creeping into rural areas.',
            'Rust is creeping across the abandoned machinery.',
          ],
        ),
        ContextualUsage(
          context: 'Time',
          description: 'Gradual passage of time',
          examples: [
            'Evening crept upon them as they worked.',
            'Winter was creeping closer with each passing day.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To grow along the ground or other surfaces, as some plants do',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Ivy crept up the side of the old building.',
        'These ground-covering plants creep rather than growing upward.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Plants',
          description: 'Botanical growth patterns',
          examples: [
            'The vines had crept through the fence and into the neighboring garden.',
            'Creeping thyme forms a lovely carpet between stepping stones.',
          ],
        ),
        ContextualUsage(
          context: 'Growth',
          description: 'Expansion along surfaces',
          examples: [
            'Moss crept across the damp stones of the abandoned building.',
            'The strawberry plants crept outward, sending runners in all directions.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move slowly due to fatigue or difficulty',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Traffic was creeping along due to construction.',
        'He crept out of bed despite his illness.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Transport',
          description: 'Slow vehicle movement',
          examples: [
            'Cars crept through the heavy fog with their hazard lights on.',
            'The train crept into the station an hour behind schedule.',
          ],
        ),
        ContextualUsage(
          context: 'Difficulty',
          description: 'Moving despite impediments',
          examples: [
            'She crept along the icy sidewalk, afraid of falling.',
            'The wounded animal crept into the underbrush to hide.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'leap',
  base: 'leap',
  past: 'leapt',
  participle: 'leapt',
  pastUK: 'leapt',
  pastUS: 'leaped',
  participleUK: 'leapt',
  participleUS: 'leaped',
  pronunciationTextUS: 'lip',
  pronunciationTextUK: 'liːp',
  meanings: [
    VerbMeaning(
      definition: 'To jump or spring a long way, to a great height, or with great force',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The cat leapt onto the table.',
        'She leapt over the fence with ease.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical movement',
          description: 'Jumping for practical purposes',
          examples: [
            'He leapt across the stream to avoid getting wet.',
            'The dancer leapt high into the air during the performance.',
          ],
        ),
        ContextualUsage(
          context: 'Sports',
          description: 'Athletic jumping',
          examples: [
            'The basketball player leapt to block the shot.',
            'She leapt over the hurdles with perfect technique.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or act quickly or suddenly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She leapt to his defense during the argument.',
        'The stock market leapt after the positive economic news.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Reaction',
          description: 'Responding with immediate action',
          examples: [
            'He leapt into action when he saw the child in danger.',
            'Firefighters leapt to the scene of the emergency.',
          ],
        ),
        ContextualUsage(
          context: 'Change',
          description: 'Sudden increases or advancements',
          examples: [
            'Sales leapt by 30% after the new advertising campaign.',
            'Her career leapt forward after the successful project.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pass abruptly from one state or topic to another',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The conversation leapt from politics to personal matters.',
        'His mind leapt to the worst possible conclusion.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Thought',
          description: 'Quick transitions in thinking',
          examples: [
            'Her thoughts leapt ahead to plan the next steps.',
            'The discussion leapt between several unrelated topics.',
          ],
        ),
        ContextualUsage(
          context: 'Transitions',
          description: 'Skipping logical steps',
          examples: [
            'The story leaps from the protagonist\'s childhood to his retirement.',
            'Don\'t leap to conclusions before hearing all the evidence.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To undertake something in a sudden, impulsive way',
      partOfSpeech: 'transitive verb',
      examples: [
        'She leapt at the chance to study abroad.',
        'He leapt into the new business venture without much planning.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Opportunity',
          description: 'Seizing chances eagerly',
          examples: [
            'They leapt at the offer to buy the house below market value.',
            'Don\'t leap into a decision you might regret later.',
          ],
        ),
        ContextualUsage(
          context: 'Initiative',
          description: 'Taking action without hesitation',
          examples: [
            'She leapt into the project with enthusiasm.',
            'He leapt to volunteer before anyone else could.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'arise',
  base: 'arise',
  past: 'arose',
  participle: 'arisen',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'əˈraɪz',
  pronunciationTextUK: 'əˈraɪz',
  meanings: [
    VerbMeaning(
      definition: 'To get up from a lying or sitting position',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He arose from his chair when the director entered the room.',
        'She had arisen early to prepare for the journey.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Formal',
          description: 'Dignified rising from seated position',
          examples: [
            'The audience arose for the national anthem.',
            'The judge arose from the bench and left the courtroom.',
          ],
        ),
        ContextualUsage(
          context: 'Morning',
          description: 'Getting up from bed',
          examples: [
            'He arises at dawn every day to meditate.',
            'They had arisen before sunrise to catch the early train.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To come into existence, attention, or prominence',
      partOfSpeech: 'intransitive verb',
      examples: [
        'New problems arose during the project.',
        'A disagreement has arisen between the two departments.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emergence',
          description: 'Coming into being or notice',
          examples: [
            'A new political movement has arisen in response to the crisis.',
            'Questions arose about the methodology used in the study.',
          ],
        ),
        ContextualUsage(
          context: 'Development',
          description: 'Evolving or appearing over time',
          examples: [
            'Complications arose following the routine surgery.',
            'The need for regulation arose from repeated industry failures.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To originate from a source',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The custom arose from ancient religious practices.',
        'Their disagreement arose from a misunderstanding.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Causation',
          description: 'Resulting from specific factors',
          examples: [
            'The company\'s financial problems arose from poor management decisions.',
            'These symptoms arise from an imbalance in the body\'s chemistry.',
          ],
        ),
        ContextualUsage(
          context: 'Origins',
          description: 'Having specific beginnings or sources',
          examples: [
            'The legend arose among the indigenous people of the region.',
            'Modern astronomy arose from ancient stargazing traditions.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To ascend or move upward',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Smoke arose from the chimney.',
        'The moon has arisen above the horizon.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Natural phenomena',
          description: 'Upward movement in nature',
          examples: [
            'Mist arose from the valley floor as the sun warmed the earth.',
            'Heat waves arose from the desert sand in the midday sun.',
          ],
        ),
        ContextualUsage(
          context: 'Celestial',
          description: 'Appearance of heavenly bodies',
          examples: [
            'The sun arose in a cloudless sky that morning.',
            'Stars had arisen by the time they finished their dinner.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'grind',
  base: 'grind',
  past: 'ground',
  participle: 'ground',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'graɪnd',
  pronunciationTextUK: 'graɪnd',
  meanings: [
    VerbMeaning(
      definition: 'To reduce something to small particles or powder by crushing it',
      partOfSpeech: 'transitive verb',
      examples: [
        'She ground the coffee beans for brewing.',
        'The mill grinds wheat into flour.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Food preparation',
          description: 'Processing ingredients',
          examples: [
            'He ground the spices using a mortar and pestle.',
            'The machine grinds meat for hamburgers.',
          ],
        ),
        ContextualUsage(
          context: 'Industrial',
          description: 'Manufacturing processes',
          examples: [
            'The factory grinds plastic waste for recycling.',
            'Jewelers grind gemstones to create facets.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To rub or press surfaces together with force and friction',
      partOfSpeech: 'transitive verb',
      examples: [
        'He ground his teeth in frustration.',
        'The gears grind against each other when the machine is running.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mechanical',
          description: 'Friction between moving parts',
          examples: [
            'The worn brake pads ground against the rotors.',
            'You can hear the transmission grinding when changing gears.',
          ],
        ),
        ContextualUsage(
          context: 'Physical tension',
          description: 'Bodily manifestations of stress',
          examples: [
            'She grinds her teeth at night due to stress.',
            'The dancer ground her heel into the floor for emphasis.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To oppress or wear down through hardship or tedium',
      partOfSpeech: 'transitive verb',
      examples: [
        'The long hours were grinding him down.',
        'Poverty grinds people\'s spirits and opportunities.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Work',
          description: 'Exhausting labor conditions',
          examples: [
            'The factory job ground her down with its monotony.',
            'Constant deadlines are grinding the team\'s morale.',
          ],
        ),
        ContextualUsage(
          context: 'Hardship',
          description: 'Effects of difficult circumstances',
          examples: [
            'Economic pressures have ground small businesses out of existence.',
            'The constant criticism ground away at his confidence.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To work or study with great effort and determination',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She\'s been grinding for her exams all week.',
        'The team continued to grind despite being behind in the score.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Effort',
          description: 'Persistent hard work',
          examples: [
            'He\'s been grinding away at the project for months.',
            'Athletes need to grind through tough training sessions.',
          ],
        ),
        ContextualUsage(
          context: 'Gaming',
          description: 'Repetitive gameplay for advancement',
          examples: [
            'Players grind for hours to level up their characters.',
            'She\'s grinding to earn enough in-game currency for the rare item.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bind',
  base: 'bind',
  past: 'bound',
  participle: 'bound',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'baɪnd',
  pronunciationTextUK: 'baɪnd',
  meanings: [
    VerbMeaning(
      definition: 'To tie or fasten something tightly with rope, cord, or other material',
      partOfSpeech: 'transitive verb',
      examples: [
        'She bound the package with string.',
        'The captive\'s hands were bound behind his back.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Restraint',
          description: 'Securing objects or people with fasteners',
          examples: [
            'The police bound the suspect\'s wrists with handcuffs.',
            'He bound the books together with twine for easier carrying.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Wrapping injuries for support or protection',
          examples: [
            'The doctor bound the sprained ankle with a compression bandage.',
            'She bound her wrist for support while playing tennis.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To connect or hold together, as by adhesion or fusion',
      partOfSpeech: 'transitive verb',
      examples: [
        'The glue binds the pieces of wood together.',
        'Shared values bind the community together.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Chemistry',
          description: 'Molecular or material connections',
          examples: [
            'This agent binds the pigment particles to the fabric.',
            'Proteins bind to specific receptor sites on cells.',
          ],
        ),
        ContextualUsage(
          context: 'Relationships',
          description: 'Creating connections between people',
          examples: [
            'Common experiences bind people in friendship.',
            'The crisis bound the neighbors together in mutual support.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To impose legal or moral obligations on someone',
      partOfSpeech: 'transitive verb',
      examples: [
        'The contract binds both parties to specific terms.',
        'Her oath of office binds her to uphold the constitution.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legal',
          description: 'Creating enforceable obligations',
          examples: [
            'The court\'s decision binds all parties to comply with the ruling.',
            'This clause binds the tenant to maintain the property.',
          ],
        ),
        ContextualUsage(
          context: 'Commitment',
          description: 'Creating personal or moral obligations',
          examples: [
            'Marriage vows bind the couple to mutual support and fidelity.',
            'Professional ethics bind doctors to prioritize patient welfare.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To constrain or restrict movement, action, or capability',
      partOfSpeech: 'transitive verb',
      examples: [
        'Excessive regulations bind businesses and stifle innovation.',
        'Fear binds people from taking necessary risks.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Limitation',
          description: 'Creating restrictions on freedom',
          examples: [
            'Tradition bound women to domestic roles for centuries.',
            'His promise binds him from accepting other offers.',
          ],
        ),
        ContextualUsage(
          context: 'Function',
          description: 'Mechanical or physical restriction',
          examples: [
            'The rusty hinge binds when the door is opened too far.',
            'The drawer binds halfway due to warped wood.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spin',
  base: 'spin',
  past: 'spun',
  participle: 'spun',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'spɪn',
  pronunciationTextUK: 'spɪn',
  meanings: [
    VerbMeaning(
      definition: 'To rotate rapidly around an axis or center',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The wheel spun quickly as the car accelerated.',
        'The top spun on the table for nearly a minute.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Motion',
          description: 'Rotational movement',
          examples: [
            'The Earth spins on its axis once every 24 hours.',
            'The figure skater spun gracefully on the ice.',
          ],
        ),
        ContextualUsage(
          context: 'Machinery',
          description: 'Mechanical rotation',
          examples: [
            'The blades of the windmill spin in the breeze.',
            'The washing machine drum spins to remove excess water.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make thread by drawing out and twisting fibers',
      partOfSpeech: 'transitive verb',
      examples: [
        'She spins wool into yarn by hand.',
        'The factory spins cotton into thread for textiles.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Crafts',
          description: 'Traditional fiber processing',
          examples: [
            'Artisans spin silk from cocoons to create luxurious fabrics.',
            'She spins alpaca fiber on an antique spinning wheel.',
          ],
        ),
        ContextualUsage(
          context: 'Industry',
          description: 'Commercial thread production',
          examples: [
            'The mill spins thousands of yards of yarn daily.',
            'Special machines spin synthetic fibers for technical textiles.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To present information or a situation in a particular way, especially one favorable to oneself',
      partOfSpeech: 'transitive verb',
      examples: [
        'The politician spun the defeat as a moral victory.',
        'The company spun the layoffs as a necessary restructuring.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Media',
          description: 'Strategic communication',
          examples: [
            'The press secretary spun the controversial policy in a positive light.',
            'Advertisers spin ordinary products as revolutionary innovations.',
          ],
        ),
        ContextualUsage(
          context: 'Narrative',
          description: 'Creating persuasive stories',
          examples: [
            'The defense attorney spun a compelling narrative of innocence.',
            'Historians sometimes spin historical events to support modern ideologies.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To feel dizzy or disoriented',
      partOfSpeech: 'intransitive verb',
      examples: [
        'My head was spinning after the roller coaster ride.',
        'The room began to spin when she stood up too quickly.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical sensation',
          description: 'Perception of rotational movement',
          examples: [
            'His head spun from the effects of the medication.',
            'The room seemed to spin around her when she received the shocking news.',
          ],
        ),
        ContextualUsage(
          context: 'Mental state',
          description: 'Feeling overwhelmed or confused',
          examples: [
            'Her mind was spinning with all the new information.',
            'His thoughts spun wildly as he tried to process what had happened.',
          ],
        ),
      ],
    ),
  ],
),
VerbModel(
  id: 'strive',
  base: 'strive',
  past: 'strove',
  participle: 'striven',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'straɪv',
  pronunciationTextUK: 'straɪv',
  meanings: [
    VerbMeaning(
      definition: 'To make great efforts to achieve or obtain something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She strove to improve her language skills.',
        'They have striven for excellence in all their work.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Achievement',
          description: 'Working toward specific goals',
          examples: [
            'The athlete strove for years to reach Olympic level.',
            'He strove tirelessly to complete the project ahead of schedule.',
          ],
        ),
        ContextualUsage(
          context: 'Improvement',
          description: 'Efforts to better oneself or skills',
          examples: [
            'Students who strive for knowledge rather than grades often learn more.',
            'The company has striven to reduce its environmental impact.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To struggle or fight vigorously',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The drowning man strove against the current.',
        'The small business has striven against larger competitors.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Adversity',
          description: 'Battling against difficult circumstances',
          examples: [
            'They strove against poverty and discrimination.',
            'The resistance movement strove against the occupation.',
          ],
        ),
        ContextualUsage(
          context: 'Competition',
          description: 'Exerting effort to overcome rivals',
          examples: [
            'The team strove against more experienced opponents.',
            'Smaller nations strove to have their voices heard at the conference.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To aim or tend toward a condition or result',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The author strives for clarity in her writing.',
        'The organization strives toward greater inclusivity.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ideals',
          description: 'Working toward principles or values',
          examples: [
            'The community strives for social justice in all its initiatives.',
            'Good scientists strive for objectivity in their research.',
          ],
        ),
        ContextualUsage(
          context: 'Quality',
          description: 'Pursuing excellence or improvement',
          examples: [
            'The chef strives for perfection in every dish.',
            'The company strives to provide exceptional customer service.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To contend in opposition, conflict, or rivalry',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Political parties strove for power after the election.',
        'Various theories strove for acceptance in the scientific community.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Conflict',
          description: 'Competing directly against others',
          examples: [
            'Departments within the organization strove against each other for limited resources.',
            'The candidates strove to present themselves as the most qualified.',
          ],
        ),
        ContextualUsage(
          context: 'Rivalry',
          description: 'Ongoing competition between entities',
          examples: [
            'The two researchers have striven against each other for decades.',
            'Ancient city-states strove for regional dominance.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'stink',
  base: 'stink',
  past: 'stank',
  participle: 'stunk',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'stɪŋk',
  pronunciationTextUK: 'stɪŋk',
  meanings: [
    VerbMeaning(
      definition: 'To emit a strong unpleasant smell',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The garbage stank after sitting in the sun all day.',
        'His socks stink after the long hike.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Decomposition',
          description: 'Odors from decaying matter',
          examples: [
            'The fish had stunk up the entire refrigerator by the time they found it.',
            'The swamp stank of rotting vegetation and stagnant water.',
          ],
        ),
        ContextualUsage(
          context: 'Hygiene',
          description: 'Body odors from poor cleanliness',
          examples: [
            'The locker room stank of sweat after the game.',
            'His breath stank of garlic and cigarettes.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be extremely bad or unpleasant',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Their customer service really stinks.',
        'The movie stank so badly we left halfway through.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Performance',
          description: 'Poor quality execution or results',
          examples: [
            'The team\'s defense stank in the second half of the season.',
            'His presentation stank because he hadn\'t prepared adequately.',
          ],
        ),
        ContextualUsage(
          context: 'Disappointment',
          description: 'Failing to meet expectations',
          examples: [
            'This deal stinks compared to what they offered last month.',
            'The concert stank because the sound system kept failing.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be highly suspicious or questionable',
      partOfSpeech: 'intransitive verb',
      examples: [
        'This whole situation stinks of corruption.',
        'Their explanation stinks to high heaven.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Dishonesty',
          description: 'Indications of deception or wrongdoing',
          examples: [
            'The sudden resignation stinks of a cover-up.',
            'The deal stank of insider trading from the beginning.',
          ],
        ),
        ContextualUsage(
          context: 'Suspicion',
          description: 'Causing doubt or mistrust',
          examples: [
            'Their convenient alibi stinks of fabrication.',
            'The timing of the announcement stinks of political manipulation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be very bad at something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'I really stink at dancing.',
        'He stank at math in school.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Skills',
          description: 'Poor abilities or aptitude',
          examples: [
            'She admits she stinks at remembering names.',
            'I stink at drawing anything more complex than stick figures.',
          ],
        ),
        ContextualUsage(
          context: 'Performance',
          description: 'Executing tasks poorly',
          examples: [
            'The rookie stank during his first professional game.',
            'I stink at public speaking when I\'m nervous.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spring',
  base: 'spring',
  past: 'sprang',
  participle: 'sprung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sprɪŋ',
  pronunciationTextUK: 'sprɪŋ',
  meanings: [
    VerbMeaning(
      definition: 'To jump or leap suddenly or quickly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The cat sprang onto the counter.',
        'He sprang to his feet when his name was called.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Reaction',
          description: 'Quick physical responses',
          examples: [
            'She sprang back when the snake appeared on the path.',
            'The soldiers sprang into action at the sound of the alarm.',
          ],
        ),
        ContextualUsage(
          context: 'Movement',
          description: 'Rapid, energetic motion',
          examples: [
            'The gymnast sprang high into the air during her routine.',
            'The deer sprang away from the approaching hikers.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To appear or originate suddenly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Tears sprang to her eyes at the sad news.',
        'The idea sprang from a casual conversation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emergence',
          description: 'Sudden appearance or development',
          examples: [
            'New businesses have sprung up throughout the district.',
            'A smile sprang to his lips when he saw her.',
          ],
        ),
        ContextualUsage(
          context: 'Origin',
          description: 'Sources or beginnings',
          examples: [
            'The legend has sprung from actual historical events.',
            'Their friendship sprang from a shared interest in mountaineering.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To release from a constrained position with elastic force',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The lid sprang open when I pressed the button.',
        'The trap has sprung but caught nothing.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mechanics',
          description: 'Elastic or tensioned movement',
          examples: [
            'The jack-in-the-box sprang up, startling the child.',
            'The door sprang shut behind them as they entered.',
          ],
        ),
        ContextualUsage(
          context: 'Release',
          description: 'Sudden freedom from constraint',
          examples: [
            'The coiled wire sprang back to its original shape.',
            'The branch sprang upward when released from the weight of snow.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause to escape from confinement',
      partOfSpeech: 'transitive verb',
      examples: [
        'They sprang the hostages from the compound.',
        'The lawyer hopes to spring his client from jail.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Liberation',
          description: 'Freeing from captivity or constraint',
          examples: [
            'Animal rights activists sprang the laboratory animals from their cages.',
            'The team sprang their teammate from the hospital for his birthday celebration.',
          ],
        ),
        ContextualUsage(
          context: 'Surprise',
          description: 'Unexpected revelations or actions',
          examples: [
            'She sprang the news of her engagement at the family dinner.',
            'The prosecutor sprang a surprise witness during the trial.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'swear',
  base: 'swear',
  past: 'swore',
  participle: 'sworn',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'swɛr',
  pronunciationTextUK: 'sweə',
  meanings: [
    VerbMeaning(
      definition: 'To make a solemn promise or statement',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She swore to tell the whole truth in court.',
        'He swore that he would return before sunset.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legal',
          description: 'Formal oaths in official settings',
          examples: [
            'The witness swore on the Bible before giving testimony.',
            'New citizens swear allegiance to their adopted country.',
          ],
        ),
        ContextualUsage(
          context: 'Commitment',
          description: 'Personal promises or pledges',
          examples: [
            'They swore to remain friends forever.',
            'She has sworn never to speak to him again after what happened.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To use profane or obscene language',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He swore loudly when he hit his thumb with the hammer.',
        'She never swears in front of the children.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotion',
          description: 'Expletives triggered by strong feelings',
          examples: [
            'The driver swore at the cyclist who cut him off.',
            'Fans swore in frustration when their team lost in the final seconds.',
          ],
        ),
        ContextualUsage(
          context: 'Speech habits',
          description: 'Regular use of profanity',
          examples: [
            'Some people swear without even realizing they\'re doing it.',
            'He tends to swear more when he\'s with his old friends.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To affirm or promise emphatically',
      partOfSpeech: 'transitive verb',
      examples: [
        'I swear I had nothing to do with the missing files.',
        'She swore her innocence repeatedly during questioning.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Insistence',
          description: 'Strong assertions of truth',
          examples: [
            'He swore he had locked the door before leaving.',
            'She swears she saw someone in the garden last night.',
          ],
        ),
        ContextualUsage(
          context: 'Testimony',
          description: 'Formal declarations under oath',
          examples: [
            'The expert swore that the signature was a forgery.',
            'Witnesses swore to having seen the accused at the scene.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To induct into office or position with a formal oath',
      partOfSpeech: 'transitive verb',
      examples: [
        'The president will be sworn in on January 20th.',
        'The judge was sworn into office yesterday.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ceremony',
          description: 'Official installation proceedings',
          examples: [
            'The new board members were sworn in at the beginning of the meeting.',
            'She was sworn in as the first female governor of the state.',
          ],
        ),
        ContextualUsage(
          context: 'Profession',
          description: 'Entry into professional roles',
          examples: [
            'New police officers are sworn in after completing their training.',
            'The attorney was sworn into the bar association yesterday.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'strike',
  base: 'strike',
  past: 'struck',
  participle: 'struck',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'straɪk',
  pronunciationTextUK: 'straɪk',
  meanings: [
    VerbMeaning(
      definition: 'To hit or deliver a blow to someone or something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The boxer struck his opponent with a powerful right hook.',
        'Lightning struck the tree during the storm.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Impact',
          description: 'Physical collision or contact',
          examples: [
            'The hammer struck the nail with precision.',
            'The ship struck a reef and began taking on water.',
          ],
        ),
        ContextualUsage(
          context: 'Assault',
          description: 'Deliberate hitting in confrontation',
          examples: [
            'He was arrested for striking a police officer.',
            'The teacher struck the student, leading to immediate dismissal.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To occur suddenly or unexpectedly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Disaster struck when the dam broke during heavy rains.',
        'Inspiration struck in the middle of the night.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Events',
          description: 'Sudden occurrences of significance',
          examples: [
            'Panic struck the crowd when gunshots were heard.',
            'A brilliant idea struck her while she was in the shower.',
          ],
        ),
        ContextualUsage(
          context: 'Timing',
          description: 'Specific moments of occurrence',
          examples: [
            'The earthquake struck at 3:42 in the morning.',
            'Fear struck him as he realized he was being followed.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To refuse to work as a form of organized protest',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The factory workers struck over unsafe conditions.',
        'Teachers are threatening to strike if their demands aren\'t met.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Labor disputes',
          description: 'Work stoppages for better conditions',
          examples: [
            'The union voted to strike after negotiations broke down.',
            'Nurses struck for three days to protest understaffing.',
          ],
        ),
        ContextualUsage(
          context: 'Protest',
          description: 'Collective action for change',
          examples: [
            'Students struck to demand action on climate change.',
            'Transport workers struck during the busy holiday season.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To create something by removing material',
      partOfSpeech: 'transitive verb',
      examples: [
        'The mint struck a commemorative coin for the occasion.',
        'They struck a balance between cost and quality.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Manufacturing',
          description: 'Creating through impression or stamping',
          examples: [
            'The press struck thousands of medals for the champions.',
            'The goldsmith struck a pattern into the soft metal.',
          ],
        ),
        ContextualUsage(
          context: 'Agreements',
          description: 'Establishing terms or relationships',
          examples: [
            'The two companies struck a deal to collaborate on the project.',
            'They struck a compromise that satisfied both parties.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'cling',
  base: 'cling',
  past: 'clung',
  participle: 'clung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'klɪŋ',
  pronunciationTextUK: 'klɪŋ',
  meanings: [
    VerbMeaning(
      definition: 'To hold tightly or adhere to something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The wet shirt clung to his body.',
        'The child clung to her mother\'s hand in the crowd.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical adhesion',
          description: 'Surface attachment or contact',
          examples: [
            'The ivy clung to the brick wall of the old building.',
            'Wet leaves clung to the bottom of her shoes.',
          ],
        ),
        ContextualUsage(
          context: 'Grip',
          description: 'Holding firmly with hands',
          examples: [
            'The climber clung to the rock face during the sudden gust of wind.',
            'She clung to the railing as she descended the icy steps.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To remain emotionally attached or loyal to someone or something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She clung to the hope that he would return someday.',
        'He clung to his beliefs despite mounting evidence to the contrary.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Relationships',
          description: 'Emotional dependence on others',
          examples: [
            'After the divorce, he clung to his friends for support.',
            'The mother clung to her adult children, unable to let them live independently.',
          ],
        ),
        ContextualUsage(
          context: 'Ideas',
          description: 'Persistent adherence to concepts',
          examples: [
            'Some people cling to outdated traditions out of fear of change.',
            'She clung to her innocence throughout the investigation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To persist or continue despite difficulty',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The smell of smoke clung to the room for days.',
        'Doubts clung to his mind about the decision.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Persistence',
          description: 'Lasting or remaining present',
          examples: [
            'The stigma of failure clung to the company for years.',
            'The fog clung to the valley until midday.',
          ],
        ),
        ContextualUsage(
          context: 'Memory',
          description: 'Retained thoughts or impressions',
          examples: [
            'The haunting melody clung to her thoughts all day.',
            'The memory of that terrible day clung to her for decades.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To stay very close to something for protection or security',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The boats clung to the shore during the storm.',
        'The hikers clung to the marked trail, afraid of getting lost.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Safety',
          description: 'Remaining near secure places',
          examples: [
            'The children clung to familiar surroundings after the move.',
            'Their ship clung to the coastline rather than venturing into open water.',
          ],
        ),
        ContextualUsage(
          context: 'Caution',
          description: 'Avoiding risk through proximity',
          examples: [
            'Investors clung to safe assets during market volatility.',
            'The small mammals clung to the edges of the forest, avoiding open spaces.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'fling',
  base: 'fling',
  past: 'flung',
  participle: 'flung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'flɪŋ',
  pronunciationTextUK: 'flɪŋ',
  meanings: [
    VerbMeaning(
      definition: 'To throw or hurl with force or energy',
      partOfSpeech: 'transitive verb',
      examples: [
        'She flung the ball across the field.',
        'He flung his backpack onto the couch.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Force',
          description: 'Throwing with intensity or anger',
          examples: [
            'The child flung the toy across the room in a tantrum.',
            'The protestor flung paint at the building.',
          ],
        ),
        ContextualUsage(
          context: 'Dismissal',
          description: 'Discarding things carelessly',
          examples: [
            'She flung the rejection letter into the trash.',
            'He flung his wet coat onto the radiator to dry.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move one\'s body or limbs in a sudden, energetic way',
      partOfSpeech: 'reflexive verb',
      examples: [
        'She flung herself into his arms.',
        'He flung himself onto the bed, exhausted.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Dramatic or sudden body motion',
          examples: [
            'The dancer flung her arms wide at the climax of the music.',
            'He flung himself at the ball to make the save.',
          ],
        ),
        ContextualUsage(
          context: 'Emotion',
          description: 'Physical expressions of feeling',
          examples: [
            'She flung her head back and laughed heartily.',
            'The actor flung himself to his knees in the dramatic scene.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To direct words or insults forcefully',
      partOfSpeech: 'transitive verb',
      examples: [
        'He flung accusations at his opponents.',
        'Critics flung harsh words at the controversial film.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Argument',
          description: 'Verbal attacks in disputes',
          examples: [
            'The politicians flung insults at each other during the debate.',
            'She flung criticisms at the proposal without offering alternatives.',
          ],
        ),
        ContextualUsage(
          context: 'Criticism',
          description: 'Harsh or sudden negative feedback',
          examples: [
            'Reviewers flung scathing critiques at the author\'s new book.',
            'The coach flung angry remarks at the referee after the call.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To engage in a short period of unrestrained activity or indulgence',
      partOfSpeech: 'noun phrase',
      examples: [
        'They had a brief fling before he moved abroad.',
        'Her shopping fling left her credit card maxed out.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Romance',
          description: 'Short-term romantic relationships',
          examples: [
            'Their summer fling ended when vacation was over.',
            'He had a fling with a coworker during a business trip.',
          ],
        ),
        ContextualUsage(
          context: 'Indulgence',
          description: 'Brief periods of excess or freedom',
          examples: [
            'After graduation, she had a fling with adventure sports.',
            'His fling with expensive dining lasted until his bonus ran out.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shrink',
  base: 'shrink',
  past: 'shrank',
  participle: 'shrunk',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʃrɪŋk',
  pronunciationTextUK: 'ʃrɪŋk',
  meanings: [
    VerbMeaning(
      definition: 'To become smaller in size, amount, or extent',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The sweater shrank in the dryer.',
        'Their savings have shrunk considerably during the recession.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical reduction',
          description: 'Decrease in physical dimensions',
          examples: [
            'The tumor had shrunk after treatment.',
            'The wool fabric shrank when washed in hot water.',
          ],
        ),
        ContextualUsage(
          context: 'Diminishment',
          description: 'Reduction in quantity or volume',
          examples: [
            'The lake has shrunk due to drought conditions.',
            'Their market share has shrunk since the new competitor arrived.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To draw back or away, especially due to fear or dislike',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She shrank from his touch.',
        'The child shrank into the corner when the stranger entered.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Fear',
          description: 'Recoiling due to fright or anxiety',
          examples: [
            'The dog shrank back when the larger animal approached.',
            'He shrank from the responsibility of leadership.',
          ],
        ),
        ContextualUsage(
          context: 'Aversion',
          description: 'Moving away from unpleasant things',
          examples: [
            'Many people shrink from confrontation whenever possible.',
            'She shrank from the sight of blood during the medical procedure.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause something to become smaller',
      partOfSpeech: 'transitive verb',
      examples: [
        'The company has shrunk its workforce by 10%.',
        'This detergent will shrink your clothes if you\'re not careful.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Manufacturing',
          description: 'Deliberate reduction in production',
          examples: [
            'They shrunk the size of candy bars while keeping the price the same.',
            'The design team shrunk the device to make it more portable.',
          ],
        ),
        ContextualUsage(
          context: 'Business',
          description: 'Reducing operations or scope',
          examples: [
            'Management shrunk the budget for research and development.',
            'They\'ve shrunk their international presence to focus on domestic markets.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To act as a psychiatrist or psychotherapist',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He\'s been shrinking for over twenty years.',
        'She shrinks at a clinic downtown.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Slang',
          description: 'Informal term for psychiatric practice',
          examples: [
            'He\'s been shrinking since he got his medical degree.',
            'Some of Hollywood\'s elite pay top dollar to shrink with the famous Dr. Miller.',
          ],
        ),
        ContextualUsage(
          context: 'Profession',
          description: 'Working in mental health field',
          examples: [
            'She shrinks for four days a week and teaches at the university on Fridays.',
            'He shrinks primarily with trauma victims and veterans.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'blow',
  base: 'blow',
  past: 'blew',
  participle: 'blown',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bloʊ',
  pronunciationTextUK: 'bləʊ',
  meanings: [
    VerbMeaning(
      definition: 'To move and create a current of air, as wind',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The wind blew fiercely all night.',
        'A cool breeze was blowing from the ocean.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Weather',
          description: 'Air movement in natural environment',
          examples: [
            'A storm was blowing in from the north.',
            'The wind blew the fallen leaves into piles.',
          ],
        ),
        ContextualUsage(
          context: 'Sensory',
          description: 'Feeling air movement',
          examples: [
            'I could feel the wind blowing through my hair.',
            'The curtains moved gently as the evening breeze blew through the window.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To force air from the mouth or nose',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She blew on her hot coffee to cool it down.',
        'He blew out all the candles on his birthday cake.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Cooling',
          description: 'Directing breath to reduce temperature',
          examples: [
            'The child blew on the spoonful of soup before eating it.',
            'She blew across the top of her tea to cool it.',
          ],
        ),
        ContextualUsage(
          context: 'Performance',
          description: 'Playing wind instruments',
          examples: [
            'She blew into the trumpet with great skill.',
            'He blew across the flute to produce a clear note.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To explode or break apart suddenly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The tire blew while they were driving on the highway.',
        'The old building blew up after the gas leak.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Destruction',
          description: 'Violent rupture or explosion',
          examples: [
            'The engine blew after years of poor maintenance.',
            'The dam blew under pressure from the flood waters.',
          ],
        ),
        ContextualUsage(
          context: 'Electronics',
          description: 'Failure of electrical components',
          examples: [
            'The fuse blew when too many appliances were running simultaneously.',
            'The power transformer blew during the lightning storm.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To squander or waste, especially money',
      partOfSpeech: 'transitive verb',
      examples: [
        'He blew his entire paycheck on gambling.',
        'She blew their savings on an impulse purchase.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Finance',
          description: 'Spending money carelessly',
          examples: [
            'They blew the budget on unnecessary expenses.',
            'He blew a fortune on luxury cars he couldn\'t afford.',
          ],
        ),
        ContextualUsage(
          context: 'Opportunity',
          description: 'Wasting chances or advantages',
          examples: [
            'The team blew their lead in the final quarter.',
            'She blew the job interview by arriving late.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'kneel',
  base: 'kneel',
  past: 'knelt',
  participle: 'knelt',
  pastUK: 'knelt',
  pastUS: 'kneeled',
  participleUK: 'knelt',
  participleUS: 'kneeled',
  pronunciationTextUS: 'nil',
  pronunciationTextUK: 'niːl',
  meanings: [
    VerbMeaning(
      definition: 'To position the body so that one or both knees rest on the ground',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He knelt to examine the injured dog.',
        'She knelt by the bed to pray.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical position',
          description: 'Practical posture for ground-level tasks',
          examples: [
            'The gardener knelt to pull weeds from the flower bed.',
            'He knelt to tie his child\'s shoelaces.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Position for providing care',
          examples: [
            'The paramedic knelt beside the injured cyclist.',
            'The nurse knelt to be at eye level with the young patient.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To adopt a position of supplication, reverence, or submission',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The faithful knelt in prayer.',
        'He knelt before the king.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Religion',
          description: 'Ritual posture in worship',
          examples: [
            'The congregation knelt for the blessing.',
            'Muslims kneel during their daily prayers.',
          ],
        ),
        ContextualUsage(
          context: 'Ceremony',
          description: 'Formal gestures of respect',
          examples: [
            'The knight knelt to receive his accolade.',
            'She knelt before the queen during the investiture ceremony.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To yield or show deference',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The company refuses to kneel to market pressures.',
        'He would never kneel to intimidation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Figurative',
          description: 'Symbolic submission or resistance',
          examples: [
            'The small nation will not kneel to threats from larger powers.',
            'She never kneels to political pressure in her journalism.',
          ],
        ),
        ContextualUsage(
          context: 'Protest',
          description: 'Physical gesture with political meaning',
          examples: [
            'Athletes knelt during the national anthem as a form of protest.',
            'Demonstrators knelt in silence to honor victims of violence.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To rest on or as if on knees',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The house kneels on the hillside overlooking the valley.',
        'Ancient trees kneel with age, their branches touching the ground.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Poetic',
          description: 'Metaphorical description of objects',
          examples: [
            'The old barn kneels in the field, its beams bent with time.',
            'Mountains kneel before the vast expanse of sky.',
          ],
        ),
        ContextualUsage(
          context: 'Architecture',
          description: 'Structural positioning or appearance',
          examples: [
            'The cottage kneels low against the harsh coastal winds.',
            'The building appears to kneel, with its lower floors wider than its upper ones.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'thrive',
  base: 'thrive',
  past: 'thrived',
  participle: 'thrived',
  pastUK: 'throve',
  pastUS: 'thrived',
  participleUK: 'thriven',
  participleUS: 'thrived',
  pronunciationTextUS: 'θraɪv',
  pronunciationTextUK: 'θraɪv',
  meanings: [
    VerbMeaning(
      definition: 'To grow vigorously and healthily',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The plants thrive in warm, humid conditions.',
        'Children thrive when they receive love and attention.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Nature',
          description: 'Robust growth of living organisms',
          examples: [
            'These native species thrive in the harsh desert climate.',
            'The garden is thriving after the recent rainfall.',
          ],
        ),
        ContextualUsage(
          context: 'Development',
          description: 'Healthy growth in children or animals',
          examples: [
            'Babies thrive on a consistent routine.',
            'The rescued animals are thriving in their new sanctuary.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To prosper or flourish in particular conditions or circumstances',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Some businesses thrive during economic downturns.',
        'She thrives under pressure.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Commercial success or expansion',
          examples: [
            'Local restaurants thrived when they adopted delivery services.',
            'The company has thrived for decades despite intense competition.',
          ],
        ),
        ContextualUsage(
          context: 'Adaptability',
          description: 'Success in challenging situations',
          examples: [
            'Creative industries thrive in urban environments.',
            'She thrives in fast-paced, high-pressure work environments.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To advance or progress toward a goal despite obstacles',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The project thrived despite limited funding.',
        'Their relationship has thrived through difficult times.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Resilience',
          description: 'Continuing success despite challenges',
          examples: [
            'The school has thrived despite budget cuts.',
            'Some artists thrive in the face of criticism.',
          ],
        ),
        ContextualUsage(
          context: 'Growth',
          description: 'Continuous improvement or development',
          examples: [
            'The online community thrived as more people joined and contributed.',
            'The theater company thrived by constantly innovating its productions.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To experience positive outcomes from particular actions or behaviors',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Athletes thrive on rigorous training and proper nutrition.',
        'The economy thrives when consumer confidence is high.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Health',
          description: 'Physical wellbeing from beneficial practices',
          examples: [
            'The human body thrives with regular exercise and proper nutrition.',
            'Her mental health thrived once she established better work-life balance.',
          ],
        ),
        ContextualUsage(
          context: 'Productivity',
          description: 'Enhanced performance in favorable conditions',
          examples: [
            'Creative thinking thrives in environments that encourage risk-taking.',
            'Teams thrive when members feel valued and heard.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bear',
  base: 'bear',
  past: 'bore',
  participle: 'borne',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɛr',
  pronunciationTextUK: 'beə',
  meanings: [
    VerbMeaning(
      definition: 'To carry or support the weight of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The pillars bear the weight of the roof.',
        'He couldn\'t bear the heavy backpack any longer.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical support',
          description: 'Holding or supporting weight',
          examples: [
            'The bridge is designed to bear heavy traffic loads.',
            'The ice was too thin to bear their weight.',
          ],
        ),
        ContextualUsage(
          context: 'Engineering',
          description: 'Structural support capacity',
          examples: [
            'These beams can bear up to five tons of pressure.',
            'The foundation must bear the load of the entire building.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To endure something difficult or painful',
      partOfSpeech: 'transitive verb',
      examples: [
        'She couldn\'t bear the thought of leaving her hometown.',
        'He bore the pain without complaining.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Tolerating psychological discomfort',
          examples: [
            'I can\'t bear to see you so unhappy.',
            'She bore the criticism with remarkable composure.',
          ],
        ),
        ContextualUsage(
          context: 'Hardship',
          description: 'Enduring difficult circumstances',
          examples: [
            'The community has borne many hardships over the years.',
            'They bore the harsh winter with limited supplies.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To give birth to offspring',
      partOfSpeech: 'transitive verb',
      examples: [
        'She bore five children during her lifetime.',
        'The cat bore a litter of six kittens.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Human reproduction',
          description: 'Pregnancy and childbirth',
          examples: [
            'She bore twins after a difficult pregnancy.',
            'Women who have borne children may experience certain health issues.',
          ],
        ),
        ContextualUsage(
          context: 'Biology',
          description: 'Animal reproduction',
          examples: [
            'The mare bore a healthy foal in the spring.',
            'Older elephants often help younger ones when they bear calves.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To produce or yield something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The apple tree bears fruit every autumn.',
        'His investments bore excellent returns.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Agriculture',
          description: 'Plant production of crops',
          examples: [
            'These vines bear grapes for premium wines.',
            'The old tree still bears abundant fruit each year.',
          ],
        ),
        ContextualUsage(
          context: 'Results',
          description: 'Producing outcomes or consequences',
          examples: [
            'Their research bore significant results for cancer treatment.',
            'His hard work finally bore fruit when he was promoted.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'slay',
  base: 'slay',
  past: 'slew',
  participle: 'slain',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sleɪ',
  pronunciationTextUK: 'sleɪ',
  meanings: [
    VerbMeaning(
      definition: 'To kill a person or animal in a violent way',
      partOfSpeech: 'transitive verb',
      examples: [
        'The knight slew the dragon with his sword.',
        'The warrior slew his enemies in battle.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mythology',
          description: 'Killing legendary creatures or enemies',
          examples: [
            'Hercules slew the Nemean Lion as his first labor.',
            'The hero slew the monster and rescued the village.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Deadly combat in past eras',
          examples: [
            'The king\'s soldiers slew all who opposed them.',
            'Many warriors were slain during the ancient battle.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To impress or amuse someone greatly (informal)',
      partOfSpeech: 'transitive verb',
      examples: [
        'Her performance slew the audience.',
        'The comedian slew them with his hilarious routine.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Entertainment',
          description: 'Exceptionally successful performances',
          examples: [
            'She slays every time she performs that song live.',
            'His dance moves slew the judges on the competition show.',
          ],
        ),
        ContextualUsage(
          context: 'Social media',
          description: 'Creating impressive content or appearance',
          examples: [
            'Her outfit absolutely slew at the fashion event.',
            'Their new video slew online, getting millions of views.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To overwhelm or greatly affect someone emotionally',
      partOfSpeech: 'transitive verb',
      examples: [
        'The news of her success slew her parents with pride.',
        'His heartfelt speech slew everyone in the room.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional impact',
          description: 'Causing strong feelings in others',
          examples: [
            'The movie\'s ending slew me; I couldn\'t stop crying.',
            'Her story of perseverance slew the interviewers.',
          ],
        ),
        ContextualUsage(
          context: 'Attraction',
          description: 'Creating strong romantic or sexual interest',
          examples: [
            'He was completely slain by her beauty and intelligence.',
            'Her charming personality slew everyone at the party.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To destroy or put an end to something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The new evidence slew the prosecution\'s case.',
        'Her rebuttal slew all his arguments.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Debate',
          description: 'Decisively defeating opposing viewpoints',
          examples: [
            'She slew his theory with irrefutable evidence.',
            'The scientist slew the misconceptions with clear data.',
          ],
        ),
        ContextualUsage(
          context: 'Competition',
          description: 'Soundly defeating rivals',
          examples: [
            'Our team slew the competition at the championship.',
            'The startup slew established businesses in the market.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sow',
  base: 'sow',
  past: 'sowed',
  participle: 'sown',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'soʊ',
  pronunciationTextUK: 'səʊ',
  meanings: [
    VerbMeaning(
      definition: 'To plant seeds in the ground',
      partOfSpeech: 'transitive verb',
      examples: [
        'The farmer sowed wheat in the field.',
        'We sowed grass seed on the bare patches of the lawn.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Agriculture',
          description: 'Planting crops for cultivation',
          examples: [
            'They sowed barley in the spring and harvested it in the fall.',
            'The community garden allows residents to sow vegetables of their choice.',
          ],
        ),
        ContextualUsage(
          context: 'Gardening',
          description: 'Planting ornamental or domestic plants',
          examples: [
            'She sowed wildflower seeds along the border of her garden.',
            'It\'s best to sow these perennials directly where you want them to grow.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To spread or scatter something widely',
      partOfSpeech: 'transitive verb',
      examples: [
        'The wind sowed leaves across the yard.',
        'Dandelions sow their seeds with the help of the breeze.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Distribution',
          description: 'Natural dispersal of materials',
          examples: [
            'The volcano sowed ash over a wide area.',
            'Flooding sowed debris throughout the town.',
          ],
        ),
        ContextualUsage(
          context: 'Natural propagation',
          description: 'Plant reproduction methods',
          examples: [
            'This species sows its seeds by attaching them to animal fur.',
            'The tree sows thousands of seeds each year, but few survive.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To implant or introduce something that develops or takes root',
      partOfSpeech: 'transitive verb',
      examples: [
        'The professor sowed the seeds of scientific curiosity in her students.',
        'The speech sowed doubt in the minds of many voters.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ideas',
          description: 'Introducing concepts or thoughts',
          examples: [
            'The book sowed revolutionary ideas that flourished years later.',
            'His mentorship sowed confidence in a generation of young professionals.',
          ],
        ),
        ContextualUsage(
          context: 'Emotions',
          description: 'Creating lasting feelings or reactions',
          examples: [
            'The scandal sowed distrust between the partners.',
            'Their kindness sowed gratitude in the community.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To establish the foundation for future developments',
      partOfSpeech: 'transitive verb',
      examples: [
        'The treaty sowed the seeds for decades of peace.',
        'Their early research sowed the groundwork for modern computing.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legacy',
          description: 'Creating lasting impact or influence',
          examples: [
            'The founding fathers sowed principles that still guide the nation.',
            'Her pioneering work sowed the foundations for future discoveries.',
          ],
        ),
        ContextualUsage(
          context: 'Consequences',
          description: 'Actions with long-term effects',
          examples: [
            'The decision sowed the seeds of the company\'s eventual downfall.',
            'These economic policies have sown prosperity for generations.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'flee',
  base: 'flee',
  past: 'fled',
  participle: 'fled',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fli',
  pronunciationTextUK: 'fliː',
  meanings: [
    VerbMeaning(
      definition: 'To run away from a place or situation of danger or discomfort',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The family fled from the burning building.',
        'Thousands fled the country during the civil war.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emergency',
          description: 'Escaping immediate physical danger',
          examples: [
            'People fled the coastal areas as the hurricane approached.',
            'The prisoners fled when the guards weren\'t looking.',
          ],
        ),
        ContextualUsage(
          context: 'Migration',
          description: 'Leaving regions due to conflict or hardship',
          examples: [
            'Refugees fled persecution in their homeland.',
            'Many families fled drought-stricken areas in search of water.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move away from someone or something very quickly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The deer fled when it sensed the hunters.',
        'Sleep fled from him despite his exhaustion.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Wildlife',
          description: 'Animal escape behaviors',
          examples: [
            'The rabbit fled into its burrow when the hawk appeared.',
            'Zebras flee from predators in coordinated groups.',
          ],
        ),
        ContextualUsage(
          context: 'Avoidance',
          description: 'Escaping uncomfortable situations',
          examples: [
            'He fled the party when his ex-girlfriend arrived.',
            'She fled the room to hide her tears.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To vanish or disappear suddenly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'All hope fled as they heard the diagnosis.',
        'The warmth quickly fled from the room.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotions',
          description: 'Sudden changes in emotional states',
          examples: [
            'His courage fled at the moment of truth.',
            'All doubts fled when she saw the results.',
          ],
        ),
        ContextualUsage(
          context: 'Time',
          description: 'Rapid passing of periods',
          examples: [
            'The years have fled since we were in college together.',
            'Summer fled too quickly, and autumn arrived.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To avoid or escape from something unpleasant',
      partOfSpeech: 'transitive verb',
      examples: [
        'He fled his responsibilities as a parent.',
        'She fled the boredom of her small town for the excitement of the city.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Responsibilities',
          description: 'Avoiding duties or obligations',
          examples: [
            'The CEO fled accountability for the company\'s failures.',
            'Many young people flee conventional career paths for more fulfilling work.',
          ],
        ),
        ContextualUsage(
          context: 'Psychology',
          description: 'Escaping mental or emotional distress',
          examples: [
            'He fled into fantasy worlds to escape his troubles.',
            'Some people flee their problems through substance abuse.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spit',
  base: 'spit',
  past: 'spat',
  participle: 'spat',
  pastUK: 'spat',
  pastUS: 'spit',
  participleUK: 'spat',
  participleUS: 'spit',
  pronunciationTextUS: 'spɪt',
  pronunciationTextUK: 'spɪt',
  meanings: [
    VerbMeaning(
      definition: 'To forcibly eject saliva from the mouth',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He spat on the ground in disgust.',
        'The camel spat at the zoo visitor.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Disgust',
          description: 'Expressing strong dislike or contempt',
          examples: [
            'The angry protester spat at the police line.',
            'The player spat on the ground after the controversial call.',
          ],
        ),
        ContextualUsage(
          context: 'Health',
          description: 'Expelling unwanted substances',
          examples: [
            'He spat out the medicine because of its bitter taste.',
            'Patients sometimes need to spit into a cup for saliva tests.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To eject something from the mouth',
      partOfSpeech: 'transitive verb',
      examples: [
        'She spat out the watermelon seeds.',
        'The machine spits out the finished products.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Food',
          description: 'Removing inedible parts',
          examples: [
            'She spat out the olive pit discreetly.',
            'Children often spit out vegetables they don\'t like.',
          ],
        ),
        ContextualUsage(
          context: 'Mechanical',
          description: 'Machines discharging items',
          examples: [
            'The printer spat out page after page of documents.',
            'The ATM spat out the cash promptly.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To speak with anger or hostility',
      partOfSpeech: 'transitive verb',
      examples: [
        'She spat insults at her opponent.',
        'He spat the words out through clenched teeth.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Argument',
          description: 'Hostile verbal communication',
          examples: [
            'The defendant spat curses at the prosecutor.',
            'She spat accusations of betrayal during their heated argument.',
          ],
        ),
        ContextualUsage(
          context: 'Performance',
          description: 'Forceful vocal delivery',
          examples: [
            'The punk singer spat the lyrics with intense energy.',
            'The actor spat his lines with perfect contempt for the character.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make a sound like spitting',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The bacon spat in the hot pan.',
        'The fire spat as the rain hit it.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Cooking',
          description: 'Food reactions during preparation',
          examples: [
            'The butter spat when it hit the hot skillet.',
            'The hot oil spat dangerously when water droplets fell in.',
          ],
        ),
        ContextualUsage(
          context: 'Weather',
          description: 'Environmental sounds',
          examples: [
            'The waves spat foam onto the rocks.',
            'The electrical wires spat sparks during the storm.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'dwell',
  base: 'dwell',
  past: 'dwelt',
  participle: 'dwelt',
  pastUK: 'dwelt',
  pastUS: 'dwelled',
  participleUK: 'dwelt',
  participleUS: 'dwelled',
  pronunciationTextUS: 'dwɛl',
  pronunciationTextUK: 'dwel',
  meanings: [
    VerbMeaning(
      definition: 'To live in or at a specified place',
      partOfSpeech: 'intransitive verb',
      examples: [
        'They dwell in a small cottage by the lake.',
        'Ancient tribes dwelt in these caves thousands of years ago.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Residential',
          description: 'Permanent living arrangements',
          examples: [
            'He dwells in a remote mountain cabin, far from civilization.',
            'Our ancestors dwelt on this land for generations.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Poetic or formal descriptions of habitation',
          examples: [
            'Fairies were said to dwell in the enchanted forest.',
            'The hermit dwelt alone in his simple hut for decades.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To remain for a time in a place, state, or condition',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Let us not dwell in the past.',
        'She dwelt in uncertainty for months before making a decision.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mental state',
          description: 'Persistent thoughts or emotions',
          examples: [
            'He dwelt in a state of anxiety about his health.',
            'The nation dwelt in fear during the height of the crisis.',
          ],
        ),
        ContextualUsage(
          context: 'Temporary',
          description: 'Passing time in specific circumstances',
          examples: [
            'They dwelt in poverty before their fortunes changed.',
            'The travelers dwelt among the villagers for several weeks.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To think, speak, or write at length about something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Let\'s not dwell on the negative aspects.',
        'She dwelt too long on minor details in her presentation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Focus',
          description: 'Excessive attention to specific topics',
          examples: [
            'The professor dwelt on this point for most of the lecture.',
            'Don\'t dwell on your mistakes; learn from them and move forward.',
          ],
        ),
        ContextualUsage(
          context: 'Communication',
          description: 'Extensive coverage in speech or writing',
          examples: [
            'The article dwells unnecessarily on the celebrity\'s personal life.',
            'The memoir dwells on childhood experiences that shaped the author.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To exist or be present in a given place, environment, or state',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Peace dwells within her despite the chaos around.',
        'Evil dwells wherever hatred flourishes.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Spiritual',
          description: 'Presence of intangible qualities or entities',
          examples: [
            'The spirit of innovation dwells within the company\'s culture.',
            'They believe God dwells in the hearts of the faithful.',
          ],
        ),
        ContextualUsage(
          context: 'Abstract',
          description: 'Location of concepts or qualities',
          examples: [
            'The answer dwells in the complexity of human psychology.',
            'True beauty dwells in the character, not the appearance.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'breed',
  base: 'breed',
  past: 'bred',
  participle: 'bred',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'brid',
  pronunciationTextUK: 'briːd',
  meanings: [
    VerbMeaning(
      definition: 'To produce offspring, typically in a controlled situation',
      partOfSpeech: 'transitive verb',
      examples: [
        'They breed horses on their farm.',
        'She breeds rare tropical fish as a hobby.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Agriculture',
          description: 'Controlled animal reproduction',
          examples: [
            'The farm breeds cattle for the dairy industry.',
            'They breed sheep specifically for their high-quality wool.',
          ],
        ),
        ContextualUsage(
          context: 'Pets',
          description: 'Producing animals for companionship',
          examples: [
            'He breeds German Shepherds for show competitions.',
            'Responsible breeders breed for health and temperament, not just appearance.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To produce plants with specific characteristics through selection',
      partOfSpeech: 'transitive verb',
      examples: [
        'Scientists have bred wheat varieties resistant to drought.',
        'She breeds orchids with unusual color patterns.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Horticulture',
          description: 'Creating improved plant varieties',
          examples: [
            'They breed roses with stronger fragrances.',
            'The company breeds corn varieties with higher yields.',
          ],
        ),
        ContextualUsage(
          context: 'Research',
          description: 'Developing plants for scientific purposes',
          examples: [
            'Researchers breed plants with specific genetic modifications.',
            'The botanical garden breeds endangered native species for conservation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause or promote the development of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'Overcrowded conditions breed disease.',
        'Poverty often breeds crime and social unrest.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social issues',
          description: 'Creating conditions for problems',
          examples: [
            'Isolation breeds mistrust between communities.',
            'Inequality breeds resentment among disadvantaged groups.',
          ],
        ),
        ContextualUsage(
          context: 'Psychology',
          description: 'Fostering mental or emotional states',
          examples: [
            'Success breeds confidence and encourages further achievement.',
            'Constant criticism breeds insecurity in children.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be born and raised in a particular place or environment',
      partOfSpeech: 'passive verb',
      examples: [
        'She was bred in the countryside.',
        'He was born and bred in Boston.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Upbringing',
          description: 'Formative environment and background',
          examples: [
            'She was city-bred and unfamiliar with rural life.',
            'He was bred into the family business from childhood.',
          ],
        ),
        ContextualUsage(
          context: 'Culture',
          description: 'Development within specific traditions',
          examples: [
            'Their children were bred with strong cultural values.',
            'Musicians bred in New Orleans often share certain stylistic traits.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'lean',
  base: 'lean',
  past: 'leaned',
  participle: 'leaned',
  pastUK: 'leant',
  pastUS: 'leaned',
  participleUK: 'leant',
  participleUS: 'leaned',
  pronunciationTextUS: 'lin',
  pronunciationTextUK: 'liːn',
  meanings: [
    VerbMeaning(
      definition: 'To incline or bend from a vertical position',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She leaned against the wall.',
        'The tower leans slightly to one side.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Position',
          description: 'Physical angling of body or objects',
          examples: [
            'He leaned forward to whisper something to her.',
            'The old fence leans inward after years of wind pressure.',
          ],
        ),
        ContextualUsage(
          context: 'Architecture',
          description: 'Structural inclination',
          examples: [
            'The Leaning Tower of Pisa famously leans at an angle of nearly four degrees.',
            'The building leaned precariously after the earthquake.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To rely on or depend on someone or something for support',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She leaned on her friends during the difficult time.',
        'The economy leans heavily on tourism.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional support',
          description: 'Seeking help during challenges',
          examples: [
            'After his divorce, he leaned on his sister for emotional support.',
            'Students often lean on each other during exam periods.',
          ],
        ),
        ContextualUsage(
          context: 'Dependence',
          description: 'Relying on resources or assistance',
          examples: [
            'The startup leans on angel investors for funding.',
            'Rural communities lean on agricultural subsidies.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To tend toward or have a preference for something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He leans toward conservative politics.',
        'Their tastes lean more to classical music than pop.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Opinion',
          description: 'Having particular viewpoints or beliefs',
          examples: [
            'The newspaper leans left in its editorial positions.',
            'She leans toward traditional methods in her teaching approach.',
          ],
        ),
        ContextualUsage(
          context: 'Decision-making',
          description: 'Favoring specific choices',
          examples: [
            'The committee is leaning toward approving the proposal.',
            'I\'m leaning toward accepting the job offer in Chicago.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reduce waste and increase efficiency',
      partOfSpeech: 'adjective',
      examples: [
        'The company has adopted lean manufacturing techniques.',
        'They run a lean operation with minimal overhead costs.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Optimized production or management',
          examples: [
            'The startup operates with a lean team of just five employees.',
            'Lean methodology helps eliminate processes that don\'t add value.',
          ],
        ),
        ContextualUsage(
          context: 'Resources',
          description: 'Efficient use of available assets',
          examples: [
            'During the recession, they learned to run a lean household budget.',
            'The project was completed under lean conditions with limited funding.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'forecast',
  base: 'forecast',
  past: 'forecast',
  participle: 'forecast',
  pastUK: '',
  pastUS: 'forecasted',
  participleUK: '',
  participleUS: 'forecasted',
  pronunciationTextUS: 'ˈfɔrkæst',
  pronunciationTextUK: 'ˈfɔːkɑːst',
  meanings: [
    VerbMeaning(
      definition: 'To predict or estimate a future event or trend',
      partOfSpeech: 'transitive verb',
      examples: [
        'Economists forecast continued growth for the next quarter.',
        'The meteorologist forecast rain for the weekend.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Weather',
          description: 'Predicting atmospheric conditions',
          examples: [
            'The satellite data helps meteorologists forecast hurricanes more accurately.',
            'They forecast sunny conditions for the outdoor event.',
          ],
        ),
        ContextualUsage(
          context: 'Economics',
          description: 'Projecting financial or market trends',
          examples: [
            'The analysts forecast a recession in the coming year.',
            'The company forecast record profits based on strong sales.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To serve as a prediction or warning of',
      partOfSpeech: 'transitive verb',
      examples: [
        'Dark clouds forecast the approaching storm.',
        'Her sudden resignation forecast major changes in the organization.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Indicators',
          description: 'Signs suggesting future developments',
          examples: [
            'Falling birth rates forecast population changes for the coming decades.',
            'The poor harvests forecast food shortages in the region.',
          ],
        ),
        ContextualUsage(
          context: 'Politics',
          description: 'Anticipating policy or leadership changes',
          examples: [
            'The cabinet reshuffle forecast a shift in government priorities.',
            'Increased military exercises forecast rising tensions between the nations.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To calculate or estimate future requirements',
      partOfSpeech: 'transitive verb',
      examples: [
        'The retailer forecast inventory needs for the holiday season.',
        'They forecast the staff required to handle the expected increase in customers.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business planning',
          description: 'Estimating future resource needs',
          examples: [
            'The factory forecast raw material requirements for the next six months.',
            'HR forecast hiring needs based on projected growth.',
          ],
        ),
        ContextualUsage(
          context: 'Budgeting',
          description: 'Projecting financial requirements',
          examples: [
            'The finance department forecast cash flow for the next fiscal year.',
            'They accurately forecast the project costs within a small margin of error.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To anticipate and make provisions for',
      partOfSpeech: 'transitive verb',
      examples: [
        'The team forecast potential problems and developed contingency plans.',
        'She forecast the need for more storage space in the design.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Risk management',
          description: 'Identifying potential issues in advance',
          examples: [
            'The project manager forecast possible delays in the construction schedule.',
            'Insurance companies forecast disaster scenarios to set appropriate premiums.',
          ],
        ),
        ContextualUsage(
          context: 'Strategy',
          description: 'Planning based on anticipated developments',
          examples: [
            'The military forecast enemy movements based on intelligence reports.',
            'The coach forecast the opposing team\'s tactics and prepared accordingly.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shed',
  base: 'shed',
  past: 'shed',
  participle: 'shed',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʃɛd',
  pronunciationTextUK: 'ʃed',
  meanings: [
    VerbMeaning(
      definition: 'To cast off or lose something naturally',
      partOfSpeech: 'transitive verb',
      examples: [
        'The dog sheds its winter coat every spring.',
        'Trees shed their leaves in autumn.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Biology',
          description: 'Natural loss of body coverings',
          examples: [
            'Snakes shed their skin as they grow.',
            'Deer shed their antlers annually.',
          ],
        ),
        ContextualUsage(
          context: 'Seasonal',
          description: 'Cyclical natural processes',
          examples: [
            'Deciduous trees shed their foliage before winter.',
            'Some birds shed and replace their feathers during molting season.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To get rid of something unwanted or unnecessary',
      partOfSpeech: 'transitive verb',
      examples: [
        'She shed her inhibitions at the dance party.',
        'The company shed hundreds of jobs during the restructuring.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Personal change',
          description: 'Eliminating unwanted traits or habits',
          examples: [
            'He shed his shyness as he gained confidence in his new role.',
            'Through therapy, she was able to shed her anxiety.',
          ],
        ),
        ContextualUsage(
          context: 'Business',
          description: 'Reducing assets or liabilities',
          examples: [
            'The corporation shed unprofitable divisions to focus on core business.',
            'Investors are shedding risky stocks in favor of safer bonds.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pour out, give forth, or release',
      partOfSpeech: 'transitive verb',
      examples: [
        'The lamp shed a warm light over the room.',
        'She shed tears at the sad news.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Illumination',
          description: 'Producing or giving off light',
          examples: [
            'The full moon shed enough light for them to find their way.',
            'The candle shed a flickering glow in the dark room.',
          ],
        ),
        ContextualUsage(
          context: 'Emotions',
          description: 'Expressing feelings physically',
          examples: [
            'He shed tears of joy at the reunion with his family.',
            'The widow shed silent tears throughout the funeral service.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To spread or cause to flow or fall',
      partOfSpeech: 'transitive verb',
      examples: [
        'The investigation shed light on the corruption scandal.',
        'Her research shed new understanding on the historical event.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Knowledge',
          description: 'Providing clarity or information',
          examples: [
            'The newly discovered documents shed light on the author\'s intentions.',
            'Further studies will shed more insight into this medical condition.',
          ],
        ),
        ContextualUsage(
          context: 'Influence',
          description: 'Creating impact or effect',
          examples: [
            'Her leadership shed positive influence throughout the organization.',
            'The scandal shed doubt on his credibility as a witness.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'rid',
  base: 'rid',
  past: 'rid',
  participle: 'rid',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'rɪd',
  pronunciationTextUK: 'rɪd',
  meanings: [
    VerbMeaning(
      definition: 'To make someone or something free of an unwanted person or thing',
      partOfSpeech: 'transitive verb',
      examples: [
        'They hired an exterminator to rid their home of pests.',
        'He finally rid himself of his gambling addiction.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Elimination',
          description: 'Removing problems or annoyances',
          examples: [
            'The software helps rid computers of malware and viruses.',
            'The city implemented measures to rid the streets of crime.',
          ],
        ),
        ContextualUsage(
          context: 'Cleaning',
          description: 'Removing dirt, stains, or contaminants',
          examples: [
            'This solution will rid the fabric of even the toughest stains.',
            'They worked to rid the water supply of harmful chemicals.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To discard or dispose of something unwanted',
      partOfSpeech: 'reflexive verb',
      examples: [
        'She finally rid herself of all the clutter in her apartment.',
        'The company is trying to rid itself of outdated inventory.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Personal possessions',
          description: 'Removing unnecessary items',
          examples: [
            'He rid himself of most of his possessions before moving abroad.',
            'They rid themselves of the vacation home that was rarely used.',
          ],
        ),
        ContextualUsage(
          context: 'Organizational',
          description: 'Eliminating ineffective elements',
          examples: [
            'The new manager rid the department of inefficient procedures.',
            'The team rid itself of players who didn\'t fit the culture.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To free from something unwanted or harmful',
      partOfSpeech: 'transitive verb',
      examples: [
        'The treatment rid her body of the infection.',
        'The country struggled to rid itself of corruption.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Health',
          description: 'Removing disease or health problems',
          examples: [
            'The medication helps rid the body of excess fluid.',
            'The therapy rid him of chronic pain he had suffered for years.',
          ],
        ),
        ContextualUsage(
          context: 'Society',
          description: 'Eliminating social problems',
          examples: [
            'They worked to rid society of prejudice and discrimination.',
            'The legislation aimed to rid the industry of unsafe practices.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To remove or clear away (usually in phrase \"get rid of\")',
      partOfSpeech: 'phrasal verb',
      examples: [
        'We need to get rid of these old newspapers.',
        'How can I get rid of this headache?',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Disposal',
          description: 'Discarding unwanted items',
          examples: [
            'They got rid of old furniture before moving to the smaller apartment.',
            'The company got rid of obsolete equipment during the upgrade.',
          ],
        ),
        ContextualUsage(
          context: 'Resolution',
          description: 'Solving problems or issues',
          examples: [
            'The treatment helped her get rid of the chronic cough.',
            'They got rid of the misunderstanding through open communication.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'wed',
  base: 'wed',
  past: 'wed',
  participle: 'wed',
  pastUK: 'wedded',
  pastUS: 'wed',
  participleUK: 'wedded',
  participleUS: 'wed',
  pronunciationTextUS: 'wɛd',
  pronunciationTextUK: 'wed',
  meanings: [
    VerbMeaning(
      definition: 'To marry or take as a spouse',
      partOfSpeech: 'transitive verb',
      examples: [
        'They were wed in a small ceremony last spring.',
        'She wed her high school sweetheart after college.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ceremony',
          description: 'Formal marriage proceedings',
          examples: [
            'The couple was wed in a traditional church service.',
            'They were wed by a justice of the peace with only close family present.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'Elegant or literary usage',
          examples: [
            'The prince wed the duchess in a lavish royal ceremony.',
            'They were wed on a beautiful autumn day in the countryside.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To join or unite closely',
      partOfSpeech: 'transitive verb',
      examples: [
        'The artist\'s work weds traditional techniques with modern themes.',
        'The design weds functionality with elegant aesthetics.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Combination',
          description: 'Merging different elements or concepts',
          examples: [
            'Her cooking weds Asian flavors with European techniques.',
            'The architecture weds environmental sustainability with classical design.',
          ],
        ),
        ContextualUsage(
          context: 'Integration',
          description: 'Bringing together disparate parts',
          examples: [
            'The theory weds concepts from both physics and chemistry.',
            'Their business model weds traditional retail with digital innovation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become strongly committed or devoted to something',
      partOfSpeech: 'passive verb',
      examples: [
        'He is wedded to the idea of retiring early.',
        'The company remains wedded to its founding principles.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Attachment',
          description: 'Strong adherence to ideas or practices',
          examples: [
            'She is wedded to traditional methods and resistant to change.',
            'The organization is wedded to outdated policies that limit progress.',
          ],
        ),
        ContextualUsage(
          context: 'Loyalty',
          description: 'Firm dedication to principles or values',
          examples: [
            'The journalist remained wedded to the truth despite pressure.',
            'They are wedded to environmental causes and sustainable practices.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To combine or mix together thoroughly',
      partOfSpeech: 'transitive verb',
      examples: [
        'The chef wed the spices into a complex flavor profile.',
        'The poem weds imagery and emotion in a powerful way.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Arts',
          description: 'Blending creative elements',
          examples: [
            'The composer wed classical structure with jazz harmonies.',
            'Her novels wed historical accuracy with compelling fictional narratives.',
          ],
        ),
        ContextualUsage(
          context: 'Products',
          description: 'Combining features or components',
          examples: [
            'The device weds simplicity of use with sophisticated technology.',
            'This recipe weds the sweetness of honey with the tartness of lemon.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'smell',
  base: 'smell',
  past: 'smelled',
  participle: 'smelled',
  pastUK: 'smelt',
  pastUS: 'smelled',
  participleUK: 'smelt',
  participleUS: 'smelled',
  pronunciationTextUS: 'smɛl',
  pronunciationTextUK: 'smel',
  meanings: [
    VerbMeaning(
      definition: 'To perceive or detect odors with the olfactory sense',
      partOfSpeech: 'transitive verb',
      examples: [
        'Can you smell the fresh bread baking?',
        'The dog smelled something interesting under the bush.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sensory perception',
          description: 'Using the nose to detect scents',
          examples: [
            'She smelled the perfume as soon as she entered the room.',
            'He could smell gas leaking from the stove.',
          ],
        ),
        ContextualUsage(
          context: 'Food',
          description: 'Evaluating aromas of edible items',
          examples: [
            'The sommelier smelled the wine before tasting it.',
            'Always smell milk before drinking it if you\'re unsure about freshness.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To emit or give off an odor',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The roses smell wonderful this morning.',
        'The garbage smells terrible after sitting in the sun.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Pleasant aromas',
          description: 'Producing enjoyable scents',
          examples: [
            'The kitchen smelled delicious while she was baking cookies.',
            'The fresh laundry smelled clean and fragrant.',
          ],
        ),
        ContextualUsage(
          context: 'Unpleasant odors',
          description: 'Producing disagreeable scents',
          examples: [
            'The refrigerator smelled bad after the power outage.',
            'His gym clothes smelled awful after the intense workout.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To detect or sense something suspicious or negative',
      partOfSpeech: 'transitive verb',
      examples: [
        'The detective could smell a lie from a mile away.',
        'Investors can smell a fraud before parting with their money.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Intuition',
          description: 'Sensing problems through instinct',
          examples: [
            'She could smell trouble brewing in the office politics.',
            'Experienced traders can smell market manipulation.',
          ],
        ),
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Figurative detection of situations',
          examples: [
            'He could smell defeat before the final quarter began.',
            'They smelled opportunity in the struggling company.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To investigate by or as if by using the sense of smell',
      partOfSpeech: 'transitive verb',
      examples: [
        'The customs dog smelled all the luggage for contraband.',
        'She smelled the milk to check if it had spoiled.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Examination',
          description: 'Checking quality or condition',
          examples: [
            'The chef smelled each fish for freshness before cooking it.',
            'Always smell natural gas lines regularly for potential leaks.',
          ],
        ),
        ContextualUsage(
          context: 'Detection',
          description: 'Finding hidden or specific items',
          examples: [
            'Truffle hunters use pigs that can smell the fungi underground.',
            'Trained dogs can smell narcotics even when well hidden.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'forbid',
  base: 'forbid',
  past: 'forbade',
  participle: 'forbidden',
  pastUK: 'forbade',
  pastUS: 'forbad',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fərˈbɪd',
  pronunciationTextUK: 'fəˈbɪd',
  meanings: [
    VerbMeaning(
      definition: 'To order someone not to do something, or to prohibit an action',
      partOfSpeech: 'transitive verb',
      examples: [
        'The teacher forbade students from using calculators during the test.',
        'Her parents forbade her to attend the party.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Authority',
          description: 'Official prohibition by those in power',
          examples: [
            'The government forbade public gatherings during the pandemic.',
            'The principal forbade cell phones in classrooms.',
          ],
        ),
        ContextualUsage(
          context: 'Parenting',
          description: 'Setting boundaries for children',
          examples: [
            'They forbade their teenager from driving at night.',
            'Her mother forbade her to play video games until homework was done.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make impossible or prevent from happening',
      partOfSpeech: 'transitive verb',
      examples: [
        'Heavy snow forbade any travel in the region.',
        'His injury forbade him from participating in the competition.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Circumstances',
          description: 'Situations preventing actions',
          examples: [
            'The stormy weather forbade them from sailing that day.',
            'Limited resources forbade expansion of the program.',
          ],
        ),
        ContextualUsage(
          context: 'Limitations',
          description: 'Constraints making things impossible',
          examples: [
            'Physics forbids traveling faster than light.',
            'His medical condition forbids strenuous exercise.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To express strong disapproval or refusal',
      partOfSpeech: 'transitive verb',
      examples: [
        'Heaven forbid that anything should go wrong!',
        'God forbid we should lose our way in this forest.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Exclamation',
          description: 'Expressions of alarm or concern',
          examples: [
            'Heaven forbid she should find out what we\'ve planned for her birthday!',
            'God forbid that we should ever face such a terrible situation.',
          ],
        ),
        ContextualUsage(
          context: 'Emphasis',
          description: 'Strengthening negative sentiments',
          examples: [
            'Forbid the thought that we would ever abandon our principles!',
            'The community forbids any suggestion of compromise on this issue.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To declare as unacceptable or inappropriate',
      partOfSpeech: 'transitive verb',
      examples: [
        'Social conventions forbid discussing certain topics at the dinner table.',
        'Professional ethics forbid lawyers from revealing client confidences.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ethics',
          description: 'Moral or professional prohibitions',
          examples: [
            'Medical ethics forbid doctors from harming patients intentionally.',
            'Religious teachings forbid certain behaviors among adherents.',
          ],
        ),
        ContextualUsage(
          context: 'Social norms',
          description: 'Cultural rules and taboos',
          examples: [
            'Etiquette forbids checking your phone during a formal dinner.',
            'Some cultures forbid making direct eye contact with elders.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'withdraw',
  base: 'withdraw',
  past: 'withdrew',
  participle: 'withdrawn',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'wɪðˈdrɔ',
  pronunciationTextUK: 'wɪðˈdrɔː',
  meanings: [
    VerbMeaning(
      definition: 'To remove or take back something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She withdrew money from her account.',
        'The author withdrew his support for the controversial project.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Financial',
          description: 'Taking money from accounts',
          examples: [
            'He withdrew his savings from the bank before moving abroad.',
            'Investors withdrew their funds when the market became unstable.',
          ],
        ),
        ContextualUsage(
          context: 'Formal processes',
          description: 'Canceling official submissions',
          examples: [
            'The candidate withdrew her application after receiving another offer.',
            'They withdrew the product from the market due to safety concerns.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To retreat or move back from a position',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The army withdrew from the occupied territory.',
        'She withdrew to her room after the argument.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Military',
          description: 'Strategic movement away from engagement',
          examples: [
            'The troops withdrew to more defensible positions.',
            'After suffering heavy casualties, they withdrew from the battlefield.',
          ],
        ),
        ContextualUsage(
          context: 'Personal space',
          description: 'Seeking isolation or privacy',
          examples: [
            'He withdrew from company when he felt overwhelmed.',
            'The artist withdrew to the countryside to focus on her work.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To remove oneself from participation or involvement',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She withdrew from the competition due to injury.',
        'Several countries withdrew from the treaty negotiations.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Competitions',
          description: 'Ending participation in organized events',
          examples: [
            'The tennis player withdrew from the tournament with a sprained ankle.',
            'Their team withdrew from the league following a funding crisis.',
          ],
        ),
        ContextualUsage(
          context: 'Social',
          description: 'Reducing engagement with others',
          examples: [
            'After his diagnosis, he gradually withdrew from social activities.',
            'The shy student withdrew from class discussions whenever possible.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become reserved, detached, or emotionally distant',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He withdrew into himself after the trauma.',
        'She has withdrawn from friends and family since the loss.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Psychological',
          description: 'Emotional detachment as coping mechanism',
          examples: [
            'Children sometimes withdraw when they feel unsafe or insecure.',
            'The patient has withdrawn into a state of depression.',
          ],
        ),
        ContextualUsage(
          context: 'Relationships',
          description: 'Reducing emotional connection',
          examples: [
            'He felt his partner withdrawing as the relationship deteriorated.',
            'Elderly people sometimes withdraw from society as they age.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'abide',
  base: 'abide',
  past: 'abided/abode',
  participle: 'abided/abode',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'əˈbaɪd',
  pronunciationTextUK: 'əˈbaɪd',
  meanings: [
    VerbMeaning(
      definition: 'To tolerate or put up with something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She cannot abide people who talk during movies.',
        'He will not abide any form of dishonesty in his company.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Tolerance',
          description: 'Expressing inability to tolerate or accept something',
          examples: [
            'I cannot abide the thought of my children going hungry.',
            'The director does not abide laziness among the staff.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To remain or continue in a place',
      partOfSpeech: 'intransitive verb',
      examples: [
        'They abided in the forest cabin for several months.',
        'The tradition has abided in this community for centuries.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Dwelling',
          description: 'Staying or living in a particular location',
          examples: [
            'They abode in the wilderness for forty days.',
            'The monks had abided in the monastery since its founding.',
          ],
        ),
        ContextualUsage(
          context: 'Persistence',
          description: 'Continuing or persisting over time',
          examples: [
            'His love for her abided despite the many years of separation.',
            'The old customs have abided through generations.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To comply with or obey a rule or decision',
      partOfSpeech: 'intransitive verb',
      examples: [
        'All participants must abide by the rules of the competition.',
        'We will abide by the court\'s decision, whatever it may be.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Compliance',
          description: 'Following rules, laws, or agreements',
          examples: [
            'Citizens are expected to abide by the laws of the country.',
            'The company promised to abide by the terms of the contract.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'backslide',
  base: 'backslide',
  past: 'backslid',
  participle: 'backslidden/backslid',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˈbækˌslaɪd',
  pronunciationTextUK: 'ˈbækˌslaɪd',
  meanings: [
    VerbMeaning(
      definition: 'To revert to bad habits or behavior after a period of improvement',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He backslid into his old drinking habits after losing his job.',
        'Many dieters backslide during holiday seasons.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Habits',
          description: 'Reverting to negative behaviors after improvement',
          examples: [
            'She had quit smoking for six months before backsliding under stress.',
            'The team backslid into their old inefficient practices when the manager was away.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To lapse in religious faith or practice',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Some members of the congregation backslid and stopped attending services.',
        'He had backslidden from his previously devout lifestyle.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Religious',
          description: 'Falling away from religious commitment or practice',
          examples: [
            'The preacher warned about the dangers of backsliding in one\'s faith.',
            'After college, many young people backslide from their childhood religious practices.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'befall',
  base: 'befall',
  past: 'befell',
  participle: 'befallen',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɪˈfɔːl',
  pronunciationTextUK: 'bɪˈfɔːl',
  meanings: [
    VerbMeaning(
      definition: 'To happen or occur, especially with negative or unfortunate consequences',
      partOfSpeech: 'intransitive verb',
      examples: [
        'No one could have predicted the tragedy that befell the small town.',
        'Whatever befalls, we will face it together as a family.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Misfortune',
          description: 'Referring to unfortunate events that happen to someone',
          examples: [
            'Many hardships befell the pioneers during their journey westward.',
            'The same fate befell several other companies in the industry.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Formal or literary usage for events occurring',
          examples: [
            'Woe befell the kingdom after the death of the beloved queen.',
            'The knight wondered what adventures might befall him on his quest.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To happen to or affect a particular person or thing',
      partOfSpeech: 'transitive verb',
      examples: [
        'She worried about what might befall her children in her absence.',
        'The disease befell primarily those with compromised immune systems.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Occurrence',
          description: 'Events happening to specific individuals',
          examples: [
            'The same illness befell both brothers within a week of each other.',
            'Great honor befell him when he was chosen to lead the expedition.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'beget',
  base: 'beget',
  past: 'begat/begot',
  participle: 'begotten',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɪˈɡɛt',
  pronunciationTextUK: 'bɪˈɡɛt',
  meanings: [
    VerbMeaning(
      definition: 'To father or sire a child',
      partOfSpeech: 'transitive verb',
      examples: [
        'According to the Bible, Abraham begat Isaac.',
        'The king begot many children with his various wives.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Biblical',
          description: 'Used in religious texts to describe ancestry',
          examples: [
            'The genealogy listed how Adam begat Seth, who begat Enosh.',
            'The Gospel of Matthew begins with who begat whom in the lineage of Jesus.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'Formal or literary reference to fathering children',
          examples: [
            'The monarch had begotten three sons and two daughters.',
            'He had begotten children by his first wife before marrying again.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause or bring about something',
      partOfSpeech: 'transitive verb',
      examples: [
        'Poverty often begets crime in urban environments.',
        'Their arrogance begot resentment among the staff.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Causation',
          description: 'One thing leading to or causing another',
          examples: [
            'Violence begets more violence in a vicious cycle.',
            'Success often begets further success through increased confidence.',
          ],
        ),
        ContextualUsage(
          context: 'Philosophical',
          description: 'Used in discussions of cause and effect',
          examples: [
            'The philosopher argued that ignorance begets fear.',
            'Their research showed how discrimination begets hostility.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'behold',
  base: 'behold',
  past: 'beheld',
  participle: 'beheld',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɪˈhoʊld',
  pronunciationTextUK: 'bɪˈhəʊld',
  meanings: [
    VerbMeaning(
      definition: 'To observe or look at something, especially something impressive or remarkable',
      partOfSpeech: 'transitive verb',
      examples: [
        'They stood atop the mountain and beheld the magnificent valley below.',
        'Behold the wonders of modern technology!',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ceremonial',
          description: 'Used in formal pronouncements or revelations',
          examples: [
            'Behold the new king, crowned before you today!',
            'The curtain was drawn back, and the audience beheld the masterpiece.',
          ],
        ),
        ContextualUsage(
          context: 'Religious',
          description: 'Used in spiritual or religious contexts',
          examples: [
            'The pilgrims beheld the holy shrine with reverence.',
            'In the vision, he beheld angels descending from heaven.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To see or perceive someone or something through observation',
      partOfSpeech: 'transitive verb',
      examples: [
        'She beheld a strange figure standing in the shadows.',
        'We beheld their transformation with amazement.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Literary',
          description: 'Elevated or poetic way of describing visual perception',
          examples: [
            'The traveler beheld the ancient ruins at sunrise.',
            'She opened the door and beheld a room full of unexpected guests.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bereave',
  base: 'bereave',
  past: 'bereaved/bereft',
  participle: 'bereaved/bereft',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɪˈriːv',
  pronunciationTextUK: 'bɪˈriːv',
  meanings: [
    VerbMeaning(
      definition: 'To deprive of a loved one through death',
      partOfSpeech: 'transitive verb',
      examples: [
        'The accident bereaved her of her husband and son.',
        'Many children were bereaved during the war.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Loss',
          description: 'Experiencing the death of a family member or loved one',
          examples: [
            'The community supported the newly bereaved family.',
            'She was bereaved of her mother at a young age.',
          ],
        ),
        ContextualUsage(
          context: 'Grief',
          description: 'The state of mourning after losing someone',
          examples: [
            'Counseling services are available for bereaved parents.',
            'The support group helps those who have been recently bereaved.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deprive or rob of something valued',
      partOfSpeech: 'transitive verb',
      examples: [
        'The famine bereaved the region of its prosperity.',
        'He was bereft of all hope after the diagnosis.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Deprivation',
          description: 'Being deprived of something important',
          examples: [
            'The artist felt bereft of inspiration in the sterile environment.',
            'The decision bereaved many farmers of their livelihood.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'beseech',
  base: 'beseech',
  past: 'beseeched/besought',
  participle: 'beseeched/besought',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɪˈsiːtʃ',
  pronunciationTextUK: 'bɪˈsiːtʃ',
  meanings: [
    VerbMeaning(
      definition: 'To ask or beg for something urgently and fervently',
      partOfSpeech: 'transitive verb',
      examples: [
        'She beseeched him to reconsider his decision.',
        'The prisoner besought the king for mercy.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Pleading',
          description: 'Making an urgent, emotional appeal',
          examples: [
            'He beseeched the committee to grant him more time.',
            'The mother besought the judge to be lenient with her son.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'Used in formal or ceremonial requests',
          examples: [
            'The ambassador beseeched the foreign government for assistance.',
            'The congregation besought divine intervention in the crisis.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To implore or entreat someone to do something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The doctor beseeched his patient to follow the treatment plan.',
        'She besought him with tears in her eyes not to leave.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Literary',
          description: 'Used in literary contexts for dramatic effect',
          examples: [
            'The heroine besought the villain to spare her family.',
            'He fell to his knees and beseeched the heavens for guidance.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bestride',
  base: 'bestride',
  past: 'bestrode',
  participle: 'bestridden/bestrid',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɪˈstraɪd',
  pronunciationTextUK: 'bɪˈstraɪd',
  meanings: [
    VerbMeaning(
      definition: 'To sit or stand with legs on either side of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The cowboy bestrode his horse confidently.',
        'She bestrode the motorcycle and started the engine.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mounting',
          description: 'Sitting astride an animal or vehicle',
          examples: [
            'The knight bestrode his warhorse before battle.',
            'He bestrode the fallen log like it was a horse.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To dominate or stand over something in a commanding way',
      partOfSpeech: 'transitive verb',
      examples: [
        'The ancient colossus bestrode the harbor entrance.',
        'His personality bestrode the entire organization.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Dominance',
          description: 'Figuratively standing over or dominating',
          examples: [
            'The CEO bestrode the industry like a modern titan.',
            'The mountain bestrode the valley, casting a long shadow.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Used metaphorically in literature',
          examples: [
            'Shakespeare described how "Caesar bestrode the narrow world like a Colossus."',
            'Their dynasty bestrode two centuries of European history.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'betake',
  base: 'betake',
  past: 'betook',
  participle: 'betaken',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɪˈteɪk',
  pronunciationTextUK: 'bɪˈteɪk',
  meanings: [
    VerbMeaning(
      definition: 'To go or proceed to a place',
      partOfSpeech: 'reflexive verb',
      examples: [
        'They betook themselves to the nearest shelter when the storm began.',
        'He betook himself to the library to study in peace.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Deliberate travel or movement to a destination',
          examples: [
            'The pilgrims betook themselves to the holy shrine.',
            'When threatened, she betook herself to her grandmother\'s house.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Formal or archaic usage in literature',
          examples: [
            'The knights betook themselves to the forest in search of adventure.',
            'After the argument, she betook herself to her chambers.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To apply or devote oneself to an activity',
      partOfSpeech: 'reflexive verb',
      examples: [
        'The students betook themselves to their studies with new vigor.',
        'He betook himself to writing poetry in his retirement.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Dedication',
          description: 'Committing oneself to a particular pursuit',
          examples: [
            'After the failure, he betook himself to more practical endeavors.',
            'She betook herself to meditation to find inner peace.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bid',
  base: 'bid',
  past: 'bid/bade',
  participle: 'bid/bidden',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɪd',
  pronunciationTextUK: 'bɪd',
  meanings: [
    VerbMeaning(
      definition: 'To offer a price, especially at an auction',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She bid \$500 for the antique vase.',
        'Several companies bid on the government contract.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Auction',
          description: 'Making financial offers at a sale',
          examples: [
            'The collector bid aggressively for the rare painting.',
            'They bid by raising their numbered paddles at the auction house.',
          ],
        ),
        ContextualUsage(
          context: 'Business',
          description: 'Submitting a price proposal for work',
          examples: [
            'Our company bid on three major construction projects last month.',
            'The vendors must bid by the deadline to be considered.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To order or command someone to do something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The king bade his knights to search for the lost treasure.',
        'She bid him enter the room.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Command',
          description: 'Giving an authoritative order',
          examples: [
            'The general bade his troops to advance.',
            'His father had bidden him to return before midnight.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'Used in formal or ceremonial contexts',
          examples: [
            'The host bade the guests welcome to the celebration.',
            'The chairperson bid the assembly to be seated.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To express greetings or farewells',
      partOfSpeech: 'transitive verb',
      examples: [
        'We bid our friends farewell before their long journey.',
        'She bid him good morning with a cheerful smile.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Greeting',
          description: 'Formally expressing salutations',
          examples: [
            'The dignitary bid the foreign visitors welcome.',
            'He bid his colleagues good day as he left the office.',
          ],
        ),
        ContextualUsage(
          context: 'Farewell',
          description: 'Formally saying goodbye',
          examples: [
            'They bid each other a fond adieu at the airport.',
            'She bid farewell to her childhood home with tears in her eyes.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'broadcast',
  base: 'broadcast',
  past: 'broadcast/broadcasted',
  participle: 'broadcast/broadcasted',
  pastUK: 'broadcast',
  pastUS: 'broadcast/broadcasted',
  participleUK: 'broadcast',
  participleUS: 'broadcast/broadcasted',
  pronunciationTextUS: 'ˈbrɔːdkæst',
  pronunciationTextUK: 'ˈbrɔːdkɑːst',
  meanings: [
    VerbMeaning(
      definition: 'To transmit a program or information by radio or television',
      partOfSpeech: 'transitive verb',
      examples: [
        'The station broadcasts news updates every hour.',
        'The event was broadcast live around the world.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Media',
          description: 'Transmission of content via electronic media',
          examples: [
            'They broadcast the presidential debate on multiple channels.',
            'The radio station broadcast classical music throughout the night.',
          ],
        ),
        ContextualUsage(
          context: 'Technology',
          description: 'Technical aspects of signal transmission',
          examples: [
            'The satellite can broadcast signals to remote locations.',
            'They broadcast in high definition for special events.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To spread or make widely known',
      partOfSpeech: 'transitive verb',
      examples: [
        'Social media helps people broadcast their opinions to a wide audience.',
        'The company broadcast the news of its merger to all employees.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Communication',
          description: 'Widely disseminating information',
          examples: [
            'The government broadcast warnings about the approaching storm.',
            'She broadcast her achievements on every social platform.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To scatter seeds over a wide area',
      partOfSpeech: 'transitive verb',
      examples: [
        'The farmer broadcast wheat seeds across the field.',
        'It\'s more efficient to broadcast certain types of grass seed.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Agriculture',
          description: 'Scattering seeds by hand or machine',
          examples: [
            'They broadcast wildflower seeds to restore the meadow.',
            'The machine can broadcast fertilizer evenly over large areas.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'burn',
  base: 'burn',
  past: 'burned/burnt',
  participle: 'burned/burnt',
  pastUK: 'burnt',
  pastUS: 'burned',
  participleUK: 'burnt',
  participleUS: 'burned',
  pronunciationTextUS: 'bɜːrn',
  pronunciationTextUK: 'bɜːn',
  meanings: [
    VerbMeaning(
      definition: 'To be on fire or cause to be on fire',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'The candle burned brightly in the dark room.',
        'They burned the old letters in the fireplace.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Fire',
          description: 'Combustion or destruction by fire',
          examples: [
            'The forest burned for three days after the lightning strike.',
            'He accidentally burned his hand while cooking.',
          ],
        ),
        ContextualUsage(
          context: 'Destruction',
          description: 'Deliberate destruction using fire',
          examples: [
            'They burned the evidence before the police arrived.',
            'Historically, books were sometimes burned by oppressive regimes.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To feel or cause a painful heat sensation',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'The hot sauce burned my tongue intensely.',
        'Her skin burned from too much sun exposure.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Pain',
          description: 'Painful sensation of heat or irritation',
          examples: [
            'The wound burned when he applied the antiseptic.',
            'His eyes burned from the chlorine in the swimming pool.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To consume fuel to produce energy',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'This car burns less fuel than our previous model.',
        'The factory burns coal to generate electricity.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Energy',
          description: 'Using fuel for power or heat',
          examples: [
            'Modern power plants burn natural gas more efficiently.',
            'Wood-burning stoves are common in rural areas.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To feel strong emotion, especially anger or passion',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He burned with anger after hearing the insulting remarks.',
        'She burned with desire to see him again.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotion',
          description: 'Intense emotional states',
          examples: [
            'The betrayal made her burn with resentment.',
            'The athletes burned with competitive spirit before the championship.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'chide',
  base: 'chide',
  past: 'chided/chid',
  participle: 'chided/chidden',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'tʃaɪd',
  pronunciationTextUK: 'tʃaɪd',
  meanings: [
    VerbMeaning(
      definition: 'To scold or rebuke mildly',
      partOfSpeech: 'transitive verb',
      examples: [
        'The teacher chided the students for talking during the exam.',
        'She chided herself for forgetting her mother\'s birthday.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Correction',
          description: 'Gentle reprimand for minor misconduct',
          examples: [
            'The coach chided the player for not following instructions.',
            'Parents often chide children for poor table manners.',
          ],
        ),
        ContextualUsage(
          context: 'Self-criticism',
          description: 'Expressing disappointment with oneself',
          examples: [
            'He chided himself for making such a basic error.',
            'She mentally chided herself for speaking without thinking.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To express disapproval or criticism',
      partOfSpeech: 'transitive verb',
      examples: [
        'The editorial chided the government for its inaction on climate change.',
        'He gently chided her outdated views on the subject.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Criticism',
          description: 'Expression of disapproval',
          examples: [
            'The committee chided the executive for exceeding the budget.',
            'Critics chided the film for its historical inaccuracies.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'Official expression of disapproval',
          examples: [
            'The judge chided the lawyer for unprofessional behavior.',
            'The report chided the agency for its lack of transparency.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'dive',
  base: 'dive',
  past: 'dived/dove',
  participle: 'dived',
  pastUK: 'dived',
  pastUS: 'dove/dived',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'daɪv',
  pronunciationTextUK: 'daɪv',
  meanings: [
    VerbMeaning(
      definition: 'To plunge headfirst into water',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He dove from the high board into the pool.',
        'The children dived into the lake to cool off.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Swimming',
          description: 'Entering water headfirst',
          examples: [
            'The swimmer dived in with perfect form.',
            'They dove into the ocean from the yacht.',
          ],
        ),
        ContextualUsage(
          context: 'Sports',
          description: 'Competitive diving as a sport',
          examples: [
            'She dived for her country in the Olympics.',
            'The diver dove from the 10-meter platform.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To descend sharply or steeply',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The falcon dove toward its prey at incredible speed.',
        'The stock prices dived after the negative earnings report.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Aviation',
          description: 'Rapid descent of aircraft',
          examples: [
            'The pilot dove the plane to avoid the collision.',
            'The fighter jet dived through the clouds.',
          ],
        ),
        ContextualUsage(
          context: 'Finance',
          description: 'Rapid decrease in value',
          examples: [
            'The company\'s shares dove by 15% in a single day.',
            'Housing prices dived during the economic crisis.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To suddenly move or reach into something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She dove into her purse to find her keys.',
        'He dived under the bed to retrieve the lost toy.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Quick, sudden movement',
          examples: [
            'The goalkeeper dove to save the penalty kick.',
            'The actor dived behind the sofa in the comedic scene.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To undertake or become involved in something enthusiastically',
      partOfSpeech: 'intransitive verb',
      examples: [
        'After graduation, she dove into her new career.',
        'He dived into the research without any preparation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Engagement',
          description: 'Full commitment to an activity',
          examples: [
            'They dove into the project with great enthusiasm.',
            'She dived into learning the new language.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'dream',
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
      definition: 'To experience dreams during sleep',
      partOfSpeech: 'intransitive verb',
      examples: [
        'I dreamed about flying last night.',
        'She often dreams of her childhood home.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sleep',
          description: 'Mental experiences during sleep',
          examples: [
            'He dreamt of strange creatures and distant planets.',
            'Some people rarely remember what they dreamed about.',
          ],
        ),
        ContextualUsage(
          context: 'Psychology',
          description: 'Dreams as mental phenomena',
          examples: [
            'The patient dreamt repeatedly about the traumatic event.',
            'People often dream in color, though they may not recall it.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To imagine or think about something desirable',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She dreams of becoming a famous pianist someday.',
        'They dreamed about owning their own home for years.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Aspiration',
          description: 'Having hopes or ambitions',
          examples: [
            'The young athlete dreamt of Olympic glory.',
            'Many entrepreneurs dream of creating the next big innovation.',
          ],
        ),
        ContextualUsage(
          context: 'Fantasy',
          description: 'Imaginative contemplation',
          examples: [
            'He spent hours dreaming about his upcoming vacation.',
            'She dreamt of a better life in a different country.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To consider something as a possibility',
      partOfSpeech: 'transitive verb',
      examples: [
        'I never dreamed they would offer me the job.',
        'He hadn\'t dreamt that his book would become a bestseller.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Expectation',
          description: 'Consideration of possibilities',
          examples: [
            'They never dreamed their small business would grow so quickly.',
            'I wouldn\'t have dreamt of declining such a generous offer.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'drink',
  base: 'drink',
  past: 'drank',
  participle: 'drunk',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'drɪŋk',
  pronunciationTextUK: 'drɪŋk',
  meanings: [
    VerbMeaning(
      definition: 'To take liquid into the mouth and swallow it',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'She drinks eight glasses of water every day.',
        'We drank fresh orange juice with breakfast.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Hydration',
          description: 'Consuming liquid to satisfy thirst',
          examples: [
            'The doctor advised him to drink more fluids when exercising.',
            'The hikers stopped to drink from a mountain stream.',
          ],
        ),
        ContextualUsage(
          context: 'Consumption',
          description: 'Enjoying beverages for pleasure',
          examples: [
            'They drank tea while discussing the book.',
            'He prefers to drink coffee without sugar.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To consume alcoholic beverages',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He doesn\'t drink for religious reasons.',
        'They drank to celebrate their anniversary.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Consuming alcohol in social settings',
          examples: [
            'The guests drank champagne at the wedding reception.',
            'College students often drink excessively at parties.',
          ],
        ),
        ContextualUsage(
          context: 'Habit',
          description: 'Regular consumption of alcohol',
          examples: [
            'He used to drink heavily before quitting alcohol altogether.',
            'She never drinks during the work week.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To absorb or take in liquid',
      partOfSpeech: 'transitive verb',
      examples: [
        'The thirsty soil drank up the rain.',
        'The sponge had drunk all the spilled water.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Absorption',
          description: 'Material absorbing liquid',
          examples: [
            'The paper towel quickly drank up the spilled ink.',
            'The parched earth drank in the sudden downpour.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'dig',
  base: 'dig',
  past: 'dug',
  participle: 'dug',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'dɪɡ',
  pronunciationTextUK: 'dɪɡ',
  meanings: [
    VerbMeaning(
      definition: 'To break up and move earth with a tool or machine',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'The workers dug a deep hole for the foundation.',
        'Children love to dig in the sand at the beach.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Construction',
          description: 'Excavation for building purposes',
          examples: [
            'They dug trenches for the new water pipes.',
            'The archaeologists dug carefully to preserve the artifacts.',
          ],
        ),
        ContextualUsage(
          context: 'Gardening',
          description: 'Working soil for planting',
          examples: [
            'He dug beds for the new vegetable garden.',
            'We need to dig around the roots before transplanting the shrub.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To search thoroughly for information or understanding',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The journalist dug into the politician\'s past.',
        'You\'ll need to dig deeper to understand the root of the problem.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Research',
          description: 'Thorough investigation to uncover facts',
          examples: [
            'The detective dug through old case files for clues.',
            'Scientists had to dig through years of data to find the pattern.',
          ],
        ),
        ContextualUsage(
          context: 'Analysis',
          description: 'Examining something in depth',
          examples: [
            'The auditors dug into the financial records for irregularities.',
            'She dug beneath the surface explanation to find the truth.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To like or appreciate something',
      partOfSpeech: 'transitive verb',
      examples: [
        'I really dig that new song they\'ve been playing on the radio.',
        'She digs his sense of humor and intelligence.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Slang',
          description: 'Informal expression of approval or enjoyment',
          examples: [
            'The audience really dug the band\'s energetic performance.',
            'He digs vintage cars and collects them as a hobby.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'eat',
  base: 'eat',
  past: 'ate',
  participle: 'eaten',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'iːt',
  pronunciationTextUK: 'iːt',
  meanings: [
    VerbMeaning(
      definition: 'To put food in the mouth, chew, and swallow',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'We ate dinner at eight o\'clock last night.',
        'The children ate all their vegetables.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Meals',
          description: 'Consuming food during regular mealtimes',
          examples: [
            'They eat breakfast together every morning.',
            'He ate lunch at his desk while working.',
          ],
        ),
        ContextualUsage(
          context: 'Nutrition',
          description: 'Consumption for sustenance and health',
          examples: [
            'The doctor advised him to eat more fruits and vegetables.',
            'She eats a high-protein diet to support her athletic training.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To consume or destroy gradually',
      partOfSpeech: 'transitive verb',
      examples: [
        'Rust had eaten away at the metal fence.',
        'Acid can eat through certain materials.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Corrosion',
          description: 'Gradual destruction by chemical action',
          examples: [
            'The salt air had eaten away the paint on the seaside house.',
            'Moths had eaten holes in the old woolen sweater.',
          ],
        ),
        ContextualUsage(
          context: 'Erosion',
          description: 'Gradual wearing away of surfaces',
          examples: [
            'The river had eaten into the banks during the flood.',
            'Years of traffic had eaten away the road surface.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To consume one\'s emotions or cause distress',
      partOfSpeech: 'transitive verb',
      examples: [
        'Guilt was eating him alive after the incident.',
        'The secret was eating away at her conscience.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotion',
          description: 'Feelings causing psychological distress',
          examples: [
            'Jealousy ate at him as he watched their happiness.',
            'The regret has eaten at her for years.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'fight',
  base: 'fight',
  past: 'fought',
  participle: 'fought',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'faɪt',
  pronunciationTextUK: 'faɪt',
  meanings: [
    VerbMeaning(
      definition: 'To engage in physical combat or battle',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The two armies fought for control of the bridge.',
        'The siblings often fought over toys when they were young.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Combat',
          description: 'Physical conflict between individuals or groups',
          examples: [
            'The boxers fought for the championship title.',
            'Rival gangs fought in the streets last night.',
          ],
        ),
        ContextualUsage(
          context: 'War',
          description: 'Military engagement between forces',
          examples: [
            'Their grandfather fought in World War II.',
            'The rebels fought against the government troops.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To struggle or contend against something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The town is fighting against the proposed development.',
        'She fought cancer for five years before going into remission.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Opposition',
          description: 'Active resistance against something undesirable',
          examples: [
            'The organization fights discrimination in all its forms.',
            'The community fought the closure of their local hospital.',
          ],
        ),
        ContextualUsage(
          context: 'Disease',
          description: 'Struggling against illness',
          examples: [
            'His body fought the infection for weeks.',
            'She continues to fight her addiction day by day.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To strive for or campaign to achieve something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The activists fought for equal rights.',
        'He fought to keep his emotions under control.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Advocacy',
          description: 'Working hard to promote a cause or achieve a goal',
          examples: [
            'The lawyer fought tirelessly for justice for her client.',
            'They fought for years to change the outdated legislation.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'foresee',
  base: 'foresee',
  past: 'foresaw',
  participle: 'foreseen',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fɔrˈsiː',
  pronunciationTextUK: 'fɔːˈsiː',
  meanings: [
    VerbMeaning(
      definition: 'To predict or anticipate something before it happens',
      partOfSpeech: 'transitive verb',
      examples: [
        'No one could have foreseen the economic collapse.',
        'She foresaw difficulties in implementing the new system.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Planning',
          description: 'Anticipating future challenges for preparation',
          examples: [
            'The committee tried to foresee all possible objections to the proposal.',
            'The company foresaw changes in the market and adapted their strategy.',
          ],
        ),
        ContextualUsage(
          context: 'Prediction',
          description: 'Estimating future events or developments',
          examples: [
            'The scientist foresaw the environmental consequences decades ago.',
            'Few economists foresaw the rapid rise of digital currencies.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To have prescience or a premonition about something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The prophet foresaw the coming disaster in his dreams.',
        'He somehow foresaw his own death in the battle.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Intuition',
          description: 'Having insight about future events',
          examples: [
            'She had foresaw her daughter\'s return before receiving any message.',
            'The novelist eerily foresaw technological developments that came decades later.',
          ],
        ),
        ContextualUsage(
          context: 'Literature',
          description: 'Characters having premonitions in fiction',
          examples: [
            'In the story, the main character foresees the betrayal through visions.',
            'The old woman in the novel had foresaw the storm that would change their lives.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'forgive',
  base: 'forgive',
  past: 'forgave',
  participle: 'forgiven',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fərˈɡɪv',
  pronunciationTextUK: 'fəˈɡɪv',
  meanings: [
    VerbMeaning(
      definition: 'To stop feeling angry or resentful toward someone for an offense or mistake',
      partOfSpeech: 'transitive verb',
      examples: [
        'She finally forgave him for lying to her.',
        'It\'s hard to forgive someone who isn\'t sorry for what they did.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Relationships',
          description: 'Pardoning offenses in personal connections',
          examples: [
            'The mother forgave her son for breaking the vase.',
            'After years of estrangement, she forgave her sister and they reconciled.',
          ],
        ),
        ContextualUsage(
          context: 'Emotional',
          description: 'Releasing negative feelings toward others',
          examples: [
            'He found peace when he finally forgave his childhood bullies.',
            'She couldn\'t forgive herself for the accident, despite others forgiving her.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cancel a debt or financial obligation',
      partOfSpeech: 'transitive verb',
      examples: [
        'The bank forgave part of their mortgage after the natural disaster.',
        'The government program forgives student loans for those in public service.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Financial',
          description: 'Cancellation of monetary obligations',
          examples: [
            'The lender forgave the remaining balance on the loan.',
            'Some countries have forgiven billions in debt owed by developing nations.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pardon or excuse an offense',
      partOfSpeech: 'transitive verb',
      examples: [
        'The priest assured her that God would forgive her sins.',
        'The king forgave the prisoner and granted him freedom.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Religious',
          description: 'Spiritual absolution of wrongdoing',
          examples: [
            'In many religions, the divine is believed to forgive those who truly repent.',
            'The congregation prayed to be forgiven for their transgressions.',
          ],
        ),
        ContextualUsage(
          context: 'Legal',
          description: 'Official pardoning of offenses',
          examples: [
            'The president has the power to forgive federal crimes through pardons.',
            'The court forgave his minor offense in light of his community service.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'forsake',
  base: 'forsake',
  past: 'forsook',
  participle: 'forsaken',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fɔrˈseɪk',
  pronunciationTextUK: 'fəˈseɪk',
  meanings: [
    VerbMeaning(
      definition: 'To abandon or leave entirely',
      partOfSpeech: 'transitive verb',
      examples: [
        'He forsook his family and moved to another country.',
        'The explorer refused to forsake the expedition despite the dangers.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Abandonment',
          description: 'Leaving people or responsibilities',
          examples: [
            'The soldier was accused of forsaking his post during battle.',
            'She felt forsaken by her friends in her time of need.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Formal or poetic expression of abandonment',
          examples: [
            'The poem described a lover forsaken at the altar.',
            'The ancient temple had been forsaken by its worshippers centuries ago.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To renounce or give up something valued or enjoyed',
      partOfSpeech: 'transitive verb',
      examples: [
        'The monk forsook all worldly possessions.',
        'She forsook her career in law to become an artist.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Renunciation',
          description: 'Deliberately giving up something valued',
          examples: [
            'For health reasons, he forsook his beloved cigars.',
            'The candidate forsook political ambition to focus on humanitarian work.',
          ],
        ),
        ContextualUsage(
          context: 'Religious',
          description: 'Spiritual renunciation of worldly things',
          examples: [
            'The ascetics had forsaken comfort to pursue spiritual enlightenment.',
            'In the sacred text, followers are urged to forsake evil ways.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'hew',
  base: 'hew',
  past: 'hewed',
  participle: 'hewn/hewed',
  pastUK: '',
  pastUS: '',
  participleUK: 'hewn',
  participleUS: 'hewn/hewed',
  pronunciationTextUS: 'hjuː',
  pronunciationTextUK: 'hjuː',
  meanings: [
    VerbMeaning(
      definition: 'To cut or chop with an ax, sword, or other sharp instrument',
      partOfSpeech: 'transitive verb',
      examples: [
        'The lumberjack hewed down the old oak tree.',
        'They hewed a path through the dense forest.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Woodcutting',
          description: 'Cutting trees or wood with tools',
          examples: [
            'The craftsman hewed the logs into rough beams.',
            'Early settlers hewed timber to build their cabins.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional methods of cutting materials',
          examples: [
            'The ancient stonecutters hewed blocks for the temple from the quarry.',
            'Medieval workers hewed ice from frozen lakes in winter.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To shape or form by cutting',
      partOfSpeech: 'transitive verb',
      examples: [
        'The sculptor hewed the statue from a single block of marble.',
        'The mine entrance was hewn into the side of the mountain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Craftsmanship',
          description: 'Shaping materials through cutting',
          examples: [
            'The artisan hewed the bowl from a piece of walnut.',
            'The elaborate doorway was hewn by master stonemasons.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To conform or adhere to something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The new policy hews closely to the original guidelines.',
        'Their interpretation hewed to traditional principles.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Adherence',
          description: 'Following or conforming to a standard or line',
          examples: [
            'The judge hewed to a strict interpretation of the law.',
            'The biography hews closely to the known facts of her life.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'inlay',
  base: 'inlay',
  past: 'inlaid',
  participle: 'inlaid',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˈɪnleɪ',
  pronunciationTextUK: 'ˈɪnleɪ',
  meanings: [
    VerbMeaning(
      definition: 'To set pieces of material into a surface to form a design',
      partOfSpeech: 'transitive verb',
      examples: [
        'The craftsman inlaid mother-of-pearl in the wooden box.',
        'She inlaid colorful stones in the mosaic tabletop.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Craftsmanship',
          description: 'Decorative technique in woodworking or other materials',
          examples: [
            'The artisan inlaid silver wire into the dark wood to create patterns.',
            'The ancient chest was inlaid with ivory and precious gems.',
          ],
        ),
        ContextualUsage(
          context: 'Art',
          description: 'Artistic technique using contrasting materials',
          examples: [
            'The Moorish palace walls were intricately inlaid with geometric patterns.',
            'The jeweler inlaid turquoise into the silver bracelet.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To insert a dental filling or restoration',
      partOfSpeech: 'transitive verb',
      examples: [
        'The dentist inlaid gold to repair the damaged tooth.',
        'Ceramic material was inlaid to restore the fractured molar.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Dental',
          description: 'Restorative dental procedure',
          examples: [
            'The tooth was inlaid with a composite material to match its color.',
            'Modern dentists rarely inlay gold fillings as they once did.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To incorporate or insert something within a larger context',
      partOfSpeech: 'transitive verb',
      examples: [
        'The author inlaid references to classical myths throughout the novel.',
        'The composer inlaid folk melodies into the symphony.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Artistic',
          description: 'Integrating elements within creative works',
          examples: [
            'The filmmaker inlaid subtle visual motifs throughout the movie.',
            'The poet inlaid archaic phrases to create an ancient atmosphere.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'input',
  base: 'input',
  past: 'input/inputted',
  participle: 'input/inputted',
  pastUK: 'input',
  pastUS: 'inputted/input',
  participleUK: 'input',
  participleUS: 'inputted/input',
  pronunciationTextUS: 'ˈɪnpʊt',
  pronunciationTextUK: 'ˈɪnpʊt',
  meanings: [
    VerbMeaning(
      definition: 'To enter data into a computer or system',
      partOfSpeech: 'transitive verb',
      examples: [
        'The secretary inputted all the new customer information.',
        'You need to input your password to access the account.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Computing',
          description: 'Entering data into electronic systems',
          examples: [
            'The analyst input the survey results into the database.',
            'She inputted the coordinates into the GPS device.',
          ],
        ),
        ContextualUsage(
          context: 'Data Processing',
          description: 'Adding information to systems for processing',
          examples: [
            'We need to input the quarterly figures before running the report.',
            'The operator input the production data at the end of each shift.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To contribute ideas or information to a discussion or project',
      partOfSpeech: 'transitive verb',
      examples: [
        'The consultant input his expertise during the planning meeting.',
        'Students are encouraged to input their own ideas for the project.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Collaboration',
          description: 'Contributing to a group effort or discussion',
          examples: [
            'Each team member input suggestions for improving efficiency.',
            'The community was invited to input their opinions about the development.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'interweave',
  base: 'interweave',
  past: 'interwove',
  participle: 'interwoven',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˌɪntərˈwiːv',
  pronunciationTextUK: 'ˌɪntəˈwiːv',
  meanings: [
    VerbMeaning(
      definition: 'To weave together or intermingle',
      partOfSpeech: 'transitive verb',
      examples: [
        'The artist interwove gold and silver threads into the tapestry.',
        'She interwove flowers and ribbons into her hair for the wedding.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Textile',
          description: 'Physical weaving of different materials',
          examples: [
            'The weaver interwove silk and wool to create a unique fabric.',
            'Branches were interwoven to form a natural fence around the garden.',
          ],
        ),
        ContextualUsage(
          context: 'Craft',
          description: 'Manual interlacing of materials for creation',
          examples: [
            'The basket maker interwove reeds of different colors into a pattern.',
            'The artisan interwove leather strips to make the bag stronger.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To combine or connect in a complex way',
      partOfSpeech: 'transitive verb',
      examples: [
        'The author interwove multiple storylines throughout the novel.',
        'Their careers had been interwoven for decades.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Narrative',
          description: 'Combining story elements in literature or film',
          examples: [
            'The screenwriter interwove comedy and tragedy in the screenplay.',
            'The documentary interwove personal testimonies with historical footage.',
          ],
        ),
        ContextualUsage(
          context: 'Conceptual',
          description: 'Connecting ideas or themes',
          examples: [
            'The philosopher interwove scientific and ethical concerns in her argument.',
            'The composer interwove traditional melodies with modern harmonies.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To blend or associate closely together',
      partOfSpeech: 'transitive verb',
      examples: [
        'Their lives became interwoven after years of friendship.',
        'Religious practices are interwoven with cultural traditions in many societies.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Close connection between people or communities',
          examples: [
            'The histories of the two families were interwoven for generations.',
            'Their business interests became increasingly interwoven over time.',
          ],
        ),
        ContextualUsage(
          context: 'Cultural',
          description: 'Blending of cultural elements or traditions',
          examples: [
            'Indigenous beliefs were interwoven with Catholic practices in the region.',
            'Art and politics are interwoven in her provocative installations.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'lay',
  base: 'lay',
  past: 'laid',
  participle: 'laid',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'leɪ',
  pronunciationTextUK: 'leɪ',
  meanings: [
    VerbMeaning(
      definition: 'To put or place in a horizontal position or position of rest',
      partOfSpeech: 'transitive verb',
      examples: [
        'She laid the baby in the crib.',
        'He laid the book on the table.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Positioning',
          description: 'Placing objects in a specific location',
          examples: [
            'The waiter laid the silverware beside each plate.',
            'The gardener laid the plants in rows before planting them.',
          ],
        ),
        ContextualUsage(
          context: 'Construction',
          description: 'Placing building materials in position',
          examples: [
            'The workers laid bricks for the new wall.',
            'They laid the foundation for the house last month.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To produce and deposit eggs',
      partOfSpeech: 'transitive verb',
      examples: [
        'The hen laid three eggs this morning.',
        'Some reptiles lay eggs in sandy soil.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Biology',
          description: 'Animal reproduction process',
          examples: [
            'Chickens typically lay one egg per day.',
            'Sea turtles return to the same beaches to lay their eggs.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To present or put forward for consideration',
      partOfSpeech: 'transitive verb',
      examples: [
        'The lawyer laid out the evidence before the jury.',
        'We laid our concerns before the committee.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Presentation',
          description: 'Formal presentation of information',
          examples: [
            'The architect laid the plans before the client for approval.',
            'The CEO laid out her vision for the company\'s future.',
          ],
        ),
        ContextualUsage(
          context: 'Accusation',
          description: 'Assigning blame or responsibility',
          examples: [
            'The prosecutor laid the blame squarely on the defendant.',
            'Critics laid the failure of the project at the manager\'s door.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To impose or establish',
      partOfSpeech: 'transitive verb',
      examples: [
        'The government laid a new tax on luxury goods.',
        'The court laid a fine of \$5,000 on the company.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legal',
          description: 'Officially imposing rules, penalties, or obligations',
          examples: [
            'The judge laid a restraining order against the defendant.',
            'The treaty laid certain obligations on the signing countries.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'mislead',
  base: 'mislead',
  past: 'misled',
  participle: 'misled',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'mɪsˈliːd',
  pronunciationTextUK: 'mɪsˈliːd',
  meanings: [
    VerbMeaning(
      definition: 'To lead or guide wrongly; lead astray',
      partOfSpeech: 'transitive verb',
      examples: [
        'The faulty map misled the hikers into dangerous terrain.',
        'His directions misled us and we got completely lost.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Navigation',
          description: 'Providing incorrect guidance about direction or location',
          examples: [
            'The outdated GPS misled the driver to a road that no longer existed.',
            'The poorly marked trail signs misled several tourists last season.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deceive or cause to have a wrong impression or idea',
      partOfSpeech: 'transitive verb',
      examples: [
        'The advertisement misled consumers about the product\'s effectiveness.',
        'He misled his parents about where he was going that night.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Deception',
          description: 'Deliberately creating false impressions',
          examples: [
            'The company misled investors about its financial situation.',
            'The politician misled the public with statistics taken out of context.',
          ],
        ),
        ContextualUsage(
          context: 'Legal',
          description: 'Fraudulent or deceitful representation',
          examples: [
            'The salesperson was fined for misleading customers about warranty coverage.',
            'The report accused the executive of intentionally misleading the board of directors.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To give the wrong idea or impression unintentionally',
      partOfSpeech: 'transitive verb',
      examples: [
        'The initial test results misled the doctors about the diagnosis.',
        'The headline unintentionally misled readers about the actual content of the article.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Miscommunication',
          description: 'Unintentional provision of incorrect information',
          examples: [
            'His enthusiasm for the project misled his team about its actual complexity.',
            'The simplified explanation misled students about the true nature of the scientific concept.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'misunderstand',
  base: 'misunderstand',
  past: 'misunderstood',
  participle: 'misunderstood',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˌmɪsəndərˈstænd',
  pronunciationTextUK: 'ˌmɪsʌndəˈstænd',
  meanings: [
    VerbMeaning(
      definition: 'To interpret or understand incorrectly',
      partOfSpeech: 'transitive verb',
      examples: [
        'She completely misunderstood the instructions for the assignment.',
        'I think you misunderstood what I was trying to say.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Communication',
          description: 'Incorrect interpretation of verbal or written messages',
          examples: [
            'The student misunderstood the professor\'s explanation of the concept.',
            'He misunderstood her tone and thought she was angry.',
          ],
        ),
        ContextualUsage(
          context: 'Direction',
          description: 'Incorrect comprehension of instructions',
          examples: [
            'The new employee misunderstood the protocol and made a critical error.',
            'They misunderstood the requirements and submitted the wrong documents.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To fail to interpret someone\'s character, motives, or actions correctly',
      partOfSpeech: 'transitive verb',
      examples: [
        'His colleagues often misunderstood his humor as rudeness.',
        'She felt misunderstood throughout most of her teenage years.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Interpersonal',
          description: 'Incorrect perception of others\' characters or intentions',
          examples: [
            'The artist was misunderstood by critics during her lifetime.',
            'He misunderstood her friendship as romantic interest.',
          ],
        ),
        ContextualUsage(
          context: 'Emotional',
          description: 'Feeling that one\'s true self or intentions aren\'t recognized',
          examples: [
            'Many adolescents feel misunderstood by their parents.',
            'The character in the film is a misunderstood genius ahead of his time.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To misinterpret a situation or concept',
      partOfSpeech: 'transitive verb',
      examples: [
        'Many people misunderstand the theory of evolution.',
        'The public often misunderstands how the tax system actually works.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Conceptual',
          description: 'Incorrect comprehension of ideas or theories',
          examples: [
            'The journalist misunderstood the scientific findings in the report.',
            'Students frequently misunderstand this mathematical principle at first.',
          ],
        ),
        ContextualUsage(
          context: 'Cultural',
          description: 'Incorrect interpretation of cultural practices or beliefs',
          examples: [
            'Visitors often misunderstand local customs and inadvertently cause offense.',
            'The film misunderstood the historical context of the events it portrayed.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'outdo',
  base: 'outdo',
  past: 'outdid',
  participle: 'outdone',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'aʊtˈduː',
  pronunciationTextUK: 'aʊtˈduː',
  meanings: [
    VerbMeaning(
      definition: 'To do better than or exceed in performance',
      partOfSpeech: 'transitive verb',
      examples: [
        'The new model outdoes the previous one in fuel efficiency.',
        'She outdid herself with her presentation at the conference.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Competition',
          description: 'Surpassing competitors or rivals',
          examples: [
            'The athlete outdid all her opponents in the final race.',
            'Their sales team outdid every other region this quarter.',
          ],
        ),
        ContextualUsage(
          context: 'Self-improvement',
          description: 'Exceeding one\'s own previous achievements',
          examples: [
            'The chef outdid himself with this new signature dish.',
            'She constantly strives to outdo her previous performances.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To go beyond or surpass in extravagance or elaborateness',
      partOfSpeech: 'transitive verb',
      examples: [
        'Each family tries to outdo the others with their Christmas decorations.',
        'The sequel outdid the original film in both budget and special effects.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Extravagance',
          description: 'Exceeding others in lavishness or impressiveness',
          examples: [
            'The host outdid everyone with an incredibly lavish dinner party.',
            'Each designer tried to outdo the others with more outrageous creations.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To overcome or defeat completely',
      partOfSpeech: 'transitive verb',
      examples: [
        'The experienced team outdid the newcomers in every aspect of the game.',
        'Her natural talent outdid years of training.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Domination',
          description: 'Completely overcoming opponents or obstacles',
          examples: [
            'The champion outdid all challengers with ease.',
            'Their marketing campaign outdid the competition and captured market share.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'overcome',
  base: 'overcome',
  past: 'overcame',
  participle: 'overcome',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˌoʊvərˈkʌm',
  pronunciationTextUK: 'ˌəʊvəˈkʌm',
  meanings: [
    VerbMeaning(
      definition: 'To succeed in dealing with or controlling a problem or difficulty',
      partOfSpeech: 'transitive verb',
      examples: [
        'She overcame her fear of public speaking through practice.',
        'They overcame numerous obstacles to complete the project on time.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Personal Growth',
          description: 'Conquering personal challenges or limitations',
          examples: [
            'He overcame his addiction after years of struggle.',
            'The immigrant overcame language barriers to establish a successful business.',
          ],
        ),
        ContextualUsage(
          context: 'Achievement',
          description: 'Surmounting difficulties to reach a goal',
          examples: [
            'The team overcame a ten-point deficit to win the championship.',
            'The company overcame financial hardship during the recession.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To defeat or triumph over an opponent or enemy',
      partOfSpeech: 'transitive verb',
      examples: [
        'The underdog overcame the champion in a stunning upset.',
        'Their army overcame superior forces through better strategy.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Competition',
          description: 'Defeating opponents in contests or conflicts',
          examples: [
            'The smaller nation overcame the regional superpower in the negotiations.',
            'Our candidate overcame the incumbent in the election.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be affected or overwhelmed by a strong emotion or sensation',
      partOfSpeech: 'transitive verb',
      examples: [
        'She was overcome with grief at the funeral.',
        'The hikers were overcome by fatigue after the long trek.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotion',
          description: 'Being overwhelmed by strong feelings',
          examples: [
            'He was overcome with joy when he saw his newborn daughter.',
            'The audience was overcome with emotion during the final scene.',
          ],
        ),
        ContextualUsage(
          context: 'Physical',
          description: 'Being overwhelmed by physical sensations or conditions',
          examples: [
            'Several workers were overcome by fumes in the factory.',
            'The climber was overcome by altitude sickness near the summit.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'overfly',
  base: 'overfly',
  past: 'overflew',
  participle: 'overflown',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˌoʊvərˈflaɪ',
  pronunciationTextUK: 'ˌəʊvəˈflaɪ',
  meanings: [
    VerbMeaning(
      definition: 'To fly over or across a particular area or territory',
      partOfSpeech: 'transitive verb',
      examples: [
        'The plane overflew several countries on its route to Asia.',
        'Military aircraft regularly overfly the border region.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Aviation',
          description: 'Aircraft traversing airspace above territories',
          examples: [
            'The helicopter overflew the disaster area to assess the damage.',
            'Special permission is required to overfly certain restricted zones.',
          ],
        ),
        ContextualUsage(
          context: 'Military',
          description: 'Military aircraft flying over areas for surveillance or operations',
          examples: [
            'The reconnaissance drone overflew enemy positions.',
            'The treaty prohibited either country from overflying the demilitarized zone.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To fly beyond or past a designated point or destination',
      partOfSpeech: 'transitive verb',
      examples: [
        'Due to poor visibility, the pilot overflew the runway.',
        'The small aircraft overflew its intended landing site.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Navigation Error',
          description: 'Accidentally flying past a destination',
          examples: [
            'The novice pilot overflew the airfield and had to circle back.',
            'They overflew the landing zone due to unexpected crosswinds.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'override',
  base: 'override',
  past: 'overrode',
  participle: 'overridden',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˌoʊvərˈraɪd',
  pronunciationTextUK: 'ˌəʊvəˈraɪd',
  meanings: [
    VerbMeaning(
      definition: 'To disregard or set aside a decision or policy',
      partOfSpeech: 'transitive verb',
      examples: [
        'The president can override a veto with a two-thirds majority vote.',
        'The manager overrode the committee\'s recommendation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Authority',
          description: 'Using superior power or position to countermand decisions',
          examples: [
            'The general overrode his subordinate\'s order to retreat.',
            'The CEO overrode the finance department\'s budget constraints for the project.',
          ],
        ),
        ContextualUsage(
          context: 'Governance',
          description: 'Constitutional or procedural power to negate decisions',
          examples: [
            'The judiciary can override legislation that violates constitutional rights.',
            'The parent company overrode the subsidiary\'s hiring freeze.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take precedence or priority over',
      partOfSpeech: 'transitive verb',
      examples: [
        'Safety concerns override all other considerations in this facility.',
        'The emergency protocol overrides standard operating procedures.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Priority',
          description: 'Having greater importance than other factors',
          examples: [
            'The need for immediate medical attention overrode patient confidentiality.',
            'National security interests often override individual privacy rights.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deactivate or bypass an automatic function or system manually',
      partOfSpeech: 'transitive verb',
      examples: [
        'The engineer overrode the safety mechanism to perform maintenance.',
        'You can override the automatic settings by switching to manual mode.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Technical',
          description: 'Manual intervention in automated processes',
          examples: [
            'The pilot overrode the autopilot to avoid the storm.',
            'The IT administrator overrode the security protocols during the system upgrade.',
          ],
        ),
        ContextualUsage(
          context: 'Computing',
          description: 'Replacing default functions or settings in programming',
          examples: [
            'The developer overrode the parent class method with a custom implementation.',
            'Users can override the default settings in the configuration file.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'overtake',
  base: 'overtake',
  past: 'overtook',
  participle: 'overtaken',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˌoʊvərˈteɪk',
  pronunciationTextUK: 'ˌəʊvəˈteɪk',
  meanings: [
    VerbMeaning(
      definition: 'To catch up with and pass while moving',
      partOfSpeech: 'transitive verb',
      examples: [
        'The sports car overtook the truck on the highway.',
        'The runner gradually overtook her competitors in the final lap.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Driving',
          description: 'Passing another vehicle while in motion',
          examples: [
            'She overtook the slow-moving bus on the straight stretch of road.',
            'It\'s illegal to overtake on a solid white line in many countries.',
          ],
        ),
        ContextualUsage(
          context: 'Sports',
          description: 'Passing competitors during a race or contest',
          examples: [
            'The cyclist overtook the leader just before the finish line.',
            'Their team overtook the frontrunners in the final quarter.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To catch up with and affect suddenly or unexpectedly',
      partOfSpeech: 'transitive verb',
      examples: [
        'Night overtook the hikers before they reached the cabin.',
        'A sense of despair overtook him as he read the letter.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Circumstance',
          description: 'Being caught in unexpected situations or conditions',
          examples: [
            'The storm overtook the small boat miles from shore.',
            'Old age seems to have overtaken him suddenly this past year.',
          ],
        ),
        ContextualUsage(
          context: 'Emotion',
          description: 'Being suddenly affected by strong feelings',
          examples: [
            'A wave of nostalgia overtook her when she saw her childhood home.',
            'Panic overtook the crowd when they heard the explosion.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become greater in amount or importance than something else',
      partOfSpeech: 'transitive verb',
      examples: [
        'Online sales have overtaken in-store purchases for the company.',
        'Environmental concerns have overtaken economic factors in the debate.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Surpassing competing products, services, or metrics',
          examples: [
            'Their new smartphone has overtaken rivals in market share.',
            'Streaming services have overtaken traditional television in popularity.',
          ],
        ),
        ContextualUsage(
          context: 'Development',
          description: 'Progress or trends exceeding others',
          examples: [
            'China has overtaken many Western countries in renewable energy production.',
            'Digital skills have overtaken traditional qualifications in importance for many jobs.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'partake',
  base: 'partake',
  past: 'partook',
  participle: 'partaken',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'pɑrˈteɪk',
  pronunciationTextUK: 'pɑːˈteɪk',
  meanings: [
    VerbMeaning(
      definition: 'To participate in or be involved in an activity',
      partOfSpeech: 'intransitive verb',
      examples: [
        'All employees are invited to partake in the company retreat.',
        'She decided not to partake in the debate about politics.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Participation',
          description: 'Joining in organized activities or events',
          examples: [
            'The students partook in various extracurricular activities.',
            'He regularly partakes in community service projects.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'Formal usage for participation',
          examples: [
            'Citizens are encouraged to partake in the democratic process.',
            'The dignitaries partook in the ceremonial proceedings.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To eat or drink something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Would you care to partake of some refreshments?',
        'The guests partook of the lavish buffet dinner.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Dining',
          description: 'Formal or elevated expression for consuming food or drink',
          examples: [
            'The diners partook of the chef\'s special tasting menu.',
            'After the ceremony, everyone partook of champagne and canapés.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To share in or receive a portion of something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'All shareholders will partake in the profits.',
        'The winners partook of the glory that came with their achievement.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Distribution',
          description: 'Receiving a share of something distributed',
          examples: [
            'Those who invested early partook of the substantial returns.',
            'All team members partake in both the successes and failures of the project.',
          ],
        ),
        ContextualUsage(
          context: 'Experience',
          description: 'Sharing in qualities or experiences',
          examples: [
            'The audience partook of the emotion conveyed by the powerful performance.',
            'By reading great literature, we partake of the wisdom of past generations.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'rebuild',
  base: 'rebuild',
  past: 'rebuilt',
  participle: 'rebuilt',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'riːˈbɪld',
  pronunciationTextUK: 'riːˈbɪld',
  meanings: [
    VerbMeaning(
      definition: 'To build again after damage or destruction',
      partOfSpeech: 'transitive verb',
      examples: [
        'They rebuilt their house after the hurricane destroyed it.',
        'The ancient temple was rebuilt after being discovered by archaeologists.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Construction',
          description: 'Physical reconstruction of structures',
          examples: [
            'The city center was rebuilt following the earthquake.',
            'Engineers rebuilt the bridge using stronger materials.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Restoration of historical structures',
          examples: [
            'The medieval cathedral was faithfully rebuilt after the fire.',
            'They are rebuilding the ancient fortress based on archaeological evidence.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To restore to a previous or better condition',
      partOfSpeech: 'transitive verb',
      examples: [
        'The mechanic rebuilt the engine, and now it runs perfectly.',
        'The coach is rebuilding the team after several key players retired.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mechanical',
          description: 'Restoring machinery or equipment',
          examples: [
            'They rebuilt the transmission with new parts.',
            'The classic car\'s interior was completely rebuilt to original specifications.',
          ],
        ),
        ContextualUsage(
          context: 'Organizational',
          description: 'Restructuring groups or teams',
          examples: [
            'The new CEO is rebuilding the executive leadership team.',
            'After the merger, they had to rebuild the entire department.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reestablish or restore something abstract',
      partOfSpeech: 'transitive verb',
      examples: [
        'It took years to rebuild trust after the scandal.',
        'She is working to rebuild her career after a long break.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Relationships',
          description: 'Restoring damaged personal connections',
          examples: [
            'The couple is trying to rebuild their marriage after a difficult period.',
            'He spent years rebuilding relationships with his estranged family members.',
          ],
        ),
        ContextualUsage(
          context: 'Reputation',
          description: 'Restoring damaged standing or image',
          examples: [
            'The company launched a campaign to rebuild its reputation after the product recall.',
            'The politician worked hard to rebuild public trust after the controversy.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'redo',
  base: 'redo',
  past: 'redid',
  participle: 'redone',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'riːˈduː',
  pronunciationTextUK: 'riːˈduː',
  meanings: [
    VerbMeaning(
      definition: 'To do again or repeat',
      partOfSpeech: 'transitive verb',
      examples: [
        'The teacher asked the student to redo the assignment.',
        'I had to redo my calculations after discovering an error.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Correction',
          description: 'Repeating a task to fix mistakes',
          examples: [
            'The contractor had to redo the electrical wiring to meet code requirements.',
            'She redid the entire presentation after receiving feedback from her manager.',
          ],
        ),
        ContextualUsage(
          context: 'Education',
          description: 'Repeating academic work',
          examples: [
            'Students who fail the course must redo it the following semester.',
            'He redid his science experiment to get more accurate results.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To renovate or redecorate',
      partOfSpeech: 'transitive verb',
      examples: [
        'They\'re redoing the kitchen with modern appliances.',
        'She redid her entire wardrobe for the new season.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Home Improvement',
          description: 'Renovating or redecorating spaces',
          examples: [
            'We\'re redoing the bathroom with a walk-in shower and new tiles.',
            'They redid their living room in a mid-century modern style.',
          ],
        ),
        ContextualUsage(
          context: 'Fashion',
          description: 'Updating or changing appearance',
          examples: [
            'The designer redid the classic jacket with contemporary details.',
            'She redid her hair color from brunette to blonde.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reorganize or restructure',
      partOfSpeech: 'transitive verb',
      examples: [
        'The company redid its entire business model to stay competitive.',
        'The editor redid the layout of the magazine for better readability.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Organizational',
          description: 'Changing structure or systems',
          examples: [
            'The new management team redid the company\'s reporting structure.',
            'The developer redid the app\'s interface based on user feedback.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'remake',
  base: 'remake',
  past: 'remade',
  participle: 'remade',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'riːˈmeɪk',
  pronunciationTextUK: 'riːˈmeɪk',
  meanings: [
    VerbMeaning(
      definition: 'To make something again or differently',
      partOfSpeech: 'transitive verb',
      examples: [
        'The tailor remade the dress to fit the client better.',
        'She remade the salad with fresh ingredients.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Craftsmanship',
          description: 'Creating an item again with modifications',
          examples: [
            'The jeweler remade the heirloom ring in a more modern style.',
            'The potter remade the vase after it cracked during firing.',
          ],
        ),
        ContextualUsage(
          context: 'Production',
          description: 'Manufacturing or producing something again',
          examples: [
            'The factory remade the product with improved materials.',
            'The chef remade the sauce because the first attempt was too salty.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To produce a new version of a film, song, or other creative work',
      partOfSpeech: 'transitive verb',
      examples: [
        'The director remade the classic film for a new generation.',
        'The band remade their earlier hit with a contemporary sound.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Entertainment',
          description: 'Creating new versions of existing creative works',
          examples: [
            'Hollywood has remade many foreign films for American audiences.',
            'The composer remade the traditional folk songs with electronic elements.',
          ],
        ),
        ContextualUsage(
          context: 'Adaptation',
          description: 'Updating works for new audiences or formats',
          examples: [
            'The production company remade the stage play as a television series.',
            'Artists often remake classic paintings with modern interpretations.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To transform or change something completely',
      partOfSpeech: 'transitive verb',
      examples: [
        'The experience remade him into a more compassionate person.',
        'Technology has remade how we communicate with each other.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Personal',
          description: 'Profound transformation of character or identity',
          examples: [
            'The tragedy remade her outlook on life completely.',
            'Military service remade the young recruit into a disciplined leader.',
          ],
        ),
        ContextualUsage(
          context: 'Societal',
          description: 'Transforming institutions or social structures',
          examples: [
            'The revolution remade the country\'s political system.',
            'The internet has remade business models across industries.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'rethink',
  base: 'rethink',
  past: 'rethought',
  participle: 'rethought',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'riːˈθɪŋk',
  pronunciationTextUK: 'riːˈθɪŋk',
  meanings: [
    VerbMeaning(
      definition: 'To think about again and change one\'s mind',
      partOfSpeech: 'transitive verb',
      examples: [
        'She rethought her decision to quit her job.',
        'We need to rethink our strategy after the recent setback.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Decision',
          description: 'Reconsidering previous choices',
          examples: [
            'The committee rethought the project after the budget was cut.',
            'He rethought his travel plans due to the weather forecast.',
          ],
        ),
        ContextualUsage(
          context: 'Planning',
          description: 'Revising plans or strategies',
          examples: [
            'The company is rethinking its approach to remote work.',
            'After the failed prototype, engineers rethought the entire design.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reconsider deeply and thoroughly',
      partOfSpeech: 'transitive verb',
      examples: [
        'The crisis forced us to rethink our priorities.',
        'Scholars are rethinking the traditional interpretation of these historical events.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Conceptual',
          description: 'Fundamentally reconsidering ideas or beliefs',
          examples: [
            'The new research has led scientists to rethink their theories about dark matter.',
            'The pandemic has made many people rethink their work-life balance.',
          ],
        ),
        ContextualUsage(
          context: 'Analytical',
          description: 'Deep reconsideration of systems or frameworks',
          examples: [
            'Educators are rethinking traditional classroom models.',
            'The philosopher\'s work encouraged readers to rethink their assumptions about ethics.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To think through from the beginning',
      partOfSpeech: 'transitive verb',
      examples: [
        'I had to rethink the entire problem from first principles.',
        'The architect rethought the building\'s layout to improve energy efficiency.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Innovation',
          description: 'Fresh approach to solving problems',
          examples: [
            'The startup rethought how grocery delivery could work in urban areas.',
            'We need to completely rethink our approach to renewable energy.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'retell',
  base: 'retell',
  past: 'retold',
  participle: 'retold',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'riːˈtɛl',
  pronunciationTextUK: 'riːˈtɛl',
  meanings: [
    VerbMeaning(
      definition: 'To tell a story or account again, often in a different way',
      partOfSpeech: 'transitive verb',
      examples: [
        'The grandmother retold the folktales she had heard in her childhood.',
        'He retold the events of the accident to the police officer.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Narrative',
          description: 'Repeating stories or accounts',
          examples: [
            'The author retold classic fairy tales with modern settings.',
            'The witness retold what she had seen that night.',
          ],
        ),
        ContextualUsage(
          context: 'Educational',
          description: 'Recounting information for learning purposes',
          examples: [
            'Students were asked to retell the story in their own words.',
            'The teacher retold the historical event in simpler terms for younger students.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To recount or relate an experience or event',
      partOfSpeech: 'transitive verb',
      examples: [
        'Veterans often retell their war experiences to younger generations.',
        'She retold her adventure with great enthusiasm.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Personal',
          description: 'Sharing personal experiences',
          examples: [
            'Grandparents love to retell stories from their youth to their grandchildren.',
            'He retold his encounter with the celebrity in vivid detail.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Recounting historical events',
          examples: [
            'The documentary retold the events leading up to the revolution.',
            'The tour guide retold the castle\'s history to the visiting group.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To adapt or reinterpret a story for a new audience',
      partOfSpeech: 'transitive verb',
      examples: [
        'The playwright retold Shakespeare\'s tragedy in a contemporary setting.',
        'Each culture retold the ancient myth according to their own values.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Adaptation',
          description: 'Modifying stories for different audiences or purposes',
          examples: [
            'The director retold the classic novel as a dystopian film.',
            'The children\'s book retold complex scientific concepts through simple analogies.',
          ],
        ),
        ContextualUsage(
          context: 'Cultural',
          description: 'Transmitting stories across cultural boundaries',
          examples: [
            'Folk musicians retold historical events through their songs.',
            'Each generation retells important cultural narratives in their own way.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'rewrite',
  base: 'rewrite',
  past: 'rewrote',
  participle: 'rewritten',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'riːˈraɪt',
  pronunciationTextUK: 'riːˈraɪt',
  meanings: [
    VerbMeaning(
      definition: 'To write again in a different form or manner',
      partOfSpeech: 'transitive verb',
      examples: [
        'The author rewrote the ending of her novel before publication.',
        'Please rewrite your essay to address the professor\'s comments.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Editing',
          description: 'Revising written material for improvement',
          examples: [
            'The journalist rewrote the article to make it more concise.',
            'She rewrote her resume to highlight her relevant experience.',
          ],
        ),
        ContextualUsage(
          context: 'Academic',
          description: 'Revising academic or educational work',
          examples: [
            'The student rewrote his thesis after receiving feedback from his advisor.',
            'The researcher rewrote the paper to address the reviewers\' concerns.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To revise or adapt a text or story into a new version',
      partOfSpeech: 'transitive verb',
      examples: [
        'The screenwriter rewrote the novel for the big screen.',
        'They rewrote the classic play to appeal to modern audiences.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Adaptation',
          description: 'Transforming content between different media or formats',
          examples: [
            'The filmmaker rewrote the complex story into a streamlined screenplay.',
            'The publisher asked him to rewrite the adult book for younger readers.',
          ],
        ),
        ContextualUsage(
          context: 'Creative',
          description: 'Creating new versions of existing works',
          examples: [
            'Each generation of historians rewrites history according to their perspective.',
            'The composer rewrote the traditional melody with a jazz influence.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To change something substantially',
      partOfSpeech: 'transitive verb',
      examples: [
        'The new legislation rewrote the rules of corporate taxation.',
        'These technological advances have rewritten how we communicate.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Transformation',
          description: 'Fundamental change to systems or processes',
          examples: [
            'The revolution rewrote the country\'s constitution and legal system.',
            'This discovery has rewritten our understanding of early human migration.',
          ],
        ),
        ContextualUsage(
          context: 'Figurative',
          description: 'Metaphorical transformation of non-textual elements',
          examples: [
            'That moment of inspiration rewrote his entire career path.',
            'The team\'s victory rewrote all expectations for the season.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shine',
  base: 'shine',
  past: 'shone/shined',
  participle: 'shone/shined',
  pastUK: 'shone',
  pastUS: 'shined/shone',
  participleUK: 'shone',
  participleUS: 'shined/shone',
  pronunciationTextUS: 'ʃaɪn',
  pronunciationTextUK: 'ʃaɪn',
  meanings: [
    VerbMeaning(
      definition: 'To emit light or be bright with reflected light',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The sun shone brightly in the clear blue sky.',
        'Her diamond ring shone in the candlelight.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Natural',
          description: 'Light emitted by natural sources',
          examples: [
            'The full moon shone through the bedroom window.',
            'Stars shone like diamonds against the black velvet of the night sky.',
          ],
        ),
        ContextualUsage(
          context: 'Reflection',
          description: 'Light reflected from surfaces',
          examples: [
            'The freshly polished silverware shone on the dining table.',
            'The wet pavement shone under the streetlights after the rain.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To polish or make something bright by rubbing',
      partOfSpeech: 'transitive verb',
      examples: [
        'He shined his shoes before the interview.',
        'The maid shined the brass doorknobs until they gleamed.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Cleaning',
          description: 'Making objects bright through polishing',
          examples: [
            'The cadets shined their boots and belt buckles for inspection.',
            'She shined the silver cutlery for the dinner party.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To excel or be outstanding at something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He really shines in mathematics.',
        'The young actress shone in her first leading role.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Performance',
          description: 'Exceptional achievement or display of talent',
          examples: [
            'The goalkeeper shone throughout the match, making several spectacular saves.',
            'She shines when speaking in public, captivating her audience effortlessly.',
          ],
        ),
        ContextualUsage(
          context: 'Recognition',
          description: 'Standing out positively',
          examples: [
            'His kindness shone through even in difficult situations.',
            'Her intelligence really shone during the debate competition.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To direct or aim a light at someone or something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The security guard shined his flashlight into the dark warehouse.',
        'Protesters had lights shined in their faces by police.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Illumination',
          description: 'Directing light for visibility',
          examples: [
            'The rescue team shined powerful searchlights over the rough sea.',
            'The dentist shined a small light into the patient\'s mouth.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shrive',
  base: 'shrive',
  past: 'shrove/shrived',
  participle: 'shriven/shrived',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʃraɪv',
  pronunciationTextUK: 'ʃraɪv',
  meanings: [
    VerbMeaning(
      definition: 'To hear the confession of and grant absolution to',
      partOfSpeech: 'transitive verb',
      examples: [
        'The priest shrove the penitent sinner.',
        'The elderly clergyman had shriven thousands during his long career.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Religious',
          description: 'Christian practice of confession and absolution',
          examples: [
            'Before battle, priests would shrive soldiers who feared death.',
            'The dying man asked to be shriven before his passing.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional religious practices in past eras',
          examples: [
            'Medieval Christians were expected to be shriven at least once a year.',
            'The abbot shrove the monks during the solemn ceremony.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To confess one\'s sins and receive absolution',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The faithful would shrive before taking communion.',
        'He had shriven regularly throughout his adult life.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Penitence',
          description: 'Act of seeking forgiveness through confession',
          examples: [
            'Pilgrims traveled long distances to shrive at the famous cathedral.',
            'The community would shrive before the Easter celebrations.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To free from guilt or the burden of sin',
      partOfSpeech: 'transitive verb',
      examples: [
        'He hoped the confession would shrive him of his guilty conscience.',
        'The ritual was meant to shrive the participants of their past misdeeds.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Symbolic or secular release from guilt',
          examples: [
            'The public apology seemed to shrive the politician in the eyes of many voters.',
            'Writing the memoir shrove her of the secrets she had kept for decades.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Poetic or archaic usage in literature',
          examples: [
            'The character sought to be shriven through his acts of charity.',
            'In the novel, nature itself seemed to shrive the protagonist of his sins.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'slink',
  base: 'slink',
  past: 'slunk',
  participle: 'slunk',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'slɪŋk',
  pronunciationTextUK: 'slɪŋk',
  meanings: [
    VerbMeaning(
      definition: 'To move in a stealthy, furtive manner',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The thief slunk through the darkened house.',
        'The cat slunk across the garden, stalking a bird.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Secretive or sneaky movement',
          examples: [
            'The teenager slunk into the house after curfew, hoping not to wake anyone.',
            'The fox slunk around the henhouse, looking for a way in.',
          ],
        ),
        ContextualUsage(
          context: 'Animal',
          description: 'Characteristic movement of certain animals',
          examples: [
            'The panther slunk through the jungle undergrowth, nearly invisible.',
            'Wolves can slink silently through the forest when hunting.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To go or move in a shameful, guilty, or reluctant manner',
      partOfSpeech: 'intransitive verb',
      examples: [
        'After losing the argument, he slunk away in embarrassment.',
        'The disgraced politician slunk out of the press conference.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Shame',
          description: 'Movement motivated by embarrassment or guilt',
          examples: [
            'The student slunk to the back of the classroom after arriving late.',
            'He slunk away from the party after spilling wine on the host.',
          ],
        ),
        ContextualUsage(
          context: 'Defeat',
          description: 'Retreating after failure or loss',
          examples: [
            'The team slunk off the field after the crushing defeat.',
            'The rejected suitor slunk away without another word.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To give birth to young prematurely',
      partOfSpeech: 'transitive verb',
      examples: [
        'The cow slunk her calf two weeks early.',
        'Stress can cause animals to slink their young.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Veterinary',
          description: 'Technical term for premature birth in animals',
          examples: [
            'The mare slunk her foal after being frightened by thunder.',
            'The farmer was concerned when several sheep slunk their lambs in the same week.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'smite',
  base: 'smite',
  past: 'smote',
  participle: 'smitten',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'smaɪt',
  pronunciationTextUK: 'smaɪt',
  meanings: [
    VerbMeaning(
      definition: 'To strike with a heavy blow or weapon',
      partOfSpeech: 'transitive verb',
      examples: [
        'The warrior smote his enemy with his sword.',
        'The boxer smote his opponent with a powerful right hook.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Biblical',
          description: 'Used in religious texts for divine punishment',
          examples: [
            'God smote the sinful city with fire and brimstone.',
            'The angel smote the firstborn of Egypt.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Archaic or poetic usage in literature',
          examples: [
            'The knight smote the dragon with his mighty lance.',
            'The giant was smitten by the hero\'s magical weapon.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To afflict or affect severely',
      partOfSpeech: 'transitive verb',
      examples: [
        'The village was smitten by a terrible plague.',
        'The crops were smote by an early frost.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Disaster',
          description: 'Being affected by calamity or misfortune',
          examples: [
            'The coastal region was smitten by a devastating hurricane.',
            'The community was smote by economic hardship after the factory closed.',
          ],
        ),
        ContextualUsage(
          context: 'Disease',
          description: 'Being afflicted by illness or epidemic',
          examples: [
            'The population was smitten by a mysterious illness.',
            'The flock was smote by a contagious disease.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To captivate or affect strongly with love or infatuation',
      partOfSpeech: 'transitive verb',
      examples: [
        'He was smitten with her beauty from the moment they met.',
        'The critic was smitten by the young artist\'s talent.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Romantic',
          description: 'Being struck by feelings of love or attraction',
          examples: [
            'The bachelor was completely smitten with his new neighbor.',
            'She was smitten by his charm and intelligence.',
          ],
        ),
        ContextualUsage(
          context: 'Admiration',
          description: 'Being strongly impressed by qualities or abilities',
          examples: [
            'The audience was smitten by the violinist\'s virtuoso performance.',
            'The professor was smitten with the student\'s brilliant analysis.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'speed',
  base: 'speed',
  past: 'sped/speeded',
  participle: 'sped/speeded',
  pastUK: 'sped',
  pastUS: 'sped/speeded',
  participleUK: 'sped',
  participleUS: 'sped/speeded',
  pronunciationTextUS: 'spiːd',
  pronunciationTextUK: 'spiːd',
  meanings: [
    VerbMeaning(
      definition: 'To move quickly or at a rate faster than usual',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The car sped down the highway at over ninety miles per hour.',
        'Time seems to speed up as you get older.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Motion',
          description: 'Moving rapidly through space',
          examples: [
            'The motorcyclist sped through the narrow streets.',
            'The falcon sped toward its prey with incredible velocity.',
          ],
        ),
        ContextualUsage(
          context: 'Temporal',
          description: 'Passage of time seeming to accelerate',
          examples: [
            'The final days of vacation always speed by too quickly.',
            'The semester sped past before the students were ready for finals.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause to move or proceed faster',
      partOfSpeech: 'transitive verb',
      examples: [
        'New technology has sped the transmission of information.',
        'The manager sped the project along to meet the deadline.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Process',
          description: 'Accelerating procedures or operations',
          examples: [
            'The new software sped up the data processing considerably.',
            'The government speeded the approval process for disaster victims.',
          ],
        ),
        ContextualUsage(
          context: 'Development',
          description: 'Hastening progress or advancement',
          examples: [
            'The additional funding sped the research toward a breakthrough.',
            'Technological innovations have sped human progress in the last century.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To help someone on their way',
      partOfSpeech: 'transitive verb',
      examples: [
        'We sped them on their journey with our best wishes.',
        'The host sped the last guests home after the party.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Assistance',
          description: 'Aiding or facilitating someone\'s departure',
          examples: [
            'The tailwind sped the sailors on their voyage home.',
            'Her parents sped her off to college with tearful goodbyes.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Formal or archaic usage in literature',
          examples: [
            'The king sped the messengers to deliver his proclamation.',
            'The goddess sped the hero on his quest with divine gifts.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spell',
  base: 'spell',
  past: 'spelled/spelt',
  participle: 'spelled/spelt',
  pastUK: 'spelt',
  pastUS: 'spelled',
  participleUK: 'spelt',
  participleUS: 'spelled',
  pronunciationTextUS: 'spɛl',
  pronunciationTextUK: 'spel',
  meanings: [
    VerbMeaning(
      definition: 'To name, write, or print the letters of a word in correct sequence',
      partOfSpeech: 'transitive verb',
      examples: [
        'She spelled her name for the receptionist.',
        'Many students find it difficult to spell long words correctly.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Education',
          description: 'Learning or demonstrating correct orthography',
          examples: [
            'Children often learn to spell through regular practice and reading.',
            'The contestant spelled every word correctly in the competition.',
          ],
        ),
        ContextualUsage(
          context: 'Communication',
          description: 'Clarifying spelling in verbal exchanges',
          examples: [
            'He had to spell his unusual surname over the phone.',
            'The operator asked her to spell the street name to avoid confusion.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take turns at doing something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The parents spelled each other at the child\'s bedside during the illness.',
        'The two workers spelled each other throughout the long shift.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Relief',
          description: 'Temporarily replacing someone to provide a break',
          examples: [
            'The coach spelled the exhausted quarterback in the fourth quarter.',
            'Volunteers spelled the firefighters who had been working for hours.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To signify or portend',
      partOfSpeech: 'transitive verb',
      examples: [
        'Dark clouds spell rain.',
        'These economic indicators spell trouble for the housing market.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Indication',
          description: 'Suggesting or pointing to consequences',
          examples: [
            'The company\'s declining sales spelled disaster for its future.',
            'Her promotion spells a significant salary increase.',
          ],
        ),
        ContextualUsage(
          context: 'Prediction',
          description: 'Foretelling or implying future events',
          examples: [
            'The tension between the countries spells conflict if not addressed.',
            'Rising temperatures spell challenges for agriculture in the region.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To form words with letters',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The child is just learning to spell.',
        'The blocks can be arranged to spell different words.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Literacy',
          description: 'Basic skill of forming words with letters',
          examples: [
            'Some children spell phonetically before learning standard spelling.',
            'Dyslexic students may struggle to spell despite high intelligence.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spill',
  base: 'spill',
  past: 'spilled/spilt',
  participle: 'spilled/spilt',
  pastUK: 'spilt',
  pastUS: 'spilled',
  participleUK: 'spilt',
  participleUS: 'spilled',
  pronunciationTextUS: 'spɪl',
  pronunciationTextUK: 'spɪl',
  meanings: [
    VerbMeaning(
      definition: 'To cause or allow liquid to flow over the edge of its container',
      partOfSpeech: 'transitive verb',
      examples: [
        'She accidentally spilled coffee on her white shirt.',
        'The child spilt milk all over the table.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Accident',
          description: 'Unintentional release of liquid',
          examples: [
            'He spilled wine on the carpet during the dinner party.',
            'The waiter spilt the soup while serving the guests.',
          ],
        ),
        ContextualUsage(
          context: 'Environmental',
          description: 'Release of substances into the environment',
          examples: [
            'The tanker spilled oil into the ocean, causing an ecological disaster.',
            'Chemicals were spilled during the factory accident, requiring evacuation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To flow or run over the edge of a container',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Water spilled over the dam after heavy rainfall.',
        'Tears spilt down her cheeks as she received the news.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Overflow',
          description: 'Liquid exceeding container capacity',
          examples: [
            'The river spilled over its banks during the flood.',
            'Paint spilled across the floor when the can was knocked over.',
          ],
        ),
        ContextualUsage(
          context: 'Emotion',
          description: 'Metaphorical overflow of feelings',
          examples: [
            'Emotions spilled out during the intense conversation.',
            'Words spilled from her mouth as she tried to explain what happened.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause to fall or tumble out',
      partOfSpeech: 'transitive verb',
      examples: [
        'He spilled the contents of his bag onto the table.',
        'The box was knocked over, spilling books across the floor.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Dispersion',
          description: 'Scattering items from a container',
          examples: [
            'The truck accident spilled cargo all over the highway.',
            'She spilled the coins from her purse while searching for her keys.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reveal or disclose information',
      partOfSpeech: 'transitive verb',
      examples: [
        'The witness finally spilled the truth about what he had seen.',
        'The captured spy refused to spill any secrets.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Confession',
          description: 'Revealing withheld information',
          examples: [
            'Under pressure, he spilled the details of the conspiracy.',
            'The suspect spilt everything during the interrogation.',
          ],
        ),
        ContextualUsage(
          context: 'Disclosure',
          description: 'Sharing confidential or private information',
          examples: [
            'The magazine article spilled all the celebrity gossip.',
            'She didn\'t want to spill her friend\'s secret to others.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spoil',
  base: 'spoil',
  past: 'spoiled/spoilt',
  participle: 'spoiled/spoilt',
  pastUK: 'spoilt',
  pastUS: 'spoiled',
  participleUK: 'spoilt',
  participleUS: 'spoiled',
  pronunciationTextUS: 'spɔɪl',
  pronunciationTextUK: 'spɔɪl',
  meanings: [
    VerbMeaning(
      definition: 'To diminish or destroy the value or quality of',
      partOfSpeech: 'transitive verb',
      examples: [
        'The bad weather spoiled our picnic plans.',
        'One rude guest spoilt the entire dinner party.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Experience',
          description: 'Negatively affecting an event or situation',
          examples: [
            'Technical problems spoiled the concert for many attendees.',
            'His negative attitude spoilt what could have been a productive meeting.',
          ],
        ),
        ContextualUsage(
          context: 'Appearance',
          description: 'Marring visual or aesthetic quality',
          examples: [
            'Graffiti spoiled the appearance of the historic building.',
            'A large stain spoilt the otherwise perfect tablecloth.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To decay or become rotten',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The milk spoiled because it was left out of the refrigerator.',
        'Fresh fruit will spoil quickly in hot weather.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Food',
          description: 'Deterioration making food inedible',
          examples: [
            'The vegetables spoiled before we could use them.',
            'Canned goods are designed not to spoil for extended periods.',
          ],
        ),
        ContextualUsage(
          context: 'Preservation',
          description: 'Preventing deterioration of perishable items',
          examples: [
            'Refrigeration prevents food from spoiling too quickly.',
            'The jam was preserved with sugar to keep it from spoiling.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To indulge or pamper excessively',
      partOfSpeech: 'transitive verb',
      examples: [
        'The grandparents spoil their grandchildren with gifts and treats.',
        'He spoilt himself with a luxury vacation after the promotion.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Indulgence',
          description: 'Providing excessive treats or privileges',
          examples: [
            'She spoils her dog with gourmet food and designer accessories.',
            'Parents sometimes spoil their children by giving them everything they want.',
          ],
        ),
        ContextualUsage(
          context: 'Self-care',
          description: 'Treating oneself to luxuries or pleasures',
          examples: [
            'After the difficult project, the team spoiled themselves with a fancy dinner.',
            'She decided to spoil herself with a day at the spa.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take goods or property by force',
      partOfSpeech: 'transitive verb',
      examples: [
        'Ancient armies would spoil conquered cities of their treasures.',
        'The invaders spoilt the village of its food supplies.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Historical',
          description: 'Plundering or looting in warfare',
          examples: [
            'Viking raiders spoiled coastal settlements throughout medieval Europe.',
            'The soldiers spoilt the palace of its gold and jewels.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Archaic usage in literature and historical texts',
          examples: [
            'In the biblical account, the victorious army spoiled the defeated city.',
            'The epic poem described how the hero spoiled his enemies of their weapons.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'stride',
  base: 'stride',
  past: 'strode',
  participle: 'stridden',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'straɪd',
  pronunciationTextUK: 'straɪd',
  meanings: [
    VerbMeaning(
      definition: 'To walk with long, decisive steps',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He strode confidently into the interview room.',
        'She strode across the field toward the waiting crowd.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Purposeful walking with long steps',
          examples: [
            'The businesswoman strode through the airport terminal with determination.',
            'The athlete strode to the starting line with focused intensity.',
          ],
        ),
        ContextualUsage(
          context: 'Confidence',
          description: 'Walking in a manner that displays self-assurance',
          examples: [
            'The new CEO strode into the boardroom as if she owned it.',
            'He strode onto the stage to accept the award, beaming with pride.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cover or traverse by taking long steps',
      partOfSpeech: 'transitive verb',
      examples: [
        'The hiker strode the final miles of the trail despite her exhaustion.',
        'He strode the length of the corridor to reach the emergency exit.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Distance',
          description: 'Covering ground with deliberate steps',
          examples: [
            'The soldier strode the parade ground during inspection.',
            'She strode the beach each morning as part of her exercise routine.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make progress or advancement',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The company continues to stride forward in its industry.',
        'The nation is striding toward energy independence.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Progress',
          description: 'Metaphorical advancement or development',
          examples: [
            'The research team is striding ahead with their breakthrough technology.',
            'The economy strode out of recession into a period of growth.',
          ],
        ),
        ContextualUsage(
          context: 'Achievement',
          description: 'Moving decisively toward goals',
          examples: [
            'The athlete has stridden past all previous records in the sport.',
            'The student strode from one academic success to another.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'string',
  base: 'string',
  past: 'strung',
  participle: 'strung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'strɪŋ',
  pronunciationTextUK: 'strɪŋ',
  meanings: [
    VerbMeaning(
      definition: 'To thread objects on a string, cord, or wire',
      partOfSpeech: 'transitive verb',
      examples: [
        'She strung beads to make a necklace.',
        'The lights were strung across the garden for the party.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Crafts',
          description: 'Creating items by threading components',
          examples: [
            'The artisan strung shells and stones to create coastal-themed decorations.',
            'Children strung popcorn and cranberries for the Christmas tree.',
          ],
        ),
        ContextualUsage(
          context: 'Decoration',
          description: 'Arranging items on lines for display',
          examples: [
            'The crew strung festive banners along the main street.',
            'Paper lanterns were strung between trees to light the garden party.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To equip something with strings or cords',
      partOfSpeech: 'transitive verb',
      examples: [
        'He strung his tennis racket with new strings.',
        'The musician strung her guitar before the performance.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Musical',
          description: 'Preparing string instruments',
          examples: [
            'The luthier strung the new violin with high-quality strings.',
            'She strung her harp with nylon strings for a softer sound.',
          ],
        ),
        ContextualUsage(
          context: 'Sports',
          description: 'Preparing sports equipment',
          examples: [
            'The technician strung the badminton racquets at high tension for competitive play.',
            'He strung his bow carefully before the archery competition.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To arrange or connect in a sequence or series',
      partOfSpeech: 'transitive verb',
      examples: [
        'The author strung together several anecdotes to make his point.',
        'The prosecutor strung the evidence into a compelling narrative.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Verbal',
          description: 'Connecting words or ideas in sequence',
          examples: [
            'The politician strung together impressive statistics to support his argument.',
            'She strung her thoughts together in a coherent presentation.',
          ],
        ),
        ContextualUsage(
          context: 'Organization',
          description: 'Arranging items or events in a sequence',
          examples: [
            'The documentary strung historical events together chronologically.',
            'The company strung several small acquisitions into a major expansion.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deceive or mislead over time',
      partOfSpeech: 'transitive verb',
      examples: [
        'He strung her along for months with false promises.',
        'The scammer strung along multiple victims simultaneously.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Deception',
          description: 'Misleading someone with false expectations',
          examples: [
            'The company strung along potential investors with optimistic projections.',
            'He strung his girlfriend along for years without any intention of marriage.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'swell',
  base: 'swell',
  past: 'swelled',
  participle: 'swollen/swelled',
  pastUK: '',
  pastUS: '',
  participleUK: 'swollen',
  participleUS: 'swollen/swelled',
  pronunciationTextUS: 'swɛl',
  pronunciationTextUK: 'swel',
  meanings: [
    VerbMeaning(
      definition: 'To increase in size, volume, or intensity',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The river swelled after days of heavy rain.',
        'The crowd swelled as more people arrived for the concert.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Natural',
          description: 'Physical expansion due to natural causes',
          examples: [
            'The wood swelled when exposed to moisture.',
            'Ocean waves swell before breaking on the shore.',
          ],
        ),
        ContextualUsage(
          context: 'Growth',
          description: 'Increase in quantity or number',
          examples: [
            'Their savings swelled over the years of careful budgeting.',
            'The organization\'s membership has swollen to over ten thousand.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become larger or more distended due to injury or illness',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Her ankle swelled after she sprained it.',
        'His eye had swollen shut from the bee sting.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Medical',
          description: 'Bodily inflammation or edema',
          examples: [
            'The patient\'s lymph nodes were swollen due to infection.',
            'His knee swelled badly following the sports injury.',
          ],
        ),
        ContextualUsage(
          context: 'Injury',
          description: 'Reaction to physical trauma',
          examples: [
            'The boxer\'s face swelled from repeated blows during the match.',
            'Her fingers swelled in the cold weather due to poor circulation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be filled with a powerful emotion',
      partOfSpeech: 'intransitive verb',
      examples: [
        'His heart swelled with pride as he watched his daughter graduate.',
        'Her chest swelled with emotion at the beautiful music.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Intense feeling causing a physical sensation',
          examples: [
            'The audience\'s hearts swelled as the orchestra played the national anthem.',
            'His chest swelled with courage as he prepared to face the challenge.',
          ],
        ),
        ContextualUsage(
          context: 'Pride',
          description: 'Feeling of satisfaction or fulfillment',
          examples: [
            'The parents\' hearts swelled with pride at their child\'s accomplishment.',
            'The team\'s confidence swelled after their string of victories.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause to increase in size or volume',
      partOfSpeech: 'transitive verb',
      examples: [
        'The heavy rains swelled the river to dangerous levels.',
        'Late arrivals swelled the audience to capacity.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Expansion',
          description: 'Causing something to become larger',
          examples: [
            'The additional funding swelled the project\'s budget considerably.',
            'New evidence swelled the case against the defendant.',
          ],
        ),
        ContextualUsage(
          context: 'Sound',
          description: 'Increasing volume or intensity of music',
          examples: [
            'The conductor swelled the orchestra\'s volume for the climactic finale.',
            'The organ music swelled to fill the cathedral.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'tread',
  base: 'tread',
  past: 'trod',
  participle: 'trodden/trod',
  pastUK: '',
  pastUS: '',
  participleUK: 'trodden',
  participleUS: 'trodden/trod',
  pronunciationTextUS: 'trɛd',
  pronunciationTextUK: 'tred',
  meanings: [
    VerbMeaning(
      definition: 'To walk or step on or over',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'Be careful not to tread on the flower beds.',
        'They trod carefully across the frozen lake.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Physical act of stepping',
          examples: [
            'The hikers trod quietly so as not to disturb the wildlife.',
            'She trod lightly on the creaking floorboards to avoid waking the baby.',
          ],
        ),
        ContextualUsage(
          context: 'Location',
          description: 'Walking in specific places',
          examples: [
            'Few foreigners had trodden on this remote island before.',
            'The pilgrim felt honored to tread where saints had walked centuries ago.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To press down with the foot',
      partOfSpeech: 'transitive verb',
      examples: [
        'She trod the grapes to make wine.',
        'The carpenter trod the pedal to operate the lathe.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Manufacturing',
          description: 'Using feet in production processes',
          examples: [
            'In traditional winemaking, workers trod the grapes by foot.',
            'The potter trod the wheel to keep it spinning while shaping the clay.',
          ],
        ),
        ContextualUsage(
          context: 'Operation',
          description: 'Using foot pressure to control machines',
          examples: [
            'The driver trod the brake pedal firmly at the red light.',
            'The seamstress trod the sewing machine pedal rhythmically.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To follow a path or course of action',
      partOfSpeech: 'transitive verb',
      examples: [
        'She trod the path to success through hard work and determination.',
        'He chose to tread a different route than his siblings.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Figurative',
          description: 'Following a course metaphorically',
          examples: [
            'The diplomat had to tread a fine line between honesty and diplomacy.',
            'Many have trod this difficult journey before you.',
          ],
        ),
        ContextualUsage(
          context: 'Career',
          description: 'Following a professional or life path',
          examples: [
            'She decided to tread in her father\'s footsteps and become a doctor.',
            'Few dare to tread the path of true artistic innovation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To crush or press down by stepping',
      partOfSpeech: 'transitive verb',
      examples: [
        'They trod the snow down to make a path.',
        'The protesters\' signs were trodden underfoot by the crowd.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Compression',
          description: 'Flattening or compacting by stepping',
          examples: [
            'Sheep had trodden the grass into mud around the water trough.',
            'Over centuries, visitors had trodden a visible path to the ancient monument.',
          ],
        ),
        ContextualUsage(
          context: 'Destruction',
          description: 'Damaging by stepping on',
          examples: [
            'The valuable documents were accidentally trodden underfoot during the move.',
            'His dreams were trodden on by unsupportive relatives.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'unbend',
  base: 'unbend',
  past: 'unbent',
  participle: 'unbent',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʌnˈbɛnd',
  pronunciationTextUK: 'ʌnˈbend',
  meanings: [
    VerbMeaning(
      definition: 'To straighten something that is bent or curved',
      partOfSpeech: 'transitive verb',
      examples: [
        'The metalworker unbent the twisted pipe.',
        'She tried to unbend the paperclip back to its original shape.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Returning bent objects to straight form',
          examples: [
            'The mechanic unbent the damaged fender as best he could.',
            'It\'s difficult to unbend the wire without weakening it.',
          ],
        ),
        ContextualUsage(
          context: 'Repair',
          description: 'Correcting deformed items',
          examples: [
            'He carefully unbent the pages of the book that had been folded.',
            'The jeweler unbent the gold ring to resize it.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To relax or become less formal or rigid',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The strict teacher finally unbent and smiled at the joke.',
        'He unbent a little at the party after a few drinks.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Relaxing formal behavior in social situations',
          examples: [
            'The CEO unbent during the company retreat and joined in the fun activities.',
            'She rarely unbends in professional settings, maintaining her serious demeanor.',
          ],
        ),
        ContextualUsage(
          context: 'Attitude',
          description: 'Becoming less rigid or strict',
          examples: [
            'The judge unbent enough to show compassion in this particular case.',
            'The strict father finally unbent and allowed his daughter to attend the concert.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To release from tension or constraint',
      partOfSpeech: 'transitive verb',
      examples: [
        'After winning the case, the lawyer unbent his mind with a vacation.',
        'She unbent her rigid schedule to accommodate the unexpected guests.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mental',
          description: 'Releasing mental pressure or strain',
          examples: [
            'The artist unbent his concentration after hours of detailed work.',
            'It takes time for some people to unbend their minds after a stressful workday.',
          ],
        ),
        ContextualUsage(
          context: 'Rules',
          description: 'Relaxing rules or requirements',
          examples: [
            'The college unbent its strict admission requirements for exceptional candidates.',
            'The committee unbent the regulations to accommodate special circumstances.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'undergo',
  base: 'undergo',
  past: 'underwent',
  participle: 'undergone',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˌʌndərˈɡoʊ',
  pronunciationTextUK: 'ˌʌndəˈɡəʊ',
  meanings: [
    VerbMeaning(
      definition: 'To experience or be subjected to something, typically unpleasant',
      partOfSpeech: 'transitive verb',
      examples: [
        'The patient underwent surgery last week.',
        'The company underwent massive restructuring after the merger.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Medical',
          description: 'Experiencing medical procedures or treatments',
          examples: [
            'She underwent chemotherapy for six months.',
            'The athlete underwent rehabilitation following the knee injury.',
          ],
        ),
        ContextualUsage(
          context: 'Testing',
          description: 'Being subjected to examination or evaluation',
          examples: [
            'All candidates must undergo a background check.',
            'The product underwent rigorous testing before being approved for sale.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To experience a change in condition, appearance, or character',
      partOfSpeech: 'transitive verb',
      examples: [
        'The neighborhood has undergone dramatic improvement in recent years.',
        'His personality underwent a profound transformation after the accident.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Transformation',
          description: 'Experiencing fundamental changes',
          examples: [
            'The city underwent rapid industrialization during the nineteenth century.',
            'Their relationship underwent a significant shift after they moved in together.',
          ],
        ),
        ContextualUsage(
          context: 'Development',
          description: 'Process of growth or evolution',
          examples: [
            'The manuscript underwent several revisions before publication.',
            'The theory has undergone considerable refinement since it was first proposed.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To endure or withstand hardship or difficulty',
      partOfSpeech: 'transitive verb',
      examples: [
        'The explorers underwent extreme hardship during their expedition.',
        'The refugees underwent terrible suffering before reaching safety.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Hardship',
          description: 'Enduring difficult conditions or experiences',
          examples: [
            'Soldiers undergo intense training before deployment.',
            'The population underwent severe deprivation during the economic crisis.',
          ],
        ),
        ContextualUsage(
          context: 'Psychological',
          description: 'Experiencing emotional or mental challenges',
          examples: [
            'She underwent considerable stress while caring for her ill parent.',
            'Many teenagers undergo identity crises as they mature.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'undertake',
  base: 'undertake',
  past: 'undertook',
  participle: 'undertaken',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ˌʌndərˈteɪk',
  pronunciationTextUK: 'ˌʌndəˈteɪk',
  meanings: [
    VerbMeaning(
      definition: 'To commit oneself to and begin a task or enterprise',
      partOfSpeech: 'transitive verb',
      examples: [
        'The company undertook the construction of the new bridge.',
        'She has undertaken to write a comprehensive history of the region.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Projects',
          description: 'Beginning significant tasks or initiatives',
          examples: [
            'The government undertook a massive infrastructure renovation program.',
            'The researcher undertook a five-year study of marine ecosystems.',
          ],
        ),
        ContextualUsage(
          context: 'Responsibility',
          description: 'Accepting responsibility for tasks',
          examples: [
            'The law firm undertook the defense of the controversial case.',
            'He undertook the management of his family\'s business during the crisis.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To promise or guarantee to do something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The contractor undertook to complete the project by March.',
        'She undertook to represent her colleague at the conference.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Commitment',
          description: 'Formally pledging to fulfill obligations',
          examples: [
            'The supplier undertook to deliver the materials within two weeks.',
            'They undertook to maintain confidentiality regarding the negotiations.',
          ],
        ),
        ContextualUsage(
          context: 'Legal',
          description: 'Making binding commitments or guarantees',
          examples: [
            'The defendant undertook to appear in court on the specified date.',
            'The company undertook to compensate customers affected by the data breach.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To accept responsibility for or take upon oneself',
      partOfSpeech: 'transitive verb',
      examples: [
        'The organization undertook the care of orphaned children.',
        'He undertook the burden of supporting his extended family.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Duty',
          description: 'Assuming duties or obligations',
          examples: [
            'The eldest son undertook the family responsibilities after his father\'s death.',
            'The volunteer undertook the coordination of the disaster relief efforts.',
          ],
        ),
        ContextualUsage(
          context: 'Support',
          description: 'Providing assistance or bearing burdens',
          examples: [
            'The foundation undertook the education expenses for underprivileged students.',
            'She undertook the care of her elderly parents despite her busy schedule.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take on an enterprise or business',
      partOfSpeech: 'transitive verb',
      examples: [
        'The family undertook a dairy farming business after moving to the countryside.',
        'The investors undertook a risky venture in an emerging market.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Starting or engaging in commercial activities',
          examples: [
            'The entrepreneur undertook several successful startup companies.',
            'They undertook the franchise operation with minimal experience.',
          ],
        ),
        ContextualUsage(
          context: 'Venture',
          description: 'Embarking on new enterprises or initiatives',
          examples: [
            'The publisher undertook a new digital platform to reach younger readers.',
            'The scientists undertook groundbreaking research in a controversial field.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'undo',
  base: 'undo',
  past: 'undid',
  participle: 'undone',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʌnˈduː',
  pronunciationTextUK: 'ʌnˈduː',
  meanings: [
    VerbMeaning(
      definition: 'To open, unfasten, or loose something that is tied, fastened, or closed',
      partOfSpeech: 'transitive verb',
      examples: [
        'He undid the knot in his shoelaces.',
        'She undid the buttons of her coat as she entered the warm building.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Clothing',
          description: 'Opening or loosening fasteners on garments',
          examples: [
            'The child couldn\'t undo the zipper on his jacket by himself.',
            'She undid her belt after the large meal.',
          ],
        ),
        ContextualUsage(
          context: 'Packaging',
          description: 'Opening wrapped or secured items',
          examples: [
            'He carefully undid the ribbon on the gift.',
            'The customs officer undid the seals to inspect the cargo.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reverse or cancel the effects or results of a previous action',
      partOfSpeech: 'transitive verb',
      examples: [
        'The new software update undid many of the previous changes.',
        'No apology could undo the damage caused by his thoughtless remarks.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Computing',
          description: 'Reversing digital actions or operations',
          examples: [
            'Press Ctrl+Z to undo your last action in most applications.',
            'The programmer wrote code to undo the database changes if an error occurred.',
          ],
        ),
        ContextualUsage(
          context: 'Correction',
          description: 'Attempting to correct or reverse mistakes',
          examples: [
            'The government tried to undo the economic damage through stimulus programs.',
            'It took years of therapy to undo the psychological harm of childhood trauma.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To ruin or destroy the order, structure, or condition of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'One careless remark undid months of careful negotiation.',
        'The scandal completely undid his political career.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Destruction',
          description: 'Causing collapse or failure of something built up',
          examples: [
            'A single mistake undid all his hard work and preparation.',
            'The financial crisis undid many previously successful businesses.',
          ],
        ),
        ContextualUsage(
          context: 'Reputation',
          description: 'Damaging someone\'s standing or status',
          examples: [
            'The revelation of corruption undid the politician\'s credibility.',
            'One poor performance undid years of building his reputation as a reliable athlete.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause emotional or physical distress',
      partOfSpeech: 'transitive verb',
      examples: [
        'The news of her illness completely undid him.',
        'She was undone by grief after losing her child.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Causing extreme distress or breakdown',
          examples: [
            'The betrayal undid her composure and she broke down in tears.',
            'He was undone by anxiety before the important presentation.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Describing emotional devastation in literature',
          examples: [
            'In the novel, the character was undone by unrequited love.',
            'The tragic hero was undone by his own fatal flaw.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'unwind',
  base: 'unwind',
  past: 'unwound',
  participle: 'unwound',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʌnˈwaɪnd',
  pronunciationTextUK: 'ʌnˈwaɪnd',
  meanings: [
    VerbMeaning(
      definition: 'To reverse the winding or twisting of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She unwound the tangled yarn before starting her knitting project.',
        'He carefully unwound the clock spring during the repair.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Straightening coiled or wrapped materials',
          examples: [
            'The worker unwound the cable from the large spool.',
            'He unwound the bandage from around his injured wrist.',
          ],
        ),
        ContextualUsage(
          context: 'Mechanical',
          description: 'Releasing tension from wound mechanisms',
          examples: [
            'The watchmaker unwound the mainspring before replacing it.',
            'She unwound the tape from the cassette to fix the jam.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To relax or free from tension or anxiety',
      partOfSpeech: 'intransitive/reflexive verb',
      examples: [
        'After the stressful day, he unwound with a glass of wine.',
        'She needs time to unwind before going to bed.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Relaxation',
          description: 'Releasing mental or emotional tension',
          examples: [
            'The executive unwound by practicing yoga every evening.',
            'They unwound at the beach resort after months of hard work.',
          ],
        ),
        ContextualUsage(
          context: 'Recreation',
          description: 'Activities that help reduce stress',
          examples: [
            'Reading helps him unwind after a demanding day at work.',
            'The peaceful music helped her unwind before sleeping.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To straighten out or clarify something complicated',
      partOfSpeech: 'transitive verb',
      examples: [
        'The detective slowly unwound the complex case.',
        'It took months to unwind the financial entanglements of the merger.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Investigation',
          description: 'Resolving complex or mysterious situations',
          examples: [
            'The journalist unwound the conspiracy through careful research.',
            'The auditors unwound years of accounting irregularities.',
          ],
        ),
        ContextualUsage(
          context: 'Legal',
          description: 'Resolving complicated legal or financial arrangements',
          examples: [
            'Lawyers spent months unwinding the complex estate.',
            'It took years to unwind the failed investment scheme.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To proceed to the end or conclusion by unfolding',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The story unwound slowly throughout the novel.',
        'The consequences of his actions unwound over several years.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Narrative',
          description: 'Development or revelation of stories or plots',
          examples: [
            'The mystery unwound through a series of surprising revelations.',
            'The documentary unwound the historical events chronologically.',
          ],
        ),
        ContextualUsage(
          context: 'Process',
          description: 'Gradual progression or development',
          examples: [
            'The events unwound in an unexpected direction.',
            'The political crisis unwound dramatically over several weeks.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'uphold',
  base: 'uphold',
  past: 'upheld',
  participle: 'upheld',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʌpˈhoʊld',
  pronunciationTextUK: 'ʌpˈhəʊld',
  meanings: [
    VerbMeaning(
      definition: 'To support or defend something such as a law, system, or principle',
      partOfSpeech: 'transitive verb',
      examples: [
        'The Supreme Court upheld the lower court\'s decision.',
        'The organization works to uphold human rights around the world.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legal',
          description: 'Maintaining or confirming legal decisions',
          examples: [
            'The appeals court upheld the conviction despite the new evidence.',
            'The judge upheld the objection from the defense attorney.',
          ],
        ),
        ContextualUsage(
          context: 'Principles',
          description: 'Supporting or defending values or standards',
          examples: [
            'The journalist strives to uphold the highest standards of ethical reporting.',
            'The company pledges to uphold environmental protection principles.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To maintain or confirm the validity of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The committee upheld the traditional interpretation of the rules.',
        'The review board upheld the original decision to deny funding.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Institutional',
          description: 'Official validation or confirmation',
          examples: [
            'The ethics committee upheld the complaint against the researcher.',
            'The professional association upheld the standards of practice for its members.',
          ],
        ),
        ContextualUsage(
          context: 'Challenge',
          description: 'Maintaining positions against opposition',
          examples: [
            'The administrator upheld the policy despite protests from students.',
            'The referee upheld the controversial call after reviewing the video.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To lift up or support physically',
      partOfSpeech: 'transitive verb',
      examples: [
        'The columns uphold the massive dome of the cathedral.',
        'Four sturdy posts upheld the traditional native dwelling.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Architecture',
          description: 'Physical support of structures',
          examples: [
            'Ancient pillars still uphold parts of the Roman aqueduct.',
            'Buttresses uphold the walls of Gothic cathedrals.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional or archaic usage',
          examples: [
            'In medieval descriptions, Atlas upholds the heavens on his shoulders.',
            'The ancient text describes how the world is upheld by giant elephants.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To maintain the honor or reputation of someone or something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She upheld the family tradition of public service.',
        'The diplomat worked to uphold his country\'s reputation abroad.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Honor',
          description: 'Maintaining positive image or legacy',
          examples: [
            'The officer strived to uphold the regiment\'s distinguished history.',
            'The new CEO promised to uphold the company\'s long-standing values.',
          ],
        ),
        ContextualUsage(
          context: 'Tradition',
          description: 'Preserving established customs or practices',
          examples: [
            'The elders work to uphold cultural traditions among the youth.',
            'The school upholds certain ceremonies that date back centuries.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'upset',
  base: 'upset',
  past: 'upset',
  participle: 'upset',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʌpˈsɛt',
  pronunciationTextUK: 'ʌpˈset',
  meanings: [
    VerbMeaning(
      definition: 'To tip or overturn something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The child accidentally upset the glass of milk.',
        'The boat was upset by the strong wind and waves.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Overturning objects from upright position',
          examples: [
            'The dog upset the trash can while looking for scraps.',
            'He upset the chess board during the argument.',
          ],
        ),
        ContextualUsage(
          context: 'Accident',
          description: 'Unintentional tipping or spilling',
          examples: [
            'She upset the paint bucket while climbing the ladder.',
            'The waiter upset several plates when he tripped.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To disturb the normal state or function of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The unexpected news upset all our plans for the weekend.',
        'The medication upset the balance of bacteria in her gut.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Disruption',
          description: 'Disturbing order, arrangement, or function',
          examples: [
            'The technical glitch upset the entire production schedule.',
            'The new policy upset the workplace hierarchy.',
          ],
        ),
        ContextualUsage(
          context: 'Balance',
          description: 'Disturbing equilibrium or harmony',
          examples: [
            'Overfishing has upset the marine ecosystem.',
            'The newcomer upset the team\'s chemistry.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause emotional distress or disturbance',
      partOfSpeech: 'transitive verb',
      examples: [
        'The harsh criticism upset her deeply.',
        'The violent movie upset the young children.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Causing distress, sadness, or agitation',
          examples: [
            'The argument upset her so much that she couldn\'t sleep.',
            'News of the accident upset everyone in the family.',
          ],
        ),
        ContextualUsage(
          context: 'Psychological',
          description: 'Disturbing mental well-being',
          examples: [
            'Constant stress can upset your mental health.',
            'The traumatic event upset his sense of security.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To defeat unexpectedly a favored opponent or overthrow an established order',
      partOfSpeech: 'transitive verb',
      examples: [
        'The underdog team upset the defending champions.',
        'The revolution upset the established political system.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sports',
          description: 'Unexpected defeat of favorites',
          examples: [
            'The unranked team upset the number one seed in the tournament.',
            'She upset the reigning champion in straight sets.',
          ],
        ),
        ContextualUsage(
          context: 'Political',
          description: 'Overthrowing established authority or expectations',
          examples: [
            'The protest movement upset the political establishment.',
            'The challenger upset the incumbent in the election.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'weep',
  base: 'weep',
  past: 'wept',
  participle: 'wept',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'wiːp',
  pronunciationTextUK: 'wiːp',
  meanings: [
    VerbMeaning(
      definition: 'To shed tears, often as an expression of grief or sadness',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She wept when she heard the tragic news.',
        'The child wept bitterly after losing his favorite toy.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Crying due to strong emotions',
          examples: [
            'The mother wept with joy at her son\'s return.',
            'He wept silently at his friend\'s funeral.',
          ],
        ),
        ContextualUsage(
          context: 'Grief',
          description: 'Expression of mourning or sadness',
          examples: [
            'The nation wept for the fallen soldiers.',
            'She wept for days after receiving the devastating diagnosis.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To express deep sorrow or grief for something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She wept the loss of her childhood home.',
        'The poet wept the decline of his beloved country.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Literary',
          description: 'Formal or poetic expression of grieving',
          examples: [
            'In the ancient poem, the widow weeps her husband\'s death.',
            'The writer wept the passing of a simpler way of life.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To exude or discharge moisture or liquid slowly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The wound wept clear fluid for several days.',
        'The old pipes wept water onto the basement floor.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Medical',
          description: 'Discharge from wounds or infections',
          examples: [
            'The doctor noted that the injury was still weeping and applied a fresh bandage.',
            'The skin condition caused the affected areas to weep and form crusts.',
          ],
        ),
        ContextualUsage(
          context: 'Natural',
          description: 'Plants or objects releasing moisture',
          examples: [
            'The birch trees weep sap in early spring.',
            'The stone walls wept moisture during humid weather.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To droop or hang down like drooping from tears',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The weeping willow\'s branches wept gracefully toward the ground.',
        'The flowers wept in the intense heat of the summer day.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Botanical',
          description: 'Describing downward growing patterns in plants',
          examples: [
            'The weeping cherry tree wept pink blossoms in the spring breeze.',
            'The gardener preferred plants that wept over the edges of containers.',
          ],
        ),
        ContextualUsage(
          context: 'Descriptive',
          description: 'Metaphorical drooping or hanging',
          examples: [
            'The melting candles wept wax down their sides.',
            'The ancient gate posts wept with vines and moss.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'wet',
  base: 'wet',
  past: 'wet/wetted',
  participle: 'wet/wetted',
  pastUK: 'wet',
  pastUS: 'wet/wetted',
  participleUK: 'wet',
  participleUS: 'wet/wetted',
  pronunciationTextUS: 'wɛt',
  pronunciationTextUK: 'wet',
  meanings: [
    VerbMeaning(
      definition: 'To make or become damp or moist',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'She wet her paintbrush before dipping it into the watercolors.',
        'The child\'s clothes wet through in the rain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Water',
          description: 'Applying or absorbing moisture',
          examples: [
            'He wet the cloth to wipe the dusty surface.',
            'The tears wet her pillow as she cried.',
          ],
        ),
        ContextualUsage(
          context: 'Weather',
          description: 'Becoming damp due to environmental conditions',
          examples: [
            'The morning dew wet the grass.',
            'The fog quickly wet our hair and clothes.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To urinate involuntarily or immerse in liquid',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'The young child wet the bed during his illness.',
        'The swimmers wet their hair before diving into the chlorinated pool.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Bathroom',
          description: 'Urinary accidents, especially with children',
          examples: [
            'The puppy wet the floor before they could take it outside.',
            'Some children wet themselves when they\'re frightened.',
          ],
        ),
        ContextualUsage(
          context: 'Swimming',
          description: 'Immersing in water before swimming',
          examples: [
            'She wet her face before putting on the swimming goggles.',
            'The coach advised them to wet their bodies before entering the cold water.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To celebrate or inaugurate something',
      partOfSpeech: 'transitive verb',
      examples: [
        'They decided to wet the baby\'s head at the local pub.',
        'Let\'s wet the new promotion with a glass of champagne.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Celebration',
          description: 'Traditional drinking to celebrate an event',
          examples: [
            'The team wetted their victory with a round of drinks.',
            'In British tradition, friends gather to wet a new baby\'s head with a toast.',
          ],
        ),
        ContextualUsage(
          context: 'Informal',
          description: 'Colloquial expression for celebratory drinking',
          examples: [
            'They wetted the new house purchase with an impromptu party.',
            'The colleagues went out to wet the signing of the major contract.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'wring',
  base: 'wring',
  past: 'wrung',
  participle: 'wrung',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'rɪŋ',
  pronunciationTextUK: 'rɪŋ',
  meanings: [
    VerbMeaning(
      definition: 'To twist and squeeze to extract liquid',
      partOfSpeech: 'transitive verb',
      examples: [
        'She wrung the wet clothes before hanging them to dry.',
        'He wrung the dishcloth over the sink.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Laundry',
          description: 'Removing water from wet fabric',
          examples: [
            'Before washing machines, people wrung clothes by hand to dry them.',
            'She wrung each sock thoroughly to speed up the drying process.',
          ],
        ),
        ContextualUsage(
          context: 'Cleaning',
          description: 'Squeezing moisture from cleaning materials',
          examples: [
            'The cleaner wrung the mop before wiping the floor.',
            'He wrung the sponge until it was just damp enough for wiping surfaces.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To obtain or extract with difficulty or effort',
      partOfSpeech: 'transitive verb',
      examples: [
        'The detective tried to wring the truth from the reluctant witness.',
        'The government wrung tax concessions from the wealthy.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Extraction',
          description: 'Forcefully obtaining something desired',
          examples: [
            'The journalist wrung an admission of guilt from the politician.',
            'They wrung every last penny of profit from the failing business.',
          ],
        ),
        ContextualUsage(
          context: 'Coercion',
          description: 'Compelling someone to give or reveal something',
          examples: [
            'The interrogators tried to wring information from the prisoner.',
            'Parents sometimes have to wring apologies from reluctant children.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To twist or contort sharply, especially in distress',
      partOfSpeech: 'transitive verb',
      examples: [
        'She wrung her hands in anxiety as she waited for news.',
        'The farmer wrung the chicken\'s neck quickly and efficiently.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Gesture',
          description: 'Physical expression of distress or worry',
          examples: [
            'The nervous mother wrung her hands throughout her son\'s performance.',
            'He wrung his cap between his fingers while waiting for the interview results.',
          ],
        ),
        ContextualUsage(
          context: 'Agriculture',
          description: 'Traditional method of killing poultry',
          examples: [
            'In the past, farmers commonly wrung the necks of chickens for slaughter.',
            'She had never seen anyone wring a bird\'s neck before visiting the farm.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause emotional pain or distress',
      partOfSpeech: 'transitive verb',
      examples: [
        'The sad story wrung tears from even the most stoic audience members.',
        'Her plight wrung his heart with compassion.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Causing deep emotional response',
          examples: [
            'The child\'s innocent question wrung her parents\' hearts.',
            'The documentary wrung sympathy from viewers around the world.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Poetic expression of emotional impact',
          examples: [
            'Her departure wrung his soul with grief.',
            'The plaintive melody wrung emotion from even the most hardened listener.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'awake',
  base: 'awake',
  past: 'awoke/awakened',
  participle: 'awoken/awakened',
  pastUK: 'awoke',
  pastUS: 'awoke/awakened',
  participleUK: 'awoken',
  participleUS: 'awoken/awakened',
  pronunciationTextUS: 'əˈweɪk',
  pronunciationTextUK: 'əˈweɪk',
  meanings: [
    VerbMeaning(
      definition: 'To stop sleeping and become conscious',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She awoke to the sound of birds singing.',
        'He usually awakens at dawn without an alarm clock.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Morning',
          description: 'Natural transition from sleep to wakefulness',
          examples: [
            'The child awoke refreshed after a long night\'s sleep.',
            'I awakened to find sunlight streaming through the window.',
          ],
        ),
        ContextualUsage(
          context: 'Disruption',
          description: 'Becoming conscious due to disturbance',
          examples: [
            'She awoke suddenly when the thunder crashed overhead.',
            'He awakened several times during the night due to the noise.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To rouse from sleep or unconsciousness',
      partOfSpeech: 'transitive verb',
      examples: [
        'The nurse awoke the patient to check his vital signs.',
        'Please awaken me at six o\'clock tomorrow morning.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Intentional',
          description: 'Deliberately causing someone to wake up',
          examples: [
            'The mother gently awoke her sleeping child.',
            'The alarm clock awakened him from a deep sleep.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Rousing from unconsciousness or sedation',
          examples: [
            'The doctor awaited anxiously for the patient to awaken after surgery.',
            'They were unable to awaken him from the coma.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become aware of or conscious about something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The public is finally awakening to the dangers of climate change.',
        'He awoke to the realization that he had been manipulated.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Awareness',
          description: 'Coming to understand or recognize something',
          examples: [
            'The community awoke to the need for better schools.',
            'She finally awakened to the fact that he was never going to change.',
          ],
        ),
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Figurative awakening of consciousness or understanding',
          examples: [
            'Reading philosophy awakened him to new ways of thinking.',
            'The crisis awoke the dormant leadership qualities within her.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To stir up or rouse an emotion or interest',
      partOfSpeech: 'transitive verb',
      examples: [
        'The speech awoke patriotic feelings in the audience.',
        'The old photograph awakened memories of her childhood.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Causing emotions or feelings to emerge',
          examples: [
            'The music awoke a profound sadness in him.',
            'Visiting her hometown awakened long-forgotten memories.',
          ],
        ),
        ContextualUsage(
          context: 'Inspiration',
          description: 'Stimulating interest or passion',
          examples: [
            'The professor\'s lectures awakened his interest in archaeology.',
            'The documentary awoke a desire in her to fight for social justice.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'cast',
  base: 'cast',
  past: 'cast',
  participle: 'cast',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kæst',
  pronunciationTextUK: 'kɑːst',
  meanings: [
    VerbMeaning(
      definition: 'To throw or direct with force',
      partOfSpeech: 'transitive verb',
      examples: [
        'The fisherman cast his line into the river.',
        'She cast a stone across the water, making it skip five times.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Fishing',
          description: 'Throwing fishing line or net',
          examples: [
            'He cast his net wide to catch as many fish as possible.',
            'The angler cast the fly with perfect precision to the spot where trout were rising.',
          ],
        ),
        ContextualUsage(
          context: 'Sports',
          description: 'Throwing in athletic contexts',
          examples: [
            'The athlete cast the javelin farther than any of his competitors.',
            'The cricketer cast the ball toward the wicket with great speed.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To select performers for roles in a play, film, or program',
      partOfSpeech: 'transitive verb',
      examples: [
        'The director cast well-known actors in all the leading roles.',
        'She was cast as the villain in the superhero movie.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Entertainment',
          description: 'Assigning roles to actors',
          examples: [
            'They cast a relative unknown in the leading role, which proved to be a brilliant decision.',
            'The television series was cast with an ensemble of diverse performers.',
          ],
        ),
        ContextualUsage(
          context: 'Theater',
          description: 'Selecting performers for stage productions',
          examples: [
            'The theater company cast local talent for their production of "Hamlet."',
            'She was thrilled to be cast in her first Broadway play.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To form by pouring liquid material into a mold',
      partOfSpeech: 'transitive verb',
      examples: [
        'The sculptor cast the statue in bronze.',
        'Dental technicians cast gold crowns for tooth restorations.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Art',
          description: 'Creating sculptures or art objects from molds',
          examples: [
            'The artist cast several versions of the sculpture before being satisfied.',
            'Ancient civilizations cast ceremonial objects in precious metals.',
          ],
        ),
        ContextualUsage(
          context: 'Industrial',
          description: 'Manufacturing objects by pouring molten material',
          examples: [
            'The factory casts engine blocks from aluminum alloys.',
            'The jeweler cast the ring according to the custom design.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To direct or throw light, shadow, or glance',
      partOfSpeech: 'transitive verb',
      examples: [
        'The setting sun cast long shadows across the field.',
        'He cast a suspicious glance at the stranger.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Light',
          description: 'Projecting light or shadow',
          examples: [
            'The candles cast a warm glow throughout the room.',
            'The tall buildings cast the street into deep shadow.',
          ],
        ),
        ContextualUsage(
          context: 'Expression',
          description: 'Directing looks or expressions',
          examples: [
            'She cast her eyes downward in embarrassment.',
            'The manager cast a disapproving look at the late employee.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To dispose of or shed',
      partOfSpeech: 'transitive verb',
      examples: [
        'The snake cast its skin during molting.',
        'The tree cast its leaves in autumn.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Biological',
          description: 'Natural shedding processes',
          examples: [
            'Deer cast their antlers each year and grow new ones.',
            'The horse cast a shoe during the long ride through rocky terrain.',
          ],
        ),
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Figuratively discarding or shedding something',
          examples: [
            'She finally cast off her fears and pursued her dream.',
            'The organization cast aside the old policies in favor of more progressive ones.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'cost',
  base: 'cost',
  past: 'cost',
  participle: 'cost',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kɔst',
  pronunciationTextUK: 'kɒst',
  meanings: [
    VerbMeaning(
      definition: 'To have a price of a specified amount',
      partOfSpeech: 'transitive verb',
      examples: [
        'The new car cost thirty thousand dollars.',
        'Dinner at that restaurant costs more than I can afford.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Purchase',
          description: 'Monetary price of goods or services',
          examples: [
            'The tickets cost fifty dollars each.',
            'Quality furniture costs more but lasts longer.',
          ],
        ),
        ContextualUsage(
          context: 'Expense',
          description: 'Financial outlay required',
          examples: [
            'Higher education costs a fortune in many countries.',
            'The renovation project cost twice what they had initially budgeted.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To require expenditure or payment',
      partOfSpeech: 'transitive verb',
      examples: [
        'The mistake cost the company millions in lost revenue.',
        'Raising children costs a lot of money these days.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Financial impact on organizations',
          examples: [
            'The lawsuit cost the corporation its reputation and significant resources.',
            'Data breaches cost businesses billions annually in remediation and lost trust.',
          ],
        ),
        ContextualUsage(
          context: 'Resource',
          description: 'Resources required for projects or activities',
          examples: [
            'The space program cost taxpayers enormous sums over the decades.',
            'Green energy initiatives will cost less as technology improves.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause loss, suffering, or sacrifice',
      partOfSpeech: 'transitive verb',
      examples: [
        'The war cost thousands of lives.',
        'His carelessness cost him his job.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Personal',
          description: 'Individual losses or consequences',
          examples: [
            'The scandal cost her the election.',
            'His addiction cost him his family and career.',
          ],
        ),
        ContextualUsage(
          context: 'Societal',
          description: 'Broader social or human impacts',
          examples: [
            'Environmental pollution costs communities their health and quality of life.',
            'The political conflict cost the region decades of potential development.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To estimate the price of producing something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The accountant costed the project at one million dollars.',
        'They carefully costed each phase of the construction.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Planning',
          description: 'Calculating expenses for budgeting purposes',
          examples: [
            'The team costed the entire marketing campaign before presenting it to management.',
            'They costed different options for the event to find the most economical approach.',
          ],
        ),
        ContextualUsage(
          context: 'Analysis',
          description: 'Professional evaluation of expenses',
          examples: [
            'The quantity surveyor costed the materials needed for the building.',
            'Government departments must cost policy proposals before implementation.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'cut',
  base: 'cut',
  past: 'cut',
  participle: 'cut',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kʌt',
  pronunciationTextUK: 'kʌt',
  meanings: [
    VerbMeaning(
      definition: 'To penetrate or divide with a sharp edge',
      partOfSpeech: 'transitive verb',
      examples: [
        'She cut the bread into slices.',
        'The surgeon cut precisely along the marked line.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Culinary',
          description: 'Food preparation with knives or tools',
          examples: [
            'The chef cut the vegetables into uniform pieces.',
            'He cut the meat against the grain for tenderness.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Surgical or medical incisions',
          examples: [
            'The doctor cut a small incision to remove the cyst.',
            'The barber cut his hair with professional scissors.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reduce or diminish in amount or size',
      partOfSpeech: 'transitive verb',
      examples: [
        'The company cut its workforce by ten percent.',
        'We need to cut expenses to stay within budget.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Reducing costs or resources',
          examples: [
            'The new CEO cut overhead expenses dramatically.',
            'They cut production by half during the economic downturn.',
          ],
        ),
        ContextualUsage(
          context: 'Personal',
          description: 'Reducing personal consumption or spending',
          examples: [
            'She cut her spending on non-essentials to save for a house.',
            'The athlete cut his calorie intake during training.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To stop, cease, or interrupt',
      partOfSpeech: 'transitive verb',
      examples: [
        'The director cut the scene from the final version of the film.',
        'The teacher cut the discussion short due to time constraints.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Media',
          description: 'Editing or removing content',
          examples: [
            'The censor cut several explicit scenes from the movie.',
            'They cut the interview when the subject became uncooperative.',
          ],
        ),
        ContextualUsage(
          context: 'Communication',
          description: 'Interrupting or ending interaction',
          examples: [
            'The chairman cut the speaker off mid-sentence.',
            'The phone company cut their service due to unpaid bills.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make or form by penetrating or removing material',
      partOfSpeech: 'transitive verb',
      examples: [
        'The sculptor cut a masterpiece from the block of marble.',
        'Workers cut a tunnel through the mountain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Creative',
          description: 'Artistic or craft creation through cutting',
          examples: [
            'She cut intricate designs in the paper to make snowflakes.',
            'The jeweler cut a brilliant diamond from the rough stone.',
          ],
        ),
        ContextualUsage(
          context: 'Construction',
          description: 'Creating openings or passages',
          examples: [
            'They cut a doorway in the wall to connect the two rooms.',
            'The landscaper cut terraces into the hillside for planting.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To wound or hurt with a sharp object',
      partOfSpeech: 'transitive verb',
      examples: [
        'He accidentally cut his finger while slicing vegetables.',
        'She cut herself on the broken glass.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Injury',
          description: 'Accidental wounding',
          examples: [
            'The child cut his knee when he fell on the gravel.',
            'Be careful not to cut yourself on the sharp edges.',
          ],
        ),
        ContextualUsage(
          context: 'Pain',
          description: 'Emotional or psychological hurt',
          examples: [
            'Her harsh words cut him deeply.',
            'The rejection cut her to the quick.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'hide',
  base: 'hide',
  past: 'hid',
  participle: 'hidden',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'haɪd',
  pronunciationTextUK: 'haɪd',
  meanings: [
    VerbMeaning(
      definition: 'To put or keep out of sight; conceal from view',
      partOfSpeech: 'transitive verb',
      examples: [
        'She hid the presents in the closet until the birthday party.',
        'The magician hid the coin in his sleeve.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Concealing objects from view',
          examples: [
            'He hid the evidence before the police arrived.',
            'The squirrel hid nuts throughout the garden for winter.',
          ],
        ),
        ContextualUsage(
          context: 'Security',
          description: 'Concealing valuables for protection',
          examples: [
            'Travelers are advised to hide their passports and money in a hotel safe.',
            'The museum hid its most valuable artifacts during the war.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To conceal oneself from view or discovery',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The children hid behind the curtains during the game of hide-and-seek.',
        'The fugitive hid in the mountains for months.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Play',
          description: 'Concealing oneself during games',
          examples: [
            'She hid under the bed to surprise her brother.',
            'The children giggled as they hid from their seeking friend.',
          ],
        ),
        ContextualUsage(
          context: 'Safety',
          description: 'Concealing oneself from danger',
          examples: [
            'The family hid in the basement during the tornado.',
            'Soldiers hid in the trenches as artillery fire rained down.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To conceal facts, feelings, or information',
      partOfSpeech: 'transitive verb',
      examples: [
        'He tried to hide his disappointment with a smile.',
        'The company hid the true financial situation from investors.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Concealing feelings or reactions',
          examples: [
            'She couldn\'t hide her excitement when she heard the news.',
            'Politicians often hide their true intentions behind carefully crafted speeches.',
          ],
        ),
        ContextualUsage(
          context: 'Deception',
          description: 'Deliberately withholding information',
          examples: [
            'The suspect hid crucial details from the investigators.',
            'The administration hid the negative environmental impact of the project.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To protect from danger or harm by concealing',
      partOfSpeech: 'transitive verb',
      examples: [
        'During the persecution, many families hid refugees in their homes.',
        'The organization hid witnesses until they could testify safely.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Protection',
          description: 'Sheltering others from harm',
          examples: [
            'During the occupation, villagers hid resistance fighters from the enemy.',
            'Animal sanctuaries hide endangered species from poachers.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Historical instances of protection through concealment',
          examples: [
            'Some families hid Jews from the Nazis during World War II.',
            'The network hid escaped slaves on their journey to freedom.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'hit',
  base: 'hit',
  past: 'hit',
  participle: 'hit',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'hɪt',
  pronunciationTextUK: 'hɪt',
  meanings: [
    VerbMeaning(
      definition: 'To bring the hand or an instrument into contact with forcefully',
      partOfSpeech: 'transitive verb',
      examples: [
        'The batter hit the ball out of the park.',
        'She hit the nail with the hammer.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sports',
          description: 'Striking balls or objects in games',
          examples: [
            'The tennis player hit a powerful serve.',
            'The golfer hit the ball straight down the fairway.',
          ],
        ),
        ContextualUsage(
          context: 'Physical',
          description: 'Striking objects with force',
          examples: [
            'He hit the drum with the palm of his hand.',
            'The carpenter hit the chisel precisely with each blow of the mallet.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To come into contact with forcefully',
      partOfSpeech: 'transitive verb',
      examples: [
        'The car hit a tree on the icy road.',
        'The missile hit its target accurately.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Collision',
          description: 'Forceful contact between objects',
          examples: [
            'The ship hit a submerged rock and began taking on water.',
            'The meteorite hit the Earth\'s surface with tremendous force.',
          ],
        ),
        ContextualUsage(
          context: 'Accident',
          description: 'Unintentional forceful contact',
          examples: [
            'The child hit his head on the coffee table.',
            'The bus hit a pothole, jolting all the passengers.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To affect suddenly or adversely',
      partOfSpeech: 'transitive verb',
      examples: [
        'The economic crisis hit small businesses particularly hard.',
        'The hurricane hit the coastal areas with devastating force.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Disaster',
          description: 'Severe impact of catastrophic events',
          examples: [
            'The drought hit farmers across the region.',
            'The epidemic hit vulnerable populations the hardest.',
          ],
        ),
        ContextualUsage(
          context: 'Financial',
          description: 'Economic impacts or consequences',
          examples: [
            'Inflation has hit consumer spending power.',
            'The new tax hit high-income earners most severely.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reach or achieve',
      partOfSpeech: 'transitive verb',
      examples: [
        'The singer\'s album hit number one on the charts.',
        'Temperatures hit record highs during the heatwave.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Achievement',
          description: 'Reaching specific goals or levels',
          examples: [
            'The company hit its sales targets for the quarter.',
            'The stock market hit an all-time high yesterday.',
          ],
        ),
        ContextualUsage(
          context: 'Measurement',
          description: 'Reaching specific measurements or values',
          examples: [
            'The speedometer hit 100 miles per hour on the straightaway.',
            'The fundraiser hit its goal of \$50,000 in just three days.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To suddenly realize or encounter',
      partOfSpeech: 'transitive verb',
      examples: [
        'The truth hit him like a ton of bricks.',
        'It suddenly hit me that I had forgotten my passport.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Realization',
          description: 'Sudden understanding or recognition',
          examples: [
            'The implications of the decision hit her as she left the meeting.',
            'It hit him that he was now completely responsible for the project.',
          ],
        ),
        ContextualUsage(
          context: 'Encounter',
          description: 'Coming upon something unexpectedly',
          examples: [
            'We hit bad traffic on our way to the airport.',
            'The hikers hit a patch of bad weather in the mountains.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'let',
  base: 'let',
  past: 'let',
  participle: 'let',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'lɛt',
  pronunciationTextUK: 'let',
  meanings: [
    VerbMeaning(
      definition: 'To allow or permit',
      partOfSpeech: 'transitive verb',
      examples: [
        'Her parents let her stay out until midnight.',
        'The teacher let the students leave early.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Permission',
          description: 'Granting approval for an action',
          examples: [
            'The guard let them enter the building after checking their IDs.',
            'She let her child have a small piece of cake as a treat.',
          ],
        ),
        ContextualUsage(
          context: 'Parenting',
          description: 'Allowing children certain freedoms',
          examples: [
            'Modern parents tend to let their children make more decisions.',
            'They don\'t let their teenagers use social media unsupervised.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause to or enable to',
      partOfSpeech: 'transitive verb',
      examples: [
        'Let me know when you arrive safely.',
        'I\'ll let you decide what to do next.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Enabling',
          description: 'Making something possible or facilitating',
          examples: [
            'The scholarship let her attend the prestigious university.',
            'The new software lets users create complex designs easily.',
          ],
        ),
        ContextualUsage(
          context: 'Communication',
          description: 'Requesting information or updates',
          examples: [
            'Please let us know your decision by Friday.',
            'Let me show you how the system works.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To rent or lease property',
      partOfSpeech: 'transitive verb',
      examples: [
        'They let their vacation home during the summer months.',
        'The office space was let to a small startup company.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Real Estate',
          description: 'Renting property to tenants',
          examples: [
            'The landlord let several apartments in the building.',
            'The company lets office space to various businesses.',
          ],
        ),
        ContextualUsage(
          context: 'Commercial',
          description: 'Business arrangements for property rental',
          examples: [
            'The shops were let on long-term leases.',
            'The university lets its facilities to outside organizations during vacation periods.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To award a contract after receiving bids',
      partOfSpeech: 'transitive verb',
      examples: [
        'The government let contracts for road construction.',
        'The developer let the plumbing work to the lowest bidder.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Construction',
          description: 'Awarding building or maintenance contracts',
          examples: [
            'The city let a contract for the new library building.',
            'The project manager let different aspects of the work to specialized contractors.',
          ],
        ),
        ContextualUsage(
          context: 'Business',
          description: 'Formal allocation of work through contracting',
          examples: [
            'The defense department lets billions in contracts each year.',
            'They let the catering contract to a local family business.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'quit',
  base: 'quit',
  past: 'quit',
  participle: 'quit',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'kwɪt',
  pronunciationTextUK: 'kwɪt',
  meanings: [
    VerbMeaning(
      definition: 'To leave or resign from a job or position',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'She quit her job to start her own business.',
        'He threatened to quit if conditions didn\'t improve.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Employment',
          description: 'Voluntarily leaving a workplace',
          examples: [
            'After ten years, she quit the company due to lack of advancement opportunities.',
            'Several employees quit when the new management took over.',
          ],
        ),
        ContextualUsage(
          context: 'Career',
          description: 'Making significant professional changes',
          examples: [
            'He quit his corporate career to become a teacher.',
            'The executive quit to join a competitor.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To stop or discontinue an action or activity',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'He quit smoking after thirty years.',
        'They quit the game when it started to rain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Habits',
          description: 'Ceasing habitual behaviors',
          examples: [
            'She quit drinking alcohol for health reasons.',
            'The doctor advised him to quit eating processed foods.',
          ],
        ),
        ContextualUsage(
          context: 'Activities',
          description: 'Discontinuing participation',
          examples: [
            'Many students quit the team after the coach was fired.',
            'She quit the book club when it became too time-consuming.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To leave a place',
      partOfSpeech: 'transitive verb',
      examples: [
        'They quit the city for a quieter life in the countryside.',
        'The hikers quit the trail before reaching the summit due to bad weather.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Departure',
          description: 'Leaving locations or settings',
          examples: [
            'The family quit their homeland during the political unrest.',
            'She quit the party early because she wasn\'t feeling well.',
          ],
        ),
        ContextualUsage(
          context: 'Relocation',
          description: 'Moving away from places',
          examples: [
            'They quit their apartment and moved into a larger house.',
            'After retirement, they quit the cold northern state for Florida.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To release from obligation or penalty',
      partOfSpeech: 'transitive verb',
      examples: [
        'The landlord quit them of all back rent.',
        'The judge quit the defendant of all charges.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legal',
          description: 'Formal release from obligations or debts',
          examples: [
            'The company was quit of its contractual responsibilities after the settlement.',
            'The ancient document quit the tenant farmers of certain feudal duties.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Archaic usage for releasing from obligations',
          examples: [
            'The king quit his subjects of taxes during the famine.',
            'The nobleman quit his serfs of their duties for one day as a festival gesture.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'set',
  base: 'set',
  past: 'set',
  participle: 'set',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sɛt',
  pronunciationTextUK: 'set',
  meanings: [
    VerbMeaning(
      definition: 'To place or put in a specified position',
      partOfSpeech: 'transitive verb',
      examples: [
        'She set the vase on the table.',
        'He set the ladder against the wall.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Positioning',
          description: 'Placing objects in particular locations',
          examples: [
            'The waiter set the plates before the guests.',
            'The gardener set the plants in rows.',
          ],
        ),
        ContextualUsage(
          context: 'Arrangement',
          description: 'Organizing items in specific configurations',
          examples: [
            'She set the chess pieces for a new game.',
            'The decorator set the furniture to maximize the space.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To establish or determine',
      partOfSpeech: 'transitive verb',
      examples: [
        'The judge set bail at ten thousand dollars.',
        'They set the date for the wedding in June.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Scheduling',
          description: 'Establishing times for events',
          examples: [
            'The committee set the deadline for applications.',
            'We set our meeting for Thursday afternoon.',
          ],
        ),
        ContextualUsage(
          context: 'Standards',
          description: 'Establishing rules or benchmarks',
          examples: [
            'The new record set a high standard for future athletes.',
            'The regulator set strict guidelines for compliance.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To adjust or fix to a particular state',
      partOfSpeech: 'transitive verb',
      examples: [
        'She set the alarm for 6:30 AM.',
        'He set the thermostat to 72 degrees.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Technical',
          description: 'Adjusting devices or instruments',
          examples: [
            'The engineer set the machine to the correct specifications.',
            'You need to set the camera settings for low light.',
          ],
        ),
        ContextualUsage(
          context: 'Configuration',
          description: 'Preparing systems for operation',
          examples: [
            'The IT department set the network security parameters.',
            'The chef set the oven to preheat before baking.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To become firm or solid',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The cement needs time to set properly.',
        'The gelatin will set in the refrigerator.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Chemical',
          description: 'Materials hardening or solidifying',
          examples: [
            'The epoxy sets within five minutes of mixing.',
            'Wait for the glue to set before handling the repaired item.',
          ],
        ),
        ContextualUsage(
          context: 'Culinary',
          description: 'Food items becoming solid or firm',
          examples: [
            'The jelly should set within a few hours.',
            'The chocolate will set faster if you put it in the freezer.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move below the horizon',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The sun sets earlier in winter.',
        'We watched as the moon set behind the mountains.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Astronomical',
          description: 'Daily disappearance of celestial bodies',
          examples: [
            'In midsummer, the sun sets after 9 PM in northern countries.',
            'Venus had already set by the time we started stargazing.',
          ],
        ),
        ContextualUsage(
          context: 'Temporal',
          description: 'Indicating end of day or time periods',
          examples: [
            'As the sun set, the temperature dropped quickly.',
            'They hurried to make camp before the sun set.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shut',
  base: 'shut',
  past: 'shut',
  participle: 'shut',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʃʌt',
  pronunciationTextUK: 'ʃʌt',
  meanings: [
    VerbMeaning(
      definition: 'To close or block an opening',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'She shut the door quietly behind her.',
        'The window shut with a loud bang during the storm.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Closing doors, windows, or containers',
          examples: [
            'He shut the lid of the treasure chest.',
            'Please shut the gate when you leave.',
          ],
        ),
        ContextualUsage(
          context: 'Safety',
          description: 'Securing openings for protection',
          examples: [
            'Shut all windows before the hurricane arrives.',
            'The bank vault shuts automatically at closing time.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To close a business or operation temporarily or permanently',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'The factory shut after fifty years in business.',
        'Many restaurants shut between lunch and dinner service.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Ceasing commercial operations',
          examples: [
            'The store shuts at 9 PM on weekdays.',
            'They had to shut the plant due to financial difficulties.',
          ],
        ),
        ContextualUsage(
          context: 'Temporary',
          description: 'Closing for limited periods',
          examples: [
            'The school shut for two weeks during the outbreak.',
            'The park shuts at dusk every evening.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To exclude or bar from a place or activity',
      partOfSpeech: 'transitive verb',
      examples: [
        'They shut him out of the discussion.',
        'The new policy shuts many people out of the housing market.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Excluding individuals from groups',
          examples: [
            'His colleagues shut him out after the disagreement.',
            'The clique deliberately shut others out of their activities.',
          ],
        ),
        ContextualUsage(
          context: 'Opportunity',
          description: 'Preventing access to resources or chances',
          examples: [
            'Discrimination shuts many qualified candidates out of leadership positions.',
            'High costs shut lower-income students out of elite universities.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To stop operating or functioning',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The computer shut down unexpectedly during the update.',
        'His mind seemed to shut off when the pressure became too intense.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Technical',
          description: 'Devices ceasing to function',
          examples: [
            'The safety system automatically shuts the machinery if it overheats.',
            'The power plant shut during the emergency.',
          ],
        ),
        ContextualUsage(
          context: 'Psychological',
          description: 'Mental or emotional withdrawal',
          examples: [
            'She tends to shut down during confrontations.',
            'The patient\'s body began shutting down as the disease progressed.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To close tightly or completely',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'He couldn\'t shut his suitcase because it was too full.',
        'Her mouth shut in a firm line of disapproval.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Containment',
          description: 'Securing contents within containers',
          examples: [
            'Make sure to shut the medicine bottle tightly.',
            'The envelope wouldn\'t shut properly with so many documents inside.',
          ],
        ),
        ContextualUsage(
          context: 'Bodily',
          description: 'Closing of body parts or features',
          examples: [
            'He shut his eyes against the bright light.',
            'The flower shuts its petals at night.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spread',
  base: 'spread',
  past: 'spread',
  participle: 'spread',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'sprɛd',
  pronunciationTextUK: 'spred',
  meanings: [
    VerbMeaning(
      definition: 'To extend or distribute over a larger area or greater number',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'The fire spread quickly through the dry forest.',
        'She spread the map on the table to examine it.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Expanding or unfolding material objects',
          examples: [
            'He spread his arms wide to embrace his children.',
            'The bird spread its wings before taking flight.',
          ],
        ),
        ContextualUsage(
          context: 'Surface',
          description: 'Covering areas with materials',
          examples: [
            'The gardener spread mulch around the plants.',
            'They spread a blanket on the grass for the picnic.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To scatter or distribute widely',
      partOfSpeech: 'transitive verb',
      examples: [
        'The farmer spread seeds across the field.',
        'They spread leaflets throughout the neighborhood to advertise the event.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Distribution',
          description: 'Dispersing items over an area',
          examples: [
            'The airplane spread fertilizer over the crops.',
            'Wind spread the dandelion seeds across the meadow.',
          ],
        ),
        ContextualUsage(
          context: 'Allocation',
          description: 'Distributing resources or materials',
          examples: [
            'She spread her investments across different sectors.',
            'It\'s best to spread the workload among team members.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To apply a layer of soft substance on a surface',
      partOfSpeech: 'transitive verb',
      examples: [
        'He spread butter thinly on the toast.',
        'The mason spread mortar between the bricks.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Culinary',
          description: 'Applying food items on surfaces',
          examples: [
            'She spread jam on her bread at breakfast.',
            'The chef spread the sauce evenly over the pizza base.',
          ],
        ),
        ContextualUsage(
          context: 'Construction',
          description: 'Applying materials in construction or repair',
          examples: [
            'The worker spread adhesive on the floor before laying the tiles.',
            'He spread a thin layer of spackle over the hole in the wall.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To circulate or become known more widely',
      partOfSpeech: 'intransitive verb',
      examples: [
        'News of their engagement spread quickly through the small town.',
        'Rumors about the company takeover spread among employees.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Information',
          description: 'Dissemination of news or knowledge',
          examples: [
            'Information spreads faster than ever in the digital age.',
            'The story spread through social media before appearing on traditional news.',
          ],
        ),
        ContextualUsage(
          context: 'Social',
          description: 'Transmission of trends, ideas, or behaviors',
          examples: [
            'The dance craze spread from the city to rural areas.',
            'Innovative teaching methods spread gradually through the education system.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To increase in scope or extent',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The protest movement spread to neighboring countries.',
        'The cancer had spread to other organs before it was detected.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Medical',
          description: 'Progression of disease or condition',
          examples: [
            'The infection spread despite treatment with antibiotics.',
            'Doctors worked to prevent the inflammation from spreading to surrounding tissues.',
          ],
        ),
        ContextualUsage(
          context: 'Cultural',
          description: 'Expansion of influence or trends',
          examples: [
            'Western music spread throughout the world in the twentieth century.',
            'Democracy spread to more countries after the Cold War ended.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'dwell',
  base: 'dwell',
  past: 'dwelt/dwelled',
  participle: 'dwelt/dwelled',
  pastUK: 'dwelt',
  pastUS: 'dwelled/dwelt',
  participleUK: 'dwelt',
  participleUS: 'dwelled/dwelt',
  pronunciationTextUS: 'dwɛl',
  pronunciationTextUK: 'dwel',
  meanings: [
    VerbMeaning(
      definition: 'To live or reside in a place',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Our ancestors dwelt in caves before building permanent structures.',
        'She dwells in a small cottage by the sea.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Residence',
          description: 'Formal or literary term for living somewhere',
          examples: [
            'The poet dwelt in isolation during his final years.',
            'Ancient civilizations dwelt primarily along river valleys.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Describing habitation in past times',
          examples: [
            'Indigenous peoples dwelt in this region for thousands of years.',
            'Medieval peasants dwelt in simple thatched cottages.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To think, speak, or write at length about something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The professor dwelt on this point for nearly an hour.',
        'She tends to dwell on past mistakes rather than moving forward.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Discussion',
          description: 'Focusing extensively on a topic',
          examples: [
            'The book dwells on the character\'s childhood experiences.',
            'The speaker dwelt too long on technical details that confused the audience.',
          ],
        ),
        ContextualUsage(
          context: 'Psychological',
          description: 'Persistent or excessive thinking about something',
          examples: [
            'The therapist advised him not to dwell on negative thoughts.',
            'She dwelt on the problem until she found a solution.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To remain or linger in a place or state',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Her eyes dwelt on the beautiful landscape.',
        'His mind dwelled in a state of confusion after the accident.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Perception',
          description: 'Maintaining attention or focus',
          examples: [
            'His gaze dwelt on her face for a moment too long.',
            'The camera dwelled on the intricate details of the artwork.',
          ],
        ),
        ContextualUsage(
          context: 'Condition',
          description: 'Remaining in a particular state',
          examples: [
            'He dwelt in uncertainty while waiting for the test results.',
            'Society cannot dwell in ignorance of these important issues.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To exist or be present in a specific place',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Peace dwells in this tranquil valley.',
        'The spirit of innovation dwells within this company.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Spiritual',
          description: 'Metaphorical presence or existence',
          examples: [
            'They believe that God dwells within all living things.',
            'Wisdom dwells in those who seek understanding.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Poetic expression of presence',
          examples: [
            'Hope dwells eternal in the human heart.',
            'Magic dwells in the ancient forest, according to local legends.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bend',
  base: 'bend',
  past: 'bent',
  participle: 'bent',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bɛnd',
  pronunciationTextUK: 'bend',
  meanings: [
    VerbMeaning(
      definition: 'To curve or force from a straight line, position, or shape',
      partOfSpeech: 'transitive verb',
      examples: [
        'The strong wind bent the young trees.',
        'She bent the wire into a circle.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Changing the shape of material objects',
          examples: [
            'The metalworker bent the rod into a hook shape.',
            'You need to bend the pipe to fit around the corner.',
          ],
        ),
        ContextualUsage(
          context: 'Manufacturing',
          description: 'Industrial forming of materials',
          examples: [
            'The machine bends steel sheets with precise measurements.',
            'Craftsmen bent the wood using steam to make furniture.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To incline the body or part of the body',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She bent down to pick up the fallen book.',
        'He bent over to tie his shoelaces.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Posture',
          description: 'Human body movement and positioning',
          examples: [
            'The yoga instructor bent backward in an impressive display of flexibility.',
            'The elderly man bent with age as he walked slowly down the street.',
          ],
        ),
        ContextualUsage(
          context: 'Physical Activity',
          description: 'Controlled body movements',
          examples: [
            'Remember to bend your knees when lifting heavy objects.',
            'The dancer bent gracefully during the performance.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To adapt or deviate from a rule, principle, or normal course',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'The manager bent the rules to accommodate the employee\'s situation.',
        'They refused to bend in their negotiations with the union.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Rules',
          description: 'Flexibility in applying regulations',
          examples: [
            'The judge sometimes bends sentencing guidelines for first-time offenders.',
            'The teacher bent the homework deadline for students affected by the power outage.',
          ],
        ),
        ContextualUsage(
          context: 'Compromise',
          description: 'Adjusting position or stance',
          examples: [
            'The politician bent to public pressure and changed his position.',
            'Neither side would bend in the territorial dispute.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To direct or turn toward a certain point or in a certain direction',
      partOfSpeech: 'transitive verb',
      examples: [
        'He bent his steps toward home.',
        'She bent all her energy toward finishing the project.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Direction',
          description: 'Changing course or focus',
          examples: [
            'The path bends around the lake before heading uphill.',
            'They bent their journey northward after hearing about the storm.',
          ],
        ),
        ContextualUsage(
          context: 'Attention',
          description: 'Focusing effort or concentration',
          examples: [
            'The team bent their minds to solving the complex problem.',
            'She bent her will to overcoming the obstacles in her path.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bind',
  base: 'bind',
  past: 'bound',
  participle: 'bound',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'baɪnd',
  pronunciationTextUK: 'baɪnd',
  meanings: [
    VerbMeaning(
      definition: 'To tie or fasten together with a band or bond',
      partOfSpeech: 'transitive verb',
      examples: [
        'He bound the documents together with string.',
        'The captive\'s hands were bound behind his back.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Securing objects together',
          examples: [
            'The farmer bound the hay into bales.',
            'She bound the flowers into a bouquet with ribbon.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Bandaging or dressing wounds',
          examples: [
            'The nurse bound the patient\'s sprained ankle with an elastic bandage.',
            'They bound the wound tightly to stop the bleeding.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To place under legal or moral obligation',
      partOfSpeech: 'transitive verb',
      examples: [
        'The contract binds both parties to the agreement.',
        'She felt bound by her promise to keep the secret.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legal',
          description: 'Creating legal obligations',
          examples: [
            'The terms of service bind all users of the website.',
            'The treaty binds the signing nations to reduce carbon emissions.',
          ],
        ),
        ContextualUsage(
          context: 'Ethical',
          description: 'Creating moral duties or obligations',
          examples: [
            'His oath of office bound him to uphold the constitution.',
            'Professional ethics bind doctors to maintain patient confidentiality.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause to stick together or cohere',
      partOfSpeech: 'transitive verb',
      examples: [
        'Egg whites bind the ingredients in the recipe.',
        'The glue binds the two pieces of wood firmly.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Culinary',
          description: 'Ingredients that hold food together',
          examples: [
            'Breadcrumbs and egg bind the meatball mixture.',
            'This sauce will bind the casserole ingredients together.',
          ],
        ),
        ContextualUsage(
          context: 'Construction',
          description: 'Materials that provide cohesion',
          examples: [
            'Cement binds the aggregate in concrete.',
            'The resin binds the particles together to form the composite material.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To constrain or restrict movement or action',
      partOfSpeech: 'transitive verb',
      examples: [
        'Fear bound him to silence.',
        'Traditional gender roles bound women to domestic duties for centuries.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Limitation',
          description: 'Restricting freedom or options',
          examples: [
            'Poverty binds many people to their circumstances.',
            'The strict rules bound students to a rigid schedule.',
          ],
        ),
        ContextualUsage(
          context: 'Psychological',
          description: 'Mental or emotional constraints',
          examples: [
            'Guilt bound her to an unhealthy relationship.',
            'His obsession with perfection bound him to endless revisions of his work.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To attach covers to a book',
      partOfSpeech: 'transitive verb',
      examples: [
        'The manuscripts were professionally bound in leather.',
        'They bound the thesis in hard covers.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Publishing',
          description: 'Creating finished books from printed pages',
          examples: [
            'The limited edition was bound in gold-tooled morocco leather.',
            'Students can have their dissertations bound at the university print shop.',
          ],
        ),
        ContextualUsage(
          context: 'Craft',
          description: 'Bookbinding as an artisanal process',
          examples: [
            'She hand-binds journals using traditional techniques.',
            'The ancient texts were bound with hand-stitched bindings.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'breed',
  base: 'breed',
  past: 'bred',
  participle: 'bred',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'briːd',
  pronunciationTextUK: 'briːd',
  meanings: [
    VerbMeaning(
      definition: 'To produce offspring, especially animals',
      partOfSpeech: 'intransitive verb',
      examples: [
        'These birds breed in the spring.',
        'Mosquitoes breed quickly in stagnant water.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Animal',
          description: 'Natural reproduction of animals',
          examples: [
            'Pandas rarely breed in captivity.',
            'Salmon return to their birthplace to breed.',
          ],
        ),
        ContextualUsage(
          context: 'Biological',
          description: 'Reproductive processes in nature',
          examples: [
            'Some species breed only once in their lifetime.',
            'Insects breed more prolifically in warm climates.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To raise animals for a specific purpose, especially through selective mating',
      partOfSpeech: 'transitive verb',
      examples: [
        'They breed horses for racing.',
        'The farm breeds cattle for organic beef production.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Agriculture',
          description: 'Controlled reproduction of livestock',
          examples: [
            'The farmer breeds sheep for their wool quality.',
            'This region has bred distinctive dairy cows for centuries.',
          ],
        ),
        ContextualUsage(
          context: 'Pets',
          description: 'Development of specific animal breeds',
          examples: [
            'She breeds champion show dogs.',
            'They breed tropical fish for the aquarium trade.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To develop plants with desirable characteristics through controlled pollination',
      partOfSpeech: 'transitive verb',
      examples: [
        'The horticulturist breeds roses with more vibrant colors.',
        'Scientists are breeding drought-resistant crops.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Horticulture',
          description: 'Creating new plant varieties',
          examples: [
            'They breed ornamental flowers for the commercial market.',
            'Botanists have bred apples for better storage qualities.',
          ],
        ),
        ContextualUsage(
          context: 'Agriculture',
          description: 'Crop improvement through breeding',
          examples: [
            'Researchers breed higher-yielding varieties of wheat.',
            'Companies breed genetically modified corn for pest resistance.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause or bring about (a situation, feeling, etc.)',
      partOfSpeech: 'transitive verb',
      examples: [
        'Poverty breeds crime in urban areas.',
        'Suspicion breeds mistrust between communities.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Creation of social conditions or attitudes',
          examples: [
            'Inequality breeds resentment among disadvantaged groups.',
            'Success often breeds confidence and further achievement.',
          ],
        ),
        ContextualUsage(
          context: 'Psychological',
          description: 'Development of mental or emotional states',
          examples: [
            'Isolation can breed depression in the elderly.',
            'The competitive environment bred innovation and creativity.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To bring up; to raise or nurture',
      partOfSpeech: 'transitive verb',
      examples: [
        'She was bred in a wealthy family with traditional values.',
        'The region breeds strong, independent individuals.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Upbringing',
          description: 'Cultural or familial raising of children',
          examples: [
            'He was bred to appreciate fine arts and literature.',
            'The town has bred generations of skilled craftspeople.',
          ],
        ),
        ContextualUsage(
          context: 'Cultural',
          description: 'Development of characteristics through environment',
          examples: [
            'Military academies breed discipline and leadership.',
            'The harsh frontier life bred resilience in early settlers.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'cleave',
  base: 'cleave',
  past: 'cleft/clove/cleaved',
  participle: 'cleft/cloven/cleaved',
  pastUK: 'cleft/clove',
  pastUS: 'cleaved/cleft/clove',
  participleUK: 'cleft/cloven',
  participleUS: 'cleaved/cleft/cloven',
  pronunciationTextUS: 'kliːv',
  pronunciationTextUK: 'kliːv',
  meanings: [
    VerbMeaning(
      definition: 'To split or sever something, especially along a natural line or grain',
      partOfSpeech: 'transitive verb',
      examples: [
        'The axe cleaved the log in two.',
        'The lightning bolt clove the ancient oak tree.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Cutting or splitting objects',
          examples: [
            'The butcher cleaved the meat from the bone.',
            'The sword cleaved through the armor.',
          ],
        ),
        ContextualUsage(
          context: 'Geological',
          description: 'Natural splitting of rocks or minerals',
          examples: [
            'Some minerals cleave along precise crystallographic planes.',
            'The glacier cleaved the mountain, creating the valley.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To adhere firmly and closely or loyally',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She cleaved to her principles despite pressure to compromise.',
        'The exile cleaved to the hope of returning to his homeland someday.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Loyalty',
          description: 'Steadfast adherence to people or principles',
          examples: [
            'He cleaved to his wife through decades of marriage.',
            'The followers cleaved to their leader\'s teachings.',
          ],
        ),
        ContextualUsage(
          context: 'Biblical',
          description: 'Biblical usage expressing attachment',
          examples: [
            'The scripture says a man shall cleave unto his wife.',
            'They cleaved unto the Lord in times of tribulation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move through something forcefully',
      partOfSpeech: 'transitive verb',
      examples: [
        'The ship cleaved through the rough waves.',
        'The diver cleaved the water with barely a splash.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Forceful passage through a medium',
          examples: [
            'The arrow cleaved the air on its way to the target.',
            'The swimmer cleaved through the water with powerful strokes.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Poetic description of movement',
          examples: [
            'The eagle cleaved the sky with outstretched wings.',
            'Their expedition cleaved a path through the dense jungle.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To divide or separate a group',
      partOfSpeech: 'transitive verb',
      examples: [
        'The controversial decision cleaved the community in two.',
        'Religious differences have cloven the population for generations.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Creating divisions among people',
          examples: [
            'The civil war cleaved families along political lines.',
            'The new policy cleaved the party into opposing factions.',
          ],
        ),
        ContextualUsage(
          context: 'Organizational',
          description: 'Dividing institutions or structures',
          examples: [
            'The restructuring cleaved the company into separate divisions.',
            'The border dispute cleaved what was once a unified region.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'feed',
  base: 'feed',
  past: 'fed',
  participle: 'fed',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fiːd',
  pronunciationTextUK: 'fiːd',
  meanings: [
    VerbMeaning(
      definition: 'To give food to someone or something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She feeds her cat twice a day.',
        'The mother fed her baby with a bottle.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Care',
          description: 'Providing nourishment to dependents',
          examples: [
            'The zookeeper feeds the animals according to their dietary needs.',
            'He feeds the homeless at the shelter every weekend.',
          ],
        ),
        ContextualUsage(
          context: 'Animals',
          description: 'Providing food to pets or livestock',
          examples: [
            'The farmer feeds the chickens with grain each morning.',
            'Remember to feed the fish while I\'m away.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To supply or provide something necessary',
      partOfSpeech: 'transitive verb',
      examples: [
        'The streams feed the reservoir with fresh water.',
        'The scandal fed the public\'s appetite for gossip.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Resources',
          description: 'Supplying physical resources',
          examples: [
            'Solar panels feed electricity into the power grid.',
            'The spring feeds water to the valley below.',
          ],
        ),
        ContextualUsage(
          context: 'Information',
          description: 'Providing data or content',
          examples: [
            'The researchers feed data into the computer model.',
            'The news agency feeds stories to multiple newspapers.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To eat or take food',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The baby is feeding well.',
        'Wild deer feed at dawn and dusk.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Animal',
          description: 'Natural eating behaviors',
          examples: [
            'Sharks feed on smaller fish and marine mammals.',
            'The birds feed on insects and seeds in the garden.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Human eating, especially in medical contexts',
          examples: [
            'The patient is now feeding without assistance.',
            'Infants typically feed every few hours.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To introduce material into a machine',
      partOfSpeech: 'transitive verb',
      examples: [
        'She fed the paper into the printer.',
        'The operator feeds the fabric through the sewing machine.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Technical',
          description: 'Inserting materials into equipment',
          examples: [
            'The carpenter feeds lumber into the planer.',
            'Workers fed coal into the furnace to keep it burning.',
          ],
        ),
        ContextualUsage(
          context: 'Manufacturing',
          description: 'Industrial processing of materials',
          examples: [
            'The conveyor belt feeds parts to the assembly station.',
            'The system feeds chemicals into the reaction chamber at precise intervals.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To nurture or gratify emotionally',
      partOfSpeech: 'transitive verb',
      examples: [
        'Good literature feeds the mind.',
        'Success fed his confidence and ambition.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Supporting psychological needs',
          examples: [
            'Travel feeds her curiosity about different cultures.',
            'His encouragement fed her determination to succeed.',
          ],
        ),
        ContextualUsage(
          context: 'Problematic',
          description: 'Sustaining negative emotions or situations',
          examples: [
            'Sensationalist media feeds people\'s fears and anxieties.',
            'The gossip only fed the conflict between the colleagues.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'flee',
  base: 'flee',
  past: 'fled',
  participle: 'fled',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fliː',
  pronunciationTextUK: 'fliː',
  meanings: [
    VerbMeaning(
      definition: 'To run away from danger, threat, or persecution',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The family fled from the war-torn country.',
        'The suspect fled when the police arrived.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Danger',
          description: 'Escaping immediate threats',
          examples: [
            'Residents fled the coastal areas as the hurricane approached.',
            'The witnesses fled the scene of the crime.',
          ],
        ),
        ContextualUsage(
          context: 'Refugee',
          description: 'Leaving homeland due to persecution or war',
          examples: [
            'Many people fled across the border to escape the regime.',
            'Thousands fled the region after the outbreak of civil war.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move away from swiftly or hastily',
      partOfSpeech: 'transitive verb',
      examples: [
        'She fled the room in tears after the announcement.',
        'The bird fled its cage when the door was left open.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Departure',
          description: 'Quick or urgent leaving',
          examples: [
            'He fled the party after an embarrassing incident.',
            'The actress fled the press conference when asked about the scandal.',
          ],
        ),
        ContextualUsage(
          context: 'Escape',
          description: 'Getting away from confinement',
          examples: [
            'The prisoner fled his captors during the transfer.',
            'The domesticated fox fled the farm and returned to the wild.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To disappear quickly or suddenly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'All color fled from her face when she heard the news.',
        'His courage fled at the sight of the challenge ahead.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Rapid disappearance of qualities or conditions',
          examples: [
            'Sleep fled from her troubled mind throughout the night.',
            'Hope fled as the search entered its third week without results.',
          ],
        ),
        ContextualUsage(
          context: 'Time',
          description: 'Swift passing of time',
          examples: [
            'The years have fled since we were last together.',
            'Summer days fled all too quickly into autumn.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take refuge or seek escape',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He fled to the mountains to escape prosecution.',
        'Many wealthy citizens fled to neighboring countries during the revolution.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Historical',
          description: 'Historical instances of seeking refuge',
          examples: [
            'The royal family fled to England during the uprising.',
            'Artists and intellectuals fled Europe during the rise of fascism.',
          ],
        ),
        ContextualUsage(
          context: 'Sanctuary',
          description: 'Seeking safety in specific locations',
          examples: [
            'Political dissidents fled to embassies seeking asylum.',
            'The survivors fled to higher ground as the flood waters rose.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'forecast',
  base: 'forecast',
  past: 'forecast/forecasted',
  participle: 'forecast/forecasted',
  pastUK: 'forecast',
  pastUS: 'forecast/forecasted',
  participleUK: 'forecast',
  participleUS: 'forecast/forecasted',
  pronunciationTextUS: 'ˈfɔrkæst',
  pronunciationTextUK: 'ˈfɔːkɑːst',
  meanings: [
    VerbMeaning(
      definition: 'To predict or estimate a future event or trend',
      partOfSpeech: 'transitive verb',
      examples: [
        'Meteorologists forecast rain for the weekend.',
        'Economists forecast slow growth in the coming quarter.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Weather',
          description: 'Predicting meteorological conditions',
          examples: [
            'The meteorologist forecast thunderstorms for later in the day.',
            'They forecast a mild winter this year based on ocean temperature patterns.',
          ],
        ),
        ContextualUsage(
          context: 'Economic',
          description: 'Projecting financial or business trends',
          examples: [
            'Analysts forecast a downturn in the housing market.',
            'The company forecast record profits following the product launch.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To plan or calculate requirements for the future',
      partOfSpeech: 'transitive verb',
      examples: [
        'The business forecasts its inventory needs six months in advance.',
        'They forecast staffing requirements based on projected growth.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Planning future business operations',
          examples: [
            'The retailer forecasts seasonal demand to optimize purchasing.',
            'Management forecast resource needs for the upcoming project.',
          ],
        ),
        ContextualUsage(
          context: 'Logistics',
          description: 'Projecting supply chain requirements',
          examples: [
            'The system forecasts material requirements based on production schedules.',
            'Airlines forecast passenger numbers to allocate aircraft appropriately.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To serve as a prediction or warning',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The falling stock prices forecast trouble for the industry.',
        'Their behavior forecast the coming conflict.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Indication',
          description: 'Signs pointing to future developments',
          examples: [
            'The political unrest forecast major changes in the government.',
            'The unusual animal migrations forecast an especially harsh winter.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Foreshadowing in narrative contexts',
          examples: [
            'The dark clouds forecast the tragedy that would unfold in the final act.',
            'His nervous demeanor forecast the revelation to come.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To anticipate and make provisions for',
      partOfSpeech: 'transitive verb',
      examples: [
        'The government forecast potential problems and prepared emergency measures.',
        'The experienced captain forecast the storm and changed course.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Preparation',
          description: 'Anticipating needs or challenges',
          examples: [
            'The committee forecast potential objections to the proposal.',
            'Experienced gardeners forecast frost and protect vulnerable plants.',
          ],
        ),
        ContextualUsage(
          context: 'Risk Management',
          description: 'Identifying and planning for potential risks',
          examples: [
            'The risk assessment team forecast various disaster scenarios.',
            'Insurance companies forecast claim patterns based on historical data.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'forsee',
  base: 'forsee',
  past: 'forsaw',
  participle: 'forseen',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'fɔrˈsiː',
  pronunciationTextUK: 'fɔːˈsiː',
  meanings: [
    VerbMeaning(
      definition: 'To see or know beforehand; to predict',
      partOfSpeech: 'transitive verb',
      examples: [
        'The analyst forsees a change in market conditions.',
        'Nobody could forsee the consequences of that decision.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Prediction',
          description: 'Anticipating future events or developments',
          examples: [
            'The economist forsaw the financial crisis months before it happened.',
            'She had forseen the company\'s bankruptcy based on their financial reports.',
          ],
        ),
        ContextualUsage(
          context: 'Planning',
          description: 'Anticipating potential issues or needs',
          examples: [
            'The project manager forsees potential delays due to supply issues.',
            'They had not forseen the technical difficulties with the new system.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To have prescience or foresight about something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The author forsees a society dominated by technology.',
        'The scientist forsaw the environmental impact decades ago.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Vision',
          description: 'Having insight into future trends or patterns',
          examples: [
            'The inventor had forseen the potential of wireless technology.',
            'Few political analysts forsaw the fall of the regime.',
          ],
        ),
        ContextualUsage(
          context: 'Intuition',
          description: 'Sensing future developments through intuition',
          examples: [
            'She had forseen her daughter\'s success from an early age.',
            'The general forsaw the enemy\'s strategy and prepared accordingly.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To anticipate and make provisions for',
      partOfSpeech: 'transitive verb',
      examples: [
        'The company forsees a need for additional staff next year.',
        'The treaty forsees mechanisms for resolving future disputes.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Preparation',
          description: 'Planning based on anticipated developments',
          examples: [
            'The government forsees increasing demand for healthcare services.',
            'The design forsees expansion capabilities for future growth.',
          ],
        ),
        ContextualUsage(
          context: 'Strategy',
          description: 'Strategic anticipation of challenges or opportunities',
          examples: [
            'The business plan forsees potential market shifts.',
            'The military forsaw the need for different capabilities in future conflicts.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'grind',
  base: 'grind',
  past: 'ground',
  participle: 'ground',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ɡraɪnd',
  pronunciationTextUK: 'ɡraɪnd',
  meanings: [
    VerbMeaning(
      definition: 'To reduce to small particles by crushing, rubbing, or pressing',
      partOfSpeech: 'transitive verb',
      examples: [
        'She grinds coffee beans every morning for fresh coffee.',
        'The chef ground the spices into a fine powder.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Culinary',
          description: 'Food preparation involving crushing ingredients',
          examples: [
            'The butcher ground the meat for hamburgers.',
            'Traditional methods involve grinding grain between stones.',
          ],
        ),
        ContextualUsage(
          context: 'Industrial',
          description: 'Manufacturing processes using grinding',
          examples: [
            'The machine grinds the metal parts to precise specifications.',
            'Workers ground the lens to the correct curvature.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To wear down, polish, or sharpen by friction',
      partOfSpeech: 'transitive verb',
      examples: [
        'The craftsman ground the knife to a razor-sharp edge.',
        'They ground the rough edges off the metal casting.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Toolmaking',
          description: 'Sharpening or finishing tools',
          examples: [
            'The machinist ground the drill bit to the correct angle.',
            'She carefully ground the scissors until they cut smoothly.',
          ],
        ),
        ContextualUsage(
          context: 'Finishing',
          description: 'Smoothing or refining surfaces',
          examples: [
            'The jeweler ground the gemstone to bring out its brilliance.',
            'The glassmaker ground the surface to remove imperfections.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To operate with a crushing or rubbing motion',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The old mill wheel grinds slowly but steadily.',
        'She could hear the gears grinding inside the machine.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mechanical',
          description: 'Machine operations involving friction',
          examples: [
            'The brakes ground as the car came to a stop.',
            'The transmission was grinding when shifting between gears.',
          ],
        ),
        ContextualUsage(
          context: 'Natural',
          description: 'Geological processes of erosion',
          examples: [
            'Glaciers grind slowly over the bedrock, carving valleys.',
            'Tectonic plates grind against each other, causing earthquakes.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To work or study with great effort or difficulty',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Students grind for weeks before final exams.',
        'He\'s been grinding away at that project for months.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Academic',
          description: 'Intense studying or academic work',
          examples: [
            'Medical students often grind through years of difficult coursework.',
            'She would grind late into the night to complete her thesis.',
          ],
        ),
        ContextualUsage(
          context: 'Professional',
          description: 'Persistent hard work or effort',
          examples: [
            'Young professionals grind in entry-level positions to build their careers.',
            'The team has been grinding all season to reach the playoffs.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To press or rub together with pressure and friction',
      partOfSpeech: 'transitive verb',
      examples: [
        'He ground his teeth in frustration.',
        'The nervous student was grinding her heel into the floor.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Bodily actions involving pressure',
          examples: [
            'Many people grind their teeth while sleeping.',
            'The dancer ground his foot into the stage for dramatic effect.',
          ],
        ),
        ContextualUsage(
          context: 'Psychological',
          description: 'Actions indicating stress or tension',
          examples: [
            'She ground her fist into her palm as she considered the problem.',
            'Politicians often grind through difficult negotiations.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'heave',
  base: 'heave',
  past: 'heaved/hove',
  participle: 'heaved/hove/hoven',
  pastUK: 'heaved',
  pastUS: 'heaved/hove',
  participleUK: 'heaved',
  participleUS: 'heaved/hove',
  pronunciationTextUS: 'hiːv',
  pronunciationTextUK: 'hiːv',
  meanings: [
    VerbMeaning(
      definition: 'To lift or raise with effort or force',
      partOfSpeech: 'transitive verb',
      examples: [
        'The workers heaved the heavy crates onto the truck.',
        'He heaved the anchor aboard with a winch.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical Labor',
          description: 'Lifting heavy objects with exertion',
          examples: [
            'The movers heaved the piano up the narrow staircase.',
            'They heaved the fallen tree off the road.',
          ],
        ),
        ContextualUsage(
          context: 'Nautical',
          description: 'Raising marine equipment with force',
          examples: [
            'The sailors hove the anchor before departure.',
            'They heaved the supplies onto the deck from the dock.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To throw with force or effort',
      partOfSpeech: 'transitive verb',
      examples: [
        'The protester heaved a rock through the window.',
        'She heaved the garbage bag into the dumpster.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Forceful',
          description: 'Throwing with significant exertion',
          examples: [
            'The pitcher heaved the ball toward home plate.',
            'In frustration, he heaved his phone against the wall.',
          ],
        ),
        ContextualUsage(
          context: 'Disposal',
          description: 'Discarding items with force',
          examples: [
            'They heaved the old furniture onto the junk pile.',
            'The cleaner heaved the bags of trash into the bin.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To rise and fall rhythmically',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Her chest heaved with sobs.',
        'The ship heaved on the rough seas.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Bodily',
          description: 'Physical motion of breathing or emotion',
          examples: [
            'His shoulders heaved as he wept silently.',
            'The runner\'s chest heaved after the race.',
          ],
        ),
        ContextualUsage(
          context: 'Maritime',
          description: 'Motion of vessels on water',
          examples: [
            'The small boat heaved violently in the storm.',
            'The deck heaved beneath their feet as waves struck the hull.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To utter with effort or distress',
      partOfSpeech: 'transitive verb',
      examples: [
        'She heaved a sigh of relief when the crisis passed.',
        'He heaved a groan when he saw how much work remained.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Expressing feelings through sound',
          examples: [
            'The audience heaved a collective gasp at the surprise ending.',
            'He heaved a deep sigh of contentment.',
          ],
        ),
        ContextualUsage(
          context: 'Exertion',
          description: 'Sounds made with physical effort',
          examples: [
            'The climbers heaved breaths of the thin mountain air.',
            'She heaved a sob as she read the letter.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To vomit or retch',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The seasick passenger heaved over the ship\'s railing.',
        'He felt ill and began to heave after eating the spoiled food.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Medical',
          description: 'Physical response to nausea',
          examples: [
            'The patient heaved repeatedly from the side effects of the medication.',
            'The smell made her stomach heave unpleasantly.',
          ],
        ),
        ContextualUsage(
          context: 'Motion Sickness',
          description: 'Nausea related to movement',
          examples: [
            'Many passengers heaved during the turbulent flight.',
            'The winding mountain road made her heave from carsickness.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'kneel',
  base: 'kneel',
  past: 'knelt/kneeled',
  participle: 'knelt/kneeled',
  pastUK: 'knelt',
  pastUS: 'knelt/kneeled',
  participleUK: 'knelt',
  participleUS: 'knelt/kneeled',
  pronunciationTextUS: 'niːl',
  pronunciationTextUK: 'niːl',
  meanings: [
    VerbMeaning(
      definition: 'To bend the knees and rest on them',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He knelt beside the injured hiker to provide first aid.',
        'The gardener kneeled on a pad while planting flowers.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical Position',
          description: 'Assuming a kneeling posture for practical purposes',
          examples: [
            'The plumber knelt to examine the pipes under the sink.',
            'She knelt to tie her child\'s shoelaces.',
          ],
        ),
        ContextualUsage(
          context: 'Work',
          description: 'Kneeling for occupational tasks',
          examples: [
            'The tile installer knelt for hours while completing the floor.',
            'Firefighters often kneel when operating in smoke-filled environments.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To assume a position of prayer or worship',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The congregation knelt during the prayer.',
        'He knelt before the altar in the ancient cathedral.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Religious',
          description: 'Kneeling as an act of devotion',
          examples: [
            'The faithful knelt to receive a blessing from the priest.',
            'Muslims kneel during parts of their daily prayers.',
          ],
        ),
        ContextualUsage(
          context: 'Ceremonial',
          description: 'Kneeling in formal ceremonies',
          examples: [
            'Knights traditionally knelt before the monarch during dubbing ceremonies.',
            'The bride and groom knelt for the blessing during the wedding service.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To adopt a position of submission or supplication',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The defeated knight knelt before his opponent.',
        'She refused to kneel to the dictator\'s demands.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Submission',
          description: 'Physical demonstration of yielding or respect',
          examples: [
            'The captive knelt before the tribal chief.',
            'In feudal times, vassals knelt before their lords to pledge fealty.',
          ],
        ),
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Figurative submission or deference',
          examples: [
            'The corporation refused to kneel to public pressure.',
            'Many have knelt at the altar of fame and fortune.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To kneel as a form of protest or statement',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The athletes knelt during the national anthem to protest injustice.',
        'Demonstrators knelt silently in the plaza for nine minutes.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Political',
          description: 'Kneeling as political expression',
          examples: [
            'The protesters knelt with raised fists in solidarity.',
            'Police officers sometimes kneel with demonstrators as a gesture of unity.',
          ],
        ),
        ContextualUsage(
          context: 'Symbolic',
          description: 'Kneeling to represent specific values or causes',
          examples: [
            'The team knelt before the game to raise awareness for social issues.',
            'Mourners knelt at the memorial site to honor victims of violence.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'knit',
  base: 'knit',
  past: 'knit/knitted',
  participle: 'knit/knitted',
  pastUK: 'knitted',
  pastUS: 'knit/knitted',
  participleUK: 'knitted',
  participleUS: 'knit/knitted',
  pronunciationTextUS: 'nɪt',
  pronunciationTextUK: 'nɪt',
  meanings: [
    VerbMeaning(
      definition: 'To make clothing or other items by interlacing yarn with needles',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'She knits sweaters for her grandchildren every winter.',
        'He learned to knit during the pandemic lockdown.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Craft',
          description: 'Creating textile items using knitting techniques',
          examples: [
            'My grandmother knitted beautiful patterns into her blankets.',
            'The group knits hats for premature babies in the hospital.',
          ],
        ),
        ContextualUsage(
          context: 'Hobby',
          description: 'Knitting as a recreational activity',
          examples: [
            'She knits to relax after a stressful day at work.',
            'They knit together at the weekly community circle.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To join or grow together firmly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The broken bone has begun to knit nicely.',
        'The wound knitted together after several weeks of healing.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Medical',
          description: 'Healing process of bodily tissues',
          examples: [
            'The surgeon explained that fractured bones typically knit in six to eight weeks.',
            'The skin edges knitted well after the stitches were removed.',
          ],
        ),
        ContextualUsage(
          context: 'Biological',
          description: 'Natural joining of living tissues',
          examples: [
            'Plant grafts must knit properly to be successful.',
            'The cells knit together to form new tissue during regeneration.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To form or create by joining elements together',
      partOfSpeech: 'transitive verb',
      examples: [
        'The director knit diverse storylines into a coherent narrative.',
        'They knitted their resources together to establish the foundation.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Organizational',
          description: 'Combining distinct elements into cohesive units',
          examples: [
            'The coach knit individual talents into a championship team.',
            'She knitted various statistical findings into a compelling research paper.',
          ],
        ),
        ContextualUsage(
          context: 'Social',
          description: 'Building relationships or communities',
          examples: [
            'Shared experiences knit the neighbors into a close community.',
            'The crisis knitted former rivals together in mutual support.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To draw together; to contract into wrinkles',
      partOfSpeech: 'transitive verb',
      examples: [
        'He knit his brow in confusion.',
        'She knitted her eyebrows as she concentrated on the problem.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Facial Expression',
          description: 'Contraction of facial features expressing emotion',
          examples: [
            'The professor knit his brows while considering the student\'s question.',
            'She knitted her forehead in concern as she read the troubling news.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Descriptive usage in writing',
          examples: [
            'The character knit her fingers together nervously as she waited.',
            'His features knitted into a scowl upon hearing the insult.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'lean',
  base: 'lean',
  past: 'leaned/leant',
  participle: 'leaned/leant',
  pastUK: 'leant',
  pastUS: 'leaned',
  participleUK: 'leant',
  participleUS: 'leaned',
  pronunciationTextUS: 'liːn',
  pronunciationTextUK: 'liːn',
  meanings: [
    VerbMeaning(
      definition: 'To rest against or incline toward something for support',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She leaned against the wall to rest.',
        'He leant on his cane for support.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Using objects or structures for bodily support',
          examples: [
            'The tired hiker leaned on a tree to catch his breath.',
            'The ladder was leaning precariously against the house.',
          ],
        ),
        ContextualUsage(
          context: 'Posture',
          description: 'Body position showing inclination',
          examples: [
            'She leaned forward to hear the whispered secret.',
            'He leaned back in his chair with a satisfied smile.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To incline in opinion or desire; to have a tendency or preference',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The committee is leaning toward approving the proposal.',
        'She leans toward conservative political views.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Opinion',
          description: 'Having an inclination or preference',
          examples: [
            'The judge leaned in favor of the plaintiff\'s arguments.',
            'Most experts lean toward the environmental explanation for the phenomenon.',
          ],
        ),
        ContextualUsage(
          context: 'Tendency',
          description: 'General disposition or trend',
          examples: [
            'The discussion leaned heavily on economic factors.',
            'Their music leans toward jazz influences rather than classical.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To rely on or depend upon someone or something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'During difficult times, she leaned on her friends for support.',
        'The company leant heavily on government contracts for revenue.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Seeking support during challenges',
          examples: [
            'He leaned on his faith to get through the tragedy.',
            'Children often lean on familiar routines during times of change.',
          ],
        ),
        ContextualUsage(
          context: 'Dependence',
          description: 'Relying on resources or assistance',
          examples: [
            'The project leaned on volunteer participation to succeed.',
            'Many households lean on multiple income streams to make ends meet.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause to incline or rest against something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She leaned her bicycle against the fence.',
        'He leant his head against the cool window.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Placement',
          description: 'Positioning objects at an angle',
          examples: [
            'The painter leaned the wet canvas carefully against the wall.',
            'She leaned her suitcase next to the door, ready for an early departure.',
          ],
        ),
        ContextualUsage(
          context: 'Bodily',
          description: 'Positioning part of the body',
          examples: [
            'He leaned his elbows on the table during the intense discussion.',
            'She leaned her shoulder into the stuck door to force it open.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reduce or streamline processes or operations',
      partOfSpeech: 'transitive verb',
      examples: [
        'The company leaned its operations to improve efficiency.',
        'They leaned the manufacturing process by eliminating waste.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Implementing efficiency principles',
          examples: [
            'The startup leaned its approach to product development.',
            'Many organizations leaned their workforce during the economic downturn.',
          ],
        ),
        ContextualUsage(
          context: 'Production',
          description: 'Optimizing manufacturing or delivery systems',
          examples: [
            'They leaned the supply chain to reduce inventory costs.',
            'The factory leaned its production line through automation.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'plead',
  base: 'plead',
  past: 'pleaded/pled',
  participle: 'pleaded/pled',
  pastUK: 'pleaded',
  pastUS: 'pleaded/pled',
  participleUK: 'pleaded',
  participleUS: 'pleaded/pled',
  pronunciationTextUS: 'pliːd',
  pronunciationTextUK: 'pliːd',
  meanings: [
    VerbMeaning(
      definition: 'To make an earnest appeal or request',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She pleaded for more time to complete the project.',
        'The child pled with his parents to buy him the toy.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Making heartfelt requests',
          examples: [
            'The prisoner pleaded for mercy from the judge.',
            'He pleaded with his friend not to leave the city.',
          ],
        ),
        ContextualUsage(
          context: 'Negotiation',
          description: 'Appealing for consideration or concessions',
          examples: [
            'The union representatives pleaded for better working conditions.',
            'She pleaded with the landlord for an extension on the rent deadline.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To offer as an excuse or defense',
      partOfSpeech: 'transitive verb',
      examples: [
        'He pleaded illness as the reason for his absence.',
        'The company pled financial hardship to justify the layoffs.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Justification',
          description: 'Providing reasons for actions or behaviors',
          examples: [
            'The student pleaded extenuating circumstances for the late assignment.',
            'She pleaded exhaustion after working three consecutive shifts.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'Official explanation for actions',
          examples: [
            'The developer pleaded unexpected geological findings for the construction delay.',
            'They pleaded force majeure to excuse their breach of contract.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make a formal statement of guilt or innocence in court',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The defendant pleaded not guilty to all charges.',
        'She pled guilty in exchange for a reduced sentence.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legal',
          description: 'Formal responses to criminal charges',
          examples: [
            'The businessman pleaded guilty to tax evasion.',
            'All three defendants pleaded not guilty at the arraignment.',
          ],
        ),
        ContextualUsage(
          context: 'Judicial',
          description: 'Entering formal pleas in legal proceedings',
          examples: [
            'His attorney advised him to plead no contest to the misdemeanor charge.',
            'The corporation pleaded not guilty to environmental violations.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To argue a case in a court of law',
      partOfSpeech: 'transitive verb',
      examples: [
        'The lawyer pleaded her client\'s case eloquently.',
        'He has pleaded many similar cases successfully.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Advocacy',
          description: 'Representing clients in legal proceedings',
          examples: [
            'The attorney pleaded for a dismissal based on lack of evidence.',
            'She has pleaded cases before the Supreme Court.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional legal representation',
          examples: [
            'Barristers traditionally pleaded cases in the higher courts.',
            'He pleaded his own case without legal representation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To advocate or argue for a cause or belief',
      partOfSpeech: 'transitive verb',
      examples: [
        'The activist pleaded the case for environmental protection.',
        'She has long pleaded the cause of educational reform.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Activism',
          description: 'Advocating for social or political causes',
          examples: [
            'The organization pleads for greater attention to human rights abuses.',
            'He has pleaded the case for prison reform for decades.',
          ],
        ),
        ContextualUsage(
          context: 'Persuasion',
          description: 'Making compelling arguments for a position',
          examples: [
            'The scientist pleaded for more research funding at the conference.',
            'She pleaded her position effectively during the debate.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'prove',
  base: 'prove',
  past: 'proved',
  participle: 'proven/proved',
  pastUK: '',
  pastUS: '',
  participleUK: 'proved',
  participleUS: 'proven/proved',
  pronunciationTextUS: 'pruːv',
  pronunciationTextUK: 'pruːv',
  meanings: [
    VerbMeaning(
      definition: 'To establish the truth or validity of by evidence or argument',
      partOfSpeech: 'transitive verb',
      examples: [
        'The scientist proved her theory through extensive experimentation.',
        'The evidence proved the suspect\'s innocence beyond doubt.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Scientific',
          description: 'Verification through scientific method',
          examples: [
            'Researchers worked for years to prove the connection between smoking and cancer.',
            'The experiment proved that the new medication was effective.',
          ],
        ),
        ContextualUsage(
          context: 'Legal',
          description: 'Establishing facts in legal proceedings',
          examples: [
            'The prosecution must prove guilt beyond reasonable doubt.',
            'The document proved that the property belonged to her family.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To demonstrate or show to be true through testing or experience',
      partOfSpeech: 'transitive verb',
      examples: [
        'The crisis proved her leadership abilities.',
        'The crash test proved the car\'s safety features were inadequate.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Testing',
          description: 'Verification through practical assessment',
          examples: [
            'The field trials proved the new crop variety\'s resistance to drought.',
            'The prototype proved that the concept was viable.',
          ],
        ),
        ContextualUsage(
          context: 'Personal',
          description: 'Demonstrating qualities through actions',
          examples: [
            'She proved her commitment by working through the weekend.',
            'The team proved their worth by winning the championship.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To turn out or be found to be after experience',
      partOfSpeech: 'linking verb',
      examples: [
        'The rumors proved false after investigation.',
        'His concerns proved well-founded when the project failed.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Outcome',
          description: 'Final determination of status or quality',
          examples: [
            'The investment proved profitable despite initial doubts.',
            'The shortcut proved dangerous during winter conditions.',
          ],
        ),
        ContextualUsage(
          context: 'Assessment',
          description: 'Evaluation based on results',
          examples: [
            'The method proved effective for most participants.',
            'His prediction proved accurate within a small margin of error.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To test or check the quality or properties of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The baker proved the dough by letting it rise before baking.',
        'They proved the weapon on the firing range before deployment.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Culinary',
          description: 'Allowing dough to rise before baking',
          examples: [
            'The recipe requires proving the bread dough for an hour.',
            'Properly proved pastry results in a lighter texture.',
          ],
        ),
        ContextualUsage(
          context: 'Technical',
          description: 'Testing equipment or materials',
          examples: [
            'Engineers proved the bridge design with stress tests.',
            'They proved the waterproofing by subjecting it to high-pressure water spray.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To demonstrate mathematical validity through logical steps',
      partOfSpeech: 'transitive verb',
      examples: [
        'The student proved the theorem using calculus principles.',
        'Mathematicians have proved many of Fermat\'s conjectures.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mathematical',
          description: 'Logical demonstration of mathematical truths',
          examples: [
            'She proved the formula by induction.',
            'Wiles finally proved Fermat\'s Last Theorem in 1994.',
          ],
        ),
        ContextualUsage(
          context: 'Academic',
          description: 'Formal verification of theoretical concepts',
          examples: [
            'The paper proved that the algorithm runs in polynomial time.',
            'Physicists proved the existence of the Higgs boson through experiments.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'rid',
  base: 'rid',
  past: 'rid',
  participle: 'rid',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'rɪd',
  pronunciationTextUK: 'rɪd',
  meanings: [
    VerbMeaning(
      definition: 'To make someone or something free of an unwanted person or thing',
      partOfSpeech: 'transitive verb',
      examples: [
        'They hired an exterminator to rid the house of pests.',
        'The government promised to rid the streets of crime.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Elimination',
          description: 'Removing unwanted elements or problems',
          examples: [
            'The software helps rid computers of malware and viruses.',
            'The treatment rids the body of toxins and impurities.',
          ],
        ),
        ContextualUsage(
          context: 'Cleaning',
          description: 'Removing dirt, stains, or contaminants',
          examples: [
            'The cleaner claims to rid fabrics of even the toughest stains.',
            'They worked to rid the water supply of harmful chemicals.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To free oneself from something unwanted or troublesome',
      partOfSpeech: 'reflexive verb',
      examples: [
        'She couldn\'t rid herself of the nagging doubt.',
        'He struggled to rid himself of the addiction.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Psychological',
          description: 'Freeing oneself from mental burdens',
          examples: [
            'The therapy helped him rid himself of anxiety.',
            'She finally rid herself of the guilt she had carried for years.',
          ],
        ),
        ContextualUsage(
          context: 'Habit',
          description: 'Eliminating unwanted behaviors or dependencies',
          examples: [
            'It took years for him to rid himself of the smoking habit.',
            'She was determined to rid herself of negative thinking patterns.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To dispose of something unwanted',
      partOfSpeech: 'transitive verb',
      examples: [
        'They rid themselves of the old furniture before moving.',
        'The company rid itself of unprofitable divisions.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Disposal',
          description: 'Discarding or removing possessions',
          examples: [
            'He rid his closet of clothes he no longer wore.',
            'The collector finally rid himself of items with little value.',
          ],
        ),
        ContextualUsage(
          context: 'Business',
          description: 'Eliminating underperforming assets or operations',
          examples: [
            'The corporation rid itself of several subsidiaries during restructuring.',
            'Investors urged the company to rid itself of low-yielding investments.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deliver or rescue from something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The hero rid the village of the dragon in the legend.',
        'The vaccine rid the world of a deadly disease.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Liberation',
          description: 'Freeing from oppression or threat',
          examples: [
            'The revolution rid the country of the dictator.',
            'Their goal was to rid society of discrimination and prejudice.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Past instances of removing threats or problems',
          examples: [
            'Medical advances have rid humanity of many previously fatal diseases.',
            'The movement worked to rid the system of corruption.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'saw',
  base: 'saw',
  past: 'sawed',
  participle: 'sawed/sawn',
  pastUK: '',
  pastUS: '',
  participleUK: 'sawn',
  participleUS: 'sawn/sawed',
  pronunciationTextUS: 'sɔː',
  pronunciationTextUK: 'sɔː',
  meanings: [
    VerbMeaning(
      definition: 'To cut or divide with a saw',
      partOfSpeech: 'transitive verb',
      examples: [
        'The carpenter sawed the plank in half.',
        'He sawed through the thick branch of the tree.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Woodworking',
          description: 'Cutting wooden materials',
          examples: [
            'She carefully sawed the timber to the required length.',
            'The craftsman sawed intricate patterns into the wooden panel.',
          ],
        ),
        ContextualUsage(
          context: 'Construction',
          description: 'Cutting building materials',
          examples: [
            'Workers sawed concrete blocks to fit the irregular space.',
            'The contractor sawed an opening for the new window.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make cutting motions like those of a saw',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He sawed at the tough meat with his knife.',
        'The violinist sawed away at the instrument, producing harsh sounds.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Musical',
          description: 'Playing string instruments roughly',
          examples: [
            'The beginner sawed at the violin, still learning proper technique.',
            'The fiddler sawed enthusiastically during the folk dance.',
          ],
        ),
        ContextualUsage(
          context: 'Physical',
          description: 'Making back-and-forth cutting motions',
          examples: [
            'She sawed desperately at the rope with a dull knife.',
            'He sawed through the ice with the improvised tool.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To divide something by cutting with repeated strokes',
      partOfSpeech: 'transitive verb',
      examples: [
        'The surgeon sawed through the bone during the operation.',
        'They sawed the fallen tree into manageable logs.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Industrial',
          description: 'Processing materials in manufacturing',
          examples: [
            'The mill sawed lumber into standard dimensions.',
            'The machine sawed metal pipes with precision.',
          ],
        ),
        ContextualUsage(
          context: 'Practical',
          description: 'Dividing materials for practical purposes',
          examples: [
            'They sawed the ice into blocks for preservation.',
            'The butcher sawed the meat into customer-requested portions.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move something back and forth',
      partOfSpeech: 'transitive verb',
      examples: [
        'The captain sawed the wheel to navigate through the narrow passage.',
        'She sawed her arms through the water while swimming.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Rhythmic back-and-forth motion',
          examples: [
            'The rower sawed his oars through the water with practiced strokes.',
            'The driver sawed the steering wheel to avoid the obstacle.',
          ],
        ),
        ContextualUsage(
          context: 'Sports',
          description: 'Athletic movements with reciprocating motion',
          examples: [
            'The boxer sawed his fists in the air during the warm-up.',
            'The swimmer sawed her arms in perfect rhythm during the race.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sew',
  base: 'sew',
  past: 'sewed',
  participle: 'sewn/sewed',
  pastUK: '',
  pastUS: '',
  participleUK: 'sewn',
  participleUS: 'sewn/sewed',
  pronunciationTextUS: 'soʊ',
  pronunciationTextUK: 'səʊ',
  meanings: [
    VerbMeaning(
      definition: 'To join, fasten, or repair by making stitches with needle and thread',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'She sewed a button onto his shirt.',
        'My grandmother taught me to sew when I was young.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Repair',
          description: 'Fixing damaged clothing or textiles',
          examples: [
            'He carefully sewed the tear in his pants.',
            'The tailor sewed the ripped seam of the jacket.',
          ],
        ),
        ContextualUsage(
          context: 'Craft',
          description: 'Sewing as a hobby or pastime',
          examples: [
            'She sews quilts as a creative outlet.',
            'I enjoy sewing my own decorative pillows.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To create garments or items by stitching fabric',
      partOfSpeech: 'transitive verb',
      examples: [
        'The designer sewed a custom wedding dress for the bride.',
        'She sews all her children\'s Halloween costumes.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Fashion',
          description: 'Creating clothing through sewing',
          examples: [
            'The seamstress sewed a beautiful evening gown for the gala.',
            'He sews his own shirts to ensure a perfect fit.',
          ],
        ),
        ContextualUsage(
          context: 'Commercial',
          description: 'Professional or industrial sewing',
          examples: [
            'The factory sews thousands of jeans daily.',
            'Artisans sew luxury handbags by hand in the workshop.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To stitch decorative patterns or embellishments',
      partOfSpeech: 'transitive verb',
      examples: [
        'She sewed sequins onto the dance costume.',
        'The artisan sewed intricate patterns into the tapestry.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Decorative',
          description: 'Adding ornamental elements through stitching',
          examples: [
            'The embroiderer sewed golden thread throughout the fabric.',
            'She sewed beads onto the wedding veil for added sparkle.',
          ],
        ),
        ContextualUsage(
          context: 'Artistic',
          description: 'Creating art through textile techniques',
          examples: [
            'The fiber artist sews found objects into her textile installations.',
            'She sewed a landscape scene using various colored threads.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To close or join a wound with stitches',
      partOfSpeech: 'transitive verb',
      examples: [
        'The doctor sewed up the cut with ten stitches.',
        'The veterinarian sewed the injured animal\'s wound.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Medical',
          description: 'Surgical closure of wounds',
          examples: [
            'The surgeon carefully sewed the incision after the operation.',
            'The emergency room doctor sewed the laceration with dissolving sutures.',
          ],
        ),
        ContextualUsage(
          context: 'Veterinary',
          description: 'Treating animal injuries with sutures',
          examples: [
            'The vet sewed the dog\'s paw after removing the thorn.',
            'They sewed the falcon\'s wing after it had been injured.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To confine or limit (usually in passive form)',
      partOfSpeech: 'transitive verb',
      examples: [
        'He was sewn up in legal proceedings for years.',
        'The company had the market sewn up with patents.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Business',
          description: 'Securing market or business advantages',
          examples: [
            'The corporation had sewn up the distribution rights for the entire region.',
            'Their team sewed up the deal before competitors could respond.',
          ],
        ),
        ContextualUsage(
          context: 'Competition',
          description: 'Ensuring victory or advantage',
          examples: [
            'The candidate had the nomination sewn up months before the convention.',
            'They sewed up the championship with three games still to play.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shed',
  base: 'shed',
  past: 'shed',
  participle: 'shed',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'ʃɛd',
  pronunciationTextUK: 'ʃed',
  meanings: [
    VerbMeaning(
      definition: 'To cast off or let fall naturally',
      partOfSpeech: 'transitive verb',
      examples: [
        'Trees shed their leaves in autumn.',
        'The snake shed its skin as it grew.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Biological',
          description: 'Natural discarding of body parts by animals',
          examples: [
            'Deer shed their antlers every year and grow new ones.',
            'Dogs shed their winter coats when warmer weather arrives.',
          ],
        ),
        ContextualUsage(
          context: 'Botanical',
          description: 'Plant processes of dropping parts',
          examples: [
            'Deciduous trees shed their foliage before winter.',
            'The plant sheds petals after pollination is complete.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pour out or give off; to emit or diffuse',
      partOfSpeech: 'transitive verb',
      examples: [
        'The lamp shed a warm light across the room.',
        'Her story shed new light on the historical event.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Illumination',
          description: 'Producing or casting light',
          examples: [
            'The candles shed a soft glow throughout the dining room.',
            'The evidence shed light on previously unknown aspects of the case.',
          ],
        ),
        ContextualUsage(
          context: 'Clarification',
          description: 'Providing understanding or information',
          examples: [
            'His research shed light on the origins of the tradition.',
            'The documents shed new light on the historical figure\'s private life.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To rid oneself of something unwanted',
      partOfSpeech: 'transitive verb',
      examples: [
        'She quickly shed her wet clothes after coming in from the rain.',
        'The company shed hundreds of jobs during the recession.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Removal',
          description: 'Discarding or removing something',
          examples: [
            'He tried to shed his reputation as a troublemaker.',
            'The athlete shed several pounds before the competition.',
          ],
        ),
        ContextualUsage(
          context: 'Organizational',
          description: 'Eliminating assets, positions, or operations',
          examples: [
            'The corporation shed unprofitable divisions during restructuring.',
            'The government shed responsibilities by privatizing certain services.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pour out or release tears',
      partOfSpeech: 'transitive verb',
      examples: [
        'She shed tears at the emotional reunion.',
        'He didn\'t shed a tear at the funeral, keeping his grief private.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Expressing feelings through crying',
          examples: [
            'The audience shed tears during the moving scene in the film.',
            'He finally shed tears after holding in his emotions for so long.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Formal or poetic description of crying',
          examples: [
            'The widow shed bitter tears over her husband\'s grave.',
            'Not a tear was shed when the villain met his fate.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deflect or cause something to glide off',
      partOfSpeech: 'transitive verb',
      examples: [
        'The raincoat sheds water effectively.',
        'The roof is designed to shed snow during winter.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Materials',
          description: 'Design features that repel substances',
          examples: [
            'The non-stick pan sheds food easily during cooking.',
            'This fabric sheds dust and resists staining.',
          ],
        ),
        ContextualUsage(
          context: 'Architecture',
          description: 'Structural elements designed for drainage',
          examples: [
            'The angled roof sheds rainwater efficiently.',
            'The special coating helps the building shed ice buildup.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'smell',
  base: 'smell',
  past: 'smelled/smelt',
  participle: 'smelled/smelt',
  pastUK: 'smelt',
  pastUS: 'smelled',
  participleUK: 'smelt',
  participleUS: 'smelled',
  pronunciationTextUS: 'smɛl',
  pronunciationTextUK: 'smel',
  meanings: [
    VerbMeaning(
      definition: 'To perceive odors or scents through the nose',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'The dog smelled something suspicious under the porch.',
        'Can you smell the bread baking in the oven?',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Sensory',
          description: 'Using the sense of smell to detect odors',
          examples: [
            'He smelled smoke and immediately checked for fire.',
            'She couldn\'t smell anything when she had a cold.',
          ],
        ),
        ContextualUsage(
          context: 'Animal',
          description: 'Animal olfactory detection',
          examples: [
            'The predator smelled its prey from a great distance.',
            'Search dogs can smell drugs hidden in luggage.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To emit or have a particular odor',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The lilacs smell wonderful in spring.',
        'The garbage smelled terrible after sitting in the sun.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Pleasant',
          description: 'Emitting enjoyable fragrances',
          examples: [
            'The kitchen smelled of freshly baked cookies.',
            'The perfume smelled of jasmine and vanilla.',
          ],
        ),
        ContextualUsage(
          context: 'Unpleasant',
          description: 'Emitting disagreeable odors',
          examples: [
            'The drain smelled because of a clog.',
            'The gym smelled of sweat and rubber mats.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To investigate or test by smelling',
      partOfSpeech: 'transitive verb',
      examples: [
        'The wine expert smelled the cork before tasting.',
        'She smelled the milk to check if it had spoiled.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Evaluation',
          description: 'Assessing quality or condition by odor',
          examples: [
            'The chef smelled the fish to ensure its freshness.',
            'The perfumer smelled different samples before blending them.',
          ],
        ),
        ContextualUsage(
          context: 'Culinary',
          description: 'Evaluating food and drink through aroma',
          examples: [
            'The sommelier carefully smelled the wine before describing its notes.',
            'She smelled the spices to determine which to use in the recipe.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To detect or discover by intuition or suspicion',
      partOfSpeech: 'transitive verb',
      examples: [
        'The detective could smell a setup from the beginning.',
        'Investors can smell opportunity in emerging markets.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Intuition',
          description: 'Sensing situations through instinct',
          examples: [
            'She could smell trouble brewing between the two rivals.',
            'Experienced traders smell market shifts before they happen.',
          ],
        ),
        ContextualUsage(
          context: 'Suspicion',
          description: 'Detecting deception or problems',
          examples: [
            'The auditor smelled fraud when examining the accounts.',
            'The teacher smelled a lie in the student\'s elaborate excuse.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To give something an aroma deliberately',
      partOfSpeech: 'transitive verb',
      examples: [
        'They smelled the candles with essential oils.',
        'The manufacturer smells the soap with lavender.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Manufacturing',
          description: 'Adding scents to products',
          examples: [
            'The company smells their cleaning products with lemon and pine.',
            'Craftspeople smell handmade papers with subtle fragrances.',
          ],
        ),
        ContextualUsage(
          context: 'Cosmetic',
          description: 'Adding fragrance to personal care items',
          examples: [
            'They smell the shampoo with tropical fruit extracts.',
            'Artisanal soap makers smell their products with natural ingredients.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sneak',
  base: 'sneak',
  past: 'sneaked/snuck',
  participle: 'sneaked/snuck',
  pastUK: 'sneaked',
  pastUS: 'snuck/sneaked',
  participleUK: 'sneaked',
  participleUS: 'snuck/sneaked',
  pronunciationTextUS: 'sniːk',
  pronunciationTextUK: 'sniːk',
  meanings: [
    VerbMeaning(
      definition: 'To move quietly and furtively to avoid being seen or heard',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The teenagers sneaked out of the house after their parents were asleep.',
        'The cat snuck across the yard, stalking a bird.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Stealth',
          description: 'Moving secretly to avoid detection',
          examples: [
            'The spy sneaked past the guards unnoticed.',
            'She snuck down the hallway to avoid waking the baby.',
          ],
        ),
        ContextualUsage(
          context: 'Escape',
          description: 'Leaving or entering places secretly',
          examples: [
            'He sneaked away from the boring party without saying goodbye.',
            'The reporter snuck into the restricted area to get a story.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To take, put, or move something secretly',
      partOfSpeech: 'transitive verb',
      examples: [
        'She sneaked cookies from the jar when no one was looking.',
        'He snuck a peek at the test answers.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Secrecy',
          description: 'Taking or moving items discreetly',
          examples: [
            'The child sneaked candy into her bedroom.',
            'He snuck his phone into the meeting despite the ban.',
          ],
        ),
        ContextualUsage(
          context: 'Forbidden',
          description: 'Accessing or viewing prohibited things',
          examples: [
            'They sneaked a look at their Christmas presents before the holiday.',
            'She snuck glances at her crush across the classroom.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To include or add something subtly or secretly',
      partOfSpeech: 'transitive verb',
      examples: [
        'The chef sneaked vegetables into the children\'s meals.',
        'The writer snuck a political message into the seemingly innocent story.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Concealment',
          description: 'Hiding additions or inclusions',
          examples: [
            'The composer sneaked melodic references to classical works into his film score.',
            'Parents often sneak healthy ingredients into food their children otherwise wouldn\'t eat.',
          ],
        ),
        ContextualUsage(
          context: 'Subtlety',
          description: 'Including elements in an unobtrusive way',
          examples: [
            'The designer sneaked the company logo into the pattern.',
            'She snuck a compliment into what seemed like casual conversation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To do something secretly or without permission',
      partOfSpeech: 'transitive verb',
      examples: [
        'They sneaked a cigarette behind the school building.',
        'He snuck a quick nap during his lunch break.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Forbidden Activities',
          description: 'Engaging in prohibited behaviors secretly',
          examples: [
            'The employees sneaked a celebration drink in the office after hours.',
            'Students sometimes sneak their phones out during class to text.',
          ],
        ),
        ContextualUsage(
          context: 'Opportunity',
          description: 'Taking advantage of brief chances',
          examples: [
            'He sneaked in some exercise by taking the stairs instead of the elevator.',
            'She snuck a few moments of meditation during her busy day.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To win or accomplish something narrowly or unexpectedly',
      partOfSpeech: 'transitive verb',
      examples: [
        'The underdog team sneaked a victory in the final seconds.',
        'She snuck into first place when the leader made a mistake.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Competition',
          description: 'Achieving surprise or narrow victories',
          examples: [
            'The runner sneaked past the favorite at the finish line.',
            'The film snuck a nomination despite limited publicity.',
          ],
        ),
        ContextualUsage(
          context: 'Achievement',
          description: 'Accomplishing goals through unexpected means',
          examples: [
            'The bill sneaked through Congress during the holiday recess.',
            'Their product snuck into the market and quickly gained popularity.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'sow',
  base: 'sow',
  past: 'sowed',
  participle: 'sown/sowed',
  pastUK: '',
  pastUS: '',
  participleUK: 'sown',
  participleUS: 'sown/sowed',
  pronunciationTextUS: 'soʊ',
  pronunciationTextUK: 'səʊ',
  meanings: [
    VerbMeaning(
      definition: 'To plant seeds in the ground',
      partOfSpeech: 'transitive verb',
      examples: [
        'The farmer sowed wheat in the northern field.',
        'They sowed wildflower seeds throughout the meadow.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Agriculture',
          description: 'Planting crops for cultivation',
          examples: [
            'Farmers traditionally sow certain crops in spring and others in fall.',
            'They sowed the fields with barley after the wheat harvest.',
          ],
        ),
        ContextualUsage(
          context: 'Gardening',
          description: 'Planting seeds in domestic settings',
          examples: [
            'She sowed herb seeds in pots on her windowsill.',
            'The gardening club sowed a variety of vegetables in the community plot.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To scatter or disperse',
      partOfSpeech: 'transitive verb',
      examples: [
        'The wind sowed the dandelion seeds across the lawn.',
        'He sowed the fertilizer evenly over the grass.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Distribution',
          description: 'Spreading materials over an area',
          examples: [
            'The plane sowed cloud-seeding chemicals to induce rainfall.',
            'She sowed a thin layer of compost over the garden bed.',
          ],
        ),
        ContextualUsage(
          context: 'Natural',
          description: 'Natural dispersal processes',
          examples: [
            'The plant sows its seeds through explosive seed pods.',
            'Birds sow seeds across wide areas through their droppings.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To establish or introduce something that develops or spreads',
      partOfSpeech: 'transitive verb',
      examples: [
        'His speech sowed doubt in the minds of the voters.',
        'The incident sowed discord among the team members.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ideas',
          description: 'Introducing concepts or beliefs',
          examples: [
            'The professor sowed the seeds of curiosity in her students.',
            'Their campaign sowed fear among the population.',
          ],
        ),
        ContextualUsage(
          context: 'Conflict',
          description: 'Creating or spreading disagreement',
          examples: [
            'The rumors sowed division within the community.',
            'The policy sowed resentment among employees.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To ensure future results through present actions',
      partOfSpeech: 'transitive verb',
      examples: [
        'You reap what you sow in relationships.',
        'They sowed the foundations for future success with careful planning.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Taking actions with future consequences',
          examples: [
            'The mentorship program sows the seeds for the next generation of leaders.',
            'The company sowed investments in research that paid off years later.',
          ],
        ),
        ContextualUsage(
          context: 'Ethical',
          description: 'Moral implications of actions and consequences',
          examples: [
            'Parents sow values and principles in their children through example.',
            'The organization sowed goodwill through its community service.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spit',
  base: 'spit',
  past: 'spat/spit',
  participle: 'spat/spit',
  pastUK: 'spat',
  pastUS: 'spit/spat',
  participleUK: 'spat',
  participleUS: 'spit/spat',
  pronunciationTextUS: 'spɪt',
  pronunciationTextUK: 'spɪt',
  meanings: [
    VerbMeaning(
      definition: 'To forcefully eject saliva or other substance from the mouth',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The baseball player spat on the ground between pitches.',
        'He spit out the medicine because of its bitter taste.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Bodily expulsion of saliva',
          examples: [
            'It\'s considered rude to spit in public places.',
            'The child spat out the vegetable he disliked.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Expelling substances for health reasons',
          examples: [
            'The patient spat blood, concerning the doctor.',
            'After brushing, he spat the toothpaste into the sink.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To eject or emit forcefully',
      partOfSpeech: 'transitive verb',
      examples: [
        'The volcano spat ash and smoke into the air.',
        'The machine gun spat bullets at the target.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mechanical',
          description: 'Forceful ejection from machines or devices',
          examples: [
            'The printer spat out page after page of the document.',
            'The engine spat sparks when it malfunctioned.',
          ],
        ),
        ContextualUsage(
          context: 'Natural',
          description: 'Forceful emission in natural phenomena',
          examples: [
            'The geyser spat boiling water high into the air.',
            'The storm clouds spat lightning across the sky.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To speak in a hostile or angry manner',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He spat out the insult without thinking.',
        'She spat angry words at the customer service representative.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Anger',
          description: 'Hostile verbal expression',
          examples: [
            'The defendant spat defiance at the judge.',
            'The critic spat venom in his review of the play.',
          ],
        ),
        ContextualUsage(
          context: 'Conflict',
          description: 'Aggressive verbal exchanges',
          examples: [
            'The rivals spat accusations at each other during the debate.',
            'She spat the words through clenched teeth, barely controlling her anger.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make a spitting sound or action',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The bacon spat in the hot pan.',
        'The fire spat as the wet wood burned.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Cooking',
          description: 'Food preparation sounds and reactions',
          examples: [
            'The oil spat dangerously when water droplets fell into the fryer.',
            'The sausages spat and sizzled on the grill.',
          ],
        ),
        ContextualUsage(
          context: 'Environmental',
          description: 'Sounds in nature or environments',
          examples: [
            'The rain spat against the window panes during the storm.',
            'The campfire spat embers into the night air.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To pierce or impale food for cooking over a fire',
      partOfSpeech: 'transitive verb',
      examples: [
        'They spit the meat for the barbecue.',
        'The chef spat vegetables and meat on skewers for grilling.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Culinary',
          description: 'Traditional cooking methods',
          examples: [
            'The whole pig was spitted for the roast.',
            'Kebabs are made by spitting pieces of meat and vegetables together.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional or historical cooking practices',
          examples: [
            'Medieval cooks spitted large pieces of meat for roasting over open fires.',
            'The hunter spitted the rabbit over the campfire.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'stave',
  base: 'stave',
  past: 'staved/stove',
  participle: 'staved/stove',
  pastUK: 'staved',
  pastUS: 'staved/stove',
  participleUK: 'staved',
  participleUS: 'staved/stove',
  pronunciationTextUS: 'steɪv',
  pronunciationTextUK: 'steɪv',
  meanings: [
    VerbMeaning(
      definition: 'To break a hole in; to smash or burst',
      partOfSpeech: 'transitive verb',
      examples: [
        'The rock staved in the side of the boat.',
        'He stove his fist through the thin wall in anger.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Damage',
          description: 'Creating holes or breaches in structures',
          examples: [
            'The falling tree staved in part of the roof.',
            'The ship\'s hull was stoved in during the collision.',
          ],
        ),
        ContextualUsage(
          context: 'Maritime',
          description: 'Damage to boats or water vessels',
          examples: [
            'The iceberg stove a hole in the ship\'s hull.',
            'The rowboat\'s bottom was staved in on the rocks.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To delay, prevent, or put off temporarily',
      partOfSpeech: 'transitive verb',
      examples: [
        'The emergency measures staved off economic collapse.',
        'They staved off bankruptcy by securing new investment.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Prevention',
          description: 'Delaying negative outcomes',
          examples: [
            'The medication staved off the symptoms temporarily.',
            'The team staved off defeat with a last-minute goal.',
          ],
        ),
        ContextualUsage(
          context: 'Financial',
          description: 'Preventing financial problems',
          examples: [
            'The loan staved off immediate financial crisis for the company.',
            'Cost-cutting measures staved off the need for layoffs.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To break into pieces or staves',
      partOfSpeech: 'transitive verb',
      examples: [
        'The barrel was staved for firewood.',
        'The impact staved the crate into pieces.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Destruction',
          description: 'Breaking items into component parts',
          examples: [
            'The workers staved the old wine barrels for repurposing.',
            'The collision staved the wooden structure into splinters.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional handling of wooden containers',
          examples: [
            'Cooper\'s tools were used to stave barrels for repair.',
            'Old ships were sometimes staved for their valuable timber.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To walk or move in a vigorous or determined manner',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He staved along the path despite his fatigue.',
        'The hikers staved through the forest toward shelter.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Movement',
          description: 'Determined or forceful walking',
          examples: [
            'They staved against the strong wind to reach their destination.',
            'The group staved through deep snow on their winter trek.',
          ],
        ),
        ContextualUsage(
          context: 'Archaic',
          description: 'Historical usage for determined movement',
          examples: [
            'The soldiers staved forward despite their wounds.',
            'Pioneers staved across difficult terrain to reach new settlements.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To furnish with staves or rungs',
      partOfSpeech: 'transitive verb',
      examples: [
        'The craftsman staved the chair with oak slats.',
        'The cooper staved the barrel with seasoned wood.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Craftsmanship',
          description: 'Adding wooden components to structures',
          examples: [
            'Traditional coopers staved barrels using specialized techniques.',
            'The furniture maker staved the back of the rocking chair.',
          ],
        ),
        ContextualUsage(
          context: 'Construction',
          description: 'Building with wooden slats or components',
          examples: [
            'The fence was staved with vertical planks.',
            'Early settlers staved their simple furniture by hand.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'strew',
  base: 'strew',
  past: 'strewed',
  participle: 'strewn/strewed',
  pastUK: '',
  pastUS: '',
  participleUK: 'strewn',
  participleUS: 'strewn/strewed',
  pronunciationTextUS: 'struː',
  pronunciationTextUK: 'struː',
  meanings: [
    VerbMeaning(
      definition: 'To scatter or spread loosely over a surface',
      partOfSpeech: 'transitive verb',
      examples: [
        'She strewed rose petals along the path to the altar.',
        'Autumn winds strewed leaves across the lawn.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ceremonial',
          description: 'Spreading materials for celebrations',
          examples: [
            'The children strewed flower petals before the bride.',
            'The host strewed confetti to welcome the guests.',
          ],
        ),
        ContextualUsage(
          context: 'Decorative',
          description: 'Aesthetic scattering of items',
          examples: [
            'The designer strewed colorful pillows across the bed.',
            'She strewed seashells along the windowsill as decoration.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cover by scattering something over a surface',
      partOfSpeech: 'transitive verb',
      examples: [
        'The baker strewed powdered sugar over the pastries.',
        'Farmers strewed their fields with lime to reduce soil acidity.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Culinary',
          description: 'Adding ingredients across food surfaces',
          examples: [
            'The chef strewed herbs over the roasted vegetables.',
            'She strewed grated cheese over the pasta before serving.',
          ],
        ),
        ContextualUsage(
          context: 'Agricultural',
          description: 'Distributing materials across land',
          examples: [
            'The gardener strewed mulch around the plants.',
            'They strewed seed on the prepared ground.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To be scattered or spread in a disorderly manner',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Books and papers were strewn all over his desk.',
        'Debris from the storm was strewn across the street.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Disarray',
          description: 'Untidy or disorganized distribution',
          examples: [
            'Children\'s toys were strewn around the living room.',
            'Clothing was strewn haphazardly across the bedroom floor.',
          ],
        ),
        ContextualUsage(
          context: 'Aftermath',
          description: 'Results of accidents or disasters',
          examples: [
            'Wreckage from the plane crash was strewn over a wide area.',
            'After the hurricane, personal belongings were strewn throughout the neighborhood.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To distribute or disperse over a period or area',
      partOfSpeech: 'transitive verb',
      examples: [
        'The author strewed literary references throughout the novel.',
        'His career was strewn with both successes and failures.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Temporal',
          description: 'Distribution across time periods',
          examples: [
            'Important events were strewn throughout the century.',
            'The composer strewed musical themes throughout the symphony.',
          ],
        ),
        ContextualUsage(
          context: 'Conceptual',
          description: 'Distribution of ideas or elements',
          examples: [
            'The speech was strewn with historical allusions.',
            'Clues were strewn throughout the mystery novel.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'thrive',
  base: 'thrive',
  past: 'thrived/throve',
  participle: 'thrived/thriven',
  pastUK: 'thrived',
  pastUS: 'thrived/throve',
  participleUK: 'thrived',
  participleUS: 'thrived/thriven',
  pronunciationTextUS: 'θraɪv',
  pronunciationTextUK: 'θraɪv',
  meanings: [
    VerbMeaning(
      definition: 'To grow vigorously; to flourish and develop successfully',
      partOfSpeech: 'intransitive verb',
      examples: [
        'These plants thrive in hot, humid conditions.',
        'The company has thrived despite economic downturns.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Biological',
          description: 'Successful plant or animal growth',
          examples: [
            'Desert cacti thrive in arid environments with little water.',
            'The endangered species has thrived since conservation efforts began.',
          ],
        ),
        ContextualUsage(
          context: 'Business',
          description: 'Success in commercial enterprises',
          examples: [
            'Local restaurants thrived when the factory opened nearby.',
            'Online businesses have thrived during the pandemic.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To prosper or be successful, especially in difficult circumstances',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She thrives under pressure and delivers her best work before deadlines.',
        'Some people thrive on the excitement of risk-taking ventures.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Personal',
          description: 'Individual achievement or success',
          examples: [
            'He thrived in the competitive academic environment.',
            'The artist thrived after moving to a more creative community.',
          ],
        ),
        ContextualUsage(
          context: 'Professional',
          description: 'Career advancement or development',
          examples: [
            'She thrived in her new role as team leader.',
            'Creative thinkers thrive in innovative organizations.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To grow to a healthy or vigorous state; to develop well physically',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The baby thrived on the new formula.',
        'Children thrive when they have stable routines and loving care.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Medical',
          description: 'Healthy physical development',
          examples: [
            'The premature infant thrived under specialized care.',
            'Patients often thrive when they take an active role in their recovery.',
          ],
        ),
        ContextualUsage(
          context: 'Nutritional',
          description: 'Growth resulting from proper nourishment',
          examples: [
            'The toddler thrived on a balanced diet.',
            'Farm animals thrive when allowed to graze naturally.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make steady progress; to advance or improve consistently',
      partOfSpeech: 'intransitive verb',
      examples: [
        'Their relationship thrived after they improved their communication.',
        'Democracy thrives when citizens actively participate.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Success in relationships or communities',
          examples: [
            'Cultural traditions thrive when passed to younger generations.',
            'The community thrived after implementing the revitalization plan.',
          ],
        ),
        ContextualUsage(
          context: 'Institutional',
          description: 'Successful development of organizations or systems',
          examples: [
            'Universities thrive when they balance tradition and innovation.',
            'Free press thrives in open societies.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'wed',
  base: 'wed',
  past: 'wed/wedded',
  participle: 'wed/wedded',
  pastUK: 'wed',
  pastUS: 'wed/wedded',
  participleUK: 'wed',
  participleUS: 'wed/wedded',
  pronunciationTextUS: 'wɛd',
  pronunciationTextUK: 'wed',
  meanings: [
    VerbMeaning(
      definition: 'To marry; to take as a spouse',
      partOfSpeech: 'transitive verb',
      examples: [
        'They wed in a small ceremony last spring.',
        'The couple was wed by a justice of the peace.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Ceremonial',
          description: 'Formal marriage procedures',
          examples: [
            'The priest wed them in the ancient cathedral.',
            'The celebrities wed in a private ceremony away from public view.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'More formal expression for marriage',
          examples: [
            'They were wed in the presence of close family and friends.',
            'Royal couples are traditionally wed with elaborate state ceremonies.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To join or connect closely or inseparably',
      partOfSpeech: 'transitive verb',
      examples: [
        'The bridge weds the two communities that were previously separated.',
        'Their shared experiences wed them in a deep friendship.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Figurative joining of non-marital elements',
          examples: [
            'The design successfully weds function and beauty.',
            'The chef\'s cuisine weds traditional techniques with modern flavors.',
          ],
        ),
        ContextualUsage(
          context: 'Conceptual',
          description: 'Combining ideas or principles',
          examples: [
            'The philosophy weds Eastern and Western traditions of thought.',
            'Their approach weds scientific rigor with creative thinking.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To perform a marriage ceremony',
      partOfSpeech: 'transitive verb',
      examples: [
        'The minister has wed hundreds of couples during his career.',
        'In some cultures, only religious officials can wed couples.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Official',
          description: 'Legal or religious authority to perform marriages',
          examples: [
            'The judge is authorized to wed couples in civil ceremonies.',
            'The rabbi has wed members of the congregation for over thirty years.',
          ],
        ),
        ContextualUsage(
          context: 'Professional',
          description: 'Conducting marriages as an occupation',
          examples: [
            'The chaplain weds military personnel on the base.',
            'The wedding officiant weds couples in unique outdoor settings.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To commit deeply or permanently to something',
      partOfSpeech: 'transitive verb',
      examples: [
        'She is wed to the idea of becoming a doctor.',
        'The organization is wed to outdated methods and resistant to change.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Commitment',
          description: 'Strong dedication to ideas or paths',
          examples: [
            'The politician is wed to his party\'s traditional ideology.',
            'Many scientists become wed to their own theories despite contradictory evidence.',
          ],
        ),
        ContextualUsage(
          context: 'Limitation',
          description: 'Restricted by firm attachment to something',
          examples: [
            'The company is wed to production methods that are no longer efficient.',
            'Some artists become wed to a particular style that limits their growth.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'withdraw',
  base: 'withdraw',
  past: 'withdrew',
  participle: 'withdrawn',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'wɪðˈdrɔː',
  pronunciationTextUK: 'wɪðˈdrɔː',
  meanings: [
    VerbMeaning(
      definition: 'To remove or take back something',
      partOfSpeech: 'transitive verb',
      examples: [
        'He withdrew money from his account.',
        'The company withdrew the product due to safety concerns.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Financial',
          description: 'Taking money from accounts or investments',
          examples: [
            'She withdrew her savings to make a down payment on a house.',
            'Investors withdrew funds when the market became volatile.',
          ],
        ),
        ContextualUsage(
          context: 'Products',
          description: 'Removing items from sale or circulation',
          examples: [
            'The publisher withdrew the book after discovering factual errors.',
            'The manufacturer withdrew the defective toys from store shelves.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To retreat or move back from a position or situation',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The army withdrew from the occupied territory.',
        'She withdrew from the competition due to injury.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Military',
          description: 'Strategic retreat of forces',
          examples: [
            'The troops withdrew to defensive positions in the mountains.',
            'The generals ordered a tactical withdrawal to regroup.',
          ],
        ),
        ContextualUsage(
          context: 'Participation',
          description: 'Ceasing involvement in activities',
          examples: [
            'The candidate withdrew from the race before the primary.',
            'He withdrew from the project when funding problems arose.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To remove oneself from social contact or interaction',
      partOfSpeech: 'intransitive verb',
      examples: [
        'After his wife\'s death, he withdrew from society.',
        'The shy child withdrew when strangers approached.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Reducing engagement with others',
          examples: [
            'The author withdrew to a remote cabin to focus on writing.',
            'Depression caused her to withdraw from friends and family.',
          ],
        ),
        ContextualUsage(
          context: 'Psychological',
          description: 'Emotional or mental retreat',
          examples: [
            'Trauma can cause people to withdraw into themselves.',
            'The patient withdrew into silence during the therapy session.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To discontinue or remove from consideration',
      partOfSpeech: 'transitive verb',
      examples: [
        'She withdrew her application for the position.',
        'The senator withdrew his support for the controversial bill.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legal',
          description: 'Formally removing legal submissions',
          examples: [
            'The attorney withdrew the objection after consulting with her client.',
            'They withdrew the lawsuit following an out-of-court settlement.',
          ],
        ),
        ContextualUsage(
          context: 'Political',
          description: 'Removing political proposals or endorsements',
          examples: [
            'The committee withdrew the amendment after strong opposition.',
            'The party withdrew its candidate when the scandal broke.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause to stop taking a drug or medication',
      partOfSpeech: 'transitive verb',
      examples: [
        'The doctor withdrew the medication when side effects appeared.',
        'They gradually withdrew the patient from the pain medication.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Medical',
          description: 'Ceasing administration of treatment',
          examples: [
            'The physician withdrew antibiotics once the infection cleared.',
            'Certain medications must be withdrawn slowly to avoid complications.',
          ],
        ),
        ContextualUsage(
          context: 'Addiction',
          description: 'Process of stopping substance use',
          examples: [
            'The program helps patients withdraw from alcohol safely.',
            'The body experiences symptoms when caffeine is withdrawn suddenly.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'forbid',
  base: 'forbid',
  past: 'forbade/forbad',
  participle: 'forbidden/forbid',
  pastUK: 'forbade',
  pastUS: 'forbade/forbad',
  participleUK: 'forbidden',
  participleUS: 'forbidden/forbid',
  pronunciationTextUS: 'fərˈbɪd',
  pronunciationTextUK: 'fəˈbɪd',
  meanings: [
    VerbMeaning(
      definition: 'To order someone not to do something; to prohibit',
      partOfSpeech: 'transitive verb',
      examples: [
        'The teacher forbade the students to leave the classroom.',
        'Her parents forbade her to date until she turned sixteen.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Authority',
          description: 'Using power to prohibit actions',
          examples: [
            'The king forbade any criticism of his policies.',
            'The supervisor forbade personal phone calls during work hours.',
          ],
        ),
        ContextualUsage(
          context: 'Parental',
          description: 'Parents restricting children\'s activities',
          examples: [
            'They forbade their teenager from attending the party.',
            'His father forbade him to ride motorcycles due to safety concerns.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To make impossible; to prevent through circumstances or conditions',
      partOfSpeech: 'transitive verb',
      examples: [
        'The storm forbade any attempt at climbing the mountain.',
        'His poor health forbade any strenuous exercise.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Circumstantial',
          description: 'Conditions making something impossible',
          examples: [
            'The heavy snow forbade travel through the mountain pass.',
            'The budget constraints forbade any additional hiring this year.',
          ],
        ),
        ContextualUsage(
          context: 'Medical',
          description: 'Health limitations preventing activities',
          examples: [
            'The doctor\'s orders forbade any contact sports for six months.',
            'Her allergy forbids eating any dairy products.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To legally prohibit something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The law forbids smoking in public buildings.',
        'Local regulations forbid construction during certain hours.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Legal',
          description: 'Laws or regulations prohibiting activities',
          examples: [
            'The constitution forbids discrimination based on religion.',
            'City ordinances forbid parking on this street during winter months.',
          ],
        ),
        ContextualUsage(
          context: 'Institutional',
          description: 'Organizational rules prohibiting actions',
          examples: [
            'School policy forbids the use of mobile phones during exams.',
            'The apartment lease forbids subletting without permission.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To express strong disapproval or refusal',
      partOfSpeech: 'transitive verb',
      examples: [
        'Heaven forbid that anything should happen to the children.',
        'God forbid we should fail at this crucial moment.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Exclamatory',
          description: 'Expressions of strong aversion',
          examples: [
            'Forbid it, Almighty God, that I should suggest such a thing!',
            'Heaven forbid that I should ever see such suffering again.',
          ],
        ),
        ContextualUsage(
          context: 'Cultural',
          description: 'Traditional expressions of worry or concern',
          examples: [
            'God forbid that war should break out during our lifetime.',
            'Forbid it that anyone should experience such tragedy.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'blow',
  base: 'blow',
  past: 'blew',
  participle: 'blown',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'bloʊ',
  pronunciationTextUK: 'bləʊ',
  meanings: [
    VerbMeaning(
      definition: 'To move and create a current of air, as wind',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The wind blew fiercely during the storm.',
        'A gentle breeze was blowing through the open window.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Weather',
          description: 'Natural movement of air',
          examples: [
            'The winter winds blew from the north, bringing cold air.',
            'Hurricane-force winds blew for hours, causing significant damage.',
          ],
        ),
        ContextualUsage(
          context: 'Sensation',
          description: 'Feeling air movement',
          examples: [
            'The sea air blew fresh against her face as she stood on the deck.',
            'A draft blew under the door, creating a cold spot in the room.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To force air out from the mouth or nose',
      partOfSpeech: 'transitive/intransitive verb',
      examples: [
        'She blew on her hot coffee before taking a sip.',
        'The child blew soap bubbles in the garden.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical Action',
          description: 'Expelling air for specific purposes',
          examples: [
            'The glassblower blew into the pipe to shape the molten glass.',
            'He blew his nose into a handkerchief.',
          ],
        ),
        ContextualUsage(
          context: 'Music',
          description: 'Playing wind instruments',
          examples: [
            'She blew into the flute, producing a melodious sound.',
            'The musician blew a long, mournful note on the saxophone.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To explode, shatter, or break apart suddenly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The tire blew while they were driving on the highway.',
        'The transformer blew during the electrical storm.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mechanical',
          description: 'Equipment or device failure',
          examples: [
            'The engine blew after years of neglected maintenance.',
            'The fuse blew when too many appliances were running simultaneously.',
          ],
        ),
        ContextualUsage(
          context: 'Structural',
          description: 'Building or construction failure',
          examples: [
            'The dam blew after days of heavy rainfall.',
            'Windows blew out when the pressure changed during the tornado.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To waste or squander money, opportunity, or advantage',
      partOfSpeech: 'transitive verb',
      examples: [
        'He blew his entire paycheck at the casino.',
        'She blew her chance for promotion by arriving late to the interview.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Financial',
          description: 'Spending money carelessly',
          examples: [
            'The lottery winner blew millions on luxury purchases within a year.',
            'He blew his savings on an extravagant vacation.',
          ],
        ),
        ContextualUsage(
          context: 'Opportunity',
          description: 'Missing or wasting chances',
          examples: [
            'The team blew their lead in the final minutes of the game.',
            'They blew the business opportunity by failing to follow up promptly.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To depart or leave quickly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'When the police arrived, the gang blew out of town.',
        'They blew out of the party when the argument started.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Informal',
          description: 'Casual expression for sudden departure',
          examples: [
            'Let\'s blow – this place is getting boring.',
            'He blew out of the meeting when his proposal was rejected.',
          ],
        ),
        ContextualUsage(
          context: 'Departure',
          description: 'Rapid or urgent leaving',
          examples: [
            'The suspects blew town before the police could make arrests.',
            'When the storm warning came, tourists blew out of the beach resort.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'bear',
  base: 'bear',
  past: 'bore',
  participle: 'borne/born',
  pastUK: '',
  pastUS: '',
  participleUK: 'borne',
  participleUS: 'borne/born',
  pronunciationTextUS: 'bɛr',
  pronunciationTextUK: 'beə',
  meanings: [
    VerbMeaning(
      definition: 'To carry or support the weight of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The pillars bear the weight of the roof.',
        'She couldn\'t bear even the lightest package after her injury.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Supporting physical weight or load',
          examples: [
            'The bridge was designed to bear heavy traffic.',
            'The shelf cannot bear the weight of all those books.',
          ],
        ),
        ContextualUsage(
          context: 'Structural',
          description: 'Architectural or engineering support',
          examples: [
            'These walls bear the load of the upper floors.',
            'The central beam bears most of the roof\'s weight.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To endure or tolerate something difficult',
      partOfSpeech: 'transitive verb',
      examples: [
        'She could not bear the thought of leaving her hometown.',
        'He bore the pain without complaint.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Handling emotional challenges',
          examples: [
            'She couldn\'t bear to watch the sad ending of the film.',
            'He bore the grief of losing his father with remarkable strength.',
          ],
        ),
        ContextualUsage(
          context: 'Suffering',
          description: 'Enduring physical or psychological pain',
          examples: [
            'The patient bore the uncomfortable procedure stoically.',
            'Some can bear isolation better than others.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To give birth to offspring',
      partOfSpeech: 'transitive verb',
      examples: [
        'She bore five children during her lifetime.',
        'The royal family was pleased when the queen bore a son.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Childbearing',
          description: 'Human reproduction and birth',
          examples: [
            'She bore twins after a difficult pregnancy.',
            'The woman had borne three daughters before having a son.',
          ],
        ),
        ContextualUsage(
          context: 'Animal',
          description: 'Animal reproduction',
          examples: [
            'The mare bore a healthy foal in the spring.',
            'Female bears typically bear cubs every other year.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To produce as a natural product or result',
      partOfSpeech: 'transitive verb',
      examples: [
        'The apple tree bore fruit despite the drought.',
        'His hard work bore excellent results.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Botanical',
          description: 'Plant production of fruits or flowers',
          examples: [
            'These vines bear grapes suited for wine-making.',
            'The old tree still bears abundant fruit each season.',
          ],
        ),
        ContextualUsage(
          context: 'Outcome',
          description: 'Yielding results or consequences',
          examples: [
            'Their research bore unexpected findings.',
            'The investment bore interest over time.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To carry or convey something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The messenger bore important news from the king.',
        'The wind bore the scent of flowers from the garden.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Transport',
          description: 'Moving or carrying objects',
          examples: [
            'The ship bore supplies to the isolated island.',
            'The river bears silt from the mountains to the valley.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'Ceremonial or formal carrying',
          examples: [
            'The knights bore the king\'s standard into battle.',
            'Pallbearers bore the coffin to the gravesite.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To have or show a particular feature, marking, or characteristic',
      partOfSpeech: 'transitive verb',
      examples: [
        'The ancient coin bears the emperor\'s likeness.',
        'He bears a strong resemblance to his grandfather.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Appearance',
          description: 'Visual characteristics or features',
          examples: [
            'The document bears the official seal of the university.',
            'Her face bears the marks of years spent in the sun.',
          ],
        ),
        ContextualUsage(
          context: 'Identification',
          description: 'Displaying identifying features',
          examples: [
            'The painting bears the artist\'s signature in the corner.',
            'These products bear labels indicating their origin.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'alight',
  base: 'alight',
  past: 'alighted/alit',
  participle: 'alighted/alit',
  pastUK: 'alighted',
  pastUS: 'alighted/alit',
  participleUK: 'alighted',
  participleUS: 'alighted/alit',
  pronunciationTextUS: 'əˈlaɪt',
  pronunciationTextUK: 'əˈlaɪt',
  meanings: [
    VerbMeaning(
      definition: 'To descend and settle or land after flight',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The butterfly alighted on the flower.',
        'The bird alit on the branch momentarily before flying away.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Avian',
          description: 'Birds landing after flight',
          examples: [
            'The eagle alighted gracefully on the cliff edge.',
            'Several sparrows alit on the garden fence to rest.',
          ],
        ),
        ContextualUsage(
          context: 'Insects',
          description: 'Insects settling after flying',
          examples: [
            'The dragonfly alighted on the lily pad.',
            'Bees alit on the blossoms to collect nectar.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To descend from a vehicle or horse',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The passengers alighted from the train at the small country station.',
        'She alit from her horse and tied it to a post.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Transport',
          description: 'Formal term for exiting vehicles',
          examples: [
            'The dignitaries alighted from their carriages at the palace entrance.',
            'Travelers alighted from the stagecoach at each stop along the route.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional dismounting in historical contexts',
          examples: [
            'The knight alighted from his steed before approaching the castle.',
            'Ladies alighted from carriages with the assistance of footmen.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To come by chance upon a discovery or idea',
      partOfSpeech: 'intransitive verb',
      examples: [
        'She alighted on the perfect solution while taking a walk.',
        'The detective finally alit on the crucial clue to solve the case.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Discovery',
          description: 'Finding or realizing something by chance',
          examples: [
            'The researcher alighted on an unexpected correlation in the data.',
            'I alighted on her name while browsing through an old directory.',
          ],
        ),
        ContextualUsage(
          context: 'Intellectual',
          description: 'Arriving at ideas or insights',
          examples: [
            'The philosopher alighted on a new theory during his meditations.',
            'After much thought, she alit on a compromise that satisfied everyone.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To illuminate or set light to something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The setting sun alighted the windows of the western face of the building.',
        'The candles alit the dark chapel with a warm glow.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Literary',
          description: 'Poetic description of illumination',
          examples: [
            'The moon alighted the landscape with silver radiance.',
            'Dawn alighted the mountain peaks before the valleys below.',
          ],
        ),
        ContextualUsage(
          context: 'Archaic',
          description: 'Historical usage for lighting or illuminating',
          examples: [
            'The servant alighted the lamps throughout the mansion at dusk.',
            'Lightning alighted the night sky during the storm.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'clothe',
  base: 'clothe',
  past: 'clothed/clad',
  participle: 'clothed/clad',
  pastUK: 'clothed',
  pastUS: 'clothed/clad',
  participleUK: 'clothed',
  participleUS: 'clothed/clad',
  pronunciationTextUS: 'kloʊð',
  pronunciationTextUK: 'kləʊð',
  meanings: [
    VerbMeaning(
      definition: 'To put clothes or a garment on; to dress',
      partOfSpeech: 'transitive verb',
      examples: [
        'The mother clothed her children in warm coats for winter.',
        'He was clothed in a simple black suit for the funeral.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Care',
          description: 'Dressing others, especially dependents',
          examples: [
            'The nurse clothed the patient in a hospital gown.',
            'Parents are responsible for clothing their children appropriately.',
          ],
        ),
        ContextualUsage(
          context: 'Formal',
          description: 'Ceremonial or official dressing',
          examples: [
            'The priests were clothed in ceremonial robes for the service.',
            'The king was clothed in royal regalia for the coronation.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To provide clothing for someone',
      partOfSpeech: 'transitive verb',
      examples: [
        'The charity clothed homeless people during the cold winter months.',
        'His salary barely clothed and fed his large family.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Charity',
          description: 'Providing garments to those in need',
          examples: [
            'The organization clothes thousands of children from low-income families.',
            'Donations helped clothe victims who lost everything in the flood.',
          ],
        ),
        ContextualUsage(
          context: 'Provision',
          description: 'Supplying clothing as a basic need',
          examples: [
            'Parents must feed, clothe, and shelter their dependents.',
            'The government program helps clothe refugees arriving with few possessions.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cover as if with clothing; to envelop or surround',
      partOfSpeech: 'transitive verb',
      examples: [
        'Snow clothed the landscape in a blanket of white.',
        'Fog clad the mountains, hiding their peaks.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Natural',
          description: 'Environmental or seasonal covering',
          examples: [
            'Autumn clothed the trees in brilliant colors.',
            'Moss had clothed the ancient ruins over centuries.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Poetic or metaphorical covering',
          examples: [
            'The night clothed the city in darkness and mystery.',
            'The building was clad in climbing vines and flowers.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To express or present ideas in words',
      partOfSpeech: 'transitive verb',
      examples: [
        'The poet clothed simple thoughts in beautiful language.',
        'He clad his criticism in humor to soften its impact.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Expression',
          description: 'Presenting concepts in particular verbal forms',
          examples: [
            'The philosopher clothed complex ideas in accessible metaphors.',
            'The speech clothed political messages in patriotic rhetoric.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Stylistic presentation in writing',
          examples: [
            'The author clothed the historical facts in vivid narrative.',
            'The lecturer clothed scientific concepts in everyday language.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'delve',
  base: 'delve',
  past: 'delved',
  participle: 'delved',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'dɛlv',
  pronunciationTextUK: 'delv',
  meanings: [
    VerbMeaning(
      definition: 'To dig or excavate, especially with a spade',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The archaeologists delved into the ancient burial site.',
        'Miners delved deep into the mountain searching for gold.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Archaeological',
          description: 'Excavation for historical artifacts',
          examples: [
            'They delved carefully through layers of sediment at the dig site.',
            'Archaeologists have delved in this region for decades, uncovering many artifacts.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional digging or excavation',
          examples: [
            'Medieval peasants delved in fields to prepare them for planting.',
            'The treasure hunters delved in areas where legends suggested buried riches.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To search thoroughly or research deeply',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The journalist delved into the politician\'s past.',
        'She delved through old records to trace her family history.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Research',
          description: 'In-depth investigation or study',
          examples: [
            'The scholar delved into obscure manuscripts for his dissertation.',
            'Detectives delved into the suspect\'s financial records for evidence.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Exploring sources or texts thoroughly',
          examples: [
            'The biographer delved into private letters and diaries.',
            'Students are encouraged to delve beyond the assigned readings.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To examine or investigate thoroughly',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The committee delved into the causes of the financial crisis.',
        'The therapist delved into childhood experiences to understand the patient\'s behavior.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Analysis',
          description: 'Detailed examination of issues or problems',
          examples: [
            'The report delves into the environmental impact of the proposed dam.',
            'The documentary delves into the complexities of international diplomacy.',
          ],
        ),
        ContextualUsage(
          context: 'Psychological',
          description: 'Exploring mental or emotional aspects',
          examples: [
            'The novel delves into the protagonist\'s inner conflicts.',
            'The counselor helped her delve into the root causes of her anxiety.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To reach inside a container or space to search for something',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He delved into his pocket for loose change.',
        'She delved into her purse to find her keys.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Searching inside containers or spaces',
          examples: [
            'The child delved into the toy box looking for a specific action figure.',
            'He delved through the cluttered drawer searching for a screwdriver.',
          ],
        ),
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Searching within abstract containers',
          examples: [
            'She delved into her memories for details of that summer.',
            'The poet delved into his imagination for fresh metaphors.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'gird',
  base: 'gird',
  past: 'girded/girt',
  participle: 'girded/girt',
  pastUK: 'girded',
  pastUS: 'girded/girt',
  participleUK: 'girded',
  participleUS: 'girded/girt',
  pronunciationTextUS: 'ɡɜrd',
  pronunciationTextUK: 'ɡɜːd',
  meanings: [
    VerbMeaning(
      definition: 'To encircle or bind with a belt or band',
      partOfSpeech: 'transitive verb',
      examples: [
        'The knight girded his sword around his waist.',
        'She girded herself with a sash before the ceremony.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional fastening of clothing or armor',
          examples: [
            'The soldiers girded their armor before battle.',
            'The samurai carefully girt his sword belt according to tradition.',
          ],
        ),
        ContextualUsage(
          context: 'Ceremonial',
          description: 'Ritual or formal fastening of garments',
          examples: [
            'The priest girded himself with ceremonial vestments.',
            'Kings were girded with special belts during coronation ceremonies.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To prepare for action or a challenge',
      partOfSpeech: 'reflexive verb',
      examples: [
        'They girded themselves for the difficult negotiations ahead.',
        'She girded herself to face her critics at the press conference.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mental',
          description: 'Psychological preparation for challenges',
          examples: [
            'The team girded themselves for the championship match.',
            'He girded himself to deliver the bad news to the shareholders.',
          ],
        ),
        ContextualUsage(
          context: 'Biblical',
          description: 'Spiritual or moral preparation',
          examples: [
            'The text urges readers to gird themselves with truth and righteousness.',
            'The prophet girded himself for the difficult task that lay before him.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To surround or encircle completely',
      partOfSpeech: 'transitive verb',
      examples: [
        'A stone wall girds the old city.',
        'The fortress was girt by a deep moat.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Architectural',
          description: 'Structures surrounding areas or buildings',
          examples: [
            'High mountains gird the valley on all sides.',
            'The palace is girded by elaborate formal gardens.',
          ],
        ),
        ContextualUsage(
          context: 'Poetic',
          description: 'Literary descriptions of surroundings',
          examples: [
            'Mighty forests gird the ancient kingdom.',
            'The island is girt by sea, as the national anthem states.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To secure or strengthen, especially with supports',
      partOfSpeech: 'transitive verb',
      examples: [
        'The engineers girded the damaged bridge with steel cables.',
        'The old tree was girt with metal bands to prevent it from splitting.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Construction',
          description: 'Adding structural support to buildings',
          examples: [
            'They girded the weak walls with buttresses.',
            'The historic structure was girded with modern reinforcements to withstand earthquakes.',
          ],
        ),
        ContextualUsage(
          context: 'Engineering',
          description: 'Reinforcing structures or objects',
          examples: [
            'The ship\'s hull was girded with additional plates for ice navigation.',
            'Workers girded the aging utility poles to extend their useful life.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'rend',
  base: 'rend',
  past: 'rent',
  participle: 'rent',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'rɛnd',
  pronunciationTextUK: 'rend',
  meanings: [
    VerbMeaning(
      definition: 'To tear apart or in pieces with force or violence',
      partOfSpeech: 'transitive verb',
      examples: [
        'The explosion rent the building apart.',
        'She rent the letter in two after reading its contents.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Physical',
          description: 'Violent tearing of materials or objects',
          examples: [
            'The storm rent the sails of the ship.',
            'The wild animal rent its prey with powerful claws.',
          ],
        ),
        ContextualUsage(
          context: 'Dramatic',
          description: 'Forceful separation in literary contexts',
          examples: [
            'The earthquake rent the ground, creating a deep chasm.',
            'The warrior\'s sword rent the enemy\'s shield in battle.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To split or cause division, especially in social or political contexts',
      partOfSpeech: 'transitive verb',
      examples: [
        'The controversial decision rent the community in two.',
        'Religious differences have rent the country for generations.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Creating divisions among people or groups',
          examples: [
            'The scandal rent the political party, leading to its eventual collapse.',
            'Civil war rent the nation, leaving lasting scars.',
          ],
        ),
        ContextualUsage(
          context: 'Organizational',
          description: 'Creating splits within institutions',
          examples: [
            'Philosophical differences rent the academic department.',
            'The dispute over leadership rent the once-unified movement.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cause intense pain, distress, or grief',
      partOfSpeech: 'transitive verb',
      examples: [
        'Her heart was rent by the news of her brother\'s death.',
        'The terrible sights rent his soul with compassion.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Causing deep emotional suffering',
          examples: [
            'Grief rent her spirit as she stood by the grave.',
            'The tragedy rent the parents\' hearts beyond repair.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Poetic description of emotional pain',
          examples: [
            'His conscience was rent by guilt over his actions.',
            'The plaintive cry rent the still night air.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To extract or remove with force',
      partOfSpeech: 'transitive verb',
      examples: [
        'The surgeon rent the tumor from the patient\'s body.',
        'The dictator was violently rent from power by the revolution.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Removal',
          description: 'Forcible extraction or separation',
          examples: [
            'The child was rent from his mother\'s arms by the kidnappers.',
            'The crown was rent from the king\'s head during the uprising.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Historical instances of forcible removal',
          examples: [
            'Indigenous peoples were rent from their ancestral lands.',
            'The artifact was rent from its original setting by looters.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'riven',
  base: 'rive',
  past: 'rived',
  participle: 'riven',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'raɪv',
  pronunciationTextUK: 'raɪv',
  meanings: [
    VerbMeaning(
      definition: 'To split or tear apart violently',
      partOfSpeech: 'transitive verb',
      examples: [
        'Lightning rived the ancient oak tree.',
        'The explosion rived the building in two.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Natural',
          description: 'Forces of nature causing splitting',
          examples: [
            'The earthquake rived the ground, creating a massive fissure.',
            'Frost had riven the rock face over centuries.',
          ],
        ),
        ContextualUsage(
          context: 'Destructive',
          description: 'Violent splitting of structures or objects',
          examples: [
            'The blast rived the ship\'s hull.',
            'The ax rived the log with a single strike.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To divide or separate into opposing groups or factions',
      partOfSpeech: 'transitive verb',
      examples: [
        'The controversial issue rived the community.',
        'Political differences have riven the country for generations.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Social',
          description: 'Creating divisions in communities',
          examples: [
            'Religious disagreements rived the congregation.',
            'The succession dispute rived the royal family.',
          ],
        ),
        ContextualUsage(
          context: 'Political',
          description: 'Creating political divisions',
          examples: [
            'Ideological differences have riven the party into competing factions.',
            'The scandal rived the government, leading to its collapse.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To break someone\'s heart or spirit',
      partOfSpeech: 'transitive verb',
      examples: [
        'Grief rived her heart when she heard the tragic news.',
        'The betrayal rived his trust in others.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Emotional',
          description: 'Causing deep emotional wounds',
          examples: [
            'The loss of her child rived her soul with unending sorrow.',
            'His cruel words rived her confidence.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Poetic expression of emotional devastation',
          examples: [
            'The character\'s spirit was riven by doubt and fear.',
            'Their love was riven by circumstance and duty.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To split or shape wood with hand tools',
      partOfSpeech: 'transitive verb',
      examples: [
        'The craftsman rived the oak to make traditional shingles.',
        'Artisans rived the timber along the grain.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Craftsmanship',
          description: 'Traditional woodworking technique',
          examples: [
            'Coopers rived staves for barrel making.',
            'The carpenter rived the wood rather than sawing it for greater strength.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Traditional building methods',
          examples: [
            'Medieval builders rived oak beams for timber-frame houses.',
            'Before modern sawmills, workers rived logs using wedges and mallets.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'shear',
  base: 'shear',
  past: 'sheared',
  participle: 'shorn/sheared',
  pastUK: '',
  pastUS: '',
  participleUK: 'shorn',
  participleUS: 'shorn/sheared',
  pronunciationTextUS: 'ʃɪr',
  pronunciationTextUK: 'ʃɪə',
  meanings: [
    VerbMeaning(
      definition: 'To cut or clip the wool, hair, or fur from an animal',
      partOfSpeech: 'transitive verb',
      examples: [
        'The farmer sheared the sheep in spring.',
        'Their dog was shorn during the hot summer months.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Agricultural',
          description: 'Harvesting wool from livestock',
          examples: [
            'Skilled workers can shear a sheep in under two minutes.',
            'They shear the alpacas once a year for their valuable fiber.',
          ],
        ),
        ContextualUsage(
          context: 'Animal Care',
          description: 'Grooming or maintaining animals',
          examples: [
            'The poodle was shorn in the traditional show cut.',
            'In hot climates, some animals are shorn to prevent overheating.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To cut through something with a sharp instrument',
      partOfSpeech: 'transitive verb',
      examples: [
        'The scissors sheared through the thick fabric.',
        'The bolt cutters sheared the padlock easily.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Manufacturing',
          description: 'Cutting materials in industrial processes',
          examples: [
            'The machine shears metal sheets to the required dimensions.',
            'Workers sheared excess material from the molded parts.',
          ],
        ),
        ContextualUsage(
          context: 'Crafts',
          description: 'Cutting materials in artistic or craft work',
          examples: [
            'The artisan sheared the gold leaf with precision.',
            'She carefully sheared the paper into intricate patterns.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To break off or away by force',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The metal bolt sheared under the extreme pressure.',
        'During the earthquake, the ground sheared along the fault line.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Mechanical',
          description: 'Structural failure in materials',
          examples: [
            'The rivets sheared off when the bridge was subjected to excessive weight.',
            'The driveshaft sheared, leaving the vehicle immobilized.',
          ],
        ),
        ContextualUsage(
          context: 'Geological',
          description: 'Earth movements along fault lines',
          examples: [
            'Tectonic forces caused the rock layers to shear horizontally.',
            'The cliff face sheared away during the landslide.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To move or cause to move with a cutting motion',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The yacht sheared away from the approaching vessel.',
        'The car sheared across three lanes of traffic.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Nautical',
          description: 'Sideways movement of vessels',
          examples: [
            'The ship sheared to port to avoid the collision.',
            'Strong currents caused the boat to shear off course.',
          ],
        ),
        ContextualUsage(
          context: 'Motion',
          description: 'Lateral movement through a medium',
          examples: [
            'The plane sheared through the cloud bank.',
            'The skier sheared across the fresh powder snow.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To deprive or strip of something',
      partOfSpeech: 'transitive verb',
      examples: [
        'The scandal sheared him of his reputation.',
        'The recession shorn many families of their savings.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Metaphorical',
          description: 'Removing or taking away non-physical things',
          examples: [
            'The defeat shorn the team of its confidence.',
            'The new policy sheared workers of their benefits.',
          ],
        ),
        ContextualUsage(
          context: 'Financial',
          description: 'Loss of assets or resources',
          examples: [
            'The investment scheme sheared investors of their life savings.',
            'Inflation has shorn the currency of much of its value.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'spake',
  base: 'speak',
  past: 'spake',
  participle: 'spoken',
  pastUK: '',
  pastUS: '',
  participleUK: '',
  participleUS: '',
  pronunciationTextUS: 'speɪk',
  pronunciationTextUK: 'speɪk',
  meanings: [
    VerbMeaning(
      definition: 'Archaic past tense of speak; to utter words or articulate sounds',
      partOfSpeech: 'intransitive verb',
      examples: [
        'And the Lord spake unto Moses, saying...',
        'Thus spake the prophet to the assembled crowd.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Biblical',
          description: 'Used in religious or biblical texts',
          examples: [
            'And God spake all these words, saying...',
            'Then spake Jesus again unto them, saying, I am the light of the world.',
          ],
        ),
        ContextualUsage(
          context: 'Literary',
          description: 'Archaic usage in poetry or formal writing',
          examples: [
            'Thus spake the warrior before entering battle.',
            'The wise man spake, and all fell silent to listen.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To express thoughts, opinions, or feelings',
      partOfSpeech: 'intransitive verb',
      examples: [
        'The oracle spake of doom and destruction.',
        'The king spake words of wisdom to his subjects.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Historical',
          description: 'Used in historical narratives or period pieces',
          examples: [
            'The ancient philosopher spake of virtue and the good life.',
            'The queen spake at length about the future of the realm.',
          ],
        ),
        ContextualUsage(
          context: 'Ceremonial',
          description: 'Formal speech in ceremonial contexts',
          examples: [
            'The high priest spake the sacred words of the ritual.',
            'The bard spake of heroic deeds and great battles.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To communicate or convey information verbally',
      partOfSpeech: 'intransitive verb',
      examples: [
        'He spake of matters never before revealed.',
        'She spake in parables that few could understand.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Prophetic',
          description: 'Divine or prophetic communication',
          examples: [
            'The seer spake of visions yet to come.',
            'And the voice from heaven spake again, saying...',
          ],
        ),
        ContextualUsage(
          context: 'Authoritative',
          description: 'Communication from positions of authority',
          examples: [
            'The judge spake the sentence with grave solemnity.',
            'The commander spake, and his orders were immediately obeyed.',
          ],
        ),
      ],
    ),
  ],
),

VerbModel(
  id: 'wreak',
  base: 'wreak',
  past: 'wreaked',
  participle: 'wreaked/wrought',
  pastUK: '',
  pastUS: '',
  participleUK: 'wreaked',
  participleUS: 'wreaked/wrought',
  pronunciationTextUS: 'riːk',
  pronunciationTextUK: 'riːk',
  meanings: [
    VerbMeaning(
      definition: 'To cause or inflict (damage, harm, or punishment)',
      partOfSpeech: 'transitive verb',
      examples: [
        'The hurricane wreaked havoc on coastal communities.',
        'The invading army wreaked destruction on the countryside.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Destruction',
          description: 'Causing damage or devastation',
          examples: [
            'The fire wreaked considerable damage before it could be contained.',
            'The scandal wreaked irreparable harm to his reputation.',
          ],
        ),
        ContextualUsage(
          context: 'Natural Disaster',
          description: 'Effects of environmental catastrophes',
          examples: [
            'The tsunami wreaked devastation along the shoreline.',
            'Drought has wreaked havoc on agricultural production.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To express or give vent to (anger or another emotion)',
      partOfSpeech: 'transitive verb',
      examples: [
        'He wreaked his vengeance on those who had wronged him.',
        'She wreaked her fury on the betrayer.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Revenge',
          description: 'Acting out of desire for retribution',
          examples: [
            'The detective vowed to wreak justice on the criminal mastermind.',
            'The defeated nation wreaked its resentment through acts of sabotage.',
          ],
        ),
        ContextualUsage(
          context: 'Emotional',
          description: 'Expressing strong feelings through actions',
          examples: [
            'The disappointed fans wreaked their frustration by rioting.',
            'He wreaked his jealousy through a campaign of harassment.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To bring about or cause to happen',
      partOfSpeech: 'transitive verb',
      examples: [
        'Their actions wrought significant changes in society.',
        'The new technology has wreaked a revolution in communications.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Change',
          description: 'Causing significant transformations',
          examples: [
            'The invention of the printing press wrought enormous changes in education.',
            'The political upheaval wreaked fundamental changes to the constitution.',
          ],
        ),
        ContextualUsage(
          context: 'Historical',
          description: 'Describing major historical developments',
          examples: [
            'The Industrial Revolution wrought vast changes in social structures.',
            'The explorer\'s arrival wreaked profound changes on the indigenous culture.',
          ],
        ),
      ],
    ),
    VerbMeaning(
      definition: 'To work or fashion (a material) into shape',
      partOfSpeech: 'transitive verb',
      examples: [
        'The blacksmith wrought the iron into an intricate gate.',
        'The sculptor wreaked his vision in marble.',
      ],
      contextualUsages: [
        ContextualUsage(
          context: 'Craftsmanship',
          description: 'Traditional working of materials',
          examples: [
            'The artisan wrought silver into delicate jewelry.',
            'Skilled metalworkers wrought decorative elements for the cathedral.',
          ],
        ),
        ContextualUsage(
          context: 'Artistic',
          description: 'Creating through skilled work',
          examples: [
            'The poet wrought powerful emotions into verse.',
            'The designer wrought a new aesthetic in fashion.',
          ],
        ),
      ],
    ),
  ],
),
    ];
  }
}
