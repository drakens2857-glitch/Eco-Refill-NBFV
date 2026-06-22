from pydantic import BaseModel
from datetime import datetime

# 🔹 Modelo de usuario con rol
class User(BaseModel):
    email: str
    password: str | None = None  # opcional cuando solo validas rol
    role: str  # jefe, inventario, ingreso, proceso

# 🔹 Modelo de material
class Material(BaseModel):
    nombre: str
    descripcion: str
    cantidad: int

# 🔹 Modelo de ingreso de plásticos
class IngresoPlastico(BaseModel):
    tipo: str
    cantidad: int
    usuario: str
    fecha: datetime = datetime.now()
