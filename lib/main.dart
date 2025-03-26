// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io'; // Importar para Platform
import 'core/constants/app_constants.dart';
import 'core/providers/app_state_notifier.dart';
import 'core/providers/user_preferences_provider.dart';
import 'core/providers/monetization_providers.dart';
import 'core/themes/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'presentation/widgets/common/error_view.dart';

// Solo importar App Tracking Transparency en iOS
import 'package:app_tracking_transparency/app_tracking_transparency.dart'
    if (dart.library.html) 'package:verblab/core/utils/web_stub.dart';

Future<void> _initializeApp() async {
  // Aseguramos que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización específica de plataforma
  if (Platform.isIOS) {
    await _initializeIOS();
  } else {
    debugPrint('Initializing on Android platform');
  }

  // Inicializar AdMob después de la inicialización específica de plataforma
  await _initializeAdMob();

  // Configuramos la orientación preferida de la app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

// Inicialización específica para iOS (ATT)
Future<void> _initializeIOS() async {
  debugPrint('Starting iOS specific initialization...');
  try {
    // Verificar el estado actual del tracking
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    debugPrint('Current tracking status: $status');

    // Solo solicitamos permiso si aún no se ha determinado
    if (status == TrackingStatus.notDetermined) {
      // Esperar un momento para mejorar la UX (permitir que la app se muestre primero)
      await Future.delayed(const Duration(milliseconds: 600));

      // Verificar si la app está en primer plano
      if (WidgetsBinding.instance.lifecycleState !=
          AppLifecycleState.detached) {
        // Solicitar permiso
        final newStatus =
            await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('New tracking status after request: $newStatus');
      }
    }
    debugPrint('iOS initialization completed successfully');
  } catch (e) {
    debugPrint('Error with tracking authorization: $e');
    // Continuamos aunque haya error en tracking
  }
}

// Inicialización de AdMob
Future<void> _initializeAdMob() async {
  debugPrint('Starting AdMob initialization...');
  try {
    // Configuración para anuncios más adecuada
    final RequestConfiguration config = RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
      maxAdContentRating: MaxAdContentRating.g,
    );

    await MobileAds.instance.updateRequestConfiguration(config);
    final initStatus = await MobileAds.instance.initialize();

    // Log detallado del estado de inicialización
    debugPrint('AdMob SDK initialized successfully');
    initStatus.adapterStatuses.forEach((adapter, status) {
      debugPrint('Adapter status for $adapter: ${status.state}');
    });
  } catch (e) {
    debugPrint('Error initializing AdMob: $e');
    // Continuamos ejecución aunque falle AdMob
  }
}

void main() async {
  try {
    debugPrint('Application starting...');
    await _initializeApp();
    debugPrint('App initialization completed');

    // Configuramos el estilo de la barra de estado
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    runApp(const ProviderScope(child: VerbLabApp()));
  } catch (e) {
    debugPrint('Fatal error during app initialization: $e');
    // Mostrar algún tipo de pantalla de error si es posible
  }
}

/// Widget principal de la aplicación VerbLab
class VerbLabApp extends ConsumerStatefulWidget {
  const VerbLabApp({super.key});

  @override
  ConsumerState<VerbLabApp> createState() => _VerbLabAppState();
}

class _VerbLabAppState extends ConsumerState<VerbLabApp> {
  @override
  void initState() {
    super.initState();
    // Inicializar datos al arrancar la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Initializing app state and ad managers...');
      ref.read(appStateProvider.notifier).initialize();

      // Inicializar y precargar anuncios con un pequeño delay
      // para evitar inicializaciones simultáneas
      Future.delayed(const Duration(milliseconds: 500), () {
        debugPrint('Initializing ad manager...');
        ref.read(adManagerProvider).initialize();

        // Pequeño delay adicional antes de cargar el primer anuncio
        Future.delayed(const Duration(milliseconds: 300), () {
          debugPrint('Loading initial banner ad...');
          ref.read(adManagerProvider).loadBannerAd();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    // Usar el provider de tema basado en preferencias
    final themeMode = ref.watch(userPreferenceThemeModeProvider);

    // Actualizar la UI según el tema seleccionado
    _updateSystemUI(themeMode == ThemeMode.dark);

    // Si la app está inicializada, mostrar el router
    if (appState.isInitialized) {
      final router = ref.watch(routerProvider);

      return MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: VerbLabTheme.lightTheme(),
        darkTheme: VerbLabTheme.darkTheme(),
        themeMode: themeMode,
        routerConfig: router,
      );
    }

    // Mientras se inicializa, mostrar pantalla simple o error
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: VerbLabTheme.lightTheme(),
      darkTheme: VerbLabTheme.darkTheme(),
      themeMode: themeMode,
      home:
          appState.hasError
              ? Scaffold(
                body: ErrorView(
                  error: 'Failed to initialize app: ${appState.error}',
                  onRetry:
                      () => ref.read(appStateProvider.notifier).initialize(),
                ),
              )
              : Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Initializing...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  /// Actualiza la UI del sistema según el tema seleccionado
  void _updateSystemUI(bool isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Invertir el brillo de los iconos según el tema
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
