// lib/presentation/pages/premium_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/themes/app_theme.dart';
import '../../core/providers/monetization_providers.dart';
import '../../core/providers/user_preferences_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/monetization/premium_button.dart';

/// Pantalla dedicada para mostrar los beneficios de la versión premium
/// y facilitar la conversión de usuarios.
class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage>
    with SingleTickerProviderStateMixin {
  // Controlador para animaciones
  late final AnimationController _animationController;
  // Animaciones para elementos individuales
  late final Animation<double> _headerScaleAnimation;
  late final Animation<double> _fadeInAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Animación para el encabezado visual
    _headerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Animación para fade in de elementos
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // Animación para slide up de elementos
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Iniciar animaciones después de que el frame se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(VerbLabTheme.spacing['lg']!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Elemento visual destacado
                _buildHeaderVisual(theme, isDarkMode),

                SizedBox(height: VerbLabTheme.spacing['lg']),

                // Título y tagline
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      'Upgrade to Premium',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SizedBox(height: VerbLabTheme.spacing['sm']),

                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      'Learn without distractions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                SizedBox(height: VerbLabTheme.spacing['xl']),

                // Beneficios
                _buildBenefitsList(theme, isDarkMode),

                SizedBox(height: VerbLabTheme.spacing['xl']),

                // Información de precio
                _buildPriceInfo(theme),

                SizedBox(height: VerbLabTheme.spacing['lg']),

                // Botón de compra prominente
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: const PremiumButton(compact: false),
                  ),
                ),

                SizedBox(height: VerbLabTheme.spacing['md']),

                // Botón para restaurar compras
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Center(
                    child: TextButton(
                      onPressed: () => _showRestoreDialog(context),
                      child: const Text('Restore Previous Purchase'),
                    ),
                  ),
                ),

                SizedBox(height: VerbLabTheme.spacing['xl']),

                // Notas legales
                _buildLegalNotes(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el elemento visual destacado en la parte superior
  Widget _buildHeaderVisual(ThemeData theme, bool isDarkMode) {
    return ScaleTransition(
      scale: _headerScaleAnimation,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(
            isDarkMode ? 0.15 : 0.08,
          ),
          borderRadius: BorderRadius.circular(VerbLabTheme.radius['lg']!),
        ),
        child: Stack(
          children: [
            // Elementos decorativos (círculos)
            Positioned(
              top: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(
                    isDarkMode ? 0.1 : 0.05,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(
                    isDarkMode ? 0.1 : 0.05,
                  ),
                ),
              ),
            ),

            // Contenido principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: VerbLabTheme.spacing['md']),
                  Text(
                    'VerbLab Premium',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la lista animada de beneficios
  Widget _buildBenefitsList(ThemeData theme, bool isDarkMode) {
    final benefits = [
      {
        'icon': Icons.block,
        'title': 'No Advertisements',
        'description': 'Enjoy a distraction-free learning experience',
      },
      {
        'icon': Icons.repeat_one,
        'title': 'One-time Payment',
        'description': 'No subscriptions, yours forever',
      },
      {
        'icon': Icons.code,
        'title': 'Support Development',
        'description': 'Help maintain and improve VerbLab',
      },
      {
        'icon': Icons.update,
        'title': 'Future Updates',
        'description': 'Get access to all upcoming features',
      },
    ];

    return Column(
      children:
          benefits.asMap().entries.map((entry) {
            final index = entry.key;
            final benefit = entry.value;

            // Calcular retraso para animación escalonada
            final delay = index * 0.1;

            final delayedAnimation = CurvedAnimation(
              parent: _animationController,
              curve: Interval(delay, delay + 0.6, curve: Curves.easeOutCubic),
            );

            return FadeTransition(
              opacity: delayedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(delayedAnimation),
                child: Padding(
                  padding: EdgeInsets.only(bottom: VerbLabTheme.spacing['md']!),
                  child: _buildBenefitItem(
                    theme,
                    isDarkMode,
                    icon: benefit['icon'] as IconData,
                    title: benefit['title'] as String,
                    description: benefit['description'] as String,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  /// Construye un ítem individual de beneficio
  Widget _buildBenefitItem(
    ThemeData theme,
    bool isDarkMode, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(
                isDarkMode ? 0.2 : 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          SizedBox(width: VerbLabTheme.spacing['md']),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: VerbLabTheme.spacing['xxs']),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de información de precio
  Widget _buildPriceInfo(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Text(
              'One-time Purchase',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: VerbLabTheme.spacing['xs']),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.premiumPrice,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: VerbLabTheme.spacing['xs']),
            Text(
              'Lifetime access, no subscription',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye las notas legales en la parte inferior
  Widget _buildLegalNotes(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: VerbLabTheme.spacing['lg']!),
        child: Column(
          children: [
            Text(
              'Payment will be charged to your Google Play account at confirmation of purchase.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: VerbLabTheme.spacing['md']),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed:
                      () => _launchURL(
                        'https://verblab.coreforge.es/privacy-policy/',
                      ),
                  child: Text(
                    'Privacy Policy',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  '•',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                TextButton(
                  onPressed:
                      () => _launchURL(
                        'https://verblab.coreforge.es/terms-of-service/',
                      ),
                  child: Text(
                    'Terms of Service',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  /// Muestra el diálogo para restaurar compras
  void _showRestoreDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Restore Purchases'),
            content: const Text(
              'This will restore your premium status if you\'ve previously purchased it on this device or with the same account.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Mostrar indicador de carga
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restoring purchases...'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Llamar al método real de restauración
                  final purchaseManager = ref.read(purchaseManagerProvider);
                  final result = await purchaseManager.restorePurchases();

                  if (!result && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to start restoration process. Please try again later.',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                  // Los resultados exitosos se manejarán a través del Stream de compras
                },
                child: const Text('Restore'),
              ),
            ],
          ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }
}
