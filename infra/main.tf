terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "macro-snapshot"
}

# S3 bucket
resource "aws_s3_bucket" "raw" {
  bucket        = local.bucket_name
  force_destroy = true
  tags = {
    Project = var.project_tag
  }
}

# IAM role for Lambda + S3
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "macro_lambda_role-${var.project_tag}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = ""
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = ["${aws_s3_bucket.raw.arn}", "${aws_s3_bucket.raw.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = ["logs:*"]
        Resource = "*"
      }
    ]
  })
}

# RDS Postgres (micro, free tier if available)
resource "aws_db_instance" "pg" {
  identifier           = "macro-snap-pg"
  engine               = "postgres"
  engine_version       = "15.5"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "macrodb"
  username             = "macro_etl"
  password             = var.db_password
  skip_final_snapshot  = true
}

output "bucket" {
  value = aws_s3_bucket.raw.id
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "pg_endpoint" {
  value = aws_db_instance.pg.address
}
