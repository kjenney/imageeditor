# Terraform Infrastructure for Image Editor

This directory contains Terraform configuration to deploy the Image Editor application on AWS EC2.

## Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Options](#configuration-options)
- [Outputs](#outputs)
- [SSH Access](#ssh-access)
- [Updating the Application](#updating-the-application)
- [Monitoring and Logs](#monitoring-and-logs)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Cost Estimation](#cost-estimation)
- [Destroying Resources](#destroying-resources)

## Architecture

The infrastructure deploys the Image Editor application on AWS with the following components:

```
                                   ┌─────────────────────────────────────────────────────────────┐
                                   │                         AWS Cloud                           │
                                   │  ┌───────────────────────────────────────────────────────┐  │
                                   │  │                    VPC (10.0.0.0/16)                  │  │
                                   │  │                                                       │  │
                                   │  │  ┌─────────────────┐    ┌─────────────────┐          │  │
     ┌──────────┐                  │  │  │ Public Subnet 1 │    │ Public Subnet 2 │          │  │
     │  Users   │                  │  │  │  (10.0.1.0/24)  │    │  (10.0.2.0/24)  │          │  │
     │          │                  │  │  │    AZ: us-*-1a  │    │    AZ: us-*-1b  │          │  │
     └────┬─────┘                  │  │  │                 │    │                 │          │  │
          │                        │  │  │ ┌─────────────┐ │    │                 │          │  │
          │ HTTP/HTTPS             │  │  │ │ EC2 Instance│ │    │   (Available    │          │  │
          │                        │  │  │ │             │ │    │    for future   │          │  │
          ▼                        │  │  │ │ ┌─────────┐ │ │    │    scaling)     │          │  │
     ┌──────────┐  ┌──────────┐    │  │  │ │ │  nginx  │ │ │    │                 │          │  │
     │ Internet │──│ Internet │────│──│──│ │ │ :80/:443│ │ │    │                 │          │  │
     │          │  │ Gateway  │    │  │  │ │ └─────────┘ │ │    │                 │          │  │
     └──────────┘  └──────────┘    │  │  │ │             │ │    │                 │          │  │
          │                        │  │  │ │ Elastic IP  │ │    │                 │          │  │
          │                        │  │  │ └─────────────┘ │    │                 │          │  │
          │                        │  │  │                 │    │                 │          │  │
          │                        │  │  │ Security Group │    │                 │          │  │
          │                        │  │  │ - HTTP (80)    │    │                 │          │  │
          │                        │  │  │ - HTTPS (443)  │    │                 │          │  │
          │                        │  │  │ - SSH (22)*    │    │                 │          │  │
          │                        │  │  └─────────────────┘    └─────────────────┘          │  │
          │                        │  │                                                       │  │
          │                        │  └───────────────────────────────────────────────────────┘  │
          │                        │                                                             │
          │                        │  ┌───────────────────────────────────────────────────────┐  │
          │                        │  │                    IAM Role                           │  │
          │                        │  │  - SSM Managed Instance Core (for Session Manager)   │  │
          │                        │  └───────────────────────────────────────────────────────┘  │
          │                        │                                                             │
          └────────────────────────┴─────────────────────────────────────────────────────────────┘

                                   * SSH access is optional and disabled by default
```

### Components

| Component | Description |
|-----------|-------------|
| **VPC** | Dedicated Virtual Private Cloud with DNS hostnames enabled |
| **Public Subnets** | Two subnets across different availability zones for high availability |
| **Internet Gateway** | Enables internet access for resources in public subnets |
| **Security Groups** | Firewall rules for HTTP (80), HTTPS (443), and optional SSH (22) |
| **EC2 Instance** | Amazon Linux 2023 running nginx to serve the application |
| **Elastic IP** | Static public IP address for consistent access |
| **IAM Role** | Instance profile with SSM access for secure management |

## Prerequisites

1. **Terraform** >= 1.0.0 ([Download](https://www.terraform.io/downloads.html))
2. **AWS CLI** configured with appropriate credentials ([Install](https://aws.amazon.com/cli/))
3. **AWS Account** with permissions to create:
   - VPC and networking resources
   - EC2 instances and related resources
   - IAM roles and policies
   - Elastic IPs

### Verify Installation

```bash
# Check Terraform version
terraform version

# Verify AWS CLI configuration
aws sts get-caller-identity
```

## Quick Start

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with your desired configuration (optional - defaults work for most cases)

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the planned changes:**
   ```bash
   terraform plan
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply
   ```
   Type `yes` when prompted to confirm.

6. **Access the application:**
   ```bash
   # Get the application URL
   terraform output app_url

   # Open in browser
   open $(terraform output -raw app_url)
   ```

## Configuration Options

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region to deploy resources | `us-east-1` | No |
| `environment` | Environment name (dev, staging, prod) | `dev` | No |
| `project_name` | Name of the project for resource naming | `imageeditor` | No |
| `vpc_cidr` | CIDR block for VPC | `10.0.0.0/16` | No |
| `public_subnet_cidrs` | CIDR blocks for public subnets | `["10.0.1.0/24", "10.0.2.0/24"]` | No |
| `instance_type` | EC2 instance type | `t3.micro` | No |
| `key_name` | SSH key pair name (optional) | `null` | No |
| `allowed_ssh_cidrs` | CIDR blocks allowed to SSH | `[]` | No |
| `app_port` | Port the application runs on | `80` | No |

### Environment Examples

**Development (default):**
```hcl
environment   = "dev"
instance_type = "t3.micro"
```

**Production:**
```hcl
environment   = "prod"
instance_type = "t3.small"
```

## Outputs

After applying the configuration, Terraform provides these outputs:

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the created VPC |
| `public_subnet_ids` | IDs of the public subnets |
| `instance_id` | ID of the EC2 instance |
| `instance_private_ip` | Private IP of the instance |
| `instance_public_ip` | Elastic IP of the instance |
| `app_url` | URL to access the application |
| `security_group_id` | ID of the security group |

**View all outputs:**
```bash
terraform output
```

**View specific output:**
```bash
terraform output app_url
```

## SSH Access

### Option 1: AWS Systems Manager Session Manager (Recommended)

SSM Session Manager is enabled by default and provides secure, auditable access without opening SSH ports.

```bash
# Start a session
aws ssm start-session --target $(terraform output -raw instance_id)
```

### Option 2: Traditional SSH

To enable SSH access:

1. **Create or use an existing EC2 key pair**
2. **Update `terraform.tfvars`:**
   ```hcl
   key_name          = "your-key-pair-name"
   allowed_ssh_cidrs = ["YOUR.IP.ADDRESS/32"]
   ```
3. **Apply the changes:**
   ```bash
   terraform apply
   ```
4. **Connect via SSH:**
   ```bash
   ssh -i ~/.ssh/your-key.pem ec2-user@$(terraform output -raw instance_public_ip)
   ```

## Updating the Application

To deploy a new version of the application:

### Method 1: Recreate the Instance

```bash
# Taint the instance to force recreation
terraform taint aws_instance.app

# Apply to create new instance with latest code
terraform apply
```

### Method 2: Manual Update on Instance

```bash
# Connect to the instance
aws ssm start-session --target $(terraform output -raw instance_id)

# Update the application
cd /var/www/imageeditor
sudo git pull
sudo npm ci --production=false
sudo npm run build
sudo cp -r dist/* /usr/share/nginx/html/
sudo systemctl reload nginx
```

## Monitoring and Logs

### Application Logs

```bash
# View user-data bootstrap logs
sudo cat /var/log/user-data.log

# View nginx access logs
sudo tail -f /var/log/nginx/access.log

# View nginx error logs
sudo tail -f /var/log/nginx/error.log
```

### Instance Metrics

Monitor via AWS Console:
1. Navigate to EC2 → Instances → Select instance
2. Click on "Monitoring" tab
3. View CPU, Network, and Disk metrics

### Health Check

```bash
# Check if nginx is running
curl -I http://$(terraform output -raw instance_public_ip)
```

## Troubleshooting

### Common Issues

#### Application not accessible after deployment

**Wait for initialization:** The instance takes 3-5 minutes to complete setup after creation.

**Check instance status:**
```bash
aws ec2 describe-instance-status --instance-ids $(terraform output -raw instance_id)
```

**View bootstrap logs:**
```bash
aws ssm start-session --target $(terraform output -raw instance_id)
# Then run:
sudo cat /var/log/user-data.log
```

#### nginx not starting

```bash
# Check nginx status
sudo systemctl status nginx

# Check nginx configuration
sudo nginx -t

# View nginx error logs
sudo cat /var/log/nginx/error.log
```

#### SSH connection refused

- Verify `key_name` is set and the key pair exists in your AWS region
- Ensure your IP is in `allowed_ssh_cidrs`
- Check security group rules in AWS Console

#### Terraform apply fails

**Provider version issues:**
```bash
terraform init -upgrade
```

**State lock issues:**
```bash
terraform force-unlock <LOCK_ID>
```

### Getting Support

1. Check the [GitHub Issues](https://github.com/kjenney/imageeditor/issues)
2. Review AWS CloudWatch logs
3. Check instance system logs in AWS Console

## Security Considerations

| Feature | Implementation |
|---------|----------------|
| SSH Access | Disabled by default; use SSM Session Manager instead |
| EBS Encryption | All volumes encrypted at rest |
| Security Groups | Minimal ingress rules (only necessary ports) |
| IAM Permissions | Least privilege principle applied |
| HTTPS | Security headers configured in nginx |

### Security Best Practices

1. **Use SSM Session Manager** instead of SSH for administrative access
2. **Restrict SSH CIDR blocks** if SSH is required
3. **Enable HTTPS** with a valid SSL certificate for production
4. **Regularly update** the instance packages
5. **Review security group rules** periodically

## Cost Estimation

### Monthly Costs (us-east-1, on-demand pricing)

| Resource | Configuration | Estimated Cost |
|----------|---------------|----------------|
| EC2 Instance | t3.micro | ~$7.59/month |
| EBS Storage | 20GB gp3 | ~$1.60/month |
| Elastic IP | Attached to running instance | Free |
| Data Transfer | Variable | ~$0.09/GB outbound |
| **Total** | | **~$9-15/month** |

### Cost Optimization Tips

1. **Use t3.micro** for development (Free Tier eligible for 12 months)
2. **Consider Reserved Instances** for production (up to 72% savings)
3. **Use Spot Instances** for non-critical workloads
4. **Stop instances** when not in use

## Destroying Resources

To tear down all infrastructure:

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

Type `yes` when prompted to confirm.

**Warning:** This will permanently delete all resources including the EC2 instance and data. Ensure you have backups of any important data.

---

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [nginx Documentation](https://nginx.org/en/docs/)
- [Image Editor Repository](https://github.com/kjenney/imageeditor)
