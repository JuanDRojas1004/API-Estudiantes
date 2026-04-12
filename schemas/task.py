from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class TaskStatus(BaseModel):
    task_id: str
    status: str
    tipo_tarea: str
    creado_en: datetime
    error: Optional[str] = None