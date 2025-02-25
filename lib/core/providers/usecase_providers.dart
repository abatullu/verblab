// lib/core/providers/usecase_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import '../../domain/usecases/initialize_database.dart';
import '../../domain/usecases/search_verbs.dart';
import '../../domain/usecases/get_verb.dart';
import '../../domain/usecases/play_pronunciation.dart';

/// Provider para el caso de uso InitializeDatabase
final initializeDatabaseProvider = Provider<InitializeDatabase>((ref) {
  final repository = ref.watch(verbRepositoryProvider);
  return InitializeDatabase(repository);
});

/// Provider para el caso de uso SearchVerbs
final searchVerbsProvider = Provider<SearchVerbs>((ref) {
  final repository = ref.watch(verbRepositoryProvider);
  return SearchVerbs(repository);
});

/// Provider para el caso de uso GetVerb
final getVerbProvider = Provider<GetVerb>((ref) {
  final repository = ref.watch(verbRepositoryProvider);
  return GetVerb(repository);
});

/// Provider para el caso de uso PlayPronunciation
final playPronunciationProvider = Provider<PlayPronunciation>((ref) {
  final repository = ref.watch(verbRepositoryProvider);
  return PlayPronunciation(repository);
});
