from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import numpy as np
import cv2
import os
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

# Si ya existe un modelo entrenado, cargarlo
if os.path.exists(MODEL_PATH):
    recognizer.read(MODEL_PATH)

@router.post("/")
async def procesar(file: UploadFile = File(...)):
    # Leer imagen subida
    image_bytes = await file.read()
    np_img = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(np_img, cv2.IMREAD_COLOR)

    if img is None:
        raise HTTPException(status_code=400, detail="No se pudo decodificar la imagen")

    # Convertir a escala de grises
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # 🔹 Detectar rostros con Haar
    face_cascade = cv2.CascadeClassifier(
        cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    )
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.3, minNeighbors=5)

    if not os.path.exists(MODEL_PATH):
        return JSONResponse({"status": "fail", "message": "Modelo no entrenado aún"})

    recognizer.read(MODEL_PATH)
    label_map = load_label_map()

    for (x, y, w, h) in faces:
        roi_gray = gray[y:y+h, x:x+w]
        label, confidence = recognizer.predict(roi_gray)

        # 🔹 Ajusta el umbral según tus pruebas
        if confidence < 100:  # más permisivo
            uid = None
            for k, v in label_map.items():
                if v == label:
                    uid = k
                    break

            if uid:
                return JSONResponse({"status": "success", "user": uid})

    return JSONResponse({"status": "fail", "message": "Rostro no reconocido"})
