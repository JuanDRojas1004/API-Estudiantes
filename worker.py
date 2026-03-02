import asyncio
import aio_pika
import json
from bson import ObjectId
# Importamos las colecciones y el motor de la base de datos
from database import coleccion, coleccion_tasks 

# Configuración de conexión (Asegúrate de que sea la misma de tu publisher)
RABBITMQ_URL = "amqp://user:password@localhost/"

async def procesar_tarea(mensaje: aio_pika.IncomingMessage):
    """
    Esta función es la que se ejecuta cada vez que llega un mensaje a la cola.
    """
    async with mensaje.process(): # El 'with' asegura que el mensaje se borre de la cola al terminar
        try:
            # 1. Decodificar el mensaje
            body = json.loads(mensaje.body.decode())
            task_id = body.get("task_id")
            tipo = body.get("tipo")
            data = body.get("data")
            alumno_id = body.get("alumno_id")

            print(f" [worker] Iniciando tarea: {task_id} | Tipo: {tipo}")

            # 2. Ejecutar la acción real en la colección de alumnos
            if tipo == "post":
                # Creamos el alumno en la DB real
                await coleccion.insert_one(data)
                print(f" [worker] Alumno creado exitosamente.")

            elif tipo == "delete":
                # Borramos el alumno de la DB real
                await coleccion.delete_one({"_id": ObjectId(alumno_id)})
                print(f" [worker] Alumno eliminado exitosamente.")

            # 3. ACTUALIZAR EL STATUS DE LA TAREA
            # Esto es lo que hace que en Swagger/Postman dejes de ver 'pending'
            resultado = await coleccion_tasks.update_one(
                {"task_id": task_id},
                {"$set": {"status": "completed", "finalizado_en": json.dumps(str(asyncio.get_event_loop().time()))}}
            )
            
            if resultado.modified_count > 0:
                print(f" [worker] Tarea {task_id} marcada como COMPLETADA en MongoDB.")
            else:
                print(f" [worker] ERROR: No se encontró la tarea {task_id} en la colección 'tasks'.")

        except Exception as e:
            print(f" [worker] ERROR CRÍTICO: {e}")
            # Si algo falla, intentamos marcar la tarea como fallida
            if 'task_id' in locals():
                await coleccion_tasks.update_one(
                    {"task_id": task_id},
                    {"$set": {"status": "failed", "error": str(e)}}
                )

async def main():
    # Establecer conexión con RabbitMQ
    connection = await aio_pika.connect_robust(RABBITMQ_URL)
    channel = await connection.channel()

    # Declarar la cola (debe llamarse igual que en el publisher.py)
    queue = await channel.declare_queue("cola_tareas", durable=True)

    print(' [*] Worker conectado. Esperando mensajes en "cola_tareas". Para salir: CTRL+C')

    # Comenzar a consumir
    await queue.consume(procesar_tarea)

    # Mantener el script corriendo indefinidamente
    try:
        await asyncio.Future()
    finally:
        await connection.close()

if __name__ == "__main__":
    asyncio.run(main())