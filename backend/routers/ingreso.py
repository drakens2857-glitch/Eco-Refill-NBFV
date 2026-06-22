from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime
from dependencies import role_required
from firebase_admin import firestore

# Inicializar Firestore
db = firestore.client()

router = APIRouter(prefix="/api/ingresos", tags=["Ingresos"])

# 🔹 Modelo de ingreso de plásticos
class IngresoPlastico(BaseModel):
    tipo: str
    cantidad: int
    usuario: str
    fecha: datetime = datetime.now()

# 🔹 Crear ingreso (solo jefe e ingreso)
@router.post("/", dependencies=[Depends(role_required(["jefe", "ingreso"]))])
def registrar_ingreso(material: IngresoPlastico):
    try:
        doc_ref = db.collection("ingresos").add(material.dict())
        return {"msg": "Ingreso registrado", "id": doc_ref[1].id, "material": material}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al registrar ingreso: {e}")

# 🔹 Listar ingresos (solo jefe e ingreso)
@router.get("/", dependencies=[Depends(role_required(["jefe", "ingreso"]))])
def listar_ingresos():
    try:
        docs = db.collection("ingresos").stream()
        ingresos = [doc.to_dict() | {"id": doc.id} for doc in docs]
        return ingresos
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al listar ingresos: {e}")

# 🔹 Eliminar ingreso (solo jefe)
@router.delete("/{ingreso_id}", dependencies=[Depends(role_required(["jefe"]))])
def eliminar_ingreso(ingreso_id: str):
    try:
        db.collection("ingresos").document(ingreso_id).delete()
        return {"msg": f"Ingreso {ingreso_id} eliminado"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al eliminar ingreso: {e}")
