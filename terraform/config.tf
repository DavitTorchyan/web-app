provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = [var.aws_credential_file]
  profile                  = var.aws_config_profile
}


terraform {
  backend "s3" {
    bucket  = "practical-task-state-store"
    key     = "david-torchyan/terraform.tfstate"
    region  = "us-east-1"
    profile = "david-torchyan"
  }
}
