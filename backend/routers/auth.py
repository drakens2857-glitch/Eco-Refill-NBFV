from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from firebase_admin import auth, firestore
from firebase_config import db   # 🔹 Importar cliente Firestore desde firebaseconfig
from services.face_service import face_service

router = APIRouter()


@router.post("/register")
def register_user(email: str, password: str):
    user = auth.create_user(email=email, password=password)
    # 🔹 Guardar en Firestore también
    db.collection("users").document(user.uid).set({
        "email": email,
        "createdAt": firestore.SERVER_TIMESTAMP,
    })
    return {"uid": user.uid, "email": user.email}


@router.get("/uid_by_email")
def get_uid_by_email(email: str):
    """
    Busca el UID de un usuario a partir de su email, usando el SDK
    de administrador (evita el problema de permisos de Firestore
    cuando el usuario aún no ha iniciado sesión, como en el login facial).
    """
    query = db.collection("users").where("email", "==", email).limit(1).get()

    if not query:
        raise HTTPException(
            status_code=404,
            detail="No se encontró ningún usuario con ese correo."
        )

    doc = query[0]

    return {"uid": doc.id}


@router.post("/register_with_face")
async def register_user_with_face(
    email: str = Form(...),
    password: str = Form(...),
    name: str = Form(...),
    phone: str = Form(...),
    cargo: str = Form(...),
    file: UploadFile = File(...)
):
    try:

        # Crear usuario en Firebase Authentication
        user = auth.create_user(
            email=email,
            password=password
        )

        # Leer imagen enviada desde Flutter
        image_bytes = await file.read()

        # Guardar el embedding facial en Firestore
        face_service.save_face(
            uid=user.uid,
            image_bytes=image_bytes
        )

        # Guardar datos del usuario
        db.collection("users").document(user.uid).set({
            "uid": user.uid,
            "name": name,
            "email": email,
            "phone": phone,
            "cargo": cargo,
            "createdAt": firestore.SERVER_TIMESTAMP
        }, merge=True)

        return {
            "success": True,
            "uid": user.uid,
            "email": user.email,
            "message": "Usuario registrado con reconocimiento facial."
        }

    except Exception as e:

        raise HTTPException(
            status_code=400,
            detail=str(e)
        )


@router.post("/login")
def login_user(email: str, password: str):
    # Aquí puedes validar contra Firebase Auth o usar tokens
    return {"message": "Login handled via Firebase client SDK"}


# 🔹 Registrar (o reemplazar) el rostro de una cuenta que ya existe.
# Pensado para usarse solo después de que el usuario ya inició sesión
# con contraseña, así se confirma que es dueño real de la cuenta.
@router.post("/add_face")
async def add_face(
    uid: str = Form(...),
    file: UploadFile = File(...)
):
    try:
        image_bytes = await file.read()

        face_service.save_face(
            uid=uid,
            image_bytes=image_bytes
        )

        return {
            "success": True,
            "message": "Rostro registrado correctamente para esta cuenta."
        }

    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=str(e)
        )


# 🔹 Login con rostro
@router.post("/login_with_face")
async def login_with_face(
    uid: str = Form(...),
    file: UploadFile = File(...)
):
    """
    Verifica que la selfie enviada corresponda al usuario indicado.
    """

    try:

        image_bytes = await file.read()

        result = face_service.compare(
            uid=uid,
            image_bytes=image_bytes
        )

        # Log de calibración: revisa esto en consola para ajustar el umbral
        print(f"[login_with_face] uid={uid} distance={result['distance']} "
              f"similarity={result['similarity']} verified={result['verified']}")

        if not result["verified"]:
            raise HTTPException(
                status_code=401,
                detail={
                    "message": "Rostro no reconocido.",
                    "similarity": result["similarity"]
                }
            )

        doc = db.collection("users").document(uid).get()

        if not doc.exists:
            raise HTTPException(
                status_code=404,
                detail="Usuario no encontrado."
            )

        data = doc.to_dict()

        # 🔹 Generar un Custom Token para esta cuenta específica.
        # Esto permite que Flutter inicie sesión real (FirebaseAuth.currentUser)
        # como este uid exacto, sin necesidad de contraseña.
        custom_token = auth.create_custom_token(uid)

        return {
            "success": True,
            "uid": uid,
            "email": data.get("email"),
            "name": data.get("name"),
            "phone": data.get("phone"),
            "cargo": data.get("cargo"),
            "similarity": result["similarity"],
            "token": custom_token.decode("utf-8"),
            "message": "Reconocimiento facial exitoso."
        }

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=400,
            detail=str(e)
        )