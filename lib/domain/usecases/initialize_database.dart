// lib/domain/usecases/initialize_database.dart
import '../repositories/verb_repository.dart';

/// Caso de uso para inicializar la base de datos de la aplicación.
///
/// Esta clase implementa la funcionalidad para preparar la base de datos
/// al iniciar la aplicación, cargando datos iniciales si es necesario.
class InitializeDatabase {
  final VerbRepository _repository;

  /// Constructor que recibe el repositorio de verbos
  InitializeDatabase(this._repository);

  /// Ejecuta la inicialización de la base de datos
  ///
  /// Este método verifica si la base de datos ya contiene datos
  /// y carga los datos iniciales solo si es necesario
  Future<void> call() async {
    await _repository.initializeDatabase();
  }

  /// Obtiene el número total de verbos en la base de datos
  ///
  /// Útil para verificar el estado de la base de datos o mostrar estadísticas
  Future<int> getVerbCount() async {
    return _repository.getVerbCount();
  }

  /// Optimiza la base de datos
  ///
  /// Útil para mejorar el rendimiento después de operaciones masivas
  Future<void> optimize() async {
    await _repository.optimizeDatabase();
  }

  /// Actualiza la base de datos si es necesario
  ///
  /// Este método es útil para futuras actualizaciones de la aplicación
  /// que requieran cambios en la estructura de datos o nuevos verbos
  Future<void> updateIfNeeded() async {
    await _repository.updateDatabaseIfNeeded();
  }
}
