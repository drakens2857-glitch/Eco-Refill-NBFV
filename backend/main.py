from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routers import auth, materiales, reportes, posts, procesar


app = FastAPI(title="Eco-Refill API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(materiales.router, prefix="/api/materiales", tags=["Materiales"])
app.include_router(reportes.router, prefix="/api/reportes", tags=["Reportes"])
app.include_router(posts.router, prefix="/api/posts", tags=["Posts"])
app.include_router(procesar.router, prefix="/api/procesar", tags=["Procesar"])


@app.get("/api/health")
async def health_check():
    return {"status": "ok", "message": "Backend corriendo con CORS habilitado"}
