from fastapi import FastAPI
from routers import auth, materiales, reportes

app = FastAPI(title="Eco-Refill API")

app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(materiales.router, prefix="/api/materiales", tags=["Materiales"])
app.include_router(reportes.router, prefix="/api/reportes", tags=["Reportes"])
