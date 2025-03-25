// lib/data/datasources/tracking/tracking_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class TrackingManager {
  // Singleton
  static final TrackingManager _instance = TrackingManager._internal();
  factory TrackingManager() => _instance;
  TrackingManager._internal();

  /// Inicializa el seguimiento de anuncios
  Future<TrackingStatus> initialize() async {
    if (!Platform.isIOS) {
      // En Android no es necesario, devolver authorized por defecto
      return TrackingStatus.authorized;
    }

    try {
      // Verificar el estado actual del tracking
      final currentStatus =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      debugPrint('Current tracking status: $currentStatus');
      return currentStatus;
    } catch (e) {
      debugPrint('Error checking tracking status: $e');
      return TrackingStatus.notDetermined;
    }
  }

  /// Solicita permiso para el seguimiento de anuncios
  Future<TrackingStatus> requestTrackingAuthorization() async {
    if (!Platform.isIOS) {
      return TrackingStatus.authorized;
    }

    try {
      final status =
          await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('Tracking authorization status: $status');
      return status;
    } catch (e) {
      debugPrint('Error requesting tracking authorization: $e');
      return TrackingStatus.notDetermined;
    }
  }
}
