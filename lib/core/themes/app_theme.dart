// lib/core/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño completo para VerbLab que implementa una experiencia
/// visual premium y minimalista según las especificaciones del TDD.
class VerbLabTheme {
  // Constantes de diseño
  static const _primaryColor = Color(0xFF2C4BFF); // Azul principal
  static const _secondaryColor = Color(0xFF6B4BFF); // Púrpura secundario
  static const _errorColor = Color(0xFFEF4444); // Rojo para errores
  static const _surfaceColor = Color(0xFFF8FAFC); // Fondo claro

  // Colores para dark mode
  static const _primaryColorDark = Color(
    0xFF4B6FFF,
  ); // Azul principal más brillante
  static const _secondaryColorDark = Color(
    0xFF8B6FFF,
  ); // Púrpura secundario más brillante
  static const _errorColorDark = Color(
    0xFFFF5252,
  ); // Rojo para errores más brillante
  static const _surfaceColorDark = Color(0xFF121212); // Fondo oscuro
  static const _darkSurfaceContainerColor = Color(
    0xFF1E1E1E,
  ); // Contenedor oscuro
  static const _darkSurfaceContainerHighestColor = Color(
    0xFF2C2C2C,
  ); // Contenedor destacado oscuro

  // Espaciado
  static const spacing = {
    'xs': 4.0, // Separación mínima
    'sm': 8.0, // Elementos relacionados
    'md': 16.0, // Secciones internas
    'lg': 24.0, // Secciones principales
    'xl': 32.0, // Márgenes mayores
    'xxl': 48.0, // Separación de bloques
  };

  // Radios
  static const radius = {
    'xs': 4.0, // Elementos pequeños
    'sm': 8.0, // Botones
    'md': 12.0, // Inputs
    'lg': 16.0, // Cards
    'xl': 24.0, // Modales
    'full': 100.0, // Circular/pill
  };

  // Elevación
  static const elevation = {
    'none': 0.0, // Flat design
    'low': 2.0, // Elementos sutiles
    'medium': 4.0, // Cards destacadas
    'high': 8.0, // Elementos flotantes
  };

  // Duraciones para animaciones
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration complex = Duration(milliseconds: 500);

  /// Crea y devuelve el tema claro para la aplicación
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _secondaryColor,
        error: _errorColor,
        surface: _surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF0F172A),
        surfaceContainerHighest: const Color(0xFFF1F5F9),
        onSurfaceVariant: const Color(0xFF64748B),
        outline: const Color(0xFFCBD5E1),
        outlineVariant: const Color(0xFFE2E8F0),
        shadow: Colors.black..withValues(alpha: 0.05),
      ),
      textTheme: createTextTheme(isDark: false),
      cardTheme: CardTheme(
        elevation: elevation['none'],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius['lg']!),
        ),
        clipBehavior: Clip.antiAlias,
        color: _surfaceColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius['md']!),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _surfaceColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing['md']!,
          vertical: spacing['sm']!,
        ),
      ),
      // Estilos para botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _primaryColor,
          padding: EdgeInsets.symmetric(
            horizontal: spacing['md']!,
            vertical: spacing['sm']!,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['md']!),
          ),
        ),
      ),
      // Configuraciones para AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      // Configuraciones para DialogTheme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius['lg']!),
        ),
        elevation: elevation['medium'],
        backgroundColor: _surfaceColor,
      ),
      // Configuraciones para SnackBarTheme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius['md']!),
        ),
      ),
      // Configuraciones para TooltipTheme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(radius['sm']!),
        ),
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      ),
      // Configuraciones para iconos
      iconTheme: const IconThemeData(color: Color(0xFF64748B), size: 24),
      // Configuraciones para divisores
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Crea y devuelve el tema oscuro para la aplicación
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _primaryColorDark,
        secondary: _secondaryColorDark,
        error: _errorColorDark,
        surface: _surfaceColorDark,
        surfaceContainerHighest: _darkSurfaceContainerHighestColor,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white.withValues(alpha: 0.7),
        outline: Colors.white.withValues(alpha: 0.2),
        outlineVariant: Colors.white.withValues(alpha: 0.1),
        shadow: Colors.black.withValues(alpha: 0.2),
        // Añadimos colores específicos para contenedores en modo oscuro
        surfaceTint: _primaryColorDark.withValues(alpha: 0.1),
        secondaryContainer: _darkSurfaceContainerColor,
        primaryContainer: _primaryColorDark.withValues(alpha: 0.2),
      ),
      // Usamos un tema de texto específico para dark mode
      textTheme: createTextTheme(isDark: true),
      // Tema para tarjetas en modo oscuro
      cardTheme: CardTheme(
        elevation: elevation['none'],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius['lg']!),
        ),
        clipBehavior: Clip.antiAlias,
        color: _darkSurfaceContainerColor,
      ),
      // Tema para entradas en modo oscuro
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius['md']!),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: _darkSurfaceContainerColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing['md']!,
          vertical: spacing['sm']!,
        ),
      ),
      // Configuraciones para AppBar en modo oscuro
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceColorDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Configuraciones para botones elevados en modo oscuro
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _primaryColorDark,
          padding: EdgeInsets.symmetric(
            horizontal: spacing['md']!,
            vertical: spacing['sm']!,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['md']!),
          ),
        ),
      ),
      // Configuraciones para diálogos en modo oscuro
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius['lg']!),
        ),
        elevation: elevation['medium'],
        backgroundColor: _darkSurfaceContainerColor,
      ),
      // Configuraciones para SnackBars en modo oscuro
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _darkSurfaceContainerHighestColor,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius['md']!),
        ),
      ),
      // Configuraciones para tooltips en modo oscuro
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _darkSurfaceContainerHighestColor,
          borderRadius: BorderRadius.circular(radius['sm']!),
        ),
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      ),
      // Configuraciones para iconos en modo oscuro
      iconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.7), size: 24),
      // Configuraciones para divisores en modo oscuro
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Crea un tema de texto con configuraciones basadas en si es modo oscuro o claro
  static TextTheme createTextTheme({required bool isDark}) {
    final baseColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final variantColor =
        isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF64748B);

    return TextTheme(
      // Títulos grandes
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        height: 1.2,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.3,
        color: baseColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.3,
        color: baseColor,
      ),
      // Títulos medianos
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.4,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
        color: baseColor,
      ),
      // Cuerpo de texto
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.15,
        height: 1.5,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
        height: 1.5,
        color: baseColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
        height: 1.5,
        color: variantColor,
      ),
      // Labels y etiquetas
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.4,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.4,
        color: variantColor,
      ),
    );
  }
}

/// Extensión para simplificar el manejo de valores alfa en colores
extension ColorExtension on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromRGBO(
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
      alpha ?? this.opacity,
    );
  }
}
