locals {
  prefix = "${var.app_name}-${var.environment}"
}

# ── Networking — use default VPC ──────────────────────────────────────────────

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "eb" {
  name        = "${local.prefix}-eb"
  description = "Elastic Beanstalk instances"
  vpc_id      = data.aws_vpc.default.id

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
}

resource "aws_security_group" "rds" {
  name        = "${local.prefix}-rds"
  description = "RDS PostgreSQL — allow from Elastic Beanstalk only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eb.id]
  }
}

# ── IAM Role for Elastic Beanstalk EC2 instances ──────────────────────────────

resource "aws_iam_role" "eb" {
  name = "${local.prefix}-eb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eb_web" {
  role       = aws_iam_role.eb.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "eb" {
  name = "${local.prefix}-eb-profile"
  role = aws_iam_role.eb.name
}

# ── Elastic Beanstalk ─────────────────────────────────────────────────────────
# Python 3.12, single t3.micro instance (no cold start, no load balancer).
# Deploy via: eb deploy  or  the app CI/CD workflow.
# Requires a Procfile at repo root: web: uvicorn main:app --host 0.0.0.0 --port 5000

data "aws_elastic_beanstalk_solution_stack" "python" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023 .* running Python 3.12$"
}

resource "aws_elastic_beanstalk_application" "main" {
  name = local.prefix
}

resource "aws_elastic_beanstalk_environment" "main" {
  name                = local.prefix
  application         = aws_elastic_beanstalk_application.main.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.python.name
  tier                = "WebServer"

  # Single instance — no load balancer, cheapest option
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.eb.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", data.aws_subnets.default.ids)
  }

  # App environment variables — map to settings.py prefixes
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APP_NAME"
    value     = var.app_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_HOST"
    value     = aws_db_instance.main.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_PORT"
    value     = "5432"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_NAME"
    value     = var.db_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_USER"
    value     = var.db_user
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_PASSWORD"
    value     = var.db_password
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CORS_ALLOWED_ORIGINS"
    value     = jsonencode(var.cors_allowed_origins)
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CORS_ALLOWED_METHODS"
    value     = jsonencode(var.cors_allowed_methods)
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CORS_ALLOWED_HEADERS"
    value     = jsonencode(var.cors_allowed_headers)
  }
}

# ── RDS PostgreSQL ────────────────────────────────────────────────────────────
# db.t4g.micro — cheapest option (~$12/month), no multi-AZ.

resource "aws_db_subnet_group" "main" {
  name       = "${local.prefix}-db"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "main" {
  identifier           = local.prefix
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t4g.micro"
  allocated_storage    = 20
  db_name              = var.db_name
  username             = var.db_user
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true

  backup_retention_period = 7
}
