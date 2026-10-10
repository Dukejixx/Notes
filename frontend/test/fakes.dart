import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notes_app/core/api_client.dart';
import 'package:notes_app/services/notes_api.dart';

/// Nota en el formato JSON de la API.
Map<String, Object?> noteJson(
  int id, {
  String category = 'Estudio',
  String? title,
}) => {
  'id': id,
  'title': title ?? 'Nota $id',
  'content': 'Contenido de la nota $id',
  'category': category,
  'created_at': '2026-10-01T10:30:00',
  'updated_at': '2026-10-01T10:30:00',
};

const statsJson = {
  'total_notes': 3,
  'by_category': [
    {'category': 'Estudio', 'count': 2, 'percentage': 66.67},
    {'category': 'Personal', 'count': 1, 'percentage': 33.33},
  ],
  'activity': [
    {'date': '2026-10-01', 'count': 2},
    {'date': '2026-10-02', 'count': 0},
    {'date': '2026-10-03', 'count': 1},
  ],
  'most_used_category': 'Estudio',
};

/// Respuesta JSON codificada en UTF-8, como la envía FastAPI.
http.Response jsonResponse(Object body, {int status = 200}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

/// API sobre un servidor simulado que atiende los dos endpoints.
NotesApi fakeApi(Future<http.Response> Function(http.Request request) handler) {
  final client = ApiClient(
    baseUrl: 'http://api.test',
    timeout: const Duration(seconds: 2),
    httpClient: MockClient(handler),
  );
  return NotesApi(client);
}
