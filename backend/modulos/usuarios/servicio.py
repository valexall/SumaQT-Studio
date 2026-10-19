"""
modulos/usuarios/servicio.py
-----------------------------
Capa de lógica de negocio para el módulo de usuarios.

Responsabilidades:
  - Validar reglas de negocio (e.g. email duplicado).
  - Orquestar llamadas al repositorio.
  - Lanzar excepciones HTTP con mensajes claros.

Las rutas solo llaman métodos de este servicio.
"""

from fastapi import HTTPException, status

from modulos.usuarios.esquemas import UsuarioCrear, UsuarioRespuesta
from modulos.usuarios.repositorio import RepositorioUsuarios


class ServicioUsuarios:
    """Encapsula la lógica de negocio del módulo de usuarios."""

    def __init__(self, repositorio: RepositorioUsuarios) -> None:
        self._repo = repositorio

    async def listar(self) -> list[UsuarioRespuesta]:
        """Devuelve la lista completa de usuarios."""
        usuarios = await self._repo.listar()
        return [UsuarioRespuesta.model_validate(u) for u in usuarios]

    async def obtener_por_id(self, usuario_id: int) -> UsuarioRespuesta:
        """Devuelve un usuario por id o lanza 404."""
        usuario = await self._repo.obtener_por_id(usuario_id)
        if usuario is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario con id={usuario_id} no encontrado.",
            )
        return UsuarioRespuesta.model_validate(usuario)

    async def crear(self, datos: UsuarioCrear) -> UsuarioRespuesta:
        """Crea un nuevo usuario validando que el email no exista."""
        existente = await self._repo.obtener_por_email(datos.email)
        if existente is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Ya existe un usuario con el email '{datos.email}'.",
            )
        usuario = await self._repo.crear(nombre=datos.nombre, email=datos.email)
        return UsuarioRespuesta.model_validate(usuario)

    async def eliminar(self, usuario_id: int) -> dict:
        """Elimina un usuario por id o lanza 404."""
        usuario = await self._repo.obtener_por_id(usuario_id)
        if usuario is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Usuario con id={usuario_id} no encontrado.",
            )
        await self._repo.eliminar(usuario)
        return {"mensaje": f"Usuario id={usuario_id} eliminado correctamente."}
