import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:notes_app/app.dart';
import 'package:notes_app/features/stats/widgets/summary_cards.dart';

import 'fakes.dart';

Future<http.Response> _server(http.Request request) async {
  if (request.url.path == '/api/v1/notes/stats') return jsonResponse(statsJson);
  return jsonResponse({
    'items': [
      noteJson(2, title: 'Aprender FastAPI'),
      noteJson(1, category: 'Personal'),
    ],
    'total': 2,
    'page': 1,
    'limit': 20,
  });
}

void main() {
  testWidgets('muestra el listado y abre el detalle de una nota', (
    tester,
  ) async {
    await tester.pumpWidget(NotesApp(api: fakeApi(_server)));
    await tester.pumpAndSettle();

    expect(find.text('Aprender FastAPI'), findsOneWidget);
    expect(find.text('2 en total'), findsOneWidget);
    expect(find.text('No hay más notas'), findsOneWidget);

    await tester.tap(find.text('Aprender FastAPI'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle de la nota'), findsOneWidget);
    expect(find.text('Contenido de la nota 2'), findsOneWidget);
  });

  testWidgets('muestra el panel de estadísticas', (tester) async {
    // Pantalla de escritorio: navegación lateral y gráficas en dos columnas.
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(NotesApp(api: fakeApi(_server)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Estadísticas'));
    await tester.pumpAndSettle();

    expect(find.text('Total de notas'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(SummaryCards), matching: find.text('3')),
      findsOneWidget,
    );
    expect(find.text('Notas por categoría'), findsOneWidget);
    expect(find.text('Actividad diaria'), findsOneWidget);
    expect(find.text('66,67 %'), findsOneWidget);
  });

  testWidgets('muestra el error y permite reintentar', (tester) async {
    var calls = 0;
    final api = fakeApi((request) async {
      calls++;
      if (calls == 1) {
        return jsonResponse({
          'detail': 'La base de datos no está disponible.',
        }, status: 503);
      }
      return _server(request);
    });

    await tester.pumpWidget(NotesApp(api: api));
    await tester.pumpAndSettle();

    expect(find.text('La base de datos no está disponible.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Aprender FastAPI'), findsOneWidget);
  });

  testWidgets('muestra el estado vacío', (tester) async {
    final api = fakeApi(
      (_) async => jsonResponse({
        'items': <Object>[],
        'total': 0,
        'page': 1,
        'limit': 20,
      }),
    );

    await tester.pumpWidget(NotesApp(api: api));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay notas'), findsOneWidget);
  });
}
