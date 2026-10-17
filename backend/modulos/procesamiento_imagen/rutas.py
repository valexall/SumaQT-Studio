import io
from fastapi import APIRouter, UploadFile, File, HTTPException, BackgroundTasks
from fastapi.responses import StreamingResponse
from PIL import Image
import rembg

router = APIRouter()


def _procesar_imagen(contenido: bytes) -> bytes:
    """Quita el fondo de la imagen usando rembg (modelo local ONNX)."""
    resultado = rembg.remove(contenido)
    return resultado


@router.post(
    "/quitar-fondo",
    summary="Quitar fondo de una imagen",
    response_description="Imagen PNG con el fondo removido",
)
async def quitar_fondo(archivo: UploadFile = File(...)):
    """
    Recibe una imagen (JPEG, PNG, WEBP) y devuelve la misma imagen
    con el fondo transparente en formato PNG.
    """
    contenido = await archivo.read()
    if not contenido:
        raise HTTPException(
            status_code=400,
            detail="El archivo enviado está vacío.",
        )

    # Validar que sea una imagen válida usando PIL
    try:
        with Image.open(io.BytesIO(contenido)) as img:
            formato = (img.format or "").upper()
            if formato not in {"JPEG", "PNG", "WEBP"}:
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

    try:
        resultado = _procesar_imagen(contenido)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error procesando la imagen: {str(e)}",
        )

    return StreamingResponse(
        io.BytesIO(resultado),
        media_type="image/png",
        headers={
            "Content-Disposition": f"attachment; filename=sin_fondo.png",
        },
    )
