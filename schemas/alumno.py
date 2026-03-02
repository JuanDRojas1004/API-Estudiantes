# schemas/alumno.py
from pydantic import BaseModel
from typing import Optional

class AlumnoBase(BaseModel):
    nombre: str
    carrera: str
    edad: int

class AlumnoCreate(AlumnoBase):
    pass

class AlumnoUpdate(BaseModel):
    nombre: Optional[str] = None
    carrera: Optional[str] = None
    edad: Optional[int] = None

class AlumnoResponse(AlumnoBase):
    id: str