from functools import lru_cache

from supabase import Client, create_client

from nucleo.configuracion import obtener_configuracion


@lru_cache()
def obtener_cliente_supabase() -> Client:
    """Cliente Supabase singleton (service_role → bypasa RLS).

    Se usa solo desde el backend; la clave nunca viaja al frontend.
    """
    config = obtener_configuracion()
    if not config.SUPABASE_URL or not config.SUPABASE_KEY:
        raise RuntimeError(
            "Faltan SUPABASE_URL o SUPABASE_KEY en backend/.env. "
            "Copia .env.example a .env y completa tus credenciales."
        )
    return create_client(config.SUPABASE_URL, config.SUPABASE_KEY)
