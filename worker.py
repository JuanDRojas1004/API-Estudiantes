# worker.py
import asyncio
import aio_pika
import json
import boto3
from bson import ObjectId
from database import coleccion, coleccion_tasks

def get_parameter(name: str) -> str:
    """Lee una IP guardada en AWS Parameter Store"""
    ssm = boto3.client("ssm", region_name="us-east-1")
    response = ssm.get_parameter(Name=name)
    return response["Parameter"]["Value"]

# Lee la IP privada de RabbitMQ desde Parameter Store
RABBITMQ_IP = get_parameter("/escuela/rabbitmq_ip")
RABBITMQ_URL = f"amqp://user:password@{RABBITMQ_IP}/"

async def procesar_tarea(mensaje: aio_pika.IncomingMessage):
    async with mensaje.process():
        try:
            body = json.loads(mensaje.body.decode())
            task_id = body.get("task_id")
            tipo = body.get("tipo")
            data = body.get("data")
            alumno_id = body.get("alumno_id")

            print(f" [worker] Iniciando tarea: {task_id} | Tipo: {tipo}")

            if tipo == "post":
                await coleccion.insert_one(data)
                print(f" [worker] Alumno creado exitosamente.")

            elif tipo == "delete":
                await coleccion.delete_one({"_id": ObjectId(alumno_id)})
                print(f" [worker] Alumno eliminado exitosamente.")

            resultado = await coleccion_tasks.update_one(
                {"task_id": task_id},
                {"$set": {
                    "status": "completed",
                    "finalizado_en": json.dumps(str(asyncio.get_event_loop().time()))
                }}
            )

            if resultado.modified_count > 0:
                print(f" [worker] Tarea {task_id} marcada como COMPLETADA.")
            else:
                print(f" [worker] ERROR: No se encontro la tarea {task_id}.")

        except Exception as e:
            print(f" [worker] ERROR CRITICO: {e}")
            if 'task_id' in locals():
                await coleccion_tasks.update_one(
                    {"task_id": task_id},
                    {"$set": {"status": "failed", "error": str(e)}}
                )

async def main():
    connection = await aio_pika.connect_robust(RABBITMQ_URL)
    channel = await connection.channel()
    queue = await channel.declare_queue("cola_tareas", durable=True)

    print(' [*] Worker conectado. Esperando mensajes en "cola_tareas". CTRL+C para salir')

    await queue.consume(procesar_tarea)

    try:
        await asyncio.Future()
    finally:
        await connection.close()

if __name__ == "__main__":
    asyncio.run(main())
