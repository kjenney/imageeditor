# Security Group for EC2 Instance
# Note: SSH access is not required - use AWS Systems Manager Session Manager instead
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg-${var.environment}"
  description = "Security group for imageeditor application"
  vpc_id      = aws_vpc.main.id

  # HTTP access from anywhere
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Diffusion API access (conditional - when Qwen Image Edit is enabled)
  dynamic "ingress" {
    for_each = var.enable_qwen_image_edit ? [1] : []
    content {
      description = "Diffusion API (FastAPI)"
      from_port   = var.diffusion_api_port
      to_port     = var.diffusion_api_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg-${var.environment}"
  }
}
