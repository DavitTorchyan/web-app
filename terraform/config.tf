provider "aws" {
  region     = var.aws_region
  access_key = "process.env.AWS_ACCESS_KEY"
  secret_key = "process.env.AWS_SECRET_KEY"
}


terraform {
  backend "s3" {
    bucket  = "practical-task-state-store"
    key     = "david-torchyan/terraform.tfstate"
    region  = "us-east-1"
  }
}
