from fastapi import APIRouter
from firebase_config import db

router = APIRouter()

@router.post("/")
def crear_reporte(descripcion: str, user_id: str):
    doc_ref = db.collection("reportes").add({
        "descripcion": descripcion,
        "user_id": user_id
    })
    return {"message": "Reporte creado", "id": doc_ref[1].id}

@router.get("/")
def listar_reportes():
    reportes = db.collection("reportes").stream()
    return [{"id": r.id, **r.to_dict()} for r in reportes]
