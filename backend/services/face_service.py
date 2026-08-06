import cv2
import numpy as np
import tempfile
import os

from insightface.app import FaceAnalysis
from firebase_config import db

# ----------------------------
# Inicializar InsightFace
# ----------------------------

app = FaceAnalysis(
    name="buffalo_l",
    providers=["CPUExecutionProvider"]
)

app.prepare(
    ctx_id=-1,
    det_size=(640, 640)
)

# 🔹 Umbral de distancia para considerar el mismo rostro.
# Con embeddings normalizados (magnitud = 1), la distancia euclidiana
# va de 0 (idéntico) a 2 (opuesto). Para InsightFace buffalo_l, la misma
# persona suele dar entre 0.5 y 1.1; personas distintas suelen dar 1.2+.
# Si te rechaza siendo tú, sube este valor poco a poco revisando el
# "distance" que se imprime en consola.
DISTANCE_THRESHOLD = 1.1


class FaceService:

    def image_to_embedding(self, image_bytes):

        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as temp:
            temp.write(image_bytes)
            temp_path = temp.name

        image = cv2.imread(temp_path)

        os.remove(temp_path)

        if image is None:
            raise Exception("No se pudo leer la imagen enviada.")

        faces = app.get(image)

        if len(faces) == 0:
            raise Exception("No se detectó ningún rostro.")

        if len(faces) > 1:
            raise Exception("Debe existir solamente un rostro.")

        embedding = faces[0].embedding

        return embedding

    def save_face(self, uid, image_bytes):

        embedding = self.image_to_embedding(image_bytes)

        embedding_list = embedding.astype(float).tolist()

        db.collection("users").document(uid).set(
            {
                "face_embedding": embedding_list
            },
            merge=True
        )

        return True

    def compare(self, uid, image_bytes):

        doc = db.collection("users").document(uid).get()

        if not doc.exists:
            raise Exception("Usuario no encontrado.")

        data = doc.to_dict()

        if "face_embedding" not in data:
            raise Exception("Usuario sin rostro registrado.")

        stored_raw = np.array(data["face_embedding"])
        current_raw = self.image_to_embedding(image_bytes)

        # 🔹 Normalizar ambos vectores (magnitud = 1) antes de comparar.
        # Esto evita que diferencias de iluminación/brillo entre la foto
        # de registro y la de login inflen la distancia artificialmente.
        stored = stored_raw / np.linalg.norm(stored_raw)
        current = current_raw / np.linalg.norm(current_raw)

        distance = np.linalg.norm(stored - current)

        similarity = max(0, 100 - distance * 40)

        verified = distance < DISTANCE_THRESHOLD

        return {
            "verified": verified,
            "similarity": round(similarity, 2),
            "distance": float(distance)
        }


face_service = FaceService()