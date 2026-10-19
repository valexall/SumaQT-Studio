from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager

from modulos.usuarios import rutas as rutas_usuarios
from modulos.procesamiento_imagen import rutas as rutas_imagen
from modulos.ordenes import rutas as rutas_ordenes
from nucleo import almacenamiento_local
from nucleo.base_datos import engine, Base

# Importar modelos para que SQLAlchemy los registre en Base.metadata
import modulos.usuarios.modelos  # noqa: F401
import modulos.ordenes.modelos  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Crea las tablas en MySQL al iniciar la aplicación (si no existen).
    En producción se recomienda usar Alembic para migraciones.
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Limpieza al apagar (opcional)
    await engine.dispose()


app = FastAPI(
    title="SumaQt Studio API",
    description="Backend Monolito Modular — Remove BG + Usuarios + Órdenes (MySQL).",
    version="1.1.0",
    lifespan=lifespan,
)

# CORS para el frontend Flutter Desktop / Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Módulos registrados
app.include_router(
    rutas_usuarios.router,
    prefix="/api/v1/usuarios",
    tags=["Usuarios"],
)
app.include_router(
    rutas_imagen.router,
    prefix="/api/v1/imagenes",
    tags=["Procesamiento de Imagen"],
)
app.include_router(
    rutas_ordenes.router,
    prefix="/api/v1/ordenes",
    tags=["Órdenes de Trabajo"],
)

# Archivos de las órdenes (original + procesado) servidos desde disco local
almacenamiento_local.asegurar_directorio()
app.mount(
    "/archivos",
    StaticFiles(directory=str(almacenamiento_local.directorio())),
    name="archivos",
)


@app.get("/", tags=["Health"])
def read_root():
    return {"estado": "ok", "servicio": "SumaQt Studio API"}
