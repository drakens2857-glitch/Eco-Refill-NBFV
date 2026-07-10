import firebase_admin
from firebase_admin import credentials, auth, firestore
import os

# 🔹 Inicializar Firebase Admin solo una vez
if not firebase_admin._apps:
    # Usa tu archivo de credenciales JSON
    cred_path = os.path.join(os.path.dirname(__file__), "eco-refill-admin.json")
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

# 🔹 Cliente Firestore
db = firestore.client()
