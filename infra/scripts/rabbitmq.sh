#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -e

echo ">>> Instalando RabbitMQ..."

# RabbitMQ necesita Erlang
dnf install -y erlang

# Repositorio de RabbitMQ
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash

dnf install -y rabbitmq-server

systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# Activar panel web de administración
rabbitmq-plugins enable rabbitmq_management

# Crear usuario (los mismos que tienes en publisher.py y worker.py)
rabbitmqctl add_user user password
rabbitmqctl set_user_tags user administrator
rabbitmqctl set_permissions -p / user ".*" ".*" ".*"

systemctl restart rabbitmq-server

echo ">>> RabbitMQ listo"
