// lib/core/constants/app_constants.dart

/// Constantes globales para la aplicación VerbLab
class AppConstants {
  // No permitir instanciación
  const AppConstants._();

  /// Nombre de la aplicación
  static const String appName = 'VerbLab';

  /// Versión de la aplicación
  static const String appVersion = '1.0.0';

  /// Correo de soporte
  static const String supportEmail = 'support@verblab.app';

  /// Duración del debounce para la búsqueda
  static const int searchDebounceMillis = 300;

  /// Valor por defecto del dialecto
  static const String defaultDialect = 'en-US';

  /// Número máximo de resultados de búsqueda
  static const int maxSearchResults = 50;

  /// Tamaño mínimo de query para búsqueda
  static const int minQueryLength = 1;

  /// Precio del producto premium
  static const String premiumPrice = '4.99 USD';

  /// ID de producto para compra premium
  static const String premiumProductId = 'verblab_premium';

  /// URL de la política de privacidad
  static const String privacyPolicyUrl = 'https://verblab.app/privacy';

  /// URL de los términos de servicio
  static const String termsOfServiceUrl = 'https://verblab.app/terms';

  /// Clave para almacenar el estado premium
  static const String premiumStatusKey = 'is_premium_user';
}

/// Constantes para la base de datos
class DBConstants {
  // No permitir instanciación
  const DBConstants._();

  /// Nombre de la base de datos
  static const String dbName = 'verblab.db';

  /// Versión de la base de datos
  static const int dbVersion = 1;

  /// Nombre de la tabla de verbos
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
}

/// Constantes para analytics y eventos
class AnalyticsConstants {
  // No permitir instanciación
  const AnalyticsConstants._();

  /// Eventos de búsqueda
  static const String eventSearch = 'search_verb';
  static const String eventVerbView = 'view_verb_detail';
  static const String eventPronunciationPlay = 'play_pronunciation';
  static const String eventDialectChange = 'change_dialect';
  static const String eventPremiumPurchase = 'purchase_premium';
  static const String eventPremiumCancel = 'cancel_premium_purchase';

  /// Parámetros de eventos
  static const String paramQuery = 'search_query';
  static const String paramVerbId = 'verb_id';
  static const String paramVerbBase = 'verb_base';
  static const String paramResultCount = 'result_count';
  static const String paramDialect = 'dialect';
  static const String paramVerbForm = 'verb_form';
  static const String paramErrorType = 'error_type';
}

/// Constantes de estado y características
class FeatureConstants {
  // No permitir instanciación
  const FeatureConstants._();

  /// Estado de TTS
  static const String ttsStateIdle = 'idle';
  static const String ttsStateLoading = 'loading';
  static const String ttsStatePlaying = 'playing';
  static const String ttsStateError = 'error';

  /// Dialectos disponibles
  static const String dialectUS = 'en-US';
  static const String dialectUK = 'en-UK';

  /// Formas verbales
  static const String verbFormBase = 'base';
  static const String verbFormPast = 'past';
  static const String verbFormParticiple = 'participle';
}
