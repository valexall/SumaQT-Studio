"""
modulos/ordenes/servicio.py
---------------------------
Capa de lógica de negocio del módulo de órdenes de trabajo.

Responsabilidades:
  - Crear / listar / actualizar / eliminar órdenes.
  - Pipeline de imagen: validar → rembg → guardar en disco → registrar.
  - Entrega de la orden (cierre) y cálculo de métricas del flujo.
  - Descargas individuales y por lote (ZIP).
"""

import asyncio
import base64
import io
import uuid
import zipfile
from datetime import datetime
from pathlib import PurePosixPath

from fastapi import HTTPException, UploadFile
from PIL import Image

from modulos.ordenes.esquemas import (
    ArchivoOut,
    MetricasOut,
    OrdenCreate,
    OrdenDetalleOut,
    OrdenOut,
    OrdenUpdate,
)
from modulos.ordenes.repositorio import RepositorioOrdenes
from modulos.procesamiento_imagen.rutas import _procesar_imagen
from nucleo import almacenamiento_local
from nucleo.base_datos import AsyncSessionLocal

_FORMATOS_PERMITIDOS = {"JPEG", "PNG", "WEBP"}


class ServicioOrdenes:
    """Encapsula la lógica de negocio y las reglas del módulo de órdenes."""

    def __init__(self, repositorio: RepositorioOrdenes) -> None:
        self._repo = repositorio

    # ── Órdenes ───────────────────────────────────────────────────────────────

    async def crear(self, datos: OrdenCreate) -> OrdenOut:
        """Evento de negocio inicial: el cliente solicita el servicio."""
        orden = await self._repo.crear(datos.model_dump())
        return OrdenOut.model_validate(orden)

    async def listar(self) -> list[OrdenOut]:
        """Devuelve todas las órdenes, de la más reciente a la más antigua."""
        ordenes = await self._repo.listar()
        return [OrdenOut.model_validate(o) for o in ordenes]

    async def metricas(self) -> MetricasOut:
        """Resultado medible: órdenes cerradas, imágenes y tiempo de entrega."""
        return MetricasOut(**await self._repo.metricas())

    async def detalle(self, orden_id: str, base_url: str) -> OrdenDetalleOut:
        """Orden completa con sus archivos (URLs de disco computadas en la respuesta)."""
        orden = await self._obtener(orden_id)
        salida = OrdenDetalleOut.model_validate(orden, from_attributes=True)
        for item in salida.archivos:
            if item.storage_path_original:
                item.url_original = almacenamiento_local.url_publica(
                    item.storage_path_original, base_url
                )
            if item.storage_path_resultado:
                item.url_resultado = almacenamiento_local.url_publica(
                    item.storage_path_resultado, base_url
                )
        return salida

    async def cerrar(self, orden_id: str) -> OrdenOut:
        """Cierra el ciclo: estado entregada + fecha para la métrica de tiempo."""
        orden = await self._obtener(orden_id)
        if orden.estado == "entregada":
            raise HTTPException(status_code=409, detail="La orden ya fue entregada.")
        return OrdenOut.model_validate(
            await self._repo.actualizar(
                orden,
                {"estado": "entregada", "cerrada_en": datetime.now()},
            )
        )

    async def actualizar(self, orden_id: str, datos: OrdenUpdate) -> OrdenOut:
        """Corrige nombre del proyecto, cliente o email si fueron ingresados mal."""
        orden = await self._obtener(orden_id)
        cambios = {
            k: v
            for k, v in datos.model_dump(exclude_unset=True).items()
            if v is not None
        }
        if not cambios:
            return OrdenOut.model_validate(orden)
        return OrdenOut.model_validate(await self._repo.actualizar(orden, cambios))

    async def eliminar(self, orden_id: str) -> dict:
        """Elimina la orden y sus archivos en base de datos y disco."""
        orden = await self._obtener(orden_id)
        try:
            await asyncio.to_thread(
                almacenamiento_local.eliminar_carpeta_orden, orden_id
            )
        except Exception:
            pass  # La limpieza del disco es best-effort: no tapa el error original.
        await self._repo.eliminar(orden)
        return {"mensaje": f"Orden {orden_id} eliminada correctamente"}

    # ── Pipeline de imágenes ──────────────────────────────────────────────────

    async def procesar_archivo(
        self, orden_id: str, archivo: UploadFile, base_url: str
    ) -> ArchivoOut:
        """Valida → rembg → guarda original + PNG en disco → registra en archivos_orden."""
        orden = await self._obtener(orden_id)

        if orden.estado == "entregada":
            raise HTTPException(
                status_code=409,
                detail="La orden ya fue entregada; no admite más imágenes.",
            )

        contenido = await archivo.read()
        if not contenido:
            raise HTTPException(status_code=400, detail="El archivo enviado está vacío.")

        formato = await asyncio.to_thread(self._validar_imagen, contenido)

        nombre = almacenamiento_local.nombre_seguro(
            archivo.filename or f"imagen.{formato.lower()}"
        )
        base = PurePosixPath(nombre).stem
        sufijo = uuid.uuid4().hex[:8]

        try:
            resultado = await asyncio.to_thread(_procesar_imagen, contenido)
        except Exception as e:
            await self._registrar_archivo_fallo(orden_id, nombre)
            raise HTTPException(
                status_code=500,
                detail=f"Error procesando la imagen: {str(e)}",
            )

        ruta_original = f"{orden_id}/original/{sufijo}_{nombre}"
        ruta_resultado = f"{orden_id}/procesado/{sufijo}_{base}_sin_fondo.png"

        try:
            await asyncio.to_thread(
                self._guardar_en_disco, ruta_original, contenido, ruta_resultado, resultado
            )
        except Exception as e:
            await self._registrar_archivo_fallo(orden_id, nombre)
            raise HTTPException(
                status_code=500,
                detail=f"Error guardando en almacenamiento local: {str(e)}",
            )

        registro = await self._repo.insertar_archivo(
            orden_id=orden_id,
            nombre_original=nombre,
            storage_path_original=ruta_original,
            storage_path_resultado=ruta_resultado,
            estado="procesado",
        )

        imagenes_procesadas = orden.imagenes_procesadas + 1
        await self._repo.actualizar(
            orden,
            {
                "imagenes_procesadas": imagenes_procesadas,
                "total_imagenes": max(orden.total_imagenes, imagenes_procesadas),
                "estado": (
                    "procesando" if orden.estado == "pendiente" else orden.estado
                ),
            },
        )

        salida = ArchivoOut.model_validate(registro, from_attributes=True)
        salida.url_original = almacenamiento_local.url_publica(ruta_original, base_url)
        salida.url_resultado = almacenamiento_local.url_publica(
            ruta_resultado, base_url
        )
        salida.imagen_base64 = base64.b64encode(resultado).decode("utf-8")
        return salida

    async def descargar_archivo(
        self, orden_id: str, archivo_id: str
    ) -> tuple[bytes, str]:
        """Lee la imagen sin fondo del disco para la descarga directa."""
        archivo = await self._repo.obtener_archivo(orden_id, archivo_id)
        if archivo is None:
            raise HTTPException(status_code=404, detail="Archivo no encontrado.")
        if not archivo.storage_path_resultado:
            raise HTTPException(
                status_code=404, detail="El archivo no tiene ruta de resultado."
            )
        try:
            data = await asyncio.to_thread(
                almacenamiento_local.leer, archivo.storage_path_resultado
            )
        except FileNotFoundError:
            raise HTTPException(
                status_code=400, detail="El archivo físico ya no existe en disco."
            )
        nombre = PurePosixPath(archivo.nombre_original).stem + "_sin_fondo.png"
        return data, nombre

    async def descargar_zip(self, orden_id: str) -> tuple[bytes, str]:
        """Agrupa todas las imágenes sin fondo de la orden en un ZIP."""
        orden = await self._obtener(orden_id)
        archivos = await self._repo.listar_archivos_procesados(orden_id)
        if not archivos:
            raise HTTPException(
                status_code=404, detail="No hay imágenes procesadas para descargar."
            )
        datos_zip = await asyncio.to_thread(self._construir_zip, archivos)
        zip_name = f"{orden.nombre_proyecto}_lote_sin_fondo.zip"
        return datos_zip, zip_name

    # ── Helpers (síncronos, se ejecutan en hilos secundarios) ─────────────────

    async def _obtener(self, orden_id: str):
        orden = await self._repo.obtener_por_id(orden_id)
        if orden is None:
            raise HTTPException(
                status_code=404, detail=f"Orden {orden_id} no encontrada."
            )
        return orden

    @staticmethod
    def _validar_imagen(contenido: bytes) -> str:
        try:
            with Image.open(io.BytesIO(contenido)) as img:
                formato = (img.format or "").upper()
        except Exception:
            raise HTTPException(
                status_code=400,
                detail="El archivo enviado no es una imagen válida o está dañado.",
            )
        if formato not in _FORMATOS_PERMITIDOS:
            raise HTTPException(
                status_code=400,
                detail=f"Formato no soportado ({formato}). Usa JPEG, PNG o WEBP.",
            )
        return formato

    @staticmethod
    def _guardar_en_disco(
        ruta_original: str,
        contenido: bytes,
        ruta_resultado: str,
        resultado: bytes,
    ) -> None:
        almacenamiento_local.guardar(ruta_original, contenido)
        almacenamiento_local.guardar(ruta_resultado, resultado)

    @staticmethod
    def _construir_zip(archivos) -> bytes:
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as zip_file:
            for idx, item in enumerate(archivos, start=1):
                if not item.storage_path_resultado:
                    continue
                try:
                    data = almacenamiento_local.leer(item.storage_path_resultado)
                except Exception:
                    continue  # Un archivo ilegible no invalida el resto del lote.
                stem = PurePosixPath(item.nombre_original).stem
                zip_file.writestr(f"{idx:02d}_{stem}_sin_fondo.png", data)
        return buffer.getvalue()

    async def _registrar_archivo_fallo(self, orden_id: str, nombre: str) -> None:
        """
        Registra un intento fallido en una SESIÓN INDEPENDIENTE.

        La sesión de la petición hará rollback al propagarse la excepción
        HTTP; este registro best-effort debe sobrevivir a ese rollback
        (comportamiento heredado del flujo con Supabase).
        """
        try:
            async with AsyncSessionLocal() as sesion:
                repo = RepositorioOrdenes(sesion)
                await repo.insertar_archivo(orden_id, nombre, estado="error")
                await sesion.commit()
        except Exception:
            pass  # El registro del fallo es best-effort: no tapa el error original.
