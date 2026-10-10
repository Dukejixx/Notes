/// La API envía fechas y horas en UTC sin sufijo de zona horaria
/// (p. ej. `2026-10-01T10:30:00`). Se interpretan como UTC y se convierten a
/// la hora local del dispositivo para mostrarlas.
DateTime parseUtcDateTime(String value) {
  final hasZone =
      value.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);
  return DateTime.parse(hasZone ? value : '${value}Z').toLocal();
}

/// Convierte una fecha `YYYY-MM-DD` (día UTC) en un [DateTime] sin hora.
DateTime parseApiDate(String value) {
  final parsed = DateTime.parse(value);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Formato `YYYY-MM-DD` que esperan los parámetros `from_date` y `to_date`.
String formatApiDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
