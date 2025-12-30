#!/bin/bash
set -e

# Log all output to a file for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting imageeditor setup..."

# Template variables
ENABLE_QWEN="${enable_qwen}"
MODEL_VARIANT="${qwen_model_variant}"
DIFFUSION_PORT="${diffusion_api_port}"
MODEL_PRELOAD="${model_preload}"
HF_TOKEN="${huggingface_token}"

# Update system packages
dnf update -y

# Install Node.js 18.x
dnf install -y nodejs npm

# Install nginx for serving static files
dnf install -y nginx

# Install git
dnf install -y git

# Create application directory
mkdir -p /var/www/imageeditor
cd /var/www/imageeditor

# Clone the repository
git clone https://github.com/kjenney/imageeditor.git .

# Install dependencies and build
npm ci --production=false
npm run build

# Copy built files to nginx directory
cp -r dist/* /usr/share/nginx/html/

# Configure nginx
cat > /etc/nginx/conf.d/imageeditor.conf << 'NGINX_CONF'
server {
    listen ${app_port};
    listen [::]:${app_port};
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Handle SPA routing - serve index.html for all routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
NGINX_CONF

# Remove default nginx config if it conflicts
rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true

# Ensure nginx html directory has correct permissions
chown -R nginx:nginx /usr/share/nginx/html

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

echo "imageeditor setup complete!"

# ========================================
# Qwen Image Edit Setup (via ComfyUI + Lightning)
# ========================================
if [ "$ENABLE_QWEN" = "true" ]; then
    echo "Setting up Qwen Image Edit with ComfyUI + Lightning variant..."

    # Verify NVIDIA drivers (Deep Learning AMI should have them)
    echo "Verifying NVIDIA drivers..."
    if ! nvidia-smi; then
        echo "ERROR: NVIDIA drivers not found. Ensure you're using a GPU instance with Deep Learning AMI."
        exit 1
    fi

    # Export environment variables for the setup script
    export HF_TOKEN="$HF_TOKEN"
    export DIFFUSION_PORT="$DIFFUSION_PORT"

    # Download and run the ComfyUI setup script
    echo "Downloading ComfyUI setup script..."
    curl -fsSL -H "Cache-Control: no-cache" "https://raw.githubusercontent.com/kjenney/imageeditor/main/terraform/scripts/comfyui_setup.sh?$(date +%s)" -o /tmp/comfyui_setup.sh
    chmod +x /tmp/comfyui_setup.sh

    echo "Running ComfyUI setup..."
    /tmp/comfyui_setup.sh

    echo "Qwen Image Edit (ComfyUI + Lightning) setup complete!"
    echo "API available at http://0.0.0.0:$DIFFUSION_PORT"
    echo "Using Lightning variant for fast 4-step inference"
fi

echo "All setup complete!"
