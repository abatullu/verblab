// lib/domain/models/tts_state.dart

/// Representa los posibles estados del servicio Text-To-Speech
enum TTSState {
  /// Estado inicial o en reposo
  idle,

  /// Cargando/preparando para reproducir
  loading,

  /// Actualmente reproduciendo audio
  playing,

  /// Un error ha ocurrido
  error;

  /// Verifica si el estado es interactivo (se puede presionar)
  bool get isInteractive => this != loading && this != playing;

  /// Verifica si el estado debería mostrar un indicador de carga
  bool get isLoading => this == loading;

  /// Verifica si el estado indica un problema
  bool get isError => this == error;
}
