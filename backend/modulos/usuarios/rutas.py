"""
modulos/usuarios/rutas.py
--------------------------
Endpoints HTTP del módulo de usuarios.

Esta capa solo:
  1. Recibe y valida el request (Pydantic lo hace automáticamente).
  2. Construye el servicio inyectando el repositorio con la sesión.
  3. Llama al servicio y devuelve la respuesta.

No contiene lógica de negocio ni acceso directo a la BD.
"""

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from nucleo.base_datos import obtener_sesion
from modulos.usuarios.esquemas import UsuarioCrear, UsuarioRespuesta
from modulos.usuarios.repositorio import RepositorioUsuarios
from modulos.usuarios.servicio import ServicioUsuarios

router = APIRouter()


def _servicio(sesion: AsyncSession = Depends(obtener_sesion)) -> ServicioUsuarios:
    """Factoría de ServicioUsuarios inyectada por FastAPI en cada petición."""
    return ServicioUsuarios(repositorio=RepositorioUsuarios(sesion))


@router.get(
    "/",
    response_model=list[UsuarioRespuesta],
    summary="Listar todos los usuarios",
)
async def listar_usuarios(
    servicio: ServicioUsuarios = Depends(_servicio),
):
    return await servicio.listar()


@router.post(
    "/",
    response_model=UsuarioRespuesta,
    status_code=status.HTTP_201_CREATED,
    summary="Crear un usuario nuevo",
)
async def crear_usuario(
    datos: UsuarioCrear,
    servicio: ServicioUsuarios = Depends(_servicio),
):
    return await servicio.crear(datos)


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
