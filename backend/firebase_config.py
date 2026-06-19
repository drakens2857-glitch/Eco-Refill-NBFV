import firebase_admin
from firebase_admin import credentials, auth, firestore
import os

# 🔹 Cargar credenciales desde archivo JSON
cred = credentials.Certificate("eco-refill-admin.json")
firebase_admin.initialize_app(cred)

# 🔹 Cliente Firestore
db = firestore.client()
