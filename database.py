# database.py
import boto3
from motor.motor_asyncio import AsyncIOMotorClient

def get_parameter(name: str) -> str:
    """Lee una IP guardada en AWS Parameter Store"""
    ssm = boto3.client("ssm", region_name="us-east-1")
    response = ssm.get_parameter(Name=name)
    return response["Parameter"]["Value"]

# Lee la IP privada de MongoDB desde Parameter Store
MONGO_IP = get_parameter("/escuela/mongodb_ip")
MONGO_URL = f"mongodb://{MONGO_IP}:27017"

client = AsyncIOMotorClient(MONGO_URL)  # type: ignore
db = client.escuela_db
coleccion = db.alumnos
coleccion_tasks = db.tasks
