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
      ),
      textTheme: TextTheme(
        // Títulos grandes
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          height: 1.3,
        ),
        // Títulos medianos
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.4,
        ),
        // Cuerpo de texto
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.25,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.4,
          height: 1.5,
        ),
        // Labels y etiquetas
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
        ),
      ),
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
      ),
    );
  }

  /// Crea y devuelve el tema oscuro para la aplicación
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _secondaryColor,
        error: _errorColor,
        surface: const Color(0xFF121212),
        surfaceContainerHighest: const Color(0xFF2A2A2A),
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white.withValues(alpha: 0.7),
        outline: Colors.white.withValues(alpha: 0.2),
        outlineVariant: Colors.white.withValues(alpha: 0.1),
      ),
      // Heredamos el resto de propiedades del tema claro
      textTheme: TextTheme(
        // Títulos grandes
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          height: 1.2,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.3,
          color: Colors.white,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          height: 1.3,
          color: Colors.white,
        ),
        // Títulos medianos
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          height: 1.4,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.4,
          color: Colors.white,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.4,
          color: Colors.white,
        ),
        // Cuerpo de texto
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.15,
          height: 1.5,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.25,
          height: 1.5,
          color: Colors.white,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.4,
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        // Labels y etiquetas
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.4,
          color: Colors.white,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: Colors.white,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
      cardTheme: CardTheme(
        elevation: elevation['none'],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius['lg']!),
        ),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF1E1E1E),
      ),
      // AppBar para tema oscuro
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
