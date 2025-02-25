// lib/core/utils/string_utils.dart

/// Utilidades para manejo de cadenas de texto
class StringUtils {
  // No permitir instanciación
  const StringUtils._();

  /// Normaliza un texto para búsqueda
  ///
  /// Convierte a minúsculas, elimina espacios adicionales y caracteres especiales
  static String normalizeForSearch(String text) {
    if (text.isEmpty) return '';

    // Convertir a minúsculas
    final normalized = text.toLowerCase();

    // Eliminar espacios adicionales
    return normalized.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Verifica si un texto contiene otro normalizado
  static bool containsNormalized(String text, String query) {
    final normalizedText = normalizeForSearch(text);
    final normalizedQuery = normalizeForSearch(query);

    return normalizedText.contains(normalizedQuery);
  }

  /// Capitaliza la primera letra de cada palabra
  static String capitalize(String text) {
    if (text.isEmpty) return '';

    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Trunca un texto a una longitud máxima, añadiendo ellipsis si es necesario
  static String truncate(
    String text,
    int maxLength, {
    String ellipsis = '...',
  }) {
    if (text.length <= maxLength) return text;

    return text.substring(0, maxLength - ellipsis.length) + ellipsis;
  }

  /// Convierte un texto a iniciales
  ///
  /// Ejemplo: "Past Simple Tense" -> "PST"
  static String toInitials(String text) {
    if (text.isEmpty) return '';

    return text
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .join('');
  }

  /// Formatea un texto para mostrar un ejemplo
  /// resaltando el verbo dentro de él
  static String formatExample(String example, List<String> verbForms) {
    String result = example;

    for (final form in verbForms) {
      if (form.isEmpty) continue;

      // Escapar caracteres especiales en el texto de búsqueda
      final escaped = RegExp.escape(form);

      // Crear un patrón que matchee la palabra completa, insensible a mayúsculas
      final pattern = RegExp(r'\b' + escaped + r'\b', caseSensitive: false);

      // Reemplazar con versión en itálica o negrita
      // NOTA: Aquí solo añadimos marcadores, la UI aplicaría el estilo
      if (result.toLowerCase().contains(form.toLowerCase())) {
        result = result.replaceAllMapped(
          pattern,
          (match) => '**${match.group(0)}**',
        );
      }
    }

    return result;
  }

  /// Identifica el tipo de forma verbal según el dialecto
  static String getVerbFormType(
    String base,
    String past,
    String participle,
    String form,
  ) {
    if (form.toLowerCase() == base.toLowerCase()) {
      return 'base';
    } else if (form.toLowerCase() == past.toLowerCase()) {
      return 'past';
    } else if (form.toLowerCase() == participle.toLowerCase()) {
      return 'participle';
    } else {
      return 'unknown';
    }
  }

  /// Extrae el tense de un verbo en una oración
  static String? extractTenseFromSentence(
    String sentence,
    List<String> verbForms,
  ) {
    // Aquí implementaríamos una lógica más compleja para extraer el tiempo verbal
    // usando patrones comunes en inglés. Esta es una versión simplificada.
    final normalized = sentence.toLowerCase();

    // Detectar past simple
    if (verbForms.length > 1 &&
        verbForms[1].isNotEmpty &&
        normalized.contains(verbForms[1].toLowerCase())) {
      return 'past';
    }

    // Detectar present perfect
    if (normalized.contains('have') || normalized.contains('has')) {
      if (verbForms.length > 2 &&
          verbForms[2].isNotEmpty &&
          normalized.contains(verbForms[2].toLowerCase())) {
        return 'participle';
      }
    }

    // Detectar present simple (default)
    return 'base';
  }
}
