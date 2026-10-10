import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:notes_app/core/api_client.dart';

import 'fakes.dart';

void main() {
  test('pide la página indicada y decodifica UTF-8', () async {
    late Uri requested;
    final api = fakeApi((request) async {
      requested = request.url;
      return jsonResponse({
        'items': [noteJson(1, title: 'Paginación eficiente')],
        'total': 1,
        'page': 2,
        'limit': 5,
      });
    });

    final page = await api.fetchNotes(page: 2, limit: 5);

    expect(requested.path, '/api/v1/notes');
    expect(requested.queryParameters, {'page': '2', 'limit': '5'});
    expect(page.items.single.title, 'Paginación eficiente');
  });

  test('envía el período de estadísticas como YYYY-MM-DD', () async {
    late Uri requested;
    final api = fakeApi((request) async {
      requested = request.url;
      return jsonResponse(statsJson);
    });

    await api.fetchStats(
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 5),
    );

    expect(requested.path, '/api/v1/notes/stats');
    expect(requested.queryParameters, {
      'from_date': '2026-10-01',
      'to_date': '2026-10-05',
    });
  });

  test('sin período no envía parámetros', () async {
    late Uri requested;
    final api = fakeApi((request) async {
      requested = request.url;
      return jsonResponse(statsJson);
    });

    await api.fetchStats();

    expect(requested.hasQuery, isFalse);
  });

  test('muestra el detalle de error que envía la API', () async {
    final api = fakeApi(
      (_) async => jsonResponse({
        'detail': 'La base de datos no está disponible.',
      }, status: 503),
    );

    expect(
      api.fetchNotes(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 503)
            .having(
              (e) => e.message,
              'message',
              'La base de datos no está disponible.',
            ),
      ),
    );
  });

  test('traduce los errores de validación de FastAPI', () async {
    final api = fakeApi(
      (_) async => jsonResponse({
        'detail': [
          {
            'loc': ['query', 'page'],
            'msg': 'error',
          },
        ],
      }, status: 422),
    );

    expect(
      api.fetchNotes(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Los parámetros de la consulta no son válidos.',
        ),
      ),
    );
  });

  test('informa si el servidor no está en marcha', () async {
    final api = fakeApi(
      (_) async => throw http.ClientException('Connection refused'),
    );

    expect(
      api.fetchNotes(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('No se pudo conectar con la API'),
        ),
      ),
    );
  });

  test(
    'convierte una respuesta con formato inesperado en un error controlado',
    () async {
      final api = fakeApi(
        (_) async => jsonResponse({'items': 'no es una lista'}),
      );

      expect(
        api.fetchNotes(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'La API devolvió datos con un formato inesperado.',
          ),
        ),
      );
    },
  );
}
