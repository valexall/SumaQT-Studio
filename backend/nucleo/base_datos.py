"""
nucleo/base_datos.py
--------------------
Motor async de SQLAlchemy para MySQL (aiomysql).

- AsyncEngine: creado una sola vez al importar el módulo.
- AsyncSessionLocal: fábrica de sesiones async.
- Base: clase base declarativa para todos los modelos ORM.
- obtener_sesion(): dependencia FastAPI que abre y cierra la sesión por petición.
"""

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase
from typing import AsyncGenerator

from nucleo.configuracion import obtener_configuracion

_config = obtener_configuracion()

# ── Motor ──────────────────────────────────────────────────────────────────────
engine = create_async_engine(
    _config.MYSQL_URL,
    echo=False,        # Cambiar a True para ver SQL en consola durante desarrollo
    pool_pre_ping=True,  # Reconecta automáticamente si la conexión fue cerrada
    pool_recycle=3600,   # Recicla conexiones cada hora
)

# ── Fábrica de sesiones ────────────────────────────────────────────────────────
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# ── Base declarativa compartida por todos los modelos ORM ─────────────────────
class Base(DeclarativeBase):
    pass


# ── Dependencia FastAPI ────────────────────────────────────────────────────────
async def obtener_sesion() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependencia inyectable en los routers de FastAPI.

    Uso:
        @router.get("/")
        async def endpoint(sesion: AsyncSession = Depends(obtener_sesion)):
            ...
    """
    async with AsyncSessionLocal() as sesion:
        try:
            yield sesion
            await sesion.commit()
        except Exception:
            await sesion.rollback()
            raise
