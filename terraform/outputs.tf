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
  value       = "aws ssm start-session --target ${aws_instance.app.id}"
}

# Qwen/Ollama outputs (conditional)
output "ollama_api_url" {
  description = "URL for the Ollama API (when Qwen is enabled)"
  value       = var.enable_qwen ? "http://${aws_eip.app.public_ip}:${var.ollama_port}" : null
}

output "qwen_model" {
  description = "Qwen model installed (when Qwen is enabled)"
  value       = var.enable_qwen ? var.qwen_model : null
}
