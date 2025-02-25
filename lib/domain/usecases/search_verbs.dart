// lib/domain/usecases/search_verbs.dart
import '../entities/verb.dart';
import '../repositories/verb_repository.dart';

/// Caso de uso para buscar verbos según un criterio de búsqueda.
///
/// Esta clase implementa la funcionalidad principal de búsqueda de verbos
/// y actúa como intermediario entre la capa de presentación y la capa de datos.
class SearchVerbs {
  final VerbRepository _repository;

  /// Constructor que recibe el repositorio de verbos
  SearchVerbs(this._repository);

  /// Ejecuta la búsqueda de verbos según la consulta proporcionada
  ///
  /// [query] es el texto a buscar en las diferentes formas del verbo
  /// Si la consulta está vacía, retorna una lista vacía
  Future<List<Verb>> call(String query) async {
    // Validar entrada
    if (query.isEmpty) {
      return Future.value([]);
    }

    // Realizar la búsqueda a través del repositorio
    return _repository.searchVerbs(query);
  }
}
