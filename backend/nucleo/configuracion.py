from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Configuracion(BaseSettings):
    # ── MySQL ────────────────────────────────────────────────────────────────
    MYSQL_HOST: str = "localhost"
    MYSQL_PORT: int = 3306
    MYSQL_USER: str = "root"
    MYSQL_PASSWORD: str = "root"
    MYSQL_DB: str = "sumaqt_studio"

    @property
    def MYSQL_URL(self) -> str:
        """URL de conexión async para SQLAlchemy + aiomysql."""
        return (
            f"mysql+aiomysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}"
            f"@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DB}"
        )

    # ── Almacenamiento local ──────────────────────────────────────────────────
    # Carpeta donde se guardan los archivos de las órdenes (original + procesado).
    # Se sirve al cliente mediante el montaje estático `/archivos`.
    STORAGE_DIR: str = "almacenamiento"

    # ── JWT Auth ─────────────────────────────────────────────────────────────
    JWT_SECRET: str = "sumaqt_studio_super_secret_jwt_key_2026_xyz"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_MINUTES: int = 60 * 24 * 7  # 7 días

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
    )


@lru_cache()
def obtener_configuracion() -> Configuracion:
    return Configuracion()
