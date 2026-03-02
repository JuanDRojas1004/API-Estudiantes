import aio_pika
import json

# Datos de conexión (los mismos que pusimos en el docker-compose)
RABBITMQ_URL = "amqp://user:password@localhost/"

async def enviar_tarea(payload: dict):
    """
    Esta función abre una conexión, envía el mensaje a la cola y se cierra.
    """
    # 1. Conectarse a RabbitMQ
    connection = await aio_pika.connect_robust(RABBITMQ_URL)
    
    async with connection:
        # 2. Crear un canal
        channel = await connection.channel()
        
        # 3. Declarar la cola (si no existe, la crea)
        queue = await channel.declare_queue("cola_tareas", durable=True)
        
        # 4. Convertir el diccionario a JSON y luego a Bytes
        mensaje_body = json.dumps(payload).encode()
        
        # 5. Enviar el mensaje
        await channel.default_exchange.publish(
            aio_pika.Message(
                body=mensaje_body,
                delivery_mode=aio_pika.DeliveryMode.PERSISTENT # El mensaje sobrevive si Rabbit se reinicia
            ),
            routing_key="cola_tareas"
        )
        
    print(f" [x] Enviado a RabbitMQ: {payload['tipo']} - Task: {payload['task_id']}")