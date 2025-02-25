// lib/core/error/failures.dart
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

/// Niveles de severidad para errores
enum ErrorSeverity {
  /// Errores menores, no críticos
  low,

  /// Errores que afectan funcionalidad pero no son críticos
  medium,

  /// Errores críticos que impiden funcionalidad central
  high,
}

/// Clase base para representar errores en la aplicación.
/// Extiende Equatable para facilitar comparaciones de igualdad.
class Failure extends Equatable {
  final String message;
  final String? details;
  final ErrorSeverity severity;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.details,
    this.severity = ErrorSeverity.medium,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, details, severity];

  @override
  String toString() =>
      '$runtimeType: $message${details != null ? '\nDetails: $details' : ''}';
}

/// Error específico para la aplicación VerbLab que incluye
/// funcionalidad de logging y métodos de utilidad.
class VerbLabError extends Failure {
  final Exception? originalError;

  const VerbLabError({
    required super.message,
    super.details,
    super.severity = ErrorSeverity.medium,
    super.stackTrace,
    this.originalError,
  });

  @override
  List<Object?> get props => [...super.props, originalError];

  /// Registra el error en el sistema de logging
  void log() {
    if (kDebugMode) {
      print('VerbLabError: $message');
      if (details != null) print('Details: $details');
      if (originalError != null) print('Original error: $originalError');
      if (stackTrace != null) print('Stack trace: $stackTrace');
    }

    // Aquí podríamos agregar integraciones con sistemas de monitoreo
    // como Firebase Crashlytics, Sentry, etc.
  }

  /// Determina si el error es recuperable
  bool get isRecoverable => severity != ErrorSeverity.high;

  /// Determina si se deben mostrar detalles al usuario
  bool get shouldShowDetails => kDebugMode || severity != ErrorSeverity.high;
}

/// Errores específicos por categoría
class DatabaseFailure extends VerbLabError {
  const DatabaseFailure({
    required super.message,
    super.details,
    super.severity = ErrorSeverity.medium,
    super.stackTrace,
    super.originalError,
  });
}

class TTSFailure extends VerbLabError {
  const TTSFailure({
    required super.message,
    super.details,
    super.severity = ErrorSeverity.low,
    super.stackTrace,
    super.originalError,
  });
}

class NetworkFailure extends VerbLabError {
  const NetworkFailure({
    required super.message,
    super.details,
    super.severity = ErrorSeverity.medium,
    super.stackTrace,
    super.originalError,
  });
}

class PurchaseFailure extends VerbLabError {
  const PurchaseFailure({
    required super.message,
    super.details,
    super.severity = ErrorSeverity.medium,
    super.stackTrace,
    super.originalError,
  });
}

class CacheFailure extends VerbLabError {
  const CacheFailure({
    required super.message,
    super.details,
    super.severity = ErrorSeverity.low,
    super.stackTrace,
    super.originalError,
  });
}

/// Excepciones específicas para lanzar en distintas partes de la aplicación
class DatabaseException implements Exception {
  final String message;
  final dynamic error;

  const DatabaseException(this.message, [this.error]);

  @override
  String toString() =>
      'DatabaseException: $message${error != null ? ' ($error)' : ''}';
}

class TTSException implements Exception {
  final String message;
  final dynamic error;

  const TTSException(this.message, [this.error]);

  @override
  String toString() =>
      'TTSException: $message${error != null ? ' ($error)' : ''}';
}

/// Utilidad para convertir Exception a Failure
VerbLabError exceptionToFailure(Exception exception, [StackTrace? stackTrace]) {
  if (exception is DatabaseException) {
    return DatabaseFailure(
      message: exception.message,
      details: exception.error?.toString(),
      stackTrace: stackTrace,
      originalError: exception,
    );
  } else if (exception is TTSException) {
    return TTSFailure(
      message: exception.message,
      details: exception.error?.toString(),
      stackTrace: stackTrace,
      originalError: exception,
    );
  } else {
    return VerbLabError(
      message: 'Unexpected error occurred',
      details: exception.toString(),
      stackTrace: stackTrace,
      originalError: exception,
    );
  }
}
