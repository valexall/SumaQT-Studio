"""
modulos/usuarios/repositorio.py
--------------------------------
Capa de acceso a datos para el módulo de usuarios.

El repositorio es el ÚNICO lugar que ejecuta queries SQLAlchemy.
El servicio y las rutas nunca importan ni usan la sesión directamente.
"""

from typing import Sequence

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from modulos.usuarios.modelos import Usuario


class RepositorioUsuarios:
    """Abstrae todas las operaciones de base de datos sobre la tabla `usuarios`."""

    def __init__(self, sesion: AsyncSession) -> None:
        self._sesion = sesion

    async def listar(self) -> Sequence[Usuario]:
        """Devuelve todos los usuarios ordenados por id."""
        resultado = await self._sesion.execute(
            select(Usuario).order_by(Usuario.id)
        )
        return resultado.scalars().all()

    async def obtener_por_id(self, usuario_id: int) -> Usuario | None:
        """Devuelve un usuario por su id, o None si no existe."""
        return await self._sesion.get(Usuario, usuario_id)

    async def obtener_por_email(self, email: str) -> Usuario | None:
        """Devuelve un usuario por su email, o None si no existe."""
        resultado = await self._sesion.execute(
            select(Usuario).where(Usuario.email == email)
        )
        return resultado.scalar_one_or_none()

    async def crear(self, nombre: str, email: str, password_hash: str) -> Usuario:
        """Persiste un nuevo usuario con su hash de contraseña y lo devuelve con su id asignado."""
        usuario = Usuario(nombre=nombre, email=email, password_hash=password_hash)
        self._sesion.add(usuario)
        await self._sesion.flush()   # Obtiene el id generado sin hacer commit
        await self._sesion.refresh(usuario)
        return usuario

    async def eliminar(self, usuario: Usuario) -> None:
        """Elimina el usuario de la base de datos."""
        await self._sesion.delete(usuario)
        await self._sesion.flush()
