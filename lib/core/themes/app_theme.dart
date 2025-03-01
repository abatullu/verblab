// lib/core/themes/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño completo para VerbLab que implementa una experiencia
/// visual premium y minimalista según las especificaciones del TDD.
///
/// Se ha refinado para crear una identidad visual distintiva manteniendo
/// el minimalismo funcional y el alto rendimiento.
class VerbLabTheme {
  // Previene la instanciación
  const VerbLabTheme._();

  // Paleta refinada para tema claro
  // Se utilizó una paleta de azules más sofisticada para crear una identidad premium
  static const _primaryColor = Color(0xFF2A54E5); // Azul principal refinado
  static const _primaryLight = Color(0xFF5C7BF7); // Variante clara para acentos
  static const _primaryDark = Color(
    0xFF1C43C7,
  ); // Variante oscura para elementos interactivos
  static const _secondaryColor = Color(
    0xFF6347E7,
  ); // Púrpura secundario refinado
  static const _errorColor = Color(
    0xFFE53935,
  ); // Rojo para errores, más refinado
  static const _surfaceColor = Color(0xFFFAFBFD); // Fondo principal, más sutil
  static const _surfaceContainer = Color(
    0xFFF2F5FC,
  ); // Contenedor de superficie
  static const _surfaceContainerHigh = Color(
    0xFFE9EEF9,
  ); // Contenedor de alto contraste

  // Colores para dark mode, refinados para mejor experiencia nocturna
  static const _primaryColorDark = Color(
    0xFF4E6AF0,
  ); // Azul principal brillante para modo oscuro
  static const _primaryLightDark = Color(
    0xFF7891FF,
  ); // Variante clara para acentos en oscuro
  static const _primaryDarkDark = Color(
    0xFF3551D3,
  ); // Variante oscura para interactivos en oscuro
  static const _secondaryColorDark = Color(
    0xFF8673FF,
  ); // Púrpura secundario para oscuro
  static const _errorColorDark = Color(
    0xFFFF5252,
  ); // Rojo para errores en oscuro
  static const _surfaceColorDark = Color(0xFF131720); // Fondo oscuro refinado
  static const _darkSurfaceContainer = Color(0xFF1C222D); // Contenedor oscuro
  static const _darkSurfaceContainerHigh = Color(
    0xFF262D3A,
  ); // Contenedor destacado oscuro

  // Espaciado - Mantenemos el sistema actual que es coherente
  static const spacing = {
    'xxs': 2.0, // Espaciado mínimo para elementos compactos
    'xs': 4.0, // Separación mínima
    'sm': 8.0, // Elementos relacionados
    'md': 16.0, // Secciones internas
    'lg': 24.0, // Secciones principales
    'xl': 32.0, // Márgenes mayores
    'xxl': 48.0, // Separación de bloques
  };

  // Radios - Refinados para ser más coherentes con el nuevo estilo
  static const radius = {
    'xs': 4.0, // Elementos pequeños
    'sm': 8.0, // Botones y elementos pequeños
    'md': 12.0, // Inputs y elementos medianos
    'lg': 16.0, // Cards y contenedores principales
    'xl': 24.0, // Modales y diálogos
    'full': 100.0, // Circular/pill para badges
  };

  // Elevación - Mantenemos los valores pero ajustamos su uso
  static const elevation = {
    'none': 0.0, // Diseño plano para la mayoría de elementos
    'low': 1.0, // Elementos sutiles con sombra mínima
    'medium': 3.0, // Cards destacadas, reducido de 4.0 para ser más sutil
    'high': 6.0, // Elementos flotantes, reducido de 8.0 para mejor coherencia
  };

  // Duraciones para animaciones
  static const Duration quick = Duration(
    milliseconds: 150,
  ); // Microinteracciones
  static const Duration standard = Duration(
    milliseconds: 250,
  ); // Transiciones estándar (reducida para mayor agilidad)
  static const Duration complex = Duration(
    milliseconds: 400,
  ); // Animaciones complejas (reducida para mayor agilidad)

  // Opacidades estándar - nuevo sistema para mantener coherencia en transparencias
  static const opacity = {
    'disabled': 0.38, // Elementos deshabilitados
    'hint': 0.6, // Textos de ayuda
    'light': 0.08, // Efectos visuales sutiles
    'medium': 0.16, // Contenedores y efectos medios
    'high': 0.24, // Elementos destacados
  };

  /// Crea y devuelve el tema claro para la aplicación
  static ThemeData lightTheme() {
    // Intentamos capturar cualquier error de carga de fuentes
    try {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: _primaryColor,
          onPrimary: Colors.white,
          primaryContainer: _primaryLight.withOpacity(opacity['medium']!),
          onPrimaryContainer: _primaryDark,

          secondary: _secondaryColor,
          onSecondary: Colors.white,
          secondaryContainer: _secondaryColor.withOpacity(opacity['medium']!),

          error: _errorColor,
          onError: Colors.white,

          surface: _surfaceColor,
          onSurface: const Color(
            0xFF1A1F2B,
          ), // Texto principal más oscuro para mejor contraste
          surfaceVariant: _surfaceContainer,
          onSurfaceVariant: const Color(
            0xFF555E71,
          ), // Texto secundario más contrastado

          background: _surfaceColor,
          onBackground: const Color(0xFF1A1F2B),

          // Componentes específicos refinados
          surfaceContainerHighest: _surfaceContainerHigh,
          outline: const Color(0xFFCBD5E1),
          outlineVariant: const Color(0xFFE4E9F2),
          shadow: Colors.black.withOpacity(0.05),
        ),
        textTheme: createTextTheme(isDark: false),
        cardTheme: CardTheme(
          elevation: elevation['none'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['lg']!),
          ),
          clipBehavior: Clip.antiAlias,
          color: _surfaceColor,
          surfaceTintColor:
              Colors.transparent, // Elimina el tinte en Material 3
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius['md']!),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _surfaceContainer,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing['md']!,
            vertical: spacing['sm']!,
          ),
          hintStyle: TextStyle(
            color: const Color(0xFF1A1F2B).withOpacity(opacity['hint']!),
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
            elevation: elevation['low'],
            shadowColor: _primaryColor.withOpacity(0.3),
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
            color: const Color(0xFF1A1F2B),
            letterSpacing: -0.5,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1A1F2B)),
        ),
        // Configuraciones para DialogTheme
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['lg']!),
          ),
          elevation: elevation['medium'],
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
        ),
        // Configuraciones para SnackBarTheme
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1C2231),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: Colors.white,
            letterSpacing: 0.25,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['md']!),
          ),
        ),
        // Configuraciones para TooltipTheme
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2B),
            borderRadius: BorderRadius.circular(radius['sm']!),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white,
            height: 1.4,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: spacing['sm']!,
            vertical: spacing['xs']!,
          ),
        ),
        // Configuraciones para iconos
        iconTheme: IconThemeData(
          color: const Color(0xFF555E71),
          size: 24,
          opacity: 1.0,
        ),
        // Configuraciones para divisores
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE4E9F2),
          thickness: 1,
          space: 1,
        ),
        // Configuraciones para BottomSheetTheme
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: _surfaceColor,
          modalBackgroundColor: _surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radius['lg']!),
            ),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        // Configuraciones para Chip
        chipTheme: ChipThemeData(
          backgroundColor: _surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['full']!),
          ),
          side: BorderSide.none,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.25,
          ),
        ),
        // Configuraciones para PopupMenuTheme
        popupMenuTheme: PopupMenuThemeData(
          color: _surfaceColor,
          elevation: elevation['medium'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['md']!),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        // Configuraciones para FloatingActionButton
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: elevation['medium'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['full']!),
          ),
        ),
        // Configuraciones para sistema Material 3
        materialTapTargetSize: MaterialTapTargetSize.padded,
        splashFactory: InkRipple.splashFactory, // Efecto de ripple más suave
        visualDensity: VisualDensity.standard,
      );
    } catch (e) {
      // Si hay error en la carga de fuentes, devolver tema fallback
      return _fallbackLightTheme();
    }
  }

  /// Crea y devuelve el tema oscuro para la aplicación
  static ThemeData darkTheme() {
    try {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: _primaryColorDark,
          onPrimary: Colors.white,
          primaryContainer: _primaryLightDark.withOpacity(opacity['medium']!),
          onPrimaryContainer: Colors.white,

          secondary: _secondaryColorDark,
          onSecondary: Colors.white,
          secondaryContainer: _secondaryColorDark.withOpacity(
            opacity['medium']!,
          ),

          error: _errorColorDark,
          onError: Colors.white,

          surface: _surfaceColorDark,
          onSurface: Colors.white,
          surfaceVariant: _darkSurfaceContainer,
          onSurfaceVariant: Colors.white.withOpacity(0.75), // Mejor contraste

          background: _surfaceColorDark,
          onBackground: Colors.white,

          // Componentes específicos refinados
          surfaceContainerHighest: _darkSurfaceContainerHigh,
          outline: Colors.white.withOpacity(0.2),
          outlineVariant: Colors.white.withOpacity(0.1),
          shadow: Colors.black.withOpacity(
            0.25,
          ), // Sombras más visibles en modo oscuro
          // Colores específicos para contenedores en modo oscuro
          surfaceTint: _primaryColorDark.withOpacity(0.1),
        ),
        // Tema de texto específico para dark mode
        textTheme: createTextTheme(isDark: true),
        // Tema para tarjetas en modo oscuro
        cardTheme: CardTheme(
          elevation: elevation['none'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['lg']!),
          ),
          clipBehavior: Clip.antiAlias,
          color: _darkSurfaceContainer,
          surfaceTintColor: Colors.transparent,
        ),
        // Tema para entradas en modo oscuro
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius['md']!),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _darkSurfaceContainer,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing['md']!,
            vertical: spacing['sm']!,
          ),
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(opacity['hint']!),
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
            letterSpacing: -0.5,
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
            elevation: elevation['medium'],
            shadowColor: _primaryDarkDark.withOpacity(0.4),
          ),
        ),
        // Configuraciones para diálogos en modo oscuro
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['lg']!),
          ),
          elevation: elevation['medium'],
          backgroundColor: _darkSurfaceContainer,
          surfaceTintColor: Colors.transparent,
        ),
        // Configuraciones para SnackBars en modo oscuro
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _darkSurfaceContainerHigh,
          contentTextStyle: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: Colors.white,
            letterSpacing: 0.25,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['md']!),
          ),
        ),
        // Configuraciones para tooltips en modo oscuro
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: _darkSurfaceContainerHigh,
            borderRadius: BorderRadius.circular(radius['sm']!),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white,
            height: 1.4,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: spacing['sm']!,
            vertical: spacing['xs']!,
          ),
        ),
        // Configuraciones para iconos en modo oscuro
        iconTheme: IconThemeData(
          color: Colors.white.withOpacity(0.8),
          size: 24,
          opacity: 1.0,
        ),
        // Configuraciones para divisores en modo oscuro
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.1),
          thickness: 1,
          space: 1,
        ),
        // Configuraciones para BottomSheetTheme en modo oscuro
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: _darkSurfaceContainer,
          modalBackgroundColor: _darkSurfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radius['lg']!),
            ),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        // Configuraciones para Chip en modo oscuro
        chipTheme: ChipThemeData(
          backgroundColor: _darkSurfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['full']!),
          ),
          side: BorderSide.none,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.25,
          ),
        ),
        // Configuraciones para PopupMenuTheme en modo oscuro
        popupMenuTheme: PopupMenuThemeData(
          color: _darkSurfaceContainer,
          elevation: elevation['medium'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['md']!),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        // Configuraciones para FloatingActionButton en modo oscuro
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColorDark,
          foregroundColor: Colors.white,
          elevation: elevation['medium'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius['full']!),
          ),
        ),
        // Configuraciones para sistema Material 3
        materialTapTargetSize: MaterialTapTargetSize.padded,
        splashFactory: InkRipple.splashFactory, // Efecto de ripple más suave
        visualDensity: VisualDensity.standard,
      );
    } catch (e) {
      // Si hay error en la carga de fuentes, devolver tema fallback
      return _fallbackDarkTheme();
    }
  }

  /// Crea un tema de texto con configuraciones basadas en si es modo oscuro o claro
  /// Optimizado para mejor jerarquía visual y legibilidad
  static TextTheme createTextTheme({required bool isDark}) {
    final baseColor = isDark ? Colors.white : const Color(0xFF1A1F2B);
    final variantColor =
        isDark ? Colors.white.withOpacity(0.75) : const Color(0xFF555E71);

    try {
      return TextTheme(
        // Títulos grandes con mayor contraste y mejor legibilidad
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
          height: 1.25, // Ajustado para mejor proporción
          color: baseColor,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          height: 1.3,
          color: baseColor,
        ),
        // Títulos medianos con mejor espaciado
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          height: 1.35, // Ajustado para mejor proporción
          color: baseColor,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15, // Ajustado para mejor coherencia
          height: 1.4,
          color: baseColor,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1, // Ajustado para mejor coherencia
          height: 1.4,
          color: baseColor,
        ),
        // Cuerpo de texto optimizado para legibilidad
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
        // Labels y etiquetas con mejor coherencia
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.3, // Ajustado para etiquetas
          color: baseColor,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.3, // Ajustado para etiquetas
          color: baseColor,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.3, // Ajustado para etiquetas
          color: variantColor,
        ),
      );
    } catch (e) {
      // Si hay problemas con la fuente, retornamos un TextTheme básico
      return _fallbackTextTheme(isDark: isDark);
    }
  }

  /// Tema de texto de respaldo en caso de problemas con las fuentes
  static TextTheme _fallbackTextTheme({required bool isDark}) {
    final baseColor = isDark ? Colors.white : const Color(0xFF1A1F2B);
    final variantColor =
        isDark ? Colors.white.withOpacity(0.75) : const Color(0xFF555E71);

    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        height: 1.2,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.25,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.3,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.35,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        height: 1.4,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.15,
        height: 1.5,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
        height: 1.5,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
        height: 1.5,
        color: variantColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.3,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
        color: baseColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
        color: variantColor,
      ),
    );
  }

  /// Tema claro de respaldo en caso de problemas con las fuentes
  static ThemeData _fallbackLightTheme() {
    final theme = ThemeData.light(useMaterial3: true);
    return theme.copyWith(
      textTheme: _fallbackTextTheme(isDark: false),
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _secondaryColor,
        error: _errorColor,
        surface: _surfaceColor,
      ),
    );
  }

  /// Tema oscuro de respaldo en caso de problemas con las fuentes
  static ThemeData _fallbackDarkTheme() {
    final theme = ThemeData.dark(useMaterial3: true);
    return theme.copyWith(
      textTheme: _fallbackTextTheme(isDark: true),
      colorScheme: ColorScheme.dark(
        primary: _primaryColorDark,
        secondary: _secondaryColorDark,
        error: _errorColorDark,
        surface: _surfaceColorDark,
      ),
    );
  }
}

/// Extensión para simplificar el manejo de valores alfa en colores
extension ColorExtension on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromRGBO(
      (red ?? r.toInt()), // Convertir a int
      (green ?? g.toInt()), // Convertir a int
      (blue ?? b.toInt()), // Convertir a int
      alpha ?? a, // Mantener double
    );
  }
}
