// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/app_state_notifier.dart';
import 'core/providers/user_preferences_provider.dart'; // Nuevo import
import 'core/themes/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'presentation/widgets/common/error_view.dart';
import 'presentation/widgets/common/theme_toggle.dart';

void main() async {
  // Aseguramos que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Configuramos la orientación preferida de la app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuramos el estilo de la barra de estado (será actualizado dinámicamente)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    // Envolvemos la app con ProviderScope para habilitar Riverpod
    const ProviderScope(child: VerbLabApp()),
  );
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    // Usar el nuevo provider de tema basado en preferencias
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

    // Mientras se inicializa, mostrar pantalla de splash o error
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
              : const SplashScreen(),
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

/// Pantalla de splash inicial
///
/// Esta pantalla se muestra mientras se inicializan los recursos
/// necesarios para la aplicación
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(padding: EdgeInsets.only(right: 8.0), child: ThemeToggle()),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título de la aplicación con estilo premium
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Subtítulo descriptivo
            Text(
              'The definitive irregular verbs app',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),

            // Indicador de carga
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
