"""
modulos/ordenes/rutas.py
------------------------
Endpoints HTTP del módulo de órdenes de trabajo.

  - POST   /api/v1/ordenes/                          → Crear una orden
  - GET    /api/v1/ordenes/                          → Listar órdenes
  - GET    /api/v1/ordenes/metricas                  → Métricas del flujo
  - GET    /api/v1/ordenes/{id}                      → Detalle con archivos
  - POST   /api/v1/ordenes/{id}/archivos             → Subir y procesar imagen
  - GET    /api/v1/ordenes/{id}/archivos/{aid}/descargar → Descarga individual
  - GET    /api/v1/ordenes/{id}/descargar-zip        → Lote completo en ZIP
  - POST   /api/v1/ordenes/{id}/cerrar               → Entregar orden
  - PATCH  /api/v1/ordenes/{id}                      → Corregir datos
  - DELETE /api/v1/ordenes/{id}                      → Eliminar orden

Los archivos se sirven desde disco mediante el montaje estático `/archivos`.
"""

from fastapi import APIRouter, Depends, File, Request, UploadFile
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from modulos.ordenes.esquemas import (
    ArchivoOut,
    MetricasOut,
    OrdenCreate,
    OrdenDetalleOut,
    OrdenOut,
    OrdenUpdate,
)
from modulos.ordenes.repositorio import RepositorioOrdenes
from modulos.ordenes.servicio import ServicioOrdenes
from nucleo.base_datos import obtener_sesion

router = APIRouter()


def _servicio(sesion: AsyncSession = Depends(obtener_sesion)) -> ServicioOrdenes:
    """Factoría de ServicioOrdenes inyectada por FastAPI en cada petición."""
    return ServicioOrdenes(repositorio=RepositorioOrdenes(sesion))


def _base_url(request: Request) -> str:
    """URL base del cliente (ej. http://127.0.0.1:8000) para las URLs públicas."""
    return str(request.base_url).rstrip("/")


@router.post("/", response_model=OrdenOut, summary="Crear una orden de trabajo")
async def crear_orden(
    orden: OrdenCreate,
    servicio: ServicioOrdenes = Depends(_servicio),
):
    """Evento de negocio inicial: el cliente solicita el servicio."""
    return await servicio.crear(orden)


@router.get("/", response_model=list[OrdenOut], summary="Listar órdenes")
async def listar_ordenes(servicio: ServicioOrdenes = Depends(_servicio)):
    return await servicio.listar()


@router.get("/metricas", response_model=MetricasOut, summary="Métricas del flujo")
async def metricas(servicio: ServicioOrdenes = Depends(_servicio)):
    """Resultado medible: órdenes cerradas, imágenes y tiempo de entrega."""
    return await servicio.metricas()


@router.get("/{orden_id}", response_model=OrdenDetalleOut, summary="Detalle de orden")
async def detalle_orden(
    orden_id: str,
    request: Request,
    servicio: ServicioOrdenes = Depends(_servicio),
):
    return await servicio.detalle(orden_id, _base_url(request))


@router.post(
    "/{orden_id}/archivos",
    response_model=ArchivoOut,
    summary="Subir y procesar una imagen de la orden",
)
async def procesar_archivo(
    orden_id: str,
    request: Request,
    archivo: UploadFile = File(...),
    servicio: ServicioOrdenes = Depends(_servicio),
):
    """Valida → rembg → guarda original + PNG en disco → registra el archivo."""
    return await servicio.procesar_archivo(orden_id, archivo, _base_url(request))


@router.get(
    "/{orden_id}/archivos/{archivo_id}/descargar",
    summary="Descargar imagen procesada",
)
async def descargar_archivo_resultado(
    orden_id: str,
    archivo_id: str,
    servicio: ServicioOrdenes = Depends(_servicio),
):
    """Descarga directamente la imagen sin fondo desde el disco."""
    data, nombre = await servicio.descargar_archivo(orden_id, archivo_id)
    return StreamingResponse(
        iter([data]),
        media_type="image/png",
        headers={"Content-Disposition": f'attachment; filename="{nombre}"'},
    )


@router.get("/{orden_id}/descargar-zip", summary="Descargar lote completo en ZIP")
async def descargar_lote_zip(
    orden_id: str,
    servicio: ServicioOrdenes = Depends(_servicio),
):
    """Genera un archivo ZIP con todas las imágenes sin fondo del lote."""
    data, nombre = await servicio.descargar_zip(orden_id)
    return StreamingResponse(
        iter([data]),
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{nombre}"'},
    )


@router.post("/{orden_id}/cerrar", response_model=OrdenOut, summary="Entregar orden")
async def cerrar_orden(
    orden_id: str,
    servicio: ServicioOrdenes = Depends(_servicio),
):
    """Cierra el ciclo: estado entregada + fecha para la métrica de tiempo."""
    return await servicio.cerrar(orden_id)


@router.patch(
    "/{orden_id}",
    response_model=OrdenOut,
    summary="Actualizar datos de una orden",
)
async def actualizar_orden(
    orden_id: str,
    datos: OrdenUpdate,
    servicio: ServicioOrdenes = Depends(_servicio),
):
    """Corrige nombre del proyecto, cliente o email si fueron ingresados incorrectamente."""
    return await servicio.actualizar(orden_id, datos)


@router.delete("/{orden_id}", summary="Eliminar una orden")
async def eliminar_orden(
    orden_id: str,
    servicio: ServicioOrdenes = Depends(_servicio),
):
    """Elimina una orden y sus archivos asociados en base de datos y disco."""
    return await servicio.eliminar(orden_id)
