// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/app_state_notifier.dart';
import 'core/themes/app_theme.dart';
import 'presentation/pages/search_page.dart';
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
class VerbLabApp extends ConsumerWidget {
  const VerbLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Intentar cargar los datos iniciales durante la primera construcción
    _initializeApp(ref);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: VerbLabTheme.lightTheme(),
      darkTheme: VerbLabTheme.darkTheme(),
      themeMode: ThemeMode.system, // Seguir la configuración del sistema
      home: const AppStartupManager(),
    );
  }

  void _initializeApp(WidgetRef ref) {
    // Usar addPostFrameCallback para evitar cambios de estado durante la construcción
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStateProvider.notifier).initialize();
    });
  }
}

/// Widget que gestiona la pantalla inicial basada en el estado de inicialización
class AppStartupManager extends ConsumerWidget {
  const AppStartupManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    // Verificar si hay un error crítico en la inicialización
    if (appState.hasError) {
      return Scaffold(
        body: ErrorView(
          error: 'Failed to initialize app: ${appState.error}',
          onRetry: () => ref.read(appStateProvider.notifier).initialize(),
        ),
      );
    }

    // Verificar si la app está inicializada
    if (appState.isInitialized) {
      return const SearchPage();
    }

    // Mostrar pantalla de splash mientras se inicializa
    return const SplashScreen();
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
