# ⚠️ INTENTIONALLY MISCONFIGURED TERRAFORM — for Snyk IaC demo only. Do not deploy.
# Each resource below trips one or more Snyk IaC rules.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Public, unencrypted S3 bucket (SNYK-CC-TF-1, public ACL + no SSE)
resource "aws_s3_bucket" "statements" {
  bucket = "patchmutual-customer-statements"
}

resource "aws_s3_bucket_acl" "statements" {
  bucket = aws_s3_bucket.statements.id
  acl    = "public-read"
}

resource "aws_s3_bucket_public_access_block" "statements" {
  bucket                  = aws_s3_bucket.statements.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Security group open to the world on SSH and RDP (SNYK-CC-TF-1 / 0.0.0.0/0 ingress)
resource "aws_security_group" "wide_open" {
  name        = "patchmutual-wide-open"
  description = "Allows all inbound from anywhere"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "RDP from anywhere"
    from_port   = 3389
    to_port     = 3389
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

# Unencrypted, publicly accessible RDS instance with a hardcoded password
resource "aws_db_instance" "bankdb" {
  identifier          = "patchmutual-bankdb"
  engine              = "mysql"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  username            = "admin"
  password            = "Password123!" # hardcoded secret + weak
  storage_encrypted   = false          # no encryption at rest
  publicly_accessible = true           # reachable from the internet
  skip_final_snapshot = true
}

# EBS volume without encryption
resource "aws_ebs_volume" "data" {
  availability_zone = "us-east-1a"
  size              = 40
  encrypted         = false
}
