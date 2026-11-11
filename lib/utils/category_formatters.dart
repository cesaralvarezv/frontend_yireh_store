/// Formatea nombres de categorías para mostrarlos en Title Case.
///
/// Mantiene en minúscula los conectores habituales del español y corrige
/// algunas palabras frecuentes que llegan sin tilde desde el backend.
String formatCategoryTitle(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return '';

  final words = normalized.split(' ');
  final formatted = <String>[];

  for (var i = 0; i < words.length; i++) {
    final lower = words[i].toLowerCase();

    if (i > 0 && _connectors.contains(lower)) {
      formatted.add(lower);
      continue;
    }

    final corrected = _accentCorrections[lower] ?? lower;
    formatted.add(_capitalize(corrected));
  }

  return formatted.join(' ');
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

const _connectors = <String>{
  'y',
  'e',
  'o',
  'u',
  'de',
  'del',
  'la',
  'las',
  'el',
  'los',
  'en',
  'con',
  'para',
  'por',
};

const _accentCorrections = <String, String>{
  'confiteria': 'confitería',
  'cafeteria': 'cafetería',
  'panaderia': 'panadería',
  'reposteria': 'repostería',
  'cafe': 'café',
  'te': 'té',
  'frias': 'frías',
  'rapidas': 'rápidas',
  'sandwiches': 'sándwiches',
};

/// Alias genérico para normalizar cualquier título a Title Case.
String formatTitleCase(String value) => formatCategoryTitle(value);
