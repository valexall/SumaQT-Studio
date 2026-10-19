"""
modulos/ordenes/esquemas.py
---------------------------
Esquemas Pydantic del módulo de órdenes: entrada, salida y contratos HTTP.

Mantienen intacto el contrato de API que consume el frontend Flutter
(las fechas `created_at` y `cerrada_en` viajan como strings ISO 8601 en JSON).
"""

from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, EmailStr, Field

EstadoOrden = Literal["pendiente", "procesando", "entregada"]
EstadoArchivo = Literal["procesado", "error"]


class OrdenCreate(BaseModel):
    nombre_proyecto: str = Field(min_length=3, max_length=120)
    cliente_nombre: str = Field(min_length=2, max_length=120)
    cliente_email: EmailStr
    total_imagenes: int = Field(gt=0, le=50)


class OrdenUpdate(BaseModel):
    nombre_proyecto: Optional[str] = Field(default=None, min_length=3, max_length=120)
    cliente_nombre: Optional[str] = Field(default=None, min_length=2, max_length=120)
    cliente_email: Optional[EmailStr] = None


class ArchivoOut(BaseModel):
    id: str
    orden_id: str
    nombre_original: str
    storage_path_original: Optional[str] = None
    storage_path_resultado: Optional[str] = None
    url_original: Optional[str] = None
    url_resultado: Optional[str] = None
    imagen_base64: Optional[str] = None
    estado: EstadoArchivo
    created_at: datetime

    model_config = {"from_attributes": True}


class OrdenOut(BaseModel):
    id: str
    nombre_proyecto: str
    cliente_nombre: str
    cliente_email: str
    total_imagenes: int
    imagenes_procesadas: int
    estado: EstadoOrden
    created_at: datetime
    cerrada_en: Optional[datetime] = None

    model_config = {"from_attributes": True}


class OrdenDetalleOut(OrdenOut):
    archivos: list[ArchivoOut] = []


class MetricasOut(BaseModel):
    ordenes_cerradas: int = 0
    imagenes_procesadas: int = 0
    seg_promedio_entrega: float = 0.0
