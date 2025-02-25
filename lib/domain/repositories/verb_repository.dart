// lib/domain/repositories/verb_repository.dart
import '../entities/verb.dart';

/// Interfaz que define las operaciones disponibles para gestionar verbos.
///
/// Esta interfaz actúa como una capa de abstracción entre los casos de uso
/// y la implementación concreta del acceso a datos, siguiendo el principio
/// de inversión de dependencias.
abstract class VerbRepository {
  /// Obtiene un verbo por su ID
  ///
  /// [id] es el identificador único del verbo
  /// Retorna el verbo encontrado o null si no existe
  Future<Verb?> getVerb(String id);

  /// Busca verbos que coincidan con la consulta proporcionada
  ///
  /// [query] es el texto a buscar en las distintas formas del verbo
  /// Retorna una lista de verbos que coinciden con la búsqueda
  Future<List<Verb>> searchVerbs(String query);

  /// Reproduce la pronunciación de una forma verbal específica
  ///
  /// [verbId] es el identificador del verbo
  /// [tense] indica la forma verbal a pronunciar ('base', 'past', 'participle')
  /// [dialect] especifica el dialecto a usar ('en-US' o 'en-UK')
  Future<void> playPronunciation(
    String verbId, {
    required String tense,
    String dialect = "en-US",
  });

  /// Detiene cualquier pronunciación en curso
  Future<void> stopPronunciation();

  /// Inicializa la base de datos con datos iniciales si es necesario
  ///
  /// Este método debe verificar si la base de datos ya contiene datos
  /// y cargar los datos iniciales solo si es necesario
  Future<void> initializeDatabase();

  /// Obtiene el número total de verbos en la base de datos
  ///
  /// Útil para verificar si la base de datos ha sido inicializada correctamente
  Future<int> getVerbCount();

  /// Actualiza la base de datos a la versión más reciente
  ///
  /// Este método es útil para futuras actualizaciones de la aplicación
  /// que requieran cambios en la estructura de datos o nuevos verbos
  Future<void> updateDatabaseIfNeeded();

  /// Limpia y optimiza la base de datos
  ///
  /// Útil para mantener el rendimiento óptimo después de muchas operaciones
  Future<void> optimizeDatabase();
}
