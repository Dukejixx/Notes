import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/note_stats.dart';
import '../../services/notes_api.dart';

/// Estado del panel de estadísticas y del período consultado.
class StatsController extends ChangeNotifier {
  StatsController(this._api);

  final NotesApi _api;

  NoteStats? _stats;
  NoteStats? get stats => _stats;

  DateTimeRange? _range;

  /// Período filtrado (ambos días incluidos); `null` = todas las notas.
  DateTimeRange? get range => _range;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _disposed = false;
  int _requestId = 0;

  /// Indica si un período supera el máximo que admite la API.
  /// Se calcula con fechas UTC para que un cambio de horario de verano (días
  /// de 23 o 25 horas) no altere el número de días.
  static bool exceedsMaxRange(DateTimeRange range) {
    DateTime day(DateTime d) => DateTime.utc(d.year, d.month, d.day);
    final days = day(range.end).difference(day(range.start)).inDays + 1;
    return days > NotesApi.maxStatsRangeDays;
  }

  Future<void> setRange(DateTimeRange? range) {
    _range = range;
    return load();
  }

  Future<void> load() async {
    // Solo se aplica la respuesta de la última petición (p. ej. si el usuario
    // cambia el período antes de que termine la anterior).
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final stats = await _api.fetchStats(from: _range?.start, to: _range?.end);
      if (requestId != _requestId) return;
      _stats = stats;
    } on ApiException catch (e) {
      if (requestId != _requestId) return;
      _error = e.message;
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
