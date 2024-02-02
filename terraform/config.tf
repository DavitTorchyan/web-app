provider "aws" {
  region     = var.aws_region
}


terraform {
  backend "s3" {
    bucket  = "practical-task-state-store"
    key     = "david-torchyan/terraform.tfstate"
    region  = "us-east-1"
  }
}
