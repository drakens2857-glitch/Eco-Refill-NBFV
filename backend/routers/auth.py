from fastapi import APIRouter
from firebase_admin import auth

router = APIRouter()

@router.post("/register")
def register_user(email: str, password: str):
    user = auth.create_user(email=email, password=password)
    return {"uid": user.uid, "email": user.email}

@router.post("/login")
def login_user(email: str, password: str):
    # Aquí puedes validar contra Firebase Auth o usar tokens
    return {"message": "Login handled via Firebase client SDK"}
