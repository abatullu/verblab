// lib/domain/models/verb_form.dart

/// Representa las diferentes formas de un verbo
enum VerbForm {
  /// Forma base o infinitivo (ej: "go")
  base('BASE'),

  /// Forma de pasado simple (ej: "went")
  past('PAST'),

  /// Forma de participio pasado (ej: "gone")
  participle('PARTICIPLE');

  /// Etiqueta visible para el usuario
  final String label;

  const VerbForm(this.label);

  /// Obtiene un [VerbForm] a partir de su nombre como string
  /// Si no encuentra coincidencia, retorna [VerbForm.base] como valor por defecto
  static VerbForm fromString(String form) {
    return VerbForm.values.firstWhere(
      (f) => f.name == form,
      orElse: () => VerbForm.base,
    );
  }
}
