// lib/domain/models/search_result.dart

import 'verb_form.dart';

/// Modelo que representa un resultado de búsqueda con metadatos adicionales
class SearchResult {
  /// El verbo encontrado
  final String verbId;

  /// Relevancia del resultado (menor número = más relevante)
  final int relevance;

  /// Forma verbal que coincidió con la búsqueda
  final VerbForm matchedForm;

  /// Indica si es una coincidencia exacta
  final bool isExactMatch;

  const SearchResult({
    required this.verbId,
    required this.relevance,
    required this.matchedForm,
    this.isExactMatch = false,
  });
}
