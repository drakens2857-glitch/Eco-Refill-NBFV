import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from uvicorn.middleware.proxy_headers import ProxyHeadersMiddleware
from routers import auth, materiales, reportes, posts, procesar


app = FastAPI(title="Eco-Refill API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 👇 Si esta carpeta no existe en el contenedor, StaticFiles lanza un
# RuntimeError al montar y hace que TODA la app falle al arrancar
# (por eso fallaban también /api/posts y todo lo demás).
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(materiales.router, prefix="/api/materiales", tags=["Materiales"])
app.include_router(reportes.router, prefix="/api/reportes", tags=["Reportes"])
app.include_router(posts.router, prefix="/api/posts", tags=["Posts"])
app.include_router(procesar.router, prefix="/api/procesar", tags=["Procesar"])


@app.get("/api/health")
async def health_check():
    return {"status": "ok", "message": "Backend corriendo con CORS habilitado"}


# 👇 Cloud Run le habla al contenedor por HTTP simple aunque el usuario haya
# entrado por HTTPS. Sin esto, cuando FastAPI arma una redirección (por
# ejemplo por una barra final de más/faltante en la URL), la construye con
# "http://" en vez de "https://", y el navegador la bloquea como
# "Mixed Content". Esto le dice a FastAPI que confíe en el encabezado
# X-Forwarded-Proto que envía Cloud Run para saber el esquema real.
app = ProxyHeadersMiddleware(app, trusted_hosts="*")
