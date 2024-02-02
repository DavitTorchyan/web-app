variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "aws_credential_file" {
  description = "AWS credentials file location"
  type        = string
  default     = "~/.aws/credentials"
}

variable "aws_config_profile" {
  description = ""
  type        = string
  default     = "torch-task"
}
