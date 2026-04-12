#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -e

echo ">>> Instalando Worker..."

dnf install -y python3 python3-pip git

# ⚠️ CAMBIA esta URL por la de tu repositorio GitHub
git clone https://github.com/JuanDRojas1004/API-Estudiantes.git /app

cd /app

pip3 install -r requirements.txt
pip3 install boto3

cat > /etc/systemd/system/worker.service << 'EOF'
[Unit]
Description=Worker RabbitMQ Estudiantes
After=network.target

[Service]
WorkingDirectory=/app
ExecStart=/usr/bin/python3 worker.py
Restart=always
RestartSec=10
Environment=AWS_DEFAULT_REGION=us-east-1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable worker
systemctl start worker

echo ">>> Worker listo"
