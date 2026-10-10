/// Configuración de la aplicación definida en tiempo de compilación.
///
/// La URL de la API se cambia sin tocar el código:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// Tiempo máximo de espera de cada petición HTTP.
  static const Duration requestTimeout = Duration(seconds: 10);
}
