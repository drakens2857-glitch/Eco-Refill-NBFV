from fastapi import APIRouter
from firebase_config import db

router = APIRouter()

@router.post("/")
def crear_material(tipo: str, cantidad: int, estado: str):
    doc_ref = db.collection("materiales").add({
        "tipo_material": tipo,
        "cantidad": cantidad,
        "estado": estado
    })
    return {"message": "Material registrado", "id": doc_ref[1].id}

@router.get("/")
def listar_materiales():
    materiales = db.collection("materiales").stream()
    return [{"id": m.id, **m.to_dict()} for m in materiales]
