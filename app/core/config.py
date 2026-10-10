"""Configuración centralizada de la aplicación a partir de variables de entorno."""

from functools import lru_cache

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import URL


class Settings(BaseSettings):
    """Valores leídos de variables de entorno o del archivo `.env`.

    Las variables de entorno del sistema tienen prioridad sobre `.env`.
    """

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "Notes API"
    api_v1_prefix: str = "/api/v1"

    db_host: str = "localhost"
    db_port: int = Field(default=3306, ge=1, le=65535)
    db_user: str = "root"
    # SecretStr evita que la contraseña aparezca al imprimir o registrar la configuración.
    db_password: SecretStr = SecretStr("")
    db_name: str = "notes_db"

    def database_url(self, database: str | None = None) -> URL:
        """Construye la URL de conexión escapando correctamente la contraseña.

        `URL.create` evita los errores de concatenar cadenas cuando la contraseña
        contiene caracteres como `@`, `:`, `/` o `#`.
        """
        return URL.create(
            drivername="mysql+pymysql",
            username=self.db_user,
            password=self.db_password.get_secret_value() or None,
            host=self.db_host,
            port=self.db_port,
            database=database or self.db_name,
            query={"charset": "utf8mb4"},
        )


@lru_cache
def get_settings() -> Settings:
    """Devuelve una instancia única de la configuración."""
    return Settings()
