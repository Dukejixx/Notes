import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/stats/stats_controller.dart';

import 'fakes.dart';

void main() {
  test(
    'consulta el período seleccionado y lo quita al limpiar el filtro',
    () async {
      final requests = <Uri>[];
      final controller = StatsController(
        fakeApi((request) async {
          requests.add(request.url);
          return jsonResponse(statsJson);
        }),
      );
      addTearDown(controller.dispose);

      await controller.setRange(
        DateTimeRange(start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 5)),
      );
      await controller.setRange(null);

      expect(requests.first.queryParameters, {
        'from_date': '2026-10-01',
        'to_date': '2026-10-05',
      });
      expect(requests.last.hasQuery, isFalse);
      expect(controller.stats?.totalNotes, 3);
      expect(controller.isLoading, isFalse);
    },
  );

  test('aplica el mismo límite de 366 días que la API', () {
    final start = DateTime(2025, 1, 1);

    expect(
      StatsController.exceedsMaxRange(
        DateTimeRange(start: start, end: DateTime(2026, 1, 1)),
      ),
      isFalse,
    );
    expect(
      StatsController.exceedsMaxRange(
        DateTimeRange(start: start, end: DateTime(2026, 1, 2)),
      ),
      isTrue,
    );
  });

  test('guarda el mensaje de error de la API', () async {
    final controller = StatsController(
      fakeApi(
        (_) async =>
            jsonResponse({'detail': 'Sin conexión con MySQL.'}, status: 503),
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.error, 'Sin conexión con MySQL.');
    expect(controller.isLoading, isFalse);
  });
}
