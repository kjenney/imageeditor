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
aws_region    = "us-east-1"
instance_type = "t3.micro"
environment   = "dev"
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

### 6. Connect to Instance (Optional)

Connect via AWS Systems Manager Session Manager:

```bash
terraform output ssm_session_command
```

Or use the AWS Console: EC2 → Select instance → Connect → Session Manager tab.

## Configuration Options

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `instance_type` | EC2 instance type (non-GPU) | `t3.micro` |
| `environment` | Environment name | `dev` |
| `enable_qwen_image_edit` | Enable Qwen Image Edit diffusion model | `false` |
| `qwen_model_variant` | Model variant: `full` or `fp8` | `full` |
| `gpu_instance_type` | GPU instance type | `g5.2xlarge` |
| `diffusion_api_port` | Diffusion API port | `8000` |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                         VPC                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │                  Public Subnet                     │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │         EC2 Instance (GPU optional)         │  │  │
│  │  │  ┌─────────┐    ┌───────────────────────┐  │  │  │
│  │  │  │  nginx  │────│     Image Editor      │  │  │  │
│  │  │  │ (:80)   │    │    (React Frontend)   │  │  │  │
│  │  │  └─────────┘    └───────────────────────┘  │  │  │
│  │  │                                             │  │  │
│  │  │  ┌─────────────────────────────────────┐   │  │  │
│  │  │  │   FastAPI Diffusion Server (:8000)  │   │  │  │
│  │  │  │   (Qwen-Image-Edit-2511 model)      │   │  │  │
│  │  │  └─────────────────────────────────────┘   │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
│                          │                               │
│                 Internet Gateway                         │
└──────────────────────────┼───────────────────────────────┘
                           │
                      Internet
```

## Qwen Image Edit (AI Feature)

Enable AI-powered image editing with the Qwen-Image-Edit-2511 diffusion model.

### Enable AI Image Editing

```hcl
enable_qwen_image_edit = true
gpu_instance_type      = "g5.2xlarge"
qwen_model_variant     = "full"
```

### GPU Instance Options

| Instance | GPU | VRAM | vCPU | RAM | Cost/hr |
|----------|-----|------|------|-----|---------|
| g5.xlarge | A10G | 24GB | 4 | 16GB | ~$1.01 |
| g5.2xlarge | A10G | 24GB | 8 | 32GB | ~$1.21 |
| g5.4xlarge | A10G | 24GB | 16 | 64GB | ~$1.62 |

### API Usage

After deployment, the Diffusion API is available:

```bash
# Get API URL
terraform output diffusion_api_url

# Health check
curl http://<ip>:8000/health

# Edit an image
curl -X POST "http://<ip>:8000/edit" \
  -F "image=@input.jpg" \
  -F "prompt=Add a sunset background" \
  -o output.png
```

### Model Variants

- **full**: Best quality, ~40GB download, requires 24GB VRAM
- **fp8**: Faster inference, ~20GB download, reduced VRAM usage

## Security

### Security Groups

- HTTP (80) - Open to all
- HTTPS (443) - Open to all

### Instance Access

Instance access is provided via AWS Systems Manager Session Manager, which offers:

- No inbound ports required (no SSH port 22 exposed)
- IAM-based authentication and authorization
- Session logging and auditing capabilities
- No need to manage SSH keys

### Best Practices

- Use IAM policies to control Session Manager access
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

### Cannot Connect via Session Manager

- Ensure the SSM agent is running on the instance
- Verify IAM permissions include `ssm:StartSession`
- Check that the instance has internet access (required for SSM)
- Install the Session Manager plugin for AWS CLI: [Installation Guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

### Application Not Loading

- Check nginx status: `sudo systemctl status nginx`
- View nginx logs: `sudo tail -f /var/log/nginx/error.log`
- Verify build files exist in `/var/www/html`

### Diffusion Server Issues

- Check service status: `sudo systemctl status diffusion-server`
- View logs: `sudo journalctl -u diffusion-server -f`
- Check GPU availability: `nvidia-smi`
- Verify model loaded: `curl http://localhost:8000/info`
- Model download can take 10-30 minutes on first startup

## More Information

See the [Terraform README](https://github.com/kjenney/imageeditor/tree/main/terraform) for detailed configuration options.
