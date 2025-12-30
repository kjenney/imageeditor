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

variable "git_branch" {
  description = "Git branch to deploy from (default: main)"
  type        = string
  default     = "main"
}

# Qwen Image Edit Configuration (ComfyUI + Lightning)
variable "enable_qwen_image_edit" {
  description = "Enable Qwen Image Edit via ComfyUI with Lightning variant (fast 4-step inference)"
  type        = bool
  default     = true
}

variable "qwen_model_variant" {
  description = "Model variant (deprecated - now uses Lightning by default)"
  type        = string
  default     = "lightning"
}

variable "gpu_instance_type" {
  description = "GPU instance type for ComfyUI (g5.2xlarge or larger recommended)"
  type        = string
  default     = "g5.2xlarge"
}

variable "diffusion_api_port" {
  description = "Port for the image editing API"
  type        = number
  default     = 8000
}

variable "qwen_storage_size" {
  description = "EBS volume size in GB for GPU instance (model files ~40GB)"
  type        = number
  default     = 120
}

variable "model_preload" {
  description = "Preload model on startup (always true with ComfyUI)"
  type        = bool
  default     = true
}

variable "huggingface_token" {
  description = "HuggingFace token for model access (optional)"
  type        = string
  default     = ""
  sensitive   = true
}
