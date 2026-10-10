import '../core/api_client.dart';
import '../models/api_date.dart';
import '../models/note.dart';
import '../models/note_stats.dart';

/// Acceso a los endpoints de notas de la API (`/api/v1`).
class NotesApi {
  NotesApi(this._client);

  static const _basePath = '/api/v1/notes';

  /// Máximo permitido por la API para `limit`.
  static const maxPageSize = 100;

  /// Máximo de días permitido por la API para un intervalo de estadísticas.
  static const maxStatsRangeDays = 366;

  final ApiClient _client;

  Future<NotePage> fetchNotes({int page = 1, int limit = 20}) async {
    assert(page >= 1 && limit >= 1 && limit <= maxPageSize);
    final json = await _client.getJson(
      _basePath,
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );
    return _parse(() => NotePage.fromJson(json));
  }

  Future<NoteStats> fetchStats({DateTime? from, DateTime? to}) async {
    final json = await _client.getJson(
      '$_basePath/stats',
      queryParameters: {
        if (from != null) 'from_date': formatApiDate(from),
        if (to != null) 'to_date': formatApiDate(to),
      },
    );
    return _parse(() => NoteStats.fromJson(json));
  }

  /// Convierte un JSON con una forma inesperada (p. ej. una versión de la API
  /// incompatible) en un error controlado en lugar de un fallo de la app.
  static T _parse<T>(T Function() parser) {
    try {
      return parser();
    } on TypeError {
      throw const ApiException(
        'La API devolvió datos con un formato inesperado.',
      );
    }
  }
}
