from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from firebase_config import db, bucket
from firebase_admin import firestore
from pydantic import BaseModel
import uuid

router = APIRouter()


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
        "category": data.get("category", ""),
        "imageUrl": data.get("imageUrl", ""),
        "created_at": created_at_iso,
    }


@router.get("")
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

        # 👇 Se sube a Firebase Storage en vez de guardarse en el disco
        # local del contenedor: el disco de Cloud Run es efímero y se
        # pierde en cada despliegue o al escalar a una instancia nueva.
        filename = f"{uuid.uuid4()}_{file.filename}"
        blob_path = f"posts/{filename}"
        blob = bucket.blob(blob_path)
        blob.upload_from_string(image_bytes, content_type=file.content_type)

        # Con "uniform bucket-level access" activado no se puede usar
        # blob.make_public() (falla porque no permite ACLs por objeto).
        # El bucket ya se hizo público a nivel de IAM (rol Storage Object
        # Viewer para allUsers), así que armamos la URL pública a mano.
        image_url = f"https://storage.googleapis.com/{bucket.name}/{blob_path}"

        doc_ref = db.collection("posts").document()
        doc_ref.set({
            "title": title,
            "description": description,
            "author": author,
            "imageUrl": image_url,
            "createdAt": firestore.SERVER_TIMESTAMP,
        })

        return {
            "status": "success",
            "id": doc_ref.id,
            "imageUrl": image_url,
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


class UpdatePostRequest(BaseModel):
    title: str | None = None
    description: str | None = None
    author: str | None = None
    category: str | None = None


@router.put("/{post_id}")
async def update_post(post_id: str, data: UpdatePostRequest):
    doc_ref = db.collection("posts").document(post_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")

    update_data = {
        k: v for k, v in data.dict(exclude_unset=True).items() if v is not None
    }

    if not update_data:
        raise HTTPException(status_code=400, detail="Nada que actualizar")

    doc_ref.update(update_data)
    return {"success": True, "id": post_id}


@router.delete("/{post_id}")
async def delete_post(post_id: str):
    doc_ref = db.collection("posts").document(post_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")

    data = doc.to_dict()
    image_url = data.get("imageUrl", "")

    doc_ref.delete()

    # 🔹 Intenta borrar también la imagen del bucket de Storage, si existe.
    if image_url and bucket.name in image_url:
        try:
            blob_path = image_url.split(f"{bucket.name}/", 1)[-1]
            bucket.blob(blob_path).delete()
        except Exception:
            pass

    return {"success": True, "id": post_id}