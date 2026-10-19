"""
modulos/ordenes/repositorio.py
-------------------------------
Capa de acceso a datos para el módulo de órdenes.

El repositorio es el ÚNICO lugar que ejecuta queries SQLAlchemy.
El servicio y las rutas nunca importan ni usan la sesión directamente.
"""

import uuid
from typing import Any, Sequence

from sqlalchemy import case, delete, func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from modulos.ordenes.modelos import ArchivoOrden, Orden


class RepositorioOrdenes:
    """Abstrae todas las operaciones sobre `ordenes` y `archivos_orden`."""

    def __init__(self, sesion: AsyncSession) -> None:
        self._sesion = sesion

    # ── Órdenes ───────────────────────────────────────────────────────────────

    async def crear(self, datos: dict[str, Any]) -> Orden:
        """Persiste una nueva orden (id UUID generado en Python) y la devuelve."""
        orden = Orden(id=str(uuid.uuid4()), **datos)
        self._sesion.add(orden)
        await self._sesion.flush()
        await self._sesion.refresh(orden)
        return orden

    async def listar(self) -> Sequence[Orden]:
        """Devuelve todas las órdenes de la más reciente a la más antigua."""
        resultado = await self._sesion.execute(
            select(Orden).order_by(Orden.created_at.desc())
        )
        return resultado.scalars().all()

    async def obtener_por_id(self, orden_id: str) -> Orden | None:
        """Devuelve una orden con sus archivos cargados (eager), o None."""
        resultado = await self._sesion.execute(
            select(Orden)
            .where(Orden.id == orden_id)
            .options(selectinload(Orden.archivos))
        )
        return resultado.scalar_one_or_none()

    async def actualizar(self, orden: Orden, cambios: dict[str, Any]) -> Orden:
        """Aplica un parche de campos sobre la orden (sin tocar los demás)."""
        for campo, valor in cambios.items():
            setattr(orden, campo, valor)
        await self._sesion.flush()
        return orden

    async def eliminar(self, orden: Orden) -> None:
        """Elimina la orden y sus registros hijos (archivos_orden)."""
        await self._sesion.execute(
            delete(ArchivoOrden).where(ArchivoOrden.orden_id == orden.id)
        )
        await self._sesion.delete(orden)
        await self._sesion.flush()

    # ── Archivos ──────────────────────────────────────────────────────────────

    async def insertar_archivo(
        self,
        orden_id: str,
        nombre_original: str,
        storage_path_original: str | None = None,
        storage_path_resultado: str | None = None,
        estado: str = "procesado",
    ) -> ArchivoOrden:
        """Registra una imagen asociada a la orden."""
        archivo = ArchivoOrden(
            id=str(uuid.uuid4()),
            orden_id=orden_id,
            nombre_original=nombre_original,
            storage_path_original=storage_path_original,
            storage_path_resultado=storage_path_resultado,
            estado=estado,
        )
        self._sesion.add(archivo)
        await self._sesion.flush()
        await self._sesion.refresh(archivo)
        return archivo

    async def obtener_archivo(
        self, orden_id: str, archivo_id: str
    ) -> ArchivoOrden | None:
        """Busca un archivo dentro de una orden."""
        resultado = await self._sesion.execute(
            select(ArchivoOrden)
            .where(
                ArchivoOrden.id == archivo_id,
                ArchivoOrden.orden_id == orden_id,
            )
            .limit(1)
        )
        return resultado.scalar_one_or_none()

    async def listar_archivos_procesados(
        self, orden_id: str
    ) -> Sequence[ArchivoOrden]:
        """Archivos con imagen sin fondo lista, en orden de subida."""
        resultado = await self._sesion.execute(
            select(ArchivoOrden)
            .where(
                ArchivoOrden.orden_id == orden_id,
                ArchivoOrden.estado == "procesado",
            )
            .order_by(ArchivoOrden.created_at)
        )
        return resultado.scalars().all()

    # ── Métricas ──────────────────────────────────────────────────────────────

    async def metricas(self) -> dict[str, float]:
        """
        Agregados del flujo de negocio (antes vista `vw_metricas_ordenes`):
          - órdenes cerradas (entregadas)
          - imágenes procesadas en total
          - segundos promedio entre creación y entrega
        """
        segundos_entrega = func.timestampdiff(
            text("SECOND"), Orden.created_at, Orden.cerrada_en
        )
        promedio = func.avg(
            case((Orden.cerrada_en.is_not(None), segundos_entrega), else_=None)
        )
        resultado = await self._sesion.execute(
            select(
                func.coalesce(
                    func.sum(case((Orden.estado == "entregada", 1), else_=0)), 0
                ),
                func.coalesce(func.sum(Orden.imagenes_procesadas), 0),
                func.coalesce(promedio, 0.0),
            )
        )
        cerradas, imagenes, promedio_seg = resultado.one()
        return {
            "ordenes_cerradas": int(cerradas),
            "imagenes_procesadas": int(imagenes),
            "seg_promedio_entrega": float(promedio_seg),
        }
