#!/bin/bash
set -e

# Log all output to a file for debugging
exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting imageeditor setup..."

# Template variables
ENABLE_QWEN="${enable_qwen}"
QWEN_MODEL="${qwen_model}"
OLLAMA_PORT="${ollama_port}"

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
# Qwen Model Setup (via Ollama)
# ========================================
if [ "$ENABLE_QWEN" = "true" ]; then
    echo "Setting up Qwen model support..."

    # Install Ollama
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh

    # Create ollama systemd service with custom port
    cat > /etc/systemd/system/ollama.service << EOF
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
Environment="OLLAMA_HOST=0.0.0.0:$OLLAMA_PORT"
User=root
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF

    # Reload systemd and start ollama
    systemctl daemon-reload
    systemctl enable ollama
    systemctl start ollama

    # Wait for Ollama to be ready
    echo "Waiting for Ollama to start..."
    sleep 10

    # Pull the Qwen model
    echo "Pulling Qwen model: $QWEN_MODEL..."
    ollama pull "$QWEN_MODEL"

    echo "Qwen model setup complete!"
    echo "Ollama API available at http://0.0.0.0:$OLLAMA_PORT"
    echo "Model: $QWEN_MODEL"
fi

echo "All setup complete!"
