// lib/presentation/widgets/common/shimmer_loading.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

/// Widget que aplica un efecto shimmer (brillo animado) a sus hijos.
///
/// Útil para mostrar estados de carga de manera elegante, aplicando
/// un efecto de brillo que se desplaza sobre placeholders de contenido.
class ShimmerLoading extends StatefulWidget {
  /// Si el shimmer está activo
  final bool isLoading;

  /// Widget hijo al que se aplicará el efecto
  final Widget child;

  /// Color base del shimmer
  final Color? baseColor;

  /// Color de destello del shimmer
  final Color? highlightColor;

  /// Duración de la animación
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.isLoading,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final baseColor =
        widget.baseColor ??
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.1);
    final highlightColor =
        widget.highlightColor ??
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlidingGradientTransform(
                slidePercent: _shimmerAnimation.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Transformador personalizado para desplazar el gradiente durante la animación
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// Widget para crear un placeholder de carga para elementos de la lista
class ShimmerListItem extends StatelessWidget {
  /// Altura del item
  final double height;

  /// Widget para mostrar estructura durante la carga
  final Widget? child;

  /// Si tiene bordes redondeados
  final bool rounded;

  const ShimmerListItem({
    super.key,
    this.height = 150,
    this.child,
    this.rounded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius:
            rounded ? BorderRadius.circular(VerbLabTheme.radius['lg']!) : null,
      ),
      child: child,
    );
  }
}
