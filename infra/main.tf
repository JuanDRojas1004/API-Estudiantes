provider "aws" {
  region = "us-east-1"
}

# =====================================================
# ANTES DE APLICAR: corre este comando en el contenedor
# para obtener tus valores de VPC y subnets:
#
# aws ec2 describe-subnets \
#   --query "Subnets[*].[SubnetId,VpcId,AvailabilityZone,CidrBlock]" \
#   --output table
#
# Reemplaza los valores de locals con lo que obtengas
# Necesitas 2 subnets en DISTINTAS zonas (ej: us-east-1a y us-east-1b)
# =====================================================
locals {
  vpc_id   = "vpc-043a8391f17a3322c"
  subnet_a = "subnet-0424da509989e8b19"
  subnet_b = "subnet-0e34cdbb2741cd877"
  key_name = "juanrojas"
  ami      = "ami-02dfbd4ff395f2a1b"
}

# =====================================================
# IAM: Permiso para que las EC2 lean el Parameter Store
# Sin esto, boto3 no puede leer las IPs
# =====================================================
resource "aws_iam_role" "ec2_role" {
  name = "ec2-parameter-store-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_role.name
}

# =====================================================
# SECURITY GROUPS (firewall de cada servicio)
# =====================================================

resource "aws_security_group" "sg_mongodb" {
  name        = "sg-mongodb"
  description = "MongoDB - solo acceso interno VPC + SSH"
  vpc_id      = local.vpc_id

  ingress {
    description = "MongoDB desde la VPC"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-mongodb" }
}

resource "aws_security_group" "sg_rabbitmq" {
  name        = "sg-rabbitmq"
  description = "RabbitMQ - AMQP interno + panel web publico"
  vpc_id      = local.vpc_id

  ingress {
    description = "AMQP desde la VPC"
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }
  ingress {
    description = "Panel web RabbitMQ"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-rabbitmq" }
}

resource "aws_security_group" "sg_api" {
  name        = "sg-api"
  description = "FastAPI - puerto 8000"
  vpc_id      = local.vpc_id

  ingress {
    description = "FastAPI"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-api" }
}

resource "aws_security_group" "sg_worker" {
  name        = "sg-worker"
  description = "Worker - solo SSH"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-worker" }
}

resource "aws_security_group" "sg_alb" {
  name        = "sg-alb"
  description = "Load Balancer - HTTP publico"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-alb" }
}

# =====================================================
# EC2: MongoDB
# =====================================================
resource "aws_instance" "mongodb" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  key_name               = local.key_name
  subnet_id              = local.subnet_a
  vpc_security_group_ids = [aws_security_group.sg_mongodb.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = file("${path.module}/scripts/mongodb.sh")

  tags = { Name = "ec2-mongodb", Project = "API-Estudiantes" }
}

# =====================================================
# EC2: RabbitMQ
# =====================================================
resource "aws_instance" "rabbitmq" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  key_name               = local.key_name
  subnet_id              = local.subnet_a
  vpc_security_group_ids = [aws_security_group.sg_rabbitmq.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = file("${path.module}/scripts/rabbitmq.sh")

  tags = { Name = "ec2-rabbitmq", Project = "API-Estudiantes" }
}

# =====================================================
# PARAMETER STORE: Guardar IPs privadas
# Las EC2 de la misma VPC se hablan por IP privada
# =====================================================
resource "aws_ssm_parameter" "mongodb_ip" {
  name  = "/escuela/mongodb_ip"
  type  = "String"
  value = aws_instance.mongodb.private_ip
  tags  = { Name = "param-mongodb-ip" }
}

resource "aws_ssm_parameter" "rabbitmq_ip" {
  name  = "/escuela/rabbitmq_ip"
  type  = "String"
  value = aws_instance.rabbitmq.private_ip
  tags  = { Name = "param-rabbitmq-ip" }
}

# =====================================================
# EC2: Worker
# =====================================================
resource "aws_instance" "worker" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  key_name               = local.key_name
  subnet_id              = local.subnet_a
  vpc_security_group_ids = [aws_security_group.sg_worker.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = file("${path.module}/scripts/worker.sh")

  depends_on = [aws_ssm_parameter.mongodb_ip, aws_ssm_parameter.rabbitmq_ip]

  tags = { Name = "ec2-worker", Project = "API-Estudiantes" }
}

# =====================================================
# EC2: API x2 (requerido por el balanceador)
# =====================================================
resource "aws_instance" "api_1" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  key_name               = local.key_name
  subnet_id              = local.subnet_a
  vpc_security_group_ids = [aws_security_group.sg_api.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = file("${path.module}/scripts/api.sh")

  depends_on = [aws_ssm_parameter.mongodb_ip, aws_ssm_parameter.rabbitmq_ip]

  tags = { Name = "ec2-api-1", Project = "API-Estudiantes" }
}

resource "aws_instance" "api_2" {
  ami                    = local.ami
  instance_type          = "t3.micro"
  key_name               = local.key_name
  subnet_id              = local.subnet_b  # zona distinta para el ALB
  vpc_security_group_ids = [aws_security_group.sg_api.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = file("${path.module}/scripts/api.sh")

  depends_on = [aws_ssm_parameter.mongodb_ip, aws_ssm_parameter.rabbitmq_ip]

  tags = { Name = "ec2-api-2", Project = "API-Estudiantes" }
}

# =====================================================
# LOAD BALANCER
# =====================================================
resource "aws_lb" "alb_api" {
  name               = "alb-api-estudiantes"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [local.subnet_a, local.subnet_b]

  tags = { Name = "alb-api-estudiantes" }
}

resource "aws_lb_target_group" "tg_api" {
  name     = "tg-api-estudiantes"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = "/alumnos"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_target_group_attachment" "api_1" {
  target_group_arn = aws_lb_target_group.tg_api.arn
  target_id        = aws_instance.api_1.id
  port             = 8000
}

resource "aws_lb_target_group_attachment" "api_2" {
  target_group_arn = aws_lb_target_group.tg_api.arn
  target_id        = aws_instance.api_2.id
  port             = 8000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb_api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_api.arn
  }
}

# =====================================================
# OUTPUTS
# =====================================================
output "url_load_balancer" {
  description = "Usa esta URL para hacer requests a la API"
  value       = "http://${aws_lb.alb_api.dns_name}"
}

output "swagger_ui" {
  description = "Documentacion de la API via Load Balancer"
  value       = "http://${aws_lb.alb_api.dns_name}/docs"
}

output "ip_mongodb" {
  value = "SSH: ssh -i vockey.pem ec2-user@${aws_instance.mongodb.public_ip}"
}

output "ip_rabbitmq" {
  value = "SSH: ssh -i vockey.pem ec2-user@${aws_instance.rabbitmq.public_ip}"
}

output "panel_rabbitmq" {
  value = "http://${aws_instance.rabbitmq.public_ip}:15672  (user/password)"
}

output "ip_worker" {
  value = "SSH: ssh -i vockey.pem ec2-user@${aws_instance.worker.public_ip}"
}

output "ip_api_1" {
  value = "SSH: ssh -i vockey.pem ec2-user@${aws_instance.api_1.public_ip}"
}

output "ip_api_2" {
  value = "SSH: ssh -i vockey.pem ec2-user@${aws_instance.api_2.public_ip}"
}
