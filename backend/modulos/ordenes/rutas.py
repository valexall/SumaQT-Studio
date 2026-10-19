import asyncio
import base64
import io
import uuid
import zipfile
from datetime import datetime, timezone
from pathlib import PurePosixPath

from fastapi import APIRouter, File, HTTPException, UploadFile
from fastapi.responses import StreamingResponse
from PIL import Image

from modulos.procesamiento_imagen.rutas import _procesar_imagen
from nucleo.base_datos import obtener_cliente_supabase
from nucleo.configuracion import obtener_configuracion

from .modelos import (
    ArchivoOut,
    MetricasOut,
    OrdenCreate,
    OrdenDetalleOut,
    OrdenOut,
    OrdenUpdate,
)

router = APIRouter()

_FORMATOS_PERMITIDOS = {"JPEG", "PNG", "WEBP"}
_TIPOS_CONTENIDO = {
    "JPEG": "image/jpeg",
    "PNG": "image/png",
    "WEBP": "image/webp",
}


def _obtener_orden(orden_id: str) -> dict:
    cliente = obtener_cliente_supabase()
    respuesta = (
        cliente.table("ordenes").select("*").eq("id", orden_id).limit(1).execute()
    )
    if not respuesta.data:
        raise HTTPException(status_code=404, detail=f"Orden {orden_id} no encontrada.")
    return respuesta.data[0]


def _subir_a_storage(ruta: str, contenido: bytes, content_type: str) -> str:
    bucket = obtener_configuracion().SUPABASE_BUCKET
    cliente = obtener_cliente_supabase()
    try:
        cliente.storage.update_bucket(bucket, {"public": True})
    except Exception:
        pass
    cliente.storage.from_(bucket).upload(
        path=ruta,
        file=contenido,
        file_options={"content-type": content_type, "x-upsert": "true"},
    )
    return cliente.storage.from_(bucket).get_public_url(ruta)


@router.post(
    "/",
    response_model=OrdenOut,
    summary="Crear una orden de trabajo",
)
def crear_orden(orden: OrdenCreate):
    """Evento de negocio inicial: el cliente solicita el servicio."""
    cliente = obtener_cliente_supabase()
    respuesta = (
        cliente.table("ordenes")
        .insert(orden.model_dump(mode="json"))
        .execute()
    )
    if not respuesta.data:
        raise HTTPException(status_code=500, detail="No se pudo crear la orden.")
    return respuesta.data[0]


@router.get("/", response_model=list[OrdenOut], summary="Listar órdenes")
def listar_ordenes():
    cliente = obtener_cliente_supabase()
    respuesta = (
        cliente.table("ordenes")
        .select("*")
        .order("created_at", desc=True)
        .execute()
    )
    return respuesta.data


@router.get("/metricas", response_model=MetricasOut, summary="Métricas del flujo")
def metricas():
    """Resultado medible: órdenes cerradas, imágenes y tiempo de entrega."""
    cliente = obtener_cliente_supabase()
    respuesta = cliente.table("vw_metricas_ordenes").select("*").limit(1).execute()
    if not respuesta.data:
        return MetricasOut()
    fila = respuesta.data[0]
    return MetricasOut(
        ordenes_cerradas=int(fila.get("ordenes_cerradas") or 0),
        imagenes_procesadas=int(fila.get("imagenes_procesadas") or 0),
        seg_promedio_entrega=float(fila.get("seg_promedio_entrega") or 0.0),
    )


@router.get("/{orden_id}", response_model=OrdenDetalleOut, summary="Detalle de orden")
def detalle_orden(orden_id: str):
    orden = _obtener_orden(orden_id)
    cliente = obtener_cliente_supabase()
    respuesta = (
        cliente.table("archivos_orden")
        .select("*")
        .eq("orden_id", orden_id)
        .order("created_at", desc=False)
        .execute()
    )
    bucket = obtener_configuracion().SUPABASE_BUCKET
    archivos = []
    for item in (respuesta.data or []):
        fila = dict(item)
        if not fila.get("url_original") and fila.get("storage_path_original"):
            fila["url_original"] = cliente.storage.from_(bucket).get_public_url(fila["storage_path_original"])
        if not fila.get("url_resultado") and fila.get("storage_path_resultado"):
            fila["url_resultado"] = cliente.storage.from_(bucket).get_public_url(fila["storage_path_resultado"])
        archivos.append(fila)
    return {**orden, "archivos": archivos}


@router.post(
    "/{orden_id}/archivos",
    response_model=ArchivoOut,
    summary="Subir y procesar una imagen de la orden",
)
async def procesar_archivo(orden_id: str, archivo: UploadFile = File(...)):
    """Valida → rembg → sube original + PNG a Storage → registra en archivos_orden."""
    orden = await asyncio.to_thread(_obtener_orden, orden_id)

    if orden["estado"] == "entregada":
        raise HTTPException(
            status_code=409,
            detail="La orden ya fue entregada; no admite más imágenes.",
        )

    contenido = await archivo.read()
    if not contenido:
        raise HTTPException(status_code=400, detail="El archivo enviado está vacío.")

    try:
        with Image.open(io.BytesIO(contenido)) as img:
            formato = (img.format or "").upper()
            if formato not in _FORMATOS_PERMITIDOS:
                raise HTTPException(
                    status_code=400,
                    detail=f"Formato no soportado ({formato}). Usa JPEG, PNG o WEBP.",
                )
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="El archivo enviado no es una imagen válida o está dañado.",
        )

    nombre = archivo.filename or f"imagen.{formato.lower()}"
    base = PurePosixPath(nombre).stem
    sufijo = uuid.uuid4().hex[:8]

    try:
        resultado = await asyncio.to_thread(_procesar_imagen, contenido)
    except Exception as e:
        _registrar_archivo(orden_id, nombre, estado="error")
        raise HTTPException(
            status_code=500,
            detail=f"Error procesando la imagen: {str(e)}",
        )

    ruta_original = f"{orden_id}/original/{sufijo}_{nombre}"
    ruta_resultado = f"{orden_id}/procesado/{sufijo}_{base}_sin_fondo.png"

    try:
        url_original = await asyncio.to_thread(
            _subir_a_storage, ruta_original, contenido, _TIPOS_CONTENIDO[formato]
        )
        url_resultado = await asyncio.to_thread(
            _subir_a_storage, ruta_resultado, resultado, "image/png"
        )
    except Exception as e:
        _registrar_archivo(orden_id, nombre, estado="error")
        raise HTTPException(
            status_code=500,
            detail=f"Error guardando en Supabase Storage: {str(e)}",
        )

    cliente = obtener_cliente_supabase()
    insert = await asyncio.to_thread(
        lambda: (
            cliente.table("archivos_orden")
            .insert(
                {
                    "orden_id": orden_id,
                    "nombre_original": nombre,
                    "storage_path_original": ruta_original,
                    "storage_path_resultado": ruta_resultado,
                    "url_resultado": url_resultado,
                    "estado": "procesado",
                }
            )
            .execute()
        )
    )
    if not insert.data:
        raise HTTPException(
            status_code=500, detail="No se pudo registrar el archivo procesado."
        )

    imagenes_procesadas = int(orden["imagenes_procesadas"]) + 1
    total_imagenes = max(int(orden.get("total_imagenes") or 0), imagenes_procesadas)
    nuevo_estado = "procesando" if orden["estado"] == "pendiente" else orden["estado"]
    await asyncio.to_thread(
        lambda: (
            cliente.table("ordenes")
            .update(
                {
                    "imagenes_procesadas": imagenes_procesadas,
                    "total_imagenes": total_imagenes,
                    "estado": nuevo_estado,
                }
            )
            .eq("id", orden_id)
            .execute()
        )
    )

    registro = dict(insert.data[0])
    registro["url_original"] = url_original
    registro["imagen_base64"] = base64.b64encode(resultado).decode("utf-8")
    return registro


@router.get("/{orden_id}/archivos/{archivo_id}/descargar", summary="Descargar imagen procesada")
def descargar_archivo_resultado(orden_id: str, archivo_id: str):
    """Descarga directamente la imagen sin fondo desde backend/storage."""
    cliente = obtener_cliente_supabase()
    resp = cliente.table("archivos_orden").select("*").eq("id", archivo_id).eq("orden_id", orden_id).limit(1).execute()
    if not resp.data:
        raise HTTPException(status_code=404, detail="Archivo no encontrado.")
    archivo = resp.data[0]
    storage_path = archivo.get("storage_path_resultado")
    if not storage_path:
        raise HTTPException(status_code=404, detail="El archivo no tiene ruta de resultado.")

    bucket = obtener_configuracion().SUPABASE_BUCKET
    try:
        data = cliente.storage.from_(bucket).download(storage_path)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"No se pudo descargar de storage: {e}")

    nombre_descarga = PurePosixPath(archivo["nombre_original"]).stem + "_sin_fondo.png"
    return StreamingResponse(
        io.BytesIO(data),
        media_type="image/png",
        headers={"Content-Disposition": f'attachment; filename="{nombre_descarga}"'},
    )


@router.get("/{orden_id}/descargar-zip", summary="Descargar lote completo en ZIP")
def descargar_lote_zip(orden_id: str):
    """Genera un archivo ZIP con todas las imágenes sin fondo del lote."""
    orden = _obtener_orden(orden_id)
    cliente = obtener_cliente_supabase()
    resp = cliente.table("archivos_orden").select("*").eq("orden_id", orden_id).eq("estado", "procesado").execute()
    if not resp.data:
        raise HTTPException(status_code=404, detail="No hay imágenes procesadas para descargar.")

    bucket = obtener_configuracion().SUPABASE_BUCKET
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zip_file:
        for idx, item in enumerate(resp.data, start=1):
            storage_path = item.get("storage_path_resultado")
            if not storage_path:
                continue
            try:
                data = cliente.storage.from_(bucket).download(storage_path)
                stem = PurePosixPath(item["nombre_original"]).stem
                filename = f"{idx:02d}_{stem}_sin_fondo.png"
                zip_file.writestr(filename, data)
            except Exception:
                continue

    zip_buffer.seek(0)
    zip_name = f"{orden.get('nombre_proyecto', 'orden')}_lote_sin_fondo.zip"
    return StreamingResponse(
        zip_buffer,
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{zip_name}"'},
    )


@router.post("/{orden_id}/cerrar", response_model=OrdenOut, summary="Entregar orden")
def cerrar_orden(orden_id: str):
    """Cierra el ciclo: estado entregada + fecha para la métrica de tiempo."""
    orden = _obtener_orden(orden_id)
    if orden["estado"] == "entregada":
        raise HTTPException(status_code=409, detail="La orden ya fue entregada.")

    cliente = obtener_cliente_supabase()
    respuesta = (
        cliente.table("ordenes")
        .update(
            {
                "estado": "entregada",
                "cerrada_en": datetime.now(timezone.utc).isoformat(),
            }
        )
        .eq("id", orden_id)
        .execute()
    )
    if not respuesta.data:
        raise HTTPException(status_code=500, detail="No se pudo cerrar la orden.")
    return respuesta.data[0]


@router.patch("/{orden_id}", response_model=OrdenOut, summary="Actualizar datos de una orden")
def actualizar_orden(orden_id: str, datos: OrdenUpdate):
    """Corrige nombre del proyecto, cliente o email si fueron ingresados incorrectamente."""
    orden = _obtener_orden(orden_id)
    payload = {k: v for k, v in datos.model_dump(exclude_unset=True).items() if v is not None}
    if not payload:
        return orden

    cliente = obtener_cliente_supabase()
    respuesta = (
        cliente.table("ordenes")
        .update(payload)
        .eq("id", orden_id)
        .execute()
    )
    if not respuesta.data:
        raise HTTPException(status_code=500, detail="No se pudo actualizar la orden.")
    return respuesta.data[0]


@router.delete("/{orden_id}", summary="Eliminar una orden")
def eliminar_orden(orden_id: str):
    """Elimina una orden y sus archivos asociados en base de datos y Storage."""
    _obtener_orden(orden_id)
    cliente = obtener_cliente_supabase()
    bucket = obtener_configuracion().SUPABASE_BUCKET

    # Intentar limpiar archivos en Storage (best-effort)
    try:
        archivos = (
            cliente.table("archivos_orden")
            .select("storage_path_original, storage_path_resultado")
            .eq("orden_id", orden_id)
            .execute()
        )
        rutas_eliminar = []
        for a in (archivos.data or []):
            if a.get("storage_path_original"):
                rutas_eliminar.append(a["storage_path_original"])
            if a.get("storage_path_resultado"):
                rutas_eliminar.append(a["storage_path_resultado"])
        if rutas_eliminar:
            cliente.storage.from_(bucket).remove(rutas_eliminar)
    except Exception:
        pass

    # Eliminar explícitamente registros hijos y orden
    try:
        cliente.table("archivos_orden").delete().eq("orden_id", orden_id).execute()
        cliente.table("ordenes").delete().eq("id", orden_id).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"No se pudo eliminar la orden: {str(e)}")

    return {"mensaje": f"Orden {orden_id} eliminada correctamente"}


def _registrar_archivo(orden_id: str, nombre: str, estado: str) -> None:
    try:
        obtener_cliente_supabase().table("archivos_orden").insert(
            {"orden_id": orden_id, "nombre_original": nombre, "estado": estado}
        ).execute()
    except Exception:
        # El registro del fallo es best-effort: no tapa el error original.
        pass
