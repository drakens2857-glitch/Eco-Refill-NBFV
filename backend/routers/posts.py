from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from firebase_config import db
from firebase_admin import firestore
import uuid
import os

router = APIRouter()

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _serialize_post(doc_id: str, data: dict) -> dict:
    created_at = data.get("createdAt")
    if created_at is None:
        created_at_iso = None
    elif hasattr(created_at, "isoformat"):
        created_at_iso = created_at.isoformat()
    else:
        created_at_iso = str(created_at)
    return {
        "id": doc_id,
        "title": data.get("title", ""),
        "description": data.get("description", ""),
        "author": data.get("author", ""),
        "imageUrl": data.get("imageUrl", ""),
        "created_at": created_at_iso,
    }


@router.get("/")
def get_posts(skip: int = 0, limit: int = 10):
    posts = (
        db.collection("posts")
        .order_by("createdAt", direction="DESCENDING")
        .offset(skip)
        .limit(limit)
        .stream()
    )
    return [_serialize_post(p.id, p.to_dict()) for p in posts]


@router.post("/create_post")
async def create_post(
    title: str = Form(...),
    description: str = Form(...),
    author: str = Form(...),
    file: UploadFile = File(...)
):
    try:
        image_bytes = await file.read()
        if not image_bytes:
            raise HTTPException(status_code=400, detail="Archivo vacío")

        filename = f"{uuid.uuid4()}_{file.filename}"
        filepath = os.path.join(UPLOAD_DIR, filename)
        with open(filepath, "wb") as f:
            f.write(image_bytes)

        doc_ref = db.collection("posts").document()
        doc_ref.set({
            "title": title,
            "description": description,
            "author": author,
            "imageUrl": f"/{UPLOAD_DIR}/{filename}",
            "createdAt": firestore.SERVER_TIMESTAMP,
        })

        return {
            "status": "success",
            "id": doc_ref.id,
            "imageUrl": f"/{UPLOAD_DIR}/{filename}",
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")