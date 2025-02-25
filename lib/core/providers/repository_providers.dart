// lib/core/providers/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/audio/tts_player.dart';
import '../../data/repositories/verb_repository_impl.dart';
import '../../domain/repositories/verb_repository.dart';

/// Provider para el helper de base de datos
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Provider para el servicio de Text-to-Speech
final ttsPlayerProvider = Provider<TTSPlayer>((ref) {
  return TTSPlayer();
});

/// Provider para el repositorio de verbos
final verbRepositoryProvider = Provider<VerbRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  final ttsPlayer = ref.watch(ttsPlayerProvider);
  return VerbRepositoryImpl(databaseHelper, ttsPlayer);
});
