"""
nucleo/seguridad.py
-------------------
Utilidades de criptografía y autenticación para SumaQt Studio.

- Hasheo y verificación de contraseñas mediante PBKDF2-HMAC-SHA256 con salt criptográfica.
- Generación y decodificación de tokens JWT (PyJWT).
"""

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any
import jwt

from nucleo.configuracion import obtener_configuracion

_config = obtener_configuracion()


# ── Contraseñas (PBKDF2-HMAC-SHA256) ──────────────────────────────────────────

def hashear_password(password: str) -> str:
    """
    Genera un hash seguro con salt aleatoria de 16 bytes y 100,000 iteraciones.
    Formato: salt$hex_digest
    """
    salt = secrets.token_hex(16)
    clave = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        100_000,
    )
    return f"{salt}${clave.hex()}"


def verificar_password(password_plana: str, password_hasheada: str) -> bool:
    """
    Verifica si una contraseña en texto plano coincide con el hash almacenado.
    Utiliza compare_digest para prevenir ataques de temporización (timing attacks).
    """
    try:
        salt, hash_original = password_hasheada.split("$")
        clave = hashlib.pbkdf2_hmac(
            "sha256",
            password_plana.encode("utf-8"),
            salt.encode("utf-8"),
            100_000,
        )
        return secrets.compare_digest(clave.hex(), hash_original)
    except Exception:
        return False


# ── Tokens JWT ────────────────────────────────────────────────────────────────

def crear_token_acceso(datos: dict[str, Any], expira_en: timedelta | None = None) -> str:
    """
    Codifica un payload en un token JWT firmado con HS256.
    """
    a_codificar = datos.copy()
    if expira_en is not None:
        expiracion = datetime.now(timezone.utc) + expira_en
    else:
        expiracion = datetime.now(timezone.utc) + timedelta(minutes=_config.JWT_EXPIRATION_MINUTES)

    a_codificar.update({"exp": expiracion, "iat": datetime.now(timezone.utc)})
    token = jwt.encode(a_codificar, _config.JWT_SECRET, algorithm=_config.JWT_ALGORITHM)
    return token


def decodificar_token_acceso(token: str) -> dict[str, Any] | None:
    """
    Decodifica y valida la firma y expiración de un token JWT.
    Retorna el payload o None si es inválido o expiró.
    """
    try:
        payload = jwt.decode(token, _config.JWT_SECRET, algorithms=[_config.JWT_ALGORITHM])
        return payload
    except jwt.PyJWTError:
        return None
