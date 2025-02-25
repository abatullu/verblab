// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/app_state_notifier.dart';
import 'core/themes/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'presentation/widgets/common/error_view.dart';

void main() async {
  // Aseguramos que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Configuramos la orientación preferida de la app
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuramos el estilo de la barra de estado
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

    // Si la app está inicializada, mostrar el router
    if (appState.isInitialized) {
      final router = ref.watch(routerProvider);

      return MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: VerbLabTheme.lightTheme(),
        darkTheme: VerbLabTheme.darkTheme(),
        themeMode: ThemeMode.system,
        routerConfig: router,
      );
    }

    // Mientras se inicializa, mostrar pantalla de splash o error
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: VerbLabTheme.lightTheme(),
      darkTheme: VerbLabTheme.darkTheme(),
      themeMode: ThemeMode.system,
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
}

/// Pantalla de splash inicial
///
/// Esta pantalla se muestra mientras se inicializan los recursos
/// necesarios para la aplicación
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título de la aplicación con estilo premium
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Subtítulo descriptivo
            Text(
              'The definitive irregular verbs app',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),

            // Indicador de carga
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
