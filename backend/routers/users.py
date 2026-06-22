from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from firebase_admin import auth, firestore
from dependencies import role_required

db = firestore.client()
router = APIRouter(prefix="/api/users", tags=["Usuarios"])

# 🔹 Modelo de usuario
class User(BaseModel):
    email: str
    password: str
    role: str  # jefe, inventario, ingreso, proceso

# 🔹 Crear usuario (solo jefe)
@router.post("/create", dependencies=[Depends(role_required(["jefe"]))])
def create_user(user: User):
    try:
        nuevo_usuario = auth.create_user(
            email=user.email,
            password=user.password,
        )
        db.collection("usuarios").document(nuevo_usuario.uid).set({
            "email": user.email,
            "role": user.role,
            "activo": True
        })
        return {"msg": "Usuario creado", "id": nuevo_usuario.uid, "role": user.role}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al crear usuario: {e}")

# 🔹 Actualizar usuario (solo jefe)
@router.put("/{user_id}", dependencies=[Depends(role_required(["jefe"]))])
def update_user(user_id: str, user: User):
    try:
        db.collection("usuarios").document(user_id).update({
            "email": user.email,
            "role": user.role
        })
        return {"msg": "Usuario actualizado", "id": user_id, "role": user.role}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al actualizar usuario: {e}")

# 🔹 Eliminar usuario (solo jefe)
@router.delete("/{user_id}", dependencies=[Depends(role_required(["jefe"]))])
def delete_user(user_id: str):
    try:
        auth.delete_user(user_id)
        db.collection("usuarios").document(user_id).delete()
        return {"msg": f"Usuario {user_id} eliminado"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar usuario: {e}")

# 🔹 Listar usuarios (solo jefe)
@router.get("/", dependencies=[Depends(role_required(["jefe"]))])
def listar_usuarios():
    try:
        docs = db.collection("usuarios").stream()
        usuarios = [doc.to_dict() | {"id": doc.id} for doc in docs]
        return usuarios
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al listar usuarios: {e}")
