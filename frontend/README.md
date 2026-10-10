# Notas — frontend Flutter

Aplicación Flutter para consultar la API de notas del backend (carpeta raíz del
repositorio). Funciona en web, Android, iOS, Windows, macOS y Linux.

## Funcionalidades

- **Notas:** listado ordenado de la más reciente a la más antigua, con carga
  progresiva al desplazarse (paginación de la API), "deslizar para recargar" y
  pantalla de detalle.
- **Estadísticas:** total de notas, categoría más usada, gráfica circular por
  categoría, gráfica de actividad diaria y filtro por período (máximo 366 días,
  igual que la API).
- Estados de carga, vacío y error con botón de reintento; mensajes en español.
- Diseño adaptable: barra inferior en móvil y barra lateral y gráficas en dos
  columnas en pantallas anchas. Tema claro y oscuro según el sistema.

La API actual solo ofrece lectura, así que la app no crea, edita ni borra notas.

## Requisitos

- Flutter **3.44.9** (Dart 3.12.2). Comprueba con `flutter --version`.
- El backend en marcha (`python -m uvicorn app.main:app --reload` desde la raíz
  del repositorio). Ver el [README principal](../README.md).

## Puesta en marcha

```bash
cd frontend
flutter pub get
flutter run -d chrome          # web
flutter run -d windows         # o macos / linux
flutter run                    # dispositivo o emulador conectado
```

`flutter devices` muestra los dispositivos disponibles.

### URL de la API

Por defecto la app llama a `http://127.0.0.1:8000`. Se cambia sin tocar el
código con `--dart-define`:

| Dónde se ejecuta la app       | Comando                                                                 |
|-------------------------------|-------------------------------------------------------------------------|
| Web, escritorio, simulador iOS | `flutter run` (valor por defecto)                                       |
| Emulador de Android           | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`           |
| Móvil físico en tu red Wi-Fi  | `flutter run --dart-define=API_BASE_URL=http://<IP-de-tu-PC>:8000`      |

En el emulador de Android, `localhost` es el propio emulador; `10.0.2.2` es tu
equipo. Para un móvil físico, arranca el backend escuchando en la red:
`python -m uvicorn app.main:app --host 0.0.0.0 --port 8000` y permite el puerto
8000 en el cortafuegos.

### Notas por plataforma

- **Web:** el backend permite CORS desde `http://localhost` y `http://127.0.0.1`
  en cualquier puerto (variable `CORS_ORIGIN_REGEX` del backend). Si sirves la
  web desde otro dominio, añádelo a esa variable.
- **Android:** el HTTP sin cifrar solo está permitido en las builds *debug*
  (`android/app/src/debug/AndroidManifest.xml`). Una build *release* necesita
  la API con HTTPS.
- **iOS:** `NSAllowsLocalNetworking` permite HTTP solo hacia la red local.
- **macOS:** la app tiene el permiso `com.apple.security.network.client`.

## Compilar

```bash
flutter build web --release
flutter build apk --release --dart-define=API_BASE_URL=https://tu-api
flutter build windows --release
```

Flutter web descarga su motor de dibujo (CanvasKit) desde el CDN de Google. Si
el equipo no tiene acceso a internet, incluye el motor en la build con
`flutter build web --no-web-resources-cdn`.

Para probar la build web localmente:

```bash
python -m http.server 5173 -d build/web    # y abre http://localhost:5173
```

## Pruebas y calidad

```bash
flutter analyze
flutter test
dart format lib test
```

Las pruebas no necesitan el backend: simulan la API con `MockClient`.

| Archivo                         | Qué verifica |
|---------------------------------|--------------|
| `test/models_test.dart`         | Lectura del JSON, fechas UTC y paginación |
| `test/notes_api_test.dart`      | URLs y parámetros, UTF-8, errores 422/503, servidor caído y respuestas mal formadas |
| `test/stats_controller_test.dart` | Filtro de período y límite de 366 días |
| `test/widget_test.dart`         | Listado, detalle, panel de estadísticas, estado vacío y reintento tras un error |

## Estructura

```
lib/
├── main.dart                     # Crea el cliente HTTP y arranca la app
├── app.dart                      # Tema, idioma y navegación adaptable
├── config/app_config.dart        # URL de la API (--dart-define) y tiempo de espera
├── core/api_client.dart          # GET + JSON + traducción de errores (ApiException)
├── models/                       # Note, NotePage, NoteStats y fechas UTC
├── services/notes_api.dart       # Los dos endpoints de /api/v1/notes
├── features/
│   ├── notes/                    # Controlador, listado, detalle y tarjetas
│   └── stats/                    # Controlador, panel y gráficas (fl_chart)
└── shared/                       # Formatos, colores por categoría y vistas de estado
```

- Los controladores (`ChangeNotifier`) contienen el estado y la lógica; las
  pantallas solo los muestran. No se usan librerías de gestión de estado.
- Las dependencias se pasan por constructor (`NotesApi` → controladores), lo que
  permite probarlas con una API simulada.
- Las fechas llegan de la API en UTC y se muestran en la hora local del
  dispositivo. La serie de actividad se agrupa por día UTC, como en el backend.

Dependencias: `http`, `fl_chart` y `flutter_localizations` (calendario en español).
