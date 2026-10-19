"""
modulos/usuarios/servicio.py
-----------------------------
Capa de lógica de negocio para el módulo de usuarios y autenticación.

Responsabilidades:
  - Registro de usuarios con hasheo PBKDF2 y validación de duplicados.
  - Autenticación (login) y emisión de tokens JWT firmados.
  - Recuperación de perfil y gestión de usuarios.
"""

from fastapi import HTTPException, status

from nucleo.seguridad import hashear_password, verificar_password, crear_token_acceso
from modulos.usuarios.esquemas import (
    UsuarioRegistro,
    UsuarioLogin,
    TokenRespuesta,
    UsuarioRespuesta,
)
from modulos.usuarios.repositorio import RepositorioUsuarios


class ServicioUsuarios:
    """Encapsula la lógica de negocio y autenticación del módulo de usuarios."""

    def __init__(self, repositorio: RepositorioUsuarios) -> None:
        self._repo = repositorio

    async def registrar(self, datos: UsuarioRegistro) -> TokenRespuesta:
        """
        Registra una nueva cuenta de usuario:
        1. Valida que el email no esté en uso.
        2. Hashea la contraseña con PBKDF2-HMAC-SHA256.
        3. Persiste el usuario en MySQL.
        4. Emite un token JWT de acceso.
        """
        existente = await self._repo.obtener_por_email(datos.email)
        if existente is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Ya existe una cuenta registrada con el email '{datos.email}'.",
            )

        password_hash = hashear_password(datos.password)
        usuario = await self._repo.crear(
            nombre=datos.nombre,
            email=datos.email,
            password_hash=password_hash,
        )

        token = crear_token_acceso({
            "sub": str(usuario.id),
            "email": usuario.email,
            "nombre": usuario.nombre,
        })

        return TokenRespuesta(
            access_token=token,
            usuario=UsuarioRespuesta.model_validate(usuario),
        )

    async def autenticar(self, datos: UsuarioLogin) -> TokenRespuesta:
        """
        Valida las credenciales de acceso:
        1. Busca el usuario por email.
        2. Compara el password usando tiempo constante (constant-time).
        3. Emite un token JWT firmado.
        """
        usuario = await self._repo.obtener_por_email(datos.email)
        if usuario is None or not verificar_password(datos.password, usuario.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Correo electrónico o contraseña incorrectos.",
                headers={"WWW-Authenticate": "Bearer"},
            )

        token = crear_token_acceso({
            "sub": str(usuario.id),
            "email": usuario.email,
            "nombre": usuario.nombre,
        })

        return TokenRespuesta(
            access_token=token,
            usuario=UsuarioRespuesta.model_validate(usuario),
        )

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
