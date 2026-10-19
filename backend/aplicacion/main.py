from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from modulos.usuarios import rutas as rutas_usuarios
from modulos.procesamiento_imagen import rutas as rutas_imagen
from modulos.ordenes import rutas as rutas_ordenes

app = FastAPI(
    title="SumaQt Studio API",
    description="Backend Monolito Modular — Remove BG + Usuarios.",
    version="1.0.0",
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


@app.get("/", tags=["Health"])
def read_root():
    return {"estado": "ok", "servicio": "SumaQt Studio API"}
