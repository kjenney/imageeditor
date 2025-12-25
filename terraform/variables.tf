variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "imageeditor"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for EC2 access"
  type        = string
  default     = null
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = []
}

variable "app_port" {
  description = "Port the application runs on"
  type        = number
  default     = 80
}

# Qwen Model Configuration
variable "enable_qwen" {
  description = "Enable Qwen model support via Ollama"
  type        = bool
  default     = false
}

variable "qwen_model" {
  description = "Qwen model to install (e.g., qwen2.5:0.5b, qwen2.5:1.5b, qwen2.5:3b, qwen2.5:7b, qwen2.5:14b, qwen2.5:32b)"
  type        = string
  default     = "qwen2.5:7b"
}

variable "ollama_port" {
  description = "Port for Ollama API server"
  type        = number
  default     = 11434
}

variable "qwen_storage_size" {
  description = "EBS volume size in GB when Qwen is enabled (larger models need more storage)"
  type        = number
  default     = 50
}
