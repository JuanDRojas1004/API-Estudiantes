# publisher.py
import aio_pika
import json
import boto3

def get_parameter(name: str) -> str:
    """Lee una IP guardada en AWS Parameter Store"""
    ssm = boto3.client("ssm", region_name="us-east-1")
    response = ssm.get_parameter(Name=name)
    return response["Parameter"]["Value"]

# Lee la IP privada de RabbitMQ desde Parameter Store
RABBITMQ_IP = get_parameter("/escuela/rabbitmq_ip")
RABBITMQ_URL = f"amqp://user:password@{RABBITMQ_IP}/"

async def enviar_tarea(payload: dict):
    connection = await aio_pika.connect_robust(RABBITMQ_URL)

    async with connection:
        channel = await connection.channel()
        queue = await channel.declare_queue("cola_tareas", durable=True)
        mensaje_body = json.dumps(payload).encode()

        await channel.default_exchange.publish(
            aio_pika.Message(
                body=mensaje_body,
                delivery_mode=aio_pika.DeliveryMode.PERSISTENT
            ),
            routing_key="cola_tareas"
        )

    print(f" [x] Enviado a RabbitMQ: {payload['tipo']} - Task: {payload['task_id']}")
