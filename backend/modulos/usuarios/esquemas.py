"""
modulos/usuarios/esquemas.py
-----------------------------
Esquemas Pydantic para el módulo de usuarios.

- UsuarioCrear:    datos de entrada para crear un usuario (request body).
- UsuarioRespuesta: datos de salida devueltos al cliente (response model).

Estos esquemas son independientes del ORM; la conversión
ORM ↔ Pydantic ocurre en el repositorio/servicio.
"""

from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class UsuarioCrear(BaseModel):
    """Payload recibido al crear un usuario nuevo."""

    nombre: str = Field(..., min_length=2, max_length=120, examples=["Ana García"])
    email: EmailStr = Field(..., examples=["ana@ejemplo.com"])


class UsuarioRespuesta(BaseModel):
    """Representación del usuario devuelta al cliente."""

    id: int
    nombre: str
    email: str
    creado_en: datetime

    model_config = {"from_attributes": True}  # Permite model_validate(orm_obj)
