// lib/domain/models/app_state.dart
import '../entities/verb.dart';
// Importando TTSState con un prefijo específico para evitar ambigüedades
import 'tts_state.dart';

/// Representa el estado global de la aplicación
///
/// Este modelo contiene todos los datos necesarios para representar
/// el estado actual de la aplicación en un momento dado.
class AppState {
  /// Indica si la aplicación está inicializada
  final bool isInitialized;

  /// Lista de resultados de búsqueda actuales
  final List<Verb> searchResults;

  /// El verbo seleccionado actualmente para visualizar detalles
  final Verb? selectedVerb;

  /// Indica si hay una operación de carga en progreso
  final bool isLoading;

  /// Dialecto seleccionado actualmente
  final String currentDialect;

  /// Error actual (si existe)
  final dynamic error;

  /// Mapa que contiene el estado de reproducción TTS por verbo y forma
  final Map<String, Map<String, TTSState>> playingStates;

  /// Constructor por defecto para [AppState]
  const AppState({
    this.isInitialized = false,
    this.searchResults = const [],
    this.selectedVerb,
    this.isLoading = false,
    this.currentDialect = 'en-US',
    this.error,
    this.playingStates = const {},
  });

  /// Constructor factory para crear el estado inicial
  factory AppState.initial() => const AppState();

  /// Determina si hay un estado de error
  bool get hasError => error != null;

  /// Determina si hay resultados de búsqueda
  bool get hasResults => searchResults.isNotEmpty;

  /// Determina si hay un verbo seleccionado
  bool get hasSelectedVerb => selectedVerb != null;

  /// Crea una copia de este AppState con los valores proporcionados reemplazados
  AppState copyWith({
    bool? isInitialized,
    List<Verb>? searchResults,
    Verb? selectedVerb,
    bool? isLoading,
    String? currentDialect,
    dynamic error,
    Map<String, Map<String, TTSState>>? playingStates,
    bool clearError = false,
    bool clearSelectedVerb = false,
    bool clearSearchResults = false,
  }) {
    return AppState(
      isInitialized: isInitialized ?? this.isInitialized,
      searchResults:
          clearSearchResults ? [] : (searchResults ?? this.searchResults),
      selectedVerb:
          clearSelectedVerb ? null : (selectedVerb ?? this.selectedVerb),
      isLoading: isLoading ?? this.isLoading,
      currentDialect: currentDialect ?? this.currentDialect,
      error: clearError ? null : (error ?? this.error),
      playingStates: playingStates ?? this.playingStates,
    );
  }
}
