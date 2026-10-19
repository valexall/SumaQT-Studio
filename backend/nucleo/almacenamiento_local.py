"""Almacenamiento de archivos en disco local.

Reemplaza al antiguo Supabase Storage: las imágenes se guardan bajo
`STORAGE_DIR` y se sirven al cliente mediante el montaje estático
`/archivos` de FastAPI. Las rutas relativas que se persisten en la base
de datos son las mismas que antes vivían en el bucket.
"""

import shutil
from pathlib import Path, PurePosixPath

from nucleo.configuracion import obtener_configuracion


def _raiz() -> Path:
    return Path(obtener_configuracion().STORAGE_DIR)


def directorio() -> Path:
    """Carpeta raíz del almacenamiento (para montarla como estática)."""
    return _raiz()


def asegurar_directorio() -> None:
    _raiz().mkdir(parents=True, exist_ok=True)


def nombre_seguro(nombre: str) -> str:
    """Extrae solo el nombre del archivo, descartando cualquier ruta."""
    return PurePosixPath(nombre).name or "archivo"


def guardar(ruta_relativa: str, contenido: bytes) -> None:
    destino = _raiz() / ruta_relativa
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_bytes(contenido)


def leer(ruta_relativa: str) -> bytes:
    archivo = _raiz() / ruta_relativa
    if not archivo.is_file():
        raise FileNotFoundError(f"Archivo no encontrado: {ruta_relativa}")
    return archivo.read_bytes()


def eliminar(ruta_relativa: str) -> None:
    archivo = _raiz() / ruta_relativa
    if archivo.is_file():
        archivo.unlink()


def eliminar_carpeta_orden(orden_id: str) -> None:
    carpeta = _raiz() / orden_id
    if carpeta.is_dir():
        shutil.rmtree(carpeta, ignore_errors=True)


def url_publica(ruta_relativa: str, base_url: str) -> str:
    return f"{base_url.rstrip('/')}/archivos/{ruta_relativa}"
