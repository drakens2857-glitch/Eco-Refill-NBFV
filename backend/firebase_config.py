import firebase_admin
from firebase_admin import credentials, auth, firestore, storage
import os
import json
import base64

if not firebase_admin._apps:
    cred_json_b64 = os.environ.get("FIREBASE_CREDENTIALS_B64")

    if cred_json_b64:
        # Producción: credenciales vienen como variable de entorno (base64)
        cred_json = json.loads(base64.b64decode(cred_json_b64))
        cred = credentials.Certificate(cred_json)
        project_id = cred_json.get("project_id")
    else:
        # Desarrollo local: usa el archivo JSON directamente
        cred_path = os.path.join(os.path.dirname(__file__), "eco-refill-admin.json")
        cred = credentials.Certificate(cred_path)
        with open(cred_path, "r") as f:
            project_id = json.load(f).get("project_id")

    # 👇 Bucket de Firebase Storage, usado para guardar las imágenes de las
    # publicaciones de forma permanente (antes se guardaban en el disco
    # local del contenedor de Cloud Run, que se borra en cada despliegue o
    # al escalar). Si tu bucket tiene un nombre distinto al esperado, define
    # la variable de entorno STORAGE_BUCKET con el nombre exacto.
    storage_bucket = os.environ.get("STORAGE_BUCKET") or f"{project_id}.firebasestorage.app"

    firebase_admin.initialize_app(cred, {"storageBucket": storage_bucket})

db = firestore.client()
bucket = storage.bucket()