# Terraform Infrastructure for Image Editor

This directory contains Terraform configuration to deploy the Image Editor application on AWS EC2.

## Architecture

The infrastructure includes:

- **VPC**: A dedicated Virtual Private Cloud with public subnets across multiple availability zones
- **Internet Gateway**: For public internet access
- **Security Groups**: Configured for HTTP/HTTPS traffic with optional SSH access
- **EC2 Instance**: Amazon Linux 2023 instance running nginx to serve the application
- **Elastic IP**: Static public IP address for consistent access
- **IAM Role**: Instance profile with SSM access for secure management

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) >= 1.0.0
2. [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
3. AWS account with permissions to create VPC, EC2, IAM, and related resources

## Quick Start

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your desired configuration

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the planned changes:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

6. Access the application using the output URL:
   ```bash
   terraform output app_url
   ```

## Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region to deploy resources | `us-east-1` |
| `environment` | Environment name (dev, staging, prod) | `dev` |
| `project_name` | Name of the project | `imageeditor` |
| `vpc_cidr` | CIDR block for VPC | `10.0.0.0/16` |
| `public_subnet_cidrs` | CIDR blocks for public subnets | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `key_name` | SSH key pair name (optional) | `null` |
| `allowed_ssh_cidrs` | CIDR blocks allowed to SSH | `[]` |
| `app_port` | Port the application runs on | `80` |

## Outputs

After applying the configuration, you'll get:

- `vpc_id`: ID of the created VPC
- `public_subnet_ids`: IDs of the public subnets
- `instance_id`: ID of the EC2 instance
- `instance_private_ip`: Private IP of the instance
- `instance_public_ip`: Elastic IP of the instance
- `app_url`: URL to access the application
- `security_group_id`: ID of the security group

## SSH Access

To enable SSH access:

1. Create or use an existing EC2 key pair
2. Set `key_name` to your key pair name
3. Add your IP to `allowed_ssh_cidrs`: `["YOUR.IP.ADDRESS/32"]`

Alternatively, use AWS Systems Manager Session Manager (SSM) which is enabled by default.

## Destroying Resources

To tear down all created resources:

```bash
terraform destroy
```

## Security Considerations

- SSH access is disabled by default; use SSM Session Manager instead
- All EBS volumes are encrypted
- Security groups restrict inbound traffic to only necessary ports
- Instance has minimal IAM permissions

## Cost Estimation

With default settings (t3.micro in us-east-1):
- EC2: ~$7.59/month (on-demand)
- EBS (20GB gp3): ~$1.60/month
- Elastic IP: Free when attached to running instance
- Data transfer: Variable based on usage

**Note**: Use AWS Free Tier eligible instance types for development to minimize costs.
