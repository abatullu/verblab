// lib/domain/usecases/get_verb.dart
import '../entities/verb.dart';
import '../repositories/verb_repository.dart';

/// Caso de uso para obtener un verbo específico por su ID.
///
/// Esta clase implementa la funcionalidad para recuperar un verbo
/// individual con todos sus detalles.
class GetVerb {
  final VerbRepository _repository;

  /// Constructor que recibe el repositorio de verbos
  GetVerb(this._repository);

  /// Ejecuta la recuperación de un verbo según su ID
  ///
  /// [id] es el identificador único del verbo a recuperar
  /// Retorna el verbo si se encuentra, o null si no existe
  Future<Verb?> call(String id) async {
    // Validar entrada
    if (id.isEmpty) {
      return Future.value(null);
    }

    // Obtener el verbo del repositorio
    return _repository.getVerb(id);
  }
}
