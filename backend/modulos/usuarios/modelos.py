"""
modulos/usuarios/modelos.py
---------------------------
Modelo ORM SQLAlchemy para la tabla `usuarios`.

Este archivo es el único que conoce la estructura de la tabla.
El resto de las capas (servicio, rutas) interactúan a través
de los esquemas Pydantic y el repositorio.
"""

from datetime import datetime
from sqlalchemy import Integer, String, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column

from nucleo.base_datos import Base


class Usuario(Base):
    """Entidad persistida en la tabla `usuarios` de MySQL."""

    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(255), nullable=False, unique=True, index=True)
    creado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    def __repr__(self) -> str:
        return f"<Usuario id={self.id} email={self.email!r}>"
