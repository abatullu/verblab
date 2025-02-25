// lib/domain/models/dialect.dart

/// Representa los dialectos soportados del inglés
enum Dialect {
  /// Inglés Americano (US)
  us('en-US', 'US'),
  
  /// Inglés Británico (UK)
  uk('en-UK', 'UK');

  /// Código del dialecto en formato BCP 47 (e.g., 'en-US')
  final String code;
  
  /// Etiqueta visible para el usuario
  final String label;

  const Dialect(this.code, this.label);

  /// Obtiene un [Dialect] a partir de su código
  /// Si no encuentra coincidencia, retorna [Dialect.us] como valor por defecto
  static Dialect fromCode(String code) {
    return Dialect.values.firstWhere(
      (d) => d.code == code,
      orElse: () => Dialect.us,
    );
  }
  
  /// Obtiene un [Dialect] a partir de su etiqueta
  /// Si no encuentra coincidencia, retorna [Dialect.us] como valor por defecto
  static Dialect fromLabel(String label) {
    return Dialect.values.firstWhere(
      (d) => d.label == label,
      orElse: () => Dialect.us,
    );
  }
  
  /// Retorna el código opuesto al actual
  String get oppositeCode => this == Dialect.us ? Dialect.uk.code : Dialect.us.code;
  
  /// Retorna la etiqueta opuesta a la actual
  String get oppositeLabel => this == Dialect.us ? Dialect.uk.label : Dialect.us.label;
}