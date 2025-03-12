// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Añadir este import
import 'core/constants/app_constants.dart';
import 'core/providers/app_state_notifier.dart';
import 'core/providers/user_preferences_provider.dart';
import 'core/providers/monetization_providers.dart'; // Añadir este import
import 'core/themes/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'presentation/widgets/common/error_view.dart';

Future<void> _initializeApp() async {
  // Aseguramos que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar AdMob
  try {
    await MobileAds.instance.initialize();
    debugPrint('AdMob SDK initialized successfully');
  } catch (e) {
    debugPrint('Error initializing AdMob: $e');
    // Continuamos ejecución aunque falle AdMob
  }

  // Configuramos la orientación preferida de la app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

void main() async {
  await _initializeApp();

  // Configuramos el estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: VerbLabApp()));
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
      ref.read(appStateProvider.notifier).initialize();

      // Inicializar y precargar anuncios
      ref.read(adManagerProvider).initialize();
      ref.read(adManagerProvider).loadBannerAd();
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
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
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
