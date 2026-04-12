from fastapi import FastAPI, HTTPException, status
from datetime import datetime
import uuid
from bson import ObjectId, errors
from schemas.alumno import AlumnoCreate, AlumnoUpdate



# Importamos las colecciones de la base de datos
from database import coleccion_tasks, coleccion

# Importamos los esquemas y la función para RabbitMQ
from schemas.alumno import AlumnoCreate
from publisher import enviar_tarea

from fastapi import FastAPI

app = FastAPI(
    title="API de Gestión de Estudiantes",
    version="1.0.0",
    contact={
        "name": "Juan David Rojas",
        "email": "juandrojas1004@gmail.com",
    },
)

# --- ENDPOINTS ---

@app.post("/alumnos", status_code=status.HTTP_202_ACCEPTED)
async def crear_alumno_async(alumno: AlumnoCreate):
    # 1. Generar UUID para la tarea
    task_id = str(uuid.uuid4())
    
    # 2. Registrar la tarea en la base de datos 'tasks'
    nueva_tarea = {
        "task_id": task_id,
        "status": "pending",
        "tipo": "post",
        "data": alumno.model_dump(),
        "creado_en": datetime.utcnow(),
        "error": None
    }
    await coleccion_tasks.insert_one(nueva_tarea)
    
    # 3. Mandar la orden al Worker vía RabbitMQ
    payload = {
        "task_id": task_id,
        "tipo": "post",
        "data": alumno.model_dump()
    }
    await enviar_tarea(payload)
    
    return {"task_id": task_id, "mensaje": "Tarea de creación encolada"}

@app.delete("/alumnos/{id}", status_code=status.HTTP_202_ACCEPTED)
async def eliminar_alumno_async(id: str):
    # 1. Generar UUID
    task_id = str(uuid.uuid4())
    
    # 2. Registrar tarea de eliminación
    nueva_tarea = {
        "task_id": task_id,
        "status": "pending",
        "tipo": "delete",
        "alumno_id": id,
        "creado_en": datetime.utcnow(),
        "error": None
    }
    await coleccion_tasks.insert_one(nueva_tarea)
    
    # 3. Mandar a la cola
    payload = {
        "task_id": task_id,
        "tipo": "delete",
        "alumno_id": id
    }
    await enviar_tarea(payload)
    
    return {"task_id": task_id, "mensaje": "Tarea de eliminación encolada"}

@app.get("/tasks/{task_id}")
async def consultar_estado_tarea(task_id: str):
    # Buscar la tarea por el UUID que generamos
    tarea = await coleccion_tasks.find_one({"task_id": task_id})
    
    if not tarea:
        raise HTTPException(status_code=404, detail="Tarea no encontrada")
    
    return {
        "task_id": tarea["task_id"],
        "status": tarea["status"],
        "tipo": tarea["tipo"],
        "creado_en": tarea["creado_en"],
        "error": tarea.get("error")
    }

@app.get("/alumnos")
async def listar_alumnos():
    # Consulta directa a la colección final de alumnos
    cursor = coleccion.find()
    alumnos = []
    async for alumno in cursor:
        alumno["_id"] = str(alumno["_id"])
        alumnos.append(alumno)
    return alumnos



@app.put("/alumnos/{id}", status_code=200)
async def actualizar_alumno(id: str, alumno_data: AlumnoUpdate):
    try:
        # Filtramos campos None (esto ya lo tenías perfecto)
        campos_para_actualizar = {k: v for k, v in alumno_data.model_dump().items() if v is not None}

        if len(campos_para_actualizar) < 1:
            raise HTTPException(status_code=400, detail="Debes enviar al menos un campo para actualizar")

        resultado = await coleccion.update_one(
            {"_id": ObjectId(id)}, 
            {"$set": campos_para_actualizar}
        )

        # Si match_count es 1, significa que el ID existe
        if resultado.matched_count == 1:
            return {"mensaje": "Alumno actualizado con éxito"}
        
        raise HTTPException(status_code=404, detail="ID no encontrado")
    except errors.InvalidId:
        raise HTTPException(status_code=400, detail="El formato del ID no es válido")