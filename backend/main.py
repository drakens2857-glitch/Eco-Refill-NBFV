from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, materiales, reportes, posts, procesar

app = FastAPI(title="Eco-Refill API")

# 🔹 Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # puedes restringir a ["http://localhost:49682"] si quieres
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 🔹 Registrar routers con prefijos
app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(materiales.router, prefix="/api/materiales", tags=["Materiales"])
app.include_router(reportes.router, prefix="/api/reportes", tags=["Reportes"])
app.include_router(posts.router, prefix="/api/posts", tags=["Posts"])  # 👈 tus posts están aquí
app.include_router(procesar.router, prefix="/api/procesar", tags=["Procesar"])  # Procesamiento de imágenes

# 🔹 Endpoint de prueba opcional (para verificar conexión desde Flutter Web)
@app.get("/api/health")
async def health_check():
    return {"status": "ok", "message": "Backend corriendo con CORS habilitado"}
