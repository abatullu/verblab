// lib/core/providers/app_state_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/purchase_details_model.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/tts_state.dart';
import 'monetization_providers.dart';
import 'premium_status_provider.dart';
import 'usecase_providers.dart';
import 'user_preferences_provider.dart';

/// StateNotifier que gestiona el estado global de la aplicación.
///
/// Este notifier centraliza todas las operaciones que modifican el estado
/// y proporciona métodos para interactuar con los casos de uso.
class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;

  /// Constructor que recibe un Ref para acceder a otros providers
  AppStateNotifier(this._ref) : super(AppState.initial()) {
    // Suscribirse a cambios de dialecto en las preferencias
    _ref.listen<String>(dialectProvider, (_, dialectValue) {
      if (dialectValue != state.currentDialect) {
        state = state.copyWith(currentDialect: dialectValue);
      }
    });
  }

  /// Inicializa la aplicación, cargando datos necesarios
  Future<void> initialize() async {
    // Ya tenemos el estado inicial
    if (state.isInitialized) return;

    try {
      // Indicar que estamos cargando
      state = state.copyWith(isLoading: true);

      // Obtener el caso de uso para inicializar la base de datos
      final initializeDatabase = _ref.read(initializeDatabaseProvider);

      // Inicializar la base de datos
      await initializeDatabase();

      // Verificar compras previas - MODIFICADO
      final purchaseManager = _ref.read(purchaseManagerProvider);
      // Inicializar el gestor de compras
      await purchaseManager.initialize();

      // Verificamos el estado premium desde las preferencias de usuario
      final prefsAsync = _ref.read(userPreferencesNotifierProvider);

      // Utilizamos when para manejar los diferentes estados de forma segura
      prefsAsync.whenData((prefs) {
        if (prefs.isPremium) {
          debugPrint('Premium status loaded from preferences: Active');

          // Asegurarse de que el estado premium esté actualizado en todos los providers
          if (_ref.read(isPremiumProvider)) {
            // Actualizar el notificador de estado premium
            if (_ref.exists(premiumStatusNotifierProvider)) {
              _ref
                  .read(premiumStatusNotifierProvider.notifier)
                  .updatePremiumStatus(true);
            }
          }
        } else {
          debugPrint('Premium status loaded from preferences: Inactive');
        }
      });

      // Configurar listener para cambios en compras premium
      _ref.listen<AsyncValue<PurchaseDetailsModel>>(purchaseUpdatesProvider, (
        _,
        next,
      ) {
        next.whenData((purchaseDetails) {
          // Si la compra fue exitosa, actualizar preferencias
          if ((purchaseDetails.status == PurchaseStatus.purchased ||
                  purchaseDetails.status == PurchaseStatus.restored) &&
              purchaseDetails.productId == AppConstants.premiumProductId) {
            // Actualizar preferencias de usuario para marcar premium
            _ref
                .read(userPreferencesNotifierProvider.notifier)
                .setPremiumStatus(true);

            // Actualizar el notificador de estado premium si existe
            if (_ref.exists(premiumStatusNotifierProvider)) {
              _ref
                  .read(premiumStatusNotifierProvider.notifier)
                  .updatePremiumStatus(true);
            }
          }
        });
      });

      // Actualizar el estado
      state = state.copyWith(isInitialized: true, isLoading: false);
    } catch (e) {
      // Actualizar el estado con el error
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Busca verbos según la consulta proporcionada
  Future<void> searchVerbs(String query) async {
    if (query.isEmpty) {
      // Si la consulta está vacía, limpiamos los resultados
      state = state.copyWith(
        searchResults: [],
        isLoading: false,
        clearError: true,
      );
      return;
    }

    try {
      // Indicar que estamos cargando
      state = state.copyWith(isLoading: true);

      // Obtener el caso de uso para buscar verbos
      final searchVerbs = _ref.read(searchVerbsProvider);

      // Realizar la búsqueda
      final results = await searchVerbs(query);

      // Actualizar el estado con los resultados
      state = state.copyWith(
        searchResults: results,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      // Actualizar el estado con el error
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Selecciona un verbo para ver sus detalles
  Future<void> selectVerb(String id) async {
    try {
      // Indicar que estamos cargando
      state = state.copyWith(isLoading: true);

      // Obtener el caso de uso para obtener un verbo
      final getVerb = _ref.read(getVerbProvider);

      // Obtener el verbo
      final verb = await getVerb(id);

      // Actualizar el estado con el verbo seleccionado
      state = state.copyWith(
        selectedVerb: verb,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      // Actualizar el estado con el error
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reproduce la pronunciación de una forma verbal
  Future<void> playPronunciation(
    String verbId, {
    required String tense,
    String? dialect,
  }) async {
    final currentDialect = dialect ?? state.currentDialect;

    try {
      // Actualizar estado de pronunciación
      final currentStates = Map<String, Map<String, TTSState>>.from(
        state.playingStates,
      );

      if (!currentStates.containsKey(verbId)) {
        currentStates[verbId] = {};
      }
      currentStates[verbId]![tense] = TTSState.playing;

      // Actualizar el estado
      state = state.copyWith(playingStates: currentStates, clearError: true);

      // Obtener el caso de uso para reproducir pronunciación
      final playPronunciation = _ref.read(playPronunciationProvider);

      // Ejecutar pronunciación
      await playPronunciation(verbId, tense: tense, dialect: currentDialect);

      // Limpiar estado al finalizar
      final updatedStates = Map<String, Map<String, TTSState>>.from(
        currentStates,
      );
      updatedStates[verbId]?.remove(tense);

      if (updatedStates[verbId]?.isEmpty ?? false) {
        updatedStates.remove(verbId);
      }

      // Actualizar el estado
      state = state.copyWith(playingStates: updatedStates);
    } catch (e) {
      // Limpiar estado en caso de error
      final updatedStates = Map<String, Map<String, TTSState>>.from(
        state.playingStates,
      );
      updatedStates[verbId]?.remove(tense);

      if (updatedStates[verbId]?.isEmpty ?? false) {
        updatedStates.remove(verbId);
      }

      // Actualizar el estado con el error
      state = state.copyWith(error: e.toString(), playingStates: updatedStates);
    }
  }

  /// Detiene cualquier pronunciación en curso
  Future<void> stopPronunciation() async {
    try {
      // Obtener el caso de uso para reproducir pronunciación
      final playPronunciation = _ref.read(playPronunciationProvider);

      // Detener pronunciación
      await playPronunciation.stop();

      // Limpiar todos los estados de reproducción
      state = state.copyWith(playingStates: {});
    } catch (e) {
      // Actualizar el estado con el error
      state = state.copyWith(
        error: e.toString(),
        playingStates: {}, // Limpiar de todos modos
      );
    }
  }

  /// Cambia el dialecto actual y lo persiste
  void setDialect(String dialect) {
    if (dialect != 'en-US' && dialect != 'en-UK') {
      return; // Ignorar valores inválidos
    }

    // Actualizar el estado local
    state = state.copyWith(currentDialect: dialect, clearError: true);

    // Actualizar las preferencias persistentes
    _ref.read(userPreferencesNotifierProvider.notifier).setDialect(dialect);
  }

  /// Limpia el error actual
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Limpia los resultados de búsqueda
  void clearResults() {
    state = state.copyWith(
      clearSearchResults: true,
      isLoading: false,
      clearError: true,
    );
  }

  /// Limpia el verbo seleccionado
  void clearSelectedVerb() {
    state = state.copyWith(clearSelectedVerb: true);
  }
}

/// Provider para el estado de la aplicación
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  return AppStateNotifier(ref);
});
