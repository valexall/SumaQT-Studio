from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Configuracion(BaseSettings):
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_BUCKET: str = "orden-imagenes"
    
    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
    )

@lru_cache()
def obtener_configuracion():
    return Configuracion()
