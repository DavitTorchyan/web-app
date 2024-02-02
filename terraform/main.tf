locals {
  name = "web-app"
}

resource "aws_ecr_repository" "app" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.0"

  name = "${local.name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = true

  public_subnet_tags = {
    "Name" = "public-subnet"
    "Tier" = "public"
  }

  private_subnet_tags = {
    "Name" = "private-subnet"
    "Tier" = "private"
  }
}

resource "aws_ecs_cluster" "app" {
  name = local.name

  tags = {
    name = local.name
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "${local.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = local.name
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_security_group" "app_sg" {
  name        = "${local.name}-sg"
  description = "Allow web traffic to ECS service"
  vpc_id      = module.vpc.vpc_id

  ingress {
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

  tags = {
    Name = local.name
  }
}

resource "aws_ecs_service" "app_service" {
  name            = "${local.name}-ecs-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets         = module.vpc.public_subnets
    assign_public_ip = true
    security_groups = [aws_security_group.app_sg.id]
  }
}
