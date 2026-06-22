from fastapi import Depends, HTTPException, Header
from firebase_admin import auth, firestore
from models import User

db = firestore.client()

# 🔹 Obtener usuario autenticado desde el token
def get_current_user(authorization: str = Header(...)):
    """
    Extrae el usuario autenticado desde el header Authorization.
    Se espera un token Firebase válido: "Bearer <idToken>"
    """
    try:
        if not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Token inválido")

        id_token = authorization.split(" ")[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token["uid"]

        # Buscar datos del usuario en Firestore
        doc = db.collection("usuarios").document(uid).get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        data = doc.to_dict()
        return User(email=data["email"], password="", role=data["role"])
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Error de autenticación: {e}")

# 🔹 Validar rol
def role_required(allowed_roles: list[str]):
    def wrapper(user: User = Depends(get_current_user)):
        if user.role not in allowed_roles:
            raise HTTPException(status_code=403, detail="Acceso denegado")
        return user
    return wrapper
