// lib/core/constants/db_constants.dart

/// Constantes específicas para la base de datos SQLite
class DBConstants {
  // No permitir instanciación
  const DBConstants._();

  /// Nombre de la base de datos
  static const String dbName = 'verblab.db';

  /// Versión de la base de datos
  static const int dbVersion = 1;

  /// Nombre de la tabla principal de verbos
  static const String verbsTable = 'verbs';

  /// Columnas de la tabla de verbos
  static const String colId = 'id';
  static const String colBase = 'base';
  static const String colPast = 'past';
  static const String colParticiple = 'participle';
  static const String colPastUK = 'past_uk';
  static const String colPastUS = 'past_us';
  static const String colParticipleUK = 'participle_uk';
  static const String colParticipleUS = 'participle_us';
  static const String colMeaning = 'meaning';
  static const String colPronunciationTextUS = 'pronunciation_text_us';
  static const String colPronunciationTextUK = 'pronunciation_text_uk';
  static const String colContextualUsage = 'contextual_usage';
  static const String colExamples = 'examples';
  static const String colSearchTerms = 'search_terms';

  /// Queries para la creación de la base de datos
  static const String createVerbsTableQuery = '''
    CREATE TABLE $verbsTable (
      $colId TEXT PRIMARY KEY,
      $colBase TEXT NOT NULL,
      $colPast TEXT NOT NULL,
      $colParticiple TEXT NOT NULL,
      $colPastUK TEXT,
      $colPastUS TEXT,
      $colParticipleUK TEXT,
      $colParticipleUS TEXT,
      $colMeaning TEXT NOT NULL,
      $colPronunciationTextUS TEXT,
      $colPronunciationTextUK TEXT,
      $colContextualUsage TEXT,
      $colExamples TEXT,
      $colSearchTerms TEXT,
      UNIQUE($colBase, $colPast, $colParticiple)
    )
  ''';

  /// Queries para la creación de índices
  static const String createSearchTermsIndexQuery = '''
    CREATE INDEX idx_search_terms ON $verbsTable($colSearchTerms)
  ''';

  static const String createVerbFormsIndexQuery = '''
    CREATE INDEX idx_verb_forms ON $verbsTable($colBase, $colPast, $colParticiple)
  ''';

  /// Query para búsqueda exacta por base
  static String exactBaseMatchQuery = '''
    SELECT * FROM $verbsTable 
    WHERE LOWER($colBase) = ?
  ''';

  /// Query para búsqueda parcial excluyendo matches exactos
  static String partialMatchQuery = '''
    SELECT * FROM $verbsTable 
    WHERE (
      $colSearchTerms LIKE ? 
      AND LOWER($colBase) != ?
    )
    ORDER BY 
      CASE 
        WHEN LOWER($colBase) LIKE ? THEN 1
        WHEN LOWER($colPast) LIKE ? THEN 2
        WHEN LOWER($colParticiple) LIKE ? THEN 3
        ELSE 4
      END,
      $colBase ASC
    LIMIT 50
  ''';

  /// Query para optimizar la base de datos
  static const String vacuumQuery = 'VACUUM';
  static const String analyzeQuery = 'ANALYZE';

  /// Query para obtener un verbo por ID
  static String getVerbByIdQuery = '''
    SELECT * FROM $verbsTable
    WHERE $colId = ?
  ''';

  /// Query para contar el número total de verbos
  static String countVerbsQuery = '''
    SELECT COUNT(*) FROM $verbsTable
  ''';
}
