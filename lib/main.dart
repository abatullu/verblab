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
import 'presentation/widgets/common/theme_toggle.dart';

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

/// Pantalla de splash mejorada con animaciones
///
/// Esta pantalla se muestra mientras se inicializan los recursos
/// necesarios para la aplicación
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controlador de animación para elementos de la pantalla splash
  late final AnimationController _animationController;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _slideUpAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animación de fade in
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Animación de escala
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Animación de deslizamiento hacia arriba
    _slideUpAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Iniciar animación
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
            // Logo animado de la aplicación
            FadeTransition(
              opacity: _fadeInAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildAppLogo(theme, isDarkMode),
              ),
            ),
            const SizedBox(height: 32),

            // Título de la aplicación con estilo premium
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Transform.translate(
                offset: Offset(0, _slideUpAnimation.value),
                child: Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subtítulo descriptivo
            FadeTransition(
              opacity: _fadeInAnimation,
              child: Transform.translate(
                offset: Offset(0, _slideUpAnimation.value),
                child: Text(
                  'The definitive irregular verbs app',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Indicador de carga
            FadeTransition(
              opacity: _fadeInAnimation,
              child: _buildLoadingIndicator(theme),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el logo de la app con un efecto visual de profundidad
  Widget _buildAppLogo(ThemeData theme, bool isDarkMode) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
          alpha: isDarkMode ? 0.15 : 0.08,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(
              alpha: isDarkMode ? 0.2 : 0.15,
            ),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'VL',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// Construye el indicador de carga con efectos visuales mejorados
  Widget _buildLoadingIndicator(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading verb database...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
