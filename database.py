from motor.motor_asyncio import AsyncIOMotorClient

# Configuración de la conexión local
MONGO_URL = "mongodb://localhost:27017"

client = AsyncIOMotorClient(MONGO_URL) # type: ignore
db = client.escuela_db
coleccion = db.alumnos
coleccion_tasks = db.tasks
