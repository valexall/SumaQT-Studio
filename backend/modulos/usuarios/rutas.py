from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def listar_usuarios():
    # TODO: Implementar lógica con Supabase
    return [{"id": 1, "nombre": "Usuario Prueba", "email": "prueba@ejemplo.com"}]
