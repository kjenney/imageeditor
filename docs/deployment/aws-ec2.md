# AWS EC2 Deployment

Deploy Image Editor to AWS EC2 using Terraform.

## Overview

The Terraform configuration provisions:

- VPC with public subnet
- Security groups for web traffic
- EC2 instance with nginx
- Automated application deployment

## Prerequisites

- AWS account with appropriate permissions
- Terraform 1.0.0+
- AWS CLI configured with credentials

## Quick Start

### 1. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings:

```hcl
aws_region     = "us-east-1"
instance_type  = "t3.micro"
ssh_key_name   = "your-key-pair-name"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Plan

```bash
terraform plan
```

### 4. Apply

```bash
terraform apply
```

Confirm with `yes` when prompted.

### 5. Access Application

Get the application URL:

```bash
terraform output app_url
```

## Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `ssh_key_name` | SSH key pair name | Required |
| `environment` | Environment name | `production` |

## Architecture

```
┌─────────────────────────────────────────────────┐
│                     VPC                         │
│  ┌──────────────────────────────────────────┐  │
│  │            Public Subnet                  │  │
│  │  ┌────────────────────────────────────┐  │  │
│  │  │         EC2 Instance               │  │  │
│  │  │  ┌─────────┐    ┌───────────────┐  │  │  │
│  │  │  │  nginx  │────│  Image Editor │  │  │  │
│  │  │  └─────────┘    └───────────────┘  │  │  │
│  │  └────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────┘  │
│                       │                         │
│              Internet Gateway                   │
└───────────────────────┼─────────────────────────┘
                        │
                   Internet
```

## Security

### Security Groups

- HTTP (80) - Open to all
- HTTPS (443) - Open to all
- SSH (22) - Restricted to your IP (configure in tfvars)

### Best Practices

- Use a bastion host for SSH access in production
- Enable AWS WAF for additional protection
- Configure SSL certificates via ACM

## Maintenance

### Updating the Application

1. Build new version locally
2. Upload to S3 or rebuild on instance
3. Restart nginx if needed

### Scaling

For higher traffic:

1. Use a larger instance type
2. Add Application Load Balancer
3. Configure Auto Scaling Group

## Cleanup

Remove all resources:

```bash
terraform destroy
```

!!! warning "Data Loss"
    This will delete all AWS resources. Ensure you have backups if needed.

## Troubleshooting

### Cannot SSH to Instance

- Check security group SSH rule
- Verify key pair name is correct
- Ensure instance has public IP

### Application Not Loading

- Check nginx status: `sudo systemctl status nginx`
- View nginx logs: `sudo tail -f /var/log/nginx/error.log`
- Verify build files exist in `/var/www/html`

## More Information

See the [Terraform README](https://github.com/kjenney/imageeditor/tree/main/terraform) for detailed configuration options.
