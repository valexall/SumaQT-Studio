"""
modulos/ordenes/modelos.py
--------------------------
Modelos ORM SQLAlchemy para las tablas `ordenes` y `archivos_orden`.

Este archivo es el único que conoce la estructura de las tablas.
El resto de las capas (servicio, rutas) interactúan a través
de los esquemas Pydantic y el repositorio.
"""

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from nucleo.base_datos import Base


class Orden(Base):
    """Entidad persistida en la tabla `ordenes` de MySQL."""

    __tablename__ = "ordenes"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    nombre_proyecto: Mapped[str] = mapped_column(String(120), nullable=False)
    cliente_nombre: Mapped[str] = mapped_column(String(120), nullable=False)
    cliente_email: Mapped[str] = mapped_column(String(255), nullable=False)
    total_imagenes: Mapped[int] = mapped_column(Integer, nullable=False)
    imagenes_procesadas: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0
    )
    estado: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pendiente"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    cerrada_en: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    archivos: Mapped[list["ArchivoOrden"]] = relationship(
        back_populates="orden",
        cascade="all, delete-orphan",
        passive_deletes=True,
        lazy="selectin",
        order_by="ArchivoOrden.created_at",
    )

    def __repr__(self) -> str:
        return f"<Orden id={self.id} estado={self.estado!r}>"


class ArchivoOrden(Base):
    """Imagen asociada a una orden (original y resultado sin fondo)."""

    __tablename__ = "archivos_orden"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    orden_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("ordenes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    nombre_original: Mapped[str] = mapped_column(String(255), nullable=False)
    storage_path_original: Mapped[str | None] = mapped_column(String(500))
    storage_path_resultado: Mapped[str | None] = mapped_column(String(500))
    estado: Mapped[str] = mapped_column(
        String(20), nullable=False, default="procesado"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    orden: Mapped["Orden"] = relationship(back_populates="archivos")

    def __repr__(self) -> str:
        return f"<ArchivoOrden id={self.id} orden_id={self.orden_id}>"
