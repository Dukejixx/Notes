# Notes API

API REST para consultar notas personales almacenadas en MySQL, construida con
FastAPI y SQLAlchemy 2.0. Esta primera versión ofrece dos endpoints de lectura:

- `GET /api/v1/notes`: listado paginado de notas.
- `GET /api/v1/notes/stats`: métricas agregadas listas para alimentar gráficas.

La arquitectura separa configuración, acceso a datos, modelos, esquemas, lógica
de negocio y endpoints, de modo que las operaciones de creación, edición y
borrado se puedan añadir más adelante sin reestructurar el proyecto.

El repositorio contiene dos partes:

| Parte    | Carpeta                    | Tecnología        | Documentación                          |
|----------|----------------------------|-------------------|----------------------------------------|
| Backend  | raíz (`app/`, `alembic/`…) | FastAPI + MySQL   | este README                            |
| Frontend | [`frontend/`](frontend/)   | Flutter 3.44.9    | [`frontend/README.md`](frontend/README.md) |

## Tecnologías

| Herramienta                 | Uso                                                         |
|-----------------------------|-------------------------------------------------------------|
| Python 3.12 o 3.13          | Lenguaje                                                    |
| FastAPI + Uvicorn           | API REST, OpenAPI y servidor ASGI                           |
| MySQL 8.0 (≥ 8.0.16)        | Base de datos                                               |
| SQLAlchemy 2.0 + PyMySQL    | ORM / consultas y driver de MySQL                           |
| cryptography                | Necesario para el método de autenticación por defecto de MySQL 8 (`caching_sha2_password`) |
| Pydantic + pydantic-settings + python-dotenv | Validación, esquemas y variables de entorno (`.env`) |
| Alembic                     | Migraciones del esquema                                     |
| pytest + HTTPX              | Pruebas automatizadas                                       |
| Ruff                        | Formato y análisis estático                                 |

## Estructura del proyecto

```
.
├── app/
│   ├── main.py                 # Creación de la app, routers y manejo de errores de BD
│   ├── core/
│   │   ├── config.py           # Configuración desde variables de entorno
│   │   └── database.py         # Motor, sesiones y dependencia get_db
│   ├── models/note.py          # Modelo SQLAlchemy (tabla notes)
│   ├── schemas/note.py         # Esquemas Pydantic de respuesta
│   ├── routers/notes.py        # Endpoints /api/v1/notes y /api/v1/notes/stats
│   └── services/note_service.py# Lógica de negocio y consultas agregadas
├── alembic/                    # Entorno y migraciones de Alembic
├── docs/                       # Diagrama y documentación del modelo de datos
├── tests/                      # Pruebas (pytest)
├── frontend/                   # App Flutter (ver frontend/README.md)
├── .env.example                # Plantilla de configuración (sin secretos)
├── alembic.ini
├── pyproject.toml              # Configuración de Ruff y pytest
└── requirements.txt
```

## Requisitos previos

- Python 3.12 o 3.13 (ambas verificadas).
- MySQL Server 8.0.16 o superior en ejecución (por ejemplo, la instalación local
  que administras con MySQL Workbench).
- Git.

Comprueba la versión de Python:

```bash
python3 --version             # Linux / macOS
py --version                  # Windows
py --list                     # Windows: versiones instaladas
```

## Instalación

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd Notes
```

### 2. Crear y activar el entorno virtual

```bash
python3.13 -m venv .venv      # o python3.12
```

En Windows usa `py -3.13 -m venv .venv` (o `py -3.12 -m venv .venv`).

Activarlo en Linux o macOS:

```bash
source .venv/bin/activate
```

Activarlo en Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

> Si PowerShell bloquea el script, ejecuta una vez
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

Con el entorno activo, `python --version` debe mostrar `Python 3.12.x` o `3.13.x`.
El directorio `.venv/` está en `.gitignore` y no se sube al repositorio.

### 3. Instalar las dependencias

```bash
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

### Actualizar las dependencias

Las versiones están fijadas en `requirements.txt` para que todas las
instalaciones sean reproducibles. Para actualizarlas:

```bash
python -m pip list --outdated                 # ver qué paquetes tienen versiones nuevas
python -m pip install --upgrade <paquete>     # actualizar uno concreto
python -m pytest && ruff check .              # comprobar que todo sigue funcionando
python -m pip show <paquete>                # consultar la versión instalada
```

Después, edita la versión correspondiente en `requirements.txt` y haz commit del
cambio. Mantén SQLAlchemy dentro de la serie 2.0.

## Configuración de MySQL

### 1. Crear la base de datos

En MySQL Workbench, abre tu conexión local (por defecto `localhost:3306`, usuario
`root`), abre una pestaña de consultas (*File → New Query Tab*) y ejecuta:

```sql
CREATE DATABASE IF NOT EXISTS notes_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

También puedes hacerlo desde la terminal:

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS notes_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

La aplicación **no** crea bases de datos ni usuarios ni modifica privilegios:
estos pasos son manuales.

### 2. Usuario y permisos (recomendado)

Para empezar puedes usar `root`, pero lo recomendable es un usuario exclusivo de
la aplicación con los privilegios mínimos sobre sus bases de datos. Ejecútalo
como `root` en MySQL Workbench y cambia la contraseña de ejemplo:

```sql
CREATE USER 'notes_app'@'localhost' IDENTIFIED BY 'cambia-esta-contraseña';

-- Lectura/escritura de datos y cambios de esquema (necesarios para las migraciones).
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP, REFERENCES
  ON notes_db.* TO 'notes_app'@'localhost';

-- Solo si vas a ejecutar las pruebas con este usuario:
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP, REFERENCES
  ON notes_test_db.* TO 'notes_app'@'localhost';
```

En producción conviene separar responsabilidades: un usuario con permisos de
esquema solo para ejecutar las migraciones y otro, usado por la API, con
`SELECT, INSERT, UPDATE, DELETE`. La versión actual solo necesita `SELECT` para
servir los endpoints.

### 3. Configurar el archivo `.env`

```bash
cp .env.example .env          # Linux / macOS
Copy-Item .env.example .env   # Windows PowerShell
```

Edita `.env` con los datos de tu instalación:

```dotenv
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=tu-contraseña-local
DB_NAME=notes_db
TEST_DB_NAME=notes_test_db
```

- `.env` está en `.gitignore`: **nunca** lo subas al repositorio.
- La contraseña puede contener caracteres especiales (`@`, `:`, `/`, `#`, `%`…):
  la URL de conexión se construye con `sqlalchemy.engine.URL.create`, que los
  escapa correctamente. No hace falta codificarla.
- Las variables de entorno del sistema tienen prioridad sobre `.env`.
- Si tu `root` local no tiene contraseña, deja `DB_PASSWORD=` vacío.
- `CORS_ORIGIN_REGEX` (opcional) define desde qué orígenes web se puede llamar a
  la API. Ver [CORS](#cors-y-frontend-web).

## Migraciones

Crea la tabla `notes` aplicando las migraciones (desde la raíz del proyecto, con
el entorno virtual activo):

```bash
alembic upgrade head
```

Alembic lee la conexión de `.env` a través de `app/core/config.py`;
`alembic.ini` no contiene credenciales.

Otros comandos útiles:

```bash
alembic current                                   # revisión aplicada
alembic history                                   # historial de migraciones
alembic check                                     # ¿coinciden modelos y migraciones?
alembic revision --autogenerate -m "descripcion"  # nueva migración tras cambiar app/models
alembic downgrade -1                              # deshacer la última migración
alembic upgrade head --sql                        # ver el SQL sin ejecutarlo
```

Revisa siempre a mano las migraciones generadas con `--autogenerate` antes de
aplicarlas. El esquema se gestiona exclusivamente con Alembic; la aplicación no
ejecuta `Base.metadata.create_all()`.

## Ejecutar la aplicación

```bash
python -m uvicorn app.main:app --reload
```

- Swagger UI: <http://127.0.0.1:8000/docs>
- ReDoc: <http://127.0.0.1:8000/redoc>
- Esquema OpenAPI: <http://127.0.0.1:8000/openapi.json>

Al arrancar, la aplicación comprueba la conexión con MySQL. Si falla, muestra un
mensaje claro en el log (sin la contraseña) y sigue en marcha; los endpoints
responden `503` hasta que MySQL esté disponible.

### CORS y frontend web

Los navegadores solo permiten que una página llame a la API si esta autoriza su
origen. Por defecto se autorizan `http://localhost` y `http://127.0.0.1` en
cualquier puerto (Flutter web usa un puerto aleatorio en desarrollo), solo con
el método `GET` y sin credenciales. Para servir el frontend desde otro dominio,
define en `.env` una expresión regular, por ejemplo:

```dotenv
CORS_ORIGIN_REGEX=^https://notas\.midominio\.com$
```

Las apps de escritorio y móviles no están sujetas a CORS.

### Datos de ejemplo

Para cargar datos de prueba, inserta algunas notas desde MySQL Workbench:

```sql
USE notes_db;
SET time_zone = '+00:00';  -- la API trabaja en UTC
INSERT INTO notes (title, content, category) VALUES
  ('Aprender FastAPI', 'Estudiar endpoints y dependencias', 'Estudio'),
  ('Comprar pan', 'Integral', 'Personal');
```

## Endpoints

Todas las rutas usan el prefijo `/api/v1`, de modo que una versión futura
(`/api/v2`) pueda convivir con esta sin romper a los clientes existentes.

### `GET /api/v1/notes` — listar notas

Devuelve las notas ordenadas por `created_at` descendente (las más recientes
primero); si dos notas tienen la misma fecha, va primero la de `id` mayor, para
que el orden sea estable entre páginas.

| Parámetro | Tipo   | Por defecto | Reglas         |
|-----------|--------|-------------|----------------|
| `page`    | entero | `1`         | `>= 1`         |
| `limit`   | entero | `10`        | `1` a `100`    |

Solicitud:

```bash
curl "http://127.0.0.1:8000/api/v1/notes?page=1&limit=10"
```

Respuesta `200`:

```json
{
  "items": [
    {
      "id": 1,
      "title": "Aprender FastAPI",
      "content": "Estudiar endpoints y dependencias",
      "category": "Estudio",
      "created_at": "2026-10-05T10:30:00",
      "updated_at": "2026-10-05T10:30:00"
    }
  ],
  "total": 1,
  "page": 1,
  "limit": 10
}
```

- `total` es el número total de notas almacenadas (no solo las de la página).
- Una página posterior a la última devuelve `items: []` con código `200`.
- Las fechas están en UTC (formato ISO 8601 sin sufijo de zona horaria).

### `GET /api/v1/notes/stats` — estadísticas para gráficas

| Parámetro   | Tipo                 | Obligatorio | Descripción                 |
|-------------|----------------------|-------------|-----------------------------|
| `from_date` | fecha (`YYYY-MM-DD`) | No          | Primer día incluido (UTC)   |
| `to_date`   | fecha (`YYYY-MM-DD`) | No          | Último día incluido (UTC)   |

Solicitud:

```bash
curl "http://127.0.0.1:8000/api/v1/notes/stats?from_date=2026-10-01&to_date=2026-10-03"
```

Respuesta `200`:

```json
{
  "total_notes": 3,
  "by_category": [
    { "category": "Estudio", "count": 2, "percentage": 66.67 },
    { "category": "Personal", "count": 1, "percentage": 33.33 }
  ],
  "activity": [
    { "date": "2026-10-01", "count": 2 },
    { "date": "2026-10-02", "count": 0 },
    { "date": "2026-10-03", "count": 1 }
  ],
  "most_used_category": "Estudio"
}
```

Reglas de cálculo:

- **Zona horaria:** todas las fechas se interpretan en **UTC**. `from_date=2026-10-02`
  incluye desde `2026-10-02 00:00:00` y `to_date=2026-10-04` incluye hasta
  `2026-10-04 23:59:59` (internamente, `created_at < 2026-10-05 00:00:00`).
- **Alcance común:** `total_notes`, `by_category`, `activity` y
  `most_used_category` se calculan sobre las mismas notas (las creadas en el
  período indicado, o todas si no se indica ninguno).
- **`by_category`:** ordenado por `count` descendente y, en caso de empate, por
  nombre. `percentage = count / total_notes × 100`, redondeado a 2 decimales;
  por el redondeo, la suma puede diferir de 100 en ±0,01 por categoría.
  Las categorías se agrupan sin distinguir mayúsculas (`Estudio` = `estudio`).
- **`most_used_category`:** la primera de `by_category` (la de más notas; si hay
  empate, la primera en orden alfabético). `null` si no hay notas en el alcance.
- **`activity`:** número de notas por día de creación (UTC), en orden
  cronológico y **sin huecos**: los días sin notas aparecen con `count: 0`.
  - Con `from_date` y `to_date`: cubre el intervalo completo.
  - En otro caso: cubre desde el primer hasta el último día con notas dentro del
    alcance.
- **Sin notas en el alcance:** `{"total_notes": 0, "by_category": [], "activity": [], "most_used_category": null}`.
- **Validación (`422`):** fechas con formato no válido, `from_date` posterior a
  `to_date` o intervalos de más de 366 días (para limitar el tamaño de la serie).
- Las agregaciones (`COUNT`, `GROUP BY category`, `GROUP BY DATE(created_at)`)
  se ejecutan en MySQL. Python solo calcula los porcentajes y rellena los días
  sin notas.

### Códigos de error

| Código | Cuándo                                       | Cuerpo                                                       |
|--------|----------------------------------------------|--------------------------------------------------------------|
| `422`  | Parámetros no válidos                         | Detalle de validación de FastAPI o `{"detail": "..."}`       |
| `503`  | MySQL no disponible (conexión rechazada, credenciales incorrectas, base inexistente…) | `{"detail": "La base de datos no está disponible. Inténtalo de nuevo más tarde."}` |
| `500`  | Otro error de acceso a datos (p. ej. falta la tabla porque no se aplicaron las migraciones) | `{"detail": "Error interno al acceder a los datos."}` |

Las respuestas de error nunca incluyen el host, el usuario, la contraseña ni la
consulta SQL. El detalle técnico (sin credenciales) se registra en el log del
servidor.

## Pruebas

Las pruebas usan una **base de datos MySQL aislada** (`TEST_DB_NAME`, por
defecto `notes_test_db`) y nunca tocan `DB_NAME`. Al empezar recrean el esquema
con las migraciones de Alembic y vacían la tabla `notes` antes de cada prueba.
Como salvaguarda, se cancelan si `TEST_DB_NAME` coincide con `DB_NAME` o no
contiene la palabra `test`.

1. Crea la base de datos de pruebas (una sola vez):

   ```sql
   CREATE DATABASE IF NOT EXISTS notes_test_db
     CHARACTER SET utf8mb4
     COLLATE utf8mb4_unicode_ci;
   ```

   Si usas un usuario distinto de `root`, concédele los permisos indicados en
   [Usuario y permisos](#2-usuario-y-permisos-recomendado).

2. Ejecuta las pruebas:

   ```bash
   python -m pytest
   ```

Si MySQL no está disponible, las pruebas que lo necesitan se marcan como
**omitidas** (`SKIPPED`) e indican el motivo; las de manejo de errores de
conexión (`tests/test_database_errors.py`) se ejecutan siempre. Una ejecución
con pruebas omitidas no verifica los endpoints.

| Archivo                         | Qué verifica |
|---------------------------------|--------------|
| `tests/test_notes.py`           | Respuesta vacía, campos públicos, orden, paginación, límites y parámetros no válidos, fecha de creación asignada por MySQL en UTC |
| `tests/test_note_stats.py`      | Conteos, porcentajes, empates, filtros de fechas (límites incluidos), días sin notas, respuesta vacía, intervalos no válidos |
| `tests/test_database_errors.py` | `503` con MySQL inaccesible y `500` ante otros errores, sin filtrar datos sensibles |
| `tests/test_cors.py`            | Orígenes permitidos y rechazados, y solo método `GET` |

### Calidad del código

```bash
ruff check .           # análisis estático
ruff format .          # formato
```

## Frontend (Flutter)

La app Flutter de [`frontend/`](frontend/) consume los dos endpoints: listado de
notas con detalle y panel de estadísticas con gráficas. Arranque rápido, con el
backend en marcha:

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Configuración de la URL de la API, emulador de Android, móvil físico, builds y
pruebas: [`frontend/README.md`](frontend/README.md).

## Diagrama de la base de datos

- `docs/database_diagram.mmd`: diagrama en formato Mermaid. GitHub lo muestra
  renderizado; también puedes pegarlo en <https://mermaid.live>.
- `docs/database_diagram.svg`: versión renderizada.
- `docs/database_diagram.md`: explicación de campos, restricciones, índices y
  decisiones de diseño.

Para regenerar el SVG tras modificar el `.mmd` (requiere Node.js):

```bash
npx -p @mermaid-js/mermaid-cli mmdc -i docs/database_diagram.mmd -o docs/database_diagram.svg -b white
```

## Limitaciones conocidas

- Solo hay endpoints de lectura: crear, editar y borrar notas se hace por ahora
  directamente en MySQL; el frontend solo consulta.
- Sin autenticación: todas las notas son visibles para cualquier cliente con
  acceso a la API. No la expongas fuera de tu equipo en este estado.
- Las fechas se manejan en UTC; las estadísticas no admiten otra zona horaria.
- El intervalo explícito de estadísticas está limitado a 366 días.
- Paginación por desplazamiento (`OFFSET`): es sencilla, pero pierde eficiencia
  con páginas muy profundas.
- `starlette.testclient` (Starlette 1.7) emite un aviso que recomienda `httpx2`;
  se mantiene `httpx` porque es la herramienta de pruebas requerida y funciona
  correctamente.

## Funcionalidades futuras

- Endpoints `POST`, `PUT/PATCH` y `DELETE` de notas, con esquemas de entrada
  que reutilicen `TITLE_MAX_LENGTH` y `CATEGORY_MAX_LENGTH`.
- Filtros del listado por categoría y por fechas (aprovechando los índices existentes).
- Autenticación y notas por usuario (tabla `users` y clave foránea en `notes`).
- Parámetro de zona horaria para las estadísticas.
- Integración continua con un servicio MySQL para ejecutar las pruebas en cada cambio.
