from fastapi import APIRouter
from firebase_config import db
from datetime import datetime

router = APIRouter()

@router.get("/")
def get_posts(skip: int = 0, limit: int = 10):
    posts = db.collection("posts").order_by("createdAt", direction="DESCENDING").offset(skip).limit(limit).stream()
    return [p.to_dict() for p in posts]

@router.post("/")
def create_post(post: dict):
    doc_ref = db.collection("posts").document()
    post["createdAt"] = datetime.utcnow().isoformat()
    doc_ref.set(post)
    return {"status": "success", "id": doc_ref.id}
