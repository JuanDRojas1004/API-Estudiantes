#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -e

echo ">>> Instalando API FastAPI..."

dnf install -y python3 python3-pip git

# ⚠️ CAMBIA esta URL por la de tu repositorio GitHub
git clone https://github.com/JuanDRojas1004/API-Estudiantes.git /app

cd /app

# Instalar dependencias del proyecto + boto3 para Parameter Store
pip3 install -r requirements.txt
pip3 install boto3

# Crear servicio systemd para que arranque automáticamente
cat > /etc/systemd/system/api.service << 'EOF'
[Unit]
Description=FastAPI Estudiantes
After=network.target

[Service]
WorkingDirectory=/app
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
Environment=AWS_DEFAULT_REGION=us-east-1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable api
systemctl start api

echo ">>> API lista en puerto 8000"
