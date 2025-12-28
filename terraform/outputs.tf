output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app.id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.app.private_ip
}

output "instance_public_ip" {
  description = "Elastic IP address of the EC2 instance"
  value       = aws_eip.app.public_ip
}

output "app_url" {
  description = "URL to access the application"
  value       = "http://${aws_eip.app.public_ip}"
}

output "security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "ssm_session_command" {
  description = "AWS CLI command to connect via Session Manager"
  value       = var.aws_profile != null ? "aws ssm start-session --target ${aws_instance.app.id} --profile ${var.aws_profile}" : "aws ssm start-session --target ${aws_instance.app.id}"
}

# Qwen Image Edit outputs (conditional)
output "diffusion_api_url" {
  description = "URL for the Diffusion API (when Qwen Image Edit is enabled)"
  value       = var.enable_qwen_image_edit ? "http://${aws_eip.app.public_ip}:${var.diffusion_api_port}" : null
}

output "qwen_model_variant" {
  description = "Qwen Image Edit model variant installed (when enabled)"
  value       = var.enable_qwen_image_edit ? var.qwen_model_variant : null
}

output "gpu_instance_type" {
  description = "GPU instance type used (when Qwen Image Edit is enabled)"
  value       = var.enable_qwen_image_edit ? var.gpu_instance_type : null
}
