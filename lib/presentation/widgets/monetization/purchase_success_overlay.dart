// lib/presentation/widgets/monetization/purchase_success_overlay.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

/// Overlay que muestra una animación celebratoria cuando el usuario adquiere premium
class PurchaseSuccessOverlay extends StatefulWidget {
  /// Callback cuando la animación termina
  final VoidCallback? onAnimationComplete;

  const PurchaseSuccessOverlay({super.key, this.onAnimationComplete});

  @override
  State<PurchaseSuccessOverlay> createState() => _PurchaseSuccessOverlayState();
}

class _PurchaseSuccessOverlayState extends State<PurchaseSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // Para las partículas de confeti
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Crear partículas de confeti con posiciones aleatorias
    for (int i = 0; i < 50; i++) {
      _particles.add(
        _Particle(
          position: Offset(
            _random.nextDouble() * 400 - 200,
            _random.nextDouble() * 400 - 200,
          ),
          color: Color.fromARGB(
            255,
            _random.nextInt(255),
            _random.nextInt(255),
            _random.nextInt(255),
          ),
          size: _random.nextDouble() * 10 + 5,
          velocity: Offset(
            _random.nextDouble() * 6 - 3,
            _random.nextDouble() * 3 + 3,
          ),
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: _random.nextDouble() * 0.2 - 0.1,
        ),
      );
    }

    // Configurar animaciones
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Iniciar la animación automáticamente
    _controller.forward();

    // Callback cuando la animación termina
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Actualizar la posición de las partículas
          for (final particle in _particles) {
            particle.position += particle.velocity;
            particle.rotation += particle.rotationSpeed;
          }

          return FadeTransition(
            opacity: _opacityAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fondo semi-transparente
                Positioned.fill(
                  child: Container(
                    color: theme.colorScheme.background.withOpacity(0.7),
                  ),
                ),

                // Partículas de confeti
                ...List.generate(_particles.length, (index) {
                  final particle = _particles[index];

                  return Positioned(
                    left: size.width / 2 + particle.position.dx,
                    top: size.height / 2 + particle.position.dy,
                    child: Transform.rotate(
                      angle: particle.rotation,
                      child: Container(
                        width: particle.size,
                        height: particle.size * 0.5,
                        decoration: BoxDecoration(
                          color: particle.color.withOpacity(
                            _opacityAnimation.value,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),

                // Mensaje de éxito
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: EdgeInsets.all(VerbLabTheme.spacing['lg']!),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(
                        VerbLabTheme.radius['lg']!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.stars,
                            size: 60,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: VerbLabTheme.spacing['md']),
                        Text(
                          'Welcome to Premium!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: VerbLabTheme.spacing['xs']),
                        Text(
                          'You now have a completely ad-free experience',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        SizedBox(height: VerbLabTheme.spacing['md']),
                        ElevatedButton(
                          onPressed: () {
                            widget.onAnimationComplete?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            minimumSize: const Size(200, 48),
                          ),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Clase para representar una partícula de confeti
class _Particle {
  Offset position;
  final Color color;
  final double size;
  final Offset velocity;
  double rotation;
  final double rotationSpeed;

  _Particle({
    required this.position,
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}
