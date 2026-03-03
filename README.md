```markdown
# API de Gestión de Alumnos - Arquitectura Asíncrona 🚀

![Python](https://img.shields.io/badge/python-3.10+-blue.svg)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100.0+-009688.svg)
![RabbitMQ](https://img.shields.io/badge/RabbitMQ-Broker-orange.svg)
![MongoDB](https://img.shields.io/badge/MongoDB-NoSQL-green.svg)

Este proyecto consiste en una API desarrollada con **FastAPI** para la gestión de alumnos. La arquitectura está diseñada para ser asíncrona, utilizando **RabbitMQ** como broker de mensajería para desacoplar las operaciones de creación y eliminación, mejorando la escalabilidad y respuesta del sistema.



## 🏗️ Arquitectura del Sistema

La solución implementa un flujo de **Productor-Consumidor**:
1.  **Producer (FastAPI):** Recibe las solicitudes, genera un `task_id` (UUID), registra la tarea en MongoDB y publica el mensaje en RabbitMQ.
2.  **Broker (RabbitMQ):** Gestiona la cola y asegura que los mensajes lleguen al Worker.
3.  **Consumer (Worker):** Procesa la lógica de negocio de forma independiente y actualiza el estado de la tarea en la base de datos.

## 📋 Endpoints

### Gestión de Alumnos
- `POST /alumnos`: Inicia el registro de un alumno (Retorna un `task_id`).
- `GET /alumnos`: Lista todos los alumnos procesados.
- `PUT /alumnos/{id}`: Actualización síncrona de datos.
- `DELETE /alumnos/{id}`: Encola la solicitud de eliminación.

### Control de Tareas
- `GET /tasks/{task_id}`: Consulta el estado de una operación (`pending`, `completed`, `error`).

---

## 🛠️ Guía de Instalación y Ejecución

Sigue estos pasos para configurar tu entorno local:

### 1. Clonar el repositorio
```bash
git clone [https://github.com/JuanDRojas1004/API-Estudiantes.git](https://github.com/JuanDRojas1004/API-Estudiantes.git)
cd API-Estudiantes

```

### 2. Configurar el Entorno Virtual

Es recomendable usar un entorno virtual para aislar las dependencias:

```bash
# Crear entorno virtual
python -m venv venv

# Activar el entorno
# En Windows:
venv\Scripts\activate
# En Linux/Mac:
source venv/bin/activate

```

### 3. Instalación de Requirements

Instala todas las librerías necesarias (FastAPI, Motor, Pika, etc.) ejecutando:

```bash
pip install -r requirements.txt

```

### 4. Levantar la API

Una vez instaladas las dependencias y con tus servicios de MongoDB y RabbitMQ activos, inicia el servidor:

```bash
uvicorn main:app --reload
docker-compose up --build

```

*La API estará disponible en: **http://localhost:8000***
*Puedes probar los endpoints en: **http://localhost:8000/docs** (Swagger UI)*

---

## 🛡️ Análisis Estático (MyPy)

Este proyecto utiliza **MyPy** para asegurar la integridad de los tipos de datos. Para ejecutar el chequeo:

```bash
mypy .

```

---

## 📦 Estructura del Proyecto

* `main.py`: Lógica de los endpoints y FastAPI.
* `database.py`: Conexión asíncrona a MongoDB.
* `publisher.py`: Integración con RabbitMQ.
* `schemas/`: Validaciones de datos con Pydantic.
* `requirements.txt`: Lista de dependencias del proyecto.

---

## 👤 Autor

* **Nombre:** Juan David Rojas
* **Email:** [juandrojas1004@gmail.com](mailto:juandrojas1004@gmail.com)
* **Institución:** Universidad Javeriana


```