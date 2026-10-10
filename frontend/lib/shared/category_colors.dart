import 'package:flutter/material.dart';

/// Paleta para distinguir categorías en chips y gráficas.
const List<Color> _palette = [
  Color(0xFF3F51B5),
  Color(0xFF00897B),
  Color(0xFFF4511E),
  Color(0xFF8E24AA),
  Color(0xFF6D4C41),
  Color(0xFF039BE5),
  Color(0xFFD81B60),
  Color(0xFF7CB342),
];

/// Color estable para una categoría: el mismo nombre produce siempre el mismo
/// color (sin distinguir mayúsculas, igual que la base de datos).
Color categoryColor(String category) {
  var hash = 0;
  for (final unit in category.toLowerCase().codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _palette[hash % _palette.length];
}
