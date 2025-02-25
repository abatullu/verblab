// lib/domain/usecases/play_pronunciation.dart
import '../repositories/verb_repository.dart';

/// Caso de uso para reproducir la pronunciación de una forma verbal.
///
/// Esta clase implementa la funcionalidad para utilizar Text-to-Speech
/// y reproducir la pronunciación de diferentes formas de un verbo.
class PlayPronunciation {
  final VerbRepository _repository;

  /// Constructor que recibe el repositorio de verbos
  PlayPronunciation(this._repository);

  /// Ejecuta la reproducción de la pronunciación
  ///
  /// [verbId] es el identificador del verbo a pronunciar
  /// [tense] indica la forma verbal ('base', 'past', 'participle')
  /// [dialect] especifica el dialecto ('en-US' o 'en-UK')
  Future<void> call(
    String verbId, {
    required String tense,
    String dialect = "en-US",
  }) async {
    // Validar entrada
    if (verbId.isEmpty) {
      throw ArgumentError('Verb ID cannot be empty');
    }

    if (tense.isEmpty) {
      throw ArgumentError('Tense cannot be empty');
    }

    if (dialect != 'en-US' && dialect != 'en-UK') {
      throw ArgumentError('Invalid dialect. Must be en-US or en-UK');
    }

    // Ejecutar la reproducción a través del repositorio
    await _repository.playPronunciation(verbId, tense: tense, dialect: dialect);
  }

  /// Detiene cualquier pronunciación en curso
  Future<void> stop() async {
    await _repository.stopPronunciation();
  }
}
