"""
modulos/usuarios/esquemas.py
-----------------------------
Esquemas Pydantic para el módulo de usuarios y autenticación.

- UsuarioRegistro: datos de entrada para registrarse (nombre, email, password).
- UsuarioLogin: credenciales para iniciar sesión (email, password).
- TokenRespuesta: respuesta de autenticación con JWT token y usuario.
- UsuarioRespuesta: representación pública del usuario (sin password_hash).
"""

from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class UsuarioRegistro(BaseModel):
    """Payload para registrar una nueva cuenta de usuario."""

    nombre: str = Field(..., min_length=2, max_length=120, examples=["Ana García"])
    email: EmailStr = Field(..., examples=["ana@ejemplo.com"])
    password: str = Field(..., min_length=6, max_length=100, examples=["Secreto123!"])


class UsuarioLogin(BaseModel):
    """Payload para autenticarse en el sistema."""

    email: EmailStr = Field(..., examples=["ana@ejemplo.com"])
    password: str = Field(..., min_length=1, examples=["Secreto123!"])


# Mantener compatibilidad con UsuarioCrear si fuera necesario
class UsuarioCrear(BaseModel):
    nombre: str = Field(..., min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(..., min_length=6)


class UsuarioRespuesta(BaseModel):
    """Representación pública del usuario."""

    id: int
    nombre: str
    email: str
    creado_en: datetime

    model_config = {"from_attributes": True}


class TokenRespuesta(BaseModel):
    """Respuesta con token JWT emitida tras login o registro exitoso."""

    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioRespuesta
