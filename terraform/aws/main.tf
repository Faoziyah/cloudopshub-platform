# main.tf — AWS Infrastructure for CloudOpsHub
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket = "cloudopshub-tfstate"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" { region = "us-east-1" }

# VPC (Virtual Private Cloud — our private network in AWS)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "cloudopshub-vpc" }
}

# Public Subnets (where our worker nodes live)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "cloudopshub-pub-a", "kubernetes.io/role/elb" = "1" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "cloudopshub-pub-b", "kubernetes.io/role/elb" = "1" }
}

# Internet Gateway (lets our cluster talk to the internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "cloudopshub-igw" }
}

# Route table (tells traffic where to go)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route { cidr_block = "0.0.0.0/0", gateway_id = aws_internet_gateway.igw.id }
  tags = { Name = "cloudopshub-rt" }
}
resource "aws_route_table_association" "a" { subnet_id = aws_subnet.public_a.id, route_table_id = aws_route_table.public.id }
resource "aws_route_table_association" "b" { subnet_id = aws_subnet.public_b.id, route_table_id = aws_route_table.public.id }

# S3 Bucket for backups and Terraform state
resource "aws_s3_bucket" "backups" {
  bucket        = "cloudopshub-velero-backups"
  force_destroy = true
  tags          = { Name = "cloudopshub-backups" }
}