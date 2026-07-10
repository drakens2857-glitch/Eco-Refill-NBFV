from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from firebase_admin import auth, firestore
from firebase_config import db   # 🔹 Importar cliente Firestore desde firebaseconfig
import cv2
import os
import numpy as np
import json

router = APIRouter()

FACES_DIR = "faces"
MODEL_PATH = "model_lbph.yml"
LABEL_MAP_PATH = "label_map.json"

# 🔹 Inicializar reconocedor LBPH
recognizer = cv2.face.LBPHFaceRecognizer_create()

def load_label_map():
    if os.path.exists(LABEL_MAP_PATH):
        with open(LABEL_MAP_PATH, "r") as f:
            return json.load(f)
    return {}

def save_label_map(label_map):
    with open(LABEL_MAP_PATH, "w") as f:
        json.dump(label_map, f)

def train_lbph_model():
    faces = []
    labels = []
    label_map = load_label_map()
    current_label = max(label_map.values(), default=-1) + 1

    for filename in os.listdir(FACES_DIR):
        if filename.endswith(".jpg"):
            path = os.path.join(FACES_DIR, filename)
            img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
            uid = filename.split(".")[0]  # 🔹 UID como string

            if uid not in label_map:
                label_map[uid] = current_label
                current_label += 1

            faces.append(img)
            labels.append(label_map[uid])

    if faces:
        recognizer.train(faces, np.array(labels))
        recognizer.save(MODEL_PATH)
        save_label_map(label_map)

@router.post("/register")
def register_user(email: str, password: str):
    user = auth.create_user(email=email, password=password)
    # 🔹 Guardar en Firestore también
    db.collection("users").document(user.uid).set({
        "email": email,
        "createdAt": firestore.SERVER_TIMESTAMP,
    })
    return {"uid": user.uid, "email": user.email}

@router.post("/register_with_face")
async def register_user_with_face(
    email: str = Form(...),
    password: str = Form(...),
    name: str = Form(...),
    phone: str = Form(...),
    cargo: str = Form(...),
    file: UploadFile = File(...)
):
    # 🔹 Crear usuario en Firebase Auth
    user = auth.create_user(email=email, password=password)

    # 🔹 Guardar rostro en carpeta
    os.makedirs(FACES_DIR, exist_ok=True)
    image_bytes = await file.read()
    np_img = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(np_img, cv2.IMREAD_GRAYSCALE)

    if img is None:
        raise HTTPException(status_code=400, detail="No se pudo decodificar la imagen")

    face_path = os.path.join(FACES_DIR, f"{user.uid}.jpg")
    cv2.imwrite(face_path, img)

    # 🔹 Entrenar/actualizar modelo LBPH
    train_lbph_model()

    # 🔹 Guardar datos en Firestore
    db.collection("users").document(user.uid).set({
        "uid": user.uid,
        "name": name,
        "email": email,
        "phone": phone,
        "cargo": cargo,
        "createdAt": firestore.SERVER_TIMESTAMP,
    })

    return {"uid": user.uid, "email": user.email, "message": "Usuario registrado con rostro"}

@router.post("/login")
def login_user(email: str, password: str):
    # Aquí puedes validar contra Firebase Auth o usar tokens
    return {"message": "Login handled via Firebase client SDK"}

# 🔹 Nuevo endpoint: login con rostro
@router.post("/login_with_face")
async def login_with_face(file: UploadFile = File(...)):
    # Cargar modelo entrenado
    if not os.path.exists(MODEL_PATH):
        raise HTTPException(status_code=400, detail="Modelo no entrenado")

    recognizer.read(MODEL_PATH)

    # Leer imagen recibida
    image_bytes = await file.read()
    np_img = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(np_img, cv2.IMREAD_GRAYSCALE)

    if img is None:
        raise HTTPException(status_code=400, detail="No se pudo decodificar la imagen")

    # Predecir rostro
    label, confidence = recognizer.predict(img)

    # 🔹 Validar confianza: mientras más bajo, mejor
    if confidence > 90:  # Ajusta este umbral según tus pruebas
        raise HTTPException(status_code=401, detail="Rostro no reconocido con suficiente confianza")

    # Invertir el mapa: label → UID
    label_map = load_label_map()
    reverse_map = {v: k for k, v in label_map.items()}
    user_uid = reverse_map.get(label)

    if not user_uid:
        raise HTTPException(status_code=404, detail="UID no encontrado en el mapa")

    # 🔹 Validar en Firestore usando el ID del documento (que ya es el UID)
    doc_ref = db.collection("users").document(user_uid)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail=f"Usuario con UID {user_uid} no encontrado en Firestore")

    # Extraer datos del documento
    user_data = doc.to_dict()

    return {
        "uid": user_uid,
        "email": user_data.get("email"),
        "name": user_data.get("name"),
        "phone": user_data.get("phone"),
        "cargo": user_data.get("cargo"),
        "confidence": confidence,  # 🔹 Devuelve también el nivel de confianza
        "message": "Login facial exitoso"
    }
