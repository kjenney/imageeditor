variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication (optional)"
  type        = string
  default     = null
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

variable "app_port" {
  description = "Port the application runs on"
  type        = number
  default     = 80
}

# Qwen Image Edit Configuration (Diffusion Model)
variable "enable_qwen_image_edit" {
  description = "Enable Qwen Image Edit diffusion model via FastAPI + Diffusers"
  type        = bool
  default     = true
}

variable "qwen_model_variant" {
  description = "Qwen Image Edit model variant: 'full' (best quality) or 'fp8' (faster, less VRAM)"
  type        = string
  default     = "full"

  validation {
    condition     = contains(["full", "fp8"], var.qwen_model_variant)
    error_message = "qwen_model_variant must be 'full' or 'fp8'"
  }
}

variable "gpu_instance_type" {
  description = "GPU instance type for diffusion model (g5.xlarge minimum for 24GB VRAM)"
  type        = string
  default     = "g5.2xlarge"
}

variable "diffusion_api_port" {
  description = "Port for FastAPI diffusion model server"
  type        = number
  default     = 8000
}

variable "qwen_storage_size" {
  description = "EBS volume size in GB for GPU instance (model is ~40GB, need space for CUDA/Python)"
  type        = number
  default     = 120
}

variable "model_preload" {
  description = "Preload model on startup (true) or lazy load on first request (false)"
  type        = bool
  default     = true
}

variable "huggingface_token" {
  description = "HuggingFace token for model access (optional)"
  type        = string
  default     = ""
  sensitive   = true
}
