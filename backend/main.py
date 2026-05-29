from fastapi import FastAPI
from dotenv import load_dotenv
import os

load_dotenv()

port = os.getenv("PORT")

print(port)

app = FastAPI()

@app.get("/")
def inicio():
    return {"mensaje": "Backend funcionando correctamente"}