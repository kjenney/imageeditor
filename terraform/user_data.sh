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
# Qwen Image Edit Setup (via FastAPI + Diffusers)
# ========================================
if [ "$ENABLE_QWEN" = "true" ]; then
    echo "Setting up Qwen Image Edit diffusion model..."

    # Verify NVIDIA drivers (Deep Learning AMI should have them)
    echo "Verifying NVIDIA drivers..."
    if ! nvidia-smi; then
        echo "ERROR: NVIDIA drivers not found. Ensure you're using a GPU instance with Deep Learning AMI."
        exit 1
    fi

    # Install Python 3.11 (required for latest transformers)
    echo "Installing Python 3.11..."
    dnf install -y python3.11 python3.11-pip python3.11-devel

    # Create application directory
    mkdir -p /opt/diffusion-server
    cd /opt/diffusion-server

    # Create virtual environment with Python 3.11
    echo "Creating Python 3.11 virtual environment..."
    python3.11 -m venv venv
    source venv/bin/activate

    # Upgrade pip
    pip install --upgrade pip

    # Install PyTorch with CUDA support
    echo "Installing PyTorch with CUDA support..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

    # Download requirements.txt from GitHub (using API to avoid CDN cache)
    echo "Downloading requirements.txt..."
    curl -fsSL -H "Cache-Control: no-cache" "https://raw.githubusercontent.com/kjenney/imageeditor/main/terraform/scripts/requirements.txt?$(date +%s)" -o requirements.txt
    echo "Requirements file contents:"
    cat requirements.txt

    # Install requirements (--upgrade ensures we get the required versions)
    echo "Installing Python dependencies..."
    pip install --upgrade -r requirements.txt

    # Install transformers from source for Qwen2_5_VL support
    echo "Installing transformers from source..."
    pip install --upgrade git+https://github.com/huggingface/transformers.git
    echo "Installed transformers version: $(pip show transformers | grep Version)"
    echo "Installed diffusers version: $(pip show diffusers | grep Version)"

    # Download the FastAPI server script from GitHub (using cache-busting)
    echo "Deploying FastAPI server..."
    curl -fsSL -H "Cache-Control: no-cache" "https://raw.githubusercontent.com/kjenney/imageeditor/main/terraform/scripts/diffusion_server.py?$(date +%s)" -o server.py
    chmod +x server.py

    # Create systemd service
    cat > /etc/systemd/system/diffusion-server.service << EOF
[Unit]
Description=Qwen Image Edit Diffusion Server
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/diffusion-server
Environment="MODEL_VARIANT=$MODEL_VARIANT"
Environment="MODEL_PRELOAD=$MODEL_PRELOAD"
Environment="HF_TOKEN=$HF_TOKEN"
Environment="PORT=$DIFFUSION_PORT"
Environment="PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512"
ExecStart=/opt/diffusion-server/venv/bin/python server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and start service
    systemctl daemon-reload
    systemctl enable diffusion-server
    systemctl start diffusion-server

    # Wait for service to start (model loading takes time)
    echo "Waiting for diffusion server to start (this may take several minutes for model download)..."
    sleep 60

    # Health check loop
    echo "Checking server health..."
    for i in {1..60}; do
        if curl -s "http://localhost:$DIFFUSION_PORT/health" | grep -q "healthy"; then
            echo "Diffusion server is healthy!"
            break
        fi
        echo "Waiting for server to be ready... ($i/60)"
        sleep 30
    done

    echo "Qwen Image Edit setup complete!"
    echo "API available at http://0.0.0.0:$DIFFUSION_PORT"
    echo "Model variant: $MODEL_VARIANT"
fi

echo "All setup complete!"
