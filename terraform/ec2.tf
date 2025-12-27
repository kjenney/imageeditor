# Get latest Amazon Linux 2023 AMI (for non-GPU instances)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Get Deep Learning AMI with NVIDIA drivers (for GPU instances)
data "aws_ami" "deep_learning" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Deep Learning Base OSS Nvidia Driver GPU AMI (Amazon Linux 2023)*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role-${var.environment}"
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
}

# Attach SSM policy for Session Manager access (primary access method - no SSH required)
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 Instance
resource "aws_instance" "app" {
  # Use Deep Learning AMI with NVIDIA drivers when diffusion model is enabled
  ami           = var.enable_qwen_image_edit ? data.aws_ami.deep_learning.id : data.aws_ami.amazon_linux_2023.id
  instance_type = var.enable_qwen_image_edit ? var.gpu_instance_type : var.instance_type

  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  # Access via AWS Systems Manager Session Manager - no SSH key required

  root_block_device {
    volume_size           = var.enable_qwen_image_edit ? var.qwen_storage_size : 30
    volume_type           = "gp3"
    iops                  = var.enable_qwen_image_edit ? 3000 : null
    throughput            = var.enable_qwen_image_edit ? 125 : null
    encrypted             = true
    delete_on_termination = true
  }

  user_data_base64            = base64encode(templatefile("${path.module}/user_data.sh", {
    app_port           = var.app_port
    enable_qwen        = var.enable_qwen_image_edit
    qwen_model_variant = var.qwen_model_variant
    diffusion_api_port = var.diffusion_api_port
    model_preload      = var.model_preload
    huggingface_token  = var.huggingface_token
  }))
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-app-${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for consistent public IP
resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-eip-${var.environment}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Separate EIP association allows instance replacement without waiting
resource "aws_eip_association" "app" {
  instance_id        = aws_instance.app.id
  allocation_id      = aws_eip.app.id
  allow_reassociation = true
}
