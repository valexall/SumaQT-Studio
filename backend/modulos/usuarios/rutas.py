"""
modulos/usuarios/rutas.py
--------------------------
Endpoints HTTP del módulo de usuarios y autenticación.

Endpoints públicos:
  - POST /api/v1/usuarios/registro  → Crea cuenta y devuelve JWT
  - POST /api/v1/usuarios/login     → Inicia sesión y devuelve JWT

Endpoints protegidos:
  - GET  /api/v1/usuarios/me        → Perfil del usuario autenticado vía Bearer Token
  - GET  /api/v1/usuarios/          → Lista de usuarios
  - GET  /api/v1/usuarios/{id}      → Detalle de un usuario
  - DELETE /api/v1/usuarios/{id}   → Elimina un usuario
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from nucleo.base_datos import obtener_sesion
from nucleo.seguridad import decodificar_token_acceso
from modulos.usuarios.esquemas import (
    UsuarioRegistro,
    UsuarioLogin,
    TokenRespuesta,
    UsuarioRespuesta,
)
from modulos.usuarios.repositorio import RepositorioUsuarios
from modulos.usuarios.servicio import ServicioUsuarios

router = APIRouter()
_seguridad_bearer = HTTPBearer(auto_error=False)


def _servicio(sesion: AsyncSession = Depends(obtener_sesion)) -> ServicioUsuarios:
    """Factoría de ServicioUsuarios inyectada por FastAPI en cada petición."""
    return ServicioUsuarios(repositorio=RepositorioUsuarios(sesion))


async def obtener_usuario_actual(
    credenciales: HTTPAuthorizationCredentials | None = Depends(_seguridad_bearer),
    servicio: ServicioUsuarios = Depends(_servicio),
) -> UsuarioRespuesta:
    """Dependencia que extrae y valida el JWT Bearer Token del header Authorization."""
    if not credenciales:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Falta el encabezado de autorización Bearer Token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    payload = decodificar_token_acceso(credenciales.credentials)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de acceso inválido o expirado.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        usuario_id = int(payload["sub"])
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Carga útil del token corrupta.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return await servicio.obtener_por_id(usuario_id)


# ── Rutas de Autenticación ────────────────────────────────────────────────────

@router.post(
    "/registro",
    response_model=TokenRespuesta,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar un nuevo usuario",
)
async def registrar_usuario(
    datos: UsuarioRegistro,
    servicio: ServicioUsuarios = Depends(_servicio),
):
    """Crea una nueva cuenta, hashea la contraseña y emite un token JWT de sesión."""
    return await servicio.registrar(datos)


@router.post(
    "/login",
    response_model=TokenRespuesta,
    summary="Iniciar sesión",
)
async def iniciar_sesion(
    datos: UsuarioLogin,
    servicio: ServicioUsuarios = Depends(_servicio),
):
    """Verifica credenciales (email y password) y retorna un token JWT válido."""
    return await servicio.autenticar(datos)


@router.get(
    "/me",
    response_model=UsuarioRespuesta,
    summary="Obtener perfil del usuario actual (protegido con Bearer Token)",
)
async def obtener_perfil_actual(
    usuario_actual: UsuarioRespuesta = Depends(obtener_usuario_actual),
):
    """Devuelve la información de la cuenta autenticada a partir del token JWT."""
    return usuario_actual


# ── Rutas de Administración / CRUD ───────────────────────────────────────────

@router.get(
    "/",
    response_model=list[UsuarioRespuesta],
    summary="Listar todos los usuarios",
)
async def listar_usuarios(
    servicio: ServicioUsuarios = Depends(_servicio),
):
    return await servicio.listar()


@router.get(
    "/{usuario_id}",
    response_model=UsuarioRespuesta,
    summary="Obtener un usuario por id",
)
async def obtener_usuario(
    usuario_id: int,
    servicio: ServicioUsuarios = Depends(_servicio),
):
    return await servicio.obtener_por_id(usuario_id)


@router.delete(
    "/{usuario_id}",
    summary="Eliminar un usuario por id",
)
async def eliminar_usuario(
    usuario_id: int,
    servicio: ServicioUsuarios = Depends(_servicio),
):
    return await servicio.eliminar(usuario_id)
