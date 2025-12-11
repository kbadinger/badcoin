#!/bin/bash

# Deploy custom CSS to BlockBook server

SERVER="badcoin.kbadinger.com"
CUSTOM_CSS="/var/www/blockbook-custom.css"

echo "Deploying custom CSS to BlockBook..."

# Copy CSS file to server
scp blockbook-custom.css root@${SERVER}:${CUSTOM_CSS}

# Update nginx configuration to inject custom CSS
ssh root@${SERVER} << 'ENDSSH'

# Backup current nginx config
cp /etc/nginx/sites-available/blockbook-badcoin /etc/nginx/sites-available/blockbook-badcoin.backup

# Update nginx config to serve custom CSS and inject it
cat > /etc/nginx/sites-available/blockbook-badcoin << 'EOF'
server {
    listen 80;
    server_name badcoin.kbadinger.com;

    # Serve custom CSS file
    location /custom.css {
        alias /var/www/blockbook-custom.css;
        add_header Content-Type text/css;
        add_header Cache-Control "no-cache";
    }

    location / {
        proxy_pass http://localhost:11332;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # Inject custom CSS into HTML responses
        sub_filter '</head>' '<link rel="stylesheet" href="/custom.css"></head>';
        sub_filter_once on;
        sub_filter_types text/html;
    }
}
EOF

# Test and reload nginx
nginx -t && systemctl reload nginx

echo "Custom CSS deployed successfully!"
echo "Visit https://badcoin.kbadinger.com to see changes"
ENDSSH
