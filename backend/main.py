from fastapi import FastAPI
from routers import auth, materiales, reportes, posts
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Eco-Refill API")

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # puedes restringir a ["http://localhost:xxxxx"] si quieres
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registrar routers
app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(materiales.router, prefix="/api/materiales", tags=["Materiales"])
app.include_router(reportes.router, prefix="/api/reportes", tags=["Reportes"])
app.include_router(posts.router, prefix="/api/posts", tags=["Posts"])
