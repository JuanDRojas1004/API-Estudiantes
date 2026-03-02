# API de Gestión de Estudiantes (Asincrónica)

Esta API permite la gestión de alumnos utilizando una arquitectura orientada a eventos. Utiliza **FastAPI** para la interfaz, **MongoDB** para el almacenamiento y **RabbitMQ** como broker de mensajería para el procesamiento en segundo plano.



## 🚀 Características
* **Procesamiento Asíncrono:** Las operaciones de creación y eliminación no bloquean la API; se delegan a un Worker vía RabbitMQ.
* **Seguimiento de Tareas:** Cada solicitud genera un `task_id` (UUID) para consultar el estado del proceso en tiempo real.
* **Documentación Automática:** Integración total con Swagger UI para pruebas rápidas.
* **Validación Robusta:** Uso de Pydantic para esquemas y MyPy para análisis estático de tipos.

## 📋 Endpoints Principales

### Alumnos
| Método | Ruta | Descripción | Estado esperado |
| :--- | :--- | :--- | :--- |
| **POST** | `/alumnos` | Inicia creación de alumno (Encola tarea) | `202 Accepted` |
| **GET** | `/alumnos` | Lista todos los alumnos en la base de datos | `200 OK` |
| **PUT** | `/alumnos/{id}` | Actualización directa de datos | `200 OK` |
| **DELETE** | `/alumnos/{id}` | Inicia eliminación de alumno (Encola tarea) | `202 Accepted` |

### Tareas (Tasks)
| Método | Ruta | Descripción |
| :--- | :--- | :--- |
| **GET** | `/tasks/{task_id}` | Consulta si una tarea está `pending`, `completed` o tiene `error`. |

---

## ⚙️ Configuración del Proyecto

### 1. Requisitos
* Python 3.10+
* MongoDB corriendo (Colecciones: `alumnos` y `tasks`)
* RabbitMQ activo

### 2. Instalación
```bash
pip install fastapi uvicorn motor pika pydantic