import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error de comunicación con la API con un mensaje apto para el usuario.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Cliente HTTP mínimo para la API REST: construye URLs, aplica el tiempo de
/// espera y traduce los errores a [ApiException].
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.timeout,
    http.Client? httpClient,
  }) : _baseUri = Uri.parse(baseUrl),
       _http = httpClient ?? http.Client();

  final Uri _baseUri;
  final Duration timeout;
  final http.Client _http;

  /// Realiza un GET y devuelve el cuerpo JSON decodificado.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _baseUri.replace(
      path: '${_baseUri.path}$path',
      queryParameters: (queryParameters?.isEmpty ?? true)
          ? null
          : queryParameters,
    );

    final http.Response response;
    try {
      response = await _http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw const ApiException(
        'No se pudo conectar con la API. Comprueba que el servidor esté en marcha.',
      );
    }

    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      throw const ApiException('La API devolvió una respuesta inesperada.');
    }
    throw ApiException(
      _errorMessage(response.statusCode, body),
      statusCode: response.statusCode,
    );
  }

  void close() => _http.close();

  static Object? _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      // utf8 explícito: el cuerpo trae tildes y eñes.
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  static String _errorMessage(int statusCode, Object? body) {
    // FastAPI devuelve {"detail": "texto"} o {"detail": [errores de validación]}.
    final detail = body is Map<String, dynamic> ? body['detail'] : null;
    if (detail is String && detail.isNotEmpty) return detail;
    return switch (statusCode) {
      422 => 'Los parámetros de la consulta no son válidos.',
      503 => 'La base de datos no está disponible. Inténtalo más tarde.',
      >= 500 => 'Error interno del servidor.',
      _ => 'Error inesperado ($statusCode).',
    };
  }
}
