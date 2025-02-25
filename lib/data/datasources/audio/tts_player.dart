// lib/data/datasources/audio/tts_player.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/error/failures.dart';

/// Servicio para reproducir la pronunciación de verbos mediante Text-to-Speech.
///
/// Esta clase implementa un patrón Singleton para garantizar un solo
/// servicio TTS en toda la aplicación. Maneja la configuración, inicialización
/// y control de la pronunciación con soporte para múltiples dialectos.
class TTSPlayer {
  // Implementación singleton
  static final TTSPlayer _instance = TTSPlayer._internal();
  factory TTSPlayer() => _instance;

  final FlutterTts _tts;
  bool _isInitialized = false;

  // Callbacks para notificar cambios de estado
  Function()? _onStart;
  Function()? _onComplete;
  Function()? _onError;

  // Para mantener seguimiento del dialecto actual
  String _currentDialect = "en-US";

  TTSPlayer._internal() : _tts = FlutterTts() {
    _configureCallbacks();
  }

  /// Inicializa el servicio TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configurar propiedades del TTS
      await Future.wait([
        _tts.setLanguage("en-US"),
        _tts.setSpeechRate(0.45), // Velocidad moderada para mejor comprensión
        _tts.setVolume(1.0), // Volumen máximo
        _tts.setPitch(1.0), // Tono neutral
      ]);

      // Verificar disponibilidad de idiomas
      final voices = await _tts.getVoices;
      final hasEnUS = voices.any(
        (voice) => voice.toString().toLowerCase().contains('en-us'),
      );
      final hasEnGB = voices.any(
        (voice) => voice.toString().toLowerCase().contains('en-gb'),
      );

      if (!hasEnUS && !hasEnGB) {
        throw TTSException('No English voices available');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      rethrow;
    }
  }

  /// Configura los callbacks para eventos TTS
  void _configureCallbacks() {
    _tts.setStartHandler(() {
      _onStart?.call();
    });

    _tts.setCompletionHandler(() {
      _onComplete?.call();
    });

    _tts.setErrorHandler((error) {
      debugPrint('TTS Error: $error');
      _onError?.call();
    });
  }

  /// Configura callbacks para notificar cambios de estado
  void setCallbacks({
    Function()? onStart,
    Function()? onComplete,
    Function()? onError,
  }) {
    _onStart = onStart;
    _onComplete = onComplete;
    _onError = onError;
  }

  /// Reproduce un texto con el dialecto especificado
  Future<void> speak(String text, {String dialect = "en-US"}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Actualizar el dialecto si es diferente al actual
      if (dialect != _currentDialect) {
        final langCode = dialect == "en-UK" ? "en-GB" : "en-US";
        await _tts.setLanguage(langCode);
        _currentDialect = dialect;
      }

      // Procesar el texto para mejorar la pronunciación
      final processedText = _preprocessText(text);

      // Reproducir el texto
      await _tts.speak(processedText);
    } catch (e) {
      debugPrint('Error in TTS speak: $e');
      throw TTSException('Failed to play pronunciation: ${e.toString()}', e);
    }
  }

  /// Preprocesa el texto para mejorar la pronunciación
  ///
  /// Algunos verbos pueden tener pronunciaciones ambiguas,
  /// este método aplica reglas específicas para mejorarlas.
  String _preprocessText(String text) {
    // Mapa de procesamiento para casos especiales
    final pronunciationMap = {
      'read': 'read.', // Para distinguir entre presente y pasado
      'lead': 'lead.',
      'wind': 'wind.',
      'tear': 'tear.',
      'bow': 'bow.',
      'row': 'row.',
      'sow': 'sow.',
      'content': 'content.',
      'perfect': 'perfect.',
      'record': 'record.',
      'live': 'live.',
      // Añadir más casos especiales según sea necesario
    };

    // Aplicar reglas específicas o retornar con punto final
    return pronunciationMap[text.toLowerCase()] ?? '$text.';
  }

  /// Detiene cualquier pronunciación en curso
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
      // No lanzamos excepción aquí para no interrumpir el flujo
    }
  }

  /// Verifica si el servicio TTS está disponible
  Future<bool> isLanguageAvailable(String dialect) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final langCode = dialect == "en-UK" ? "en-GB" : "en-US";
      return await _tts.isLanguageAvailable(langCode) ?? false;
    } catch (e) {
      debugPrint('Error checking language availability: $e');
      return false;
    }
  }

  /// Obtiene la lista de voces disponibles (útil para debugging)
  Future<List<dynamic>> getAvailableVoices() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _tts.getVoices;
    } catch (e) {
      debugPrint('Error getting voices: $e');
      return [];
    }
  }

  /// Libera recursos cuando ya no se necesita el servicio
  Future<void> dispose() async {
    await stop();
    // FlutterTTS no tiene un método dispose() explícito
  }
}
