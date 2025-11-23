#!/bin/bash

# Badcoin BlockBook Setup Script
# Automates the installation and configuration of BlockBook explorer

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="badcoin.kbadinger.com"
RPC_USER="badcoinrpc"
RPC_PASS="AtXZoFZcRapKn@zJg8@uNfHZZms^dRyBU9sBMjQ9WDCs"
GO_VERSION="1.21.5"

# Functions
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

confirm() {
    read -p "$1 (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

echo "=================================="
echo "Badcoin BlockBook Setup Script"
echo "=================================="
echo ""
echo "This will:"
echo "1. Clean up Iquidus/MongoDB"
echo "2. Install Go and dependencies"
echo "3. Build BlockBook from source"
echo "4. Configure for Badcoin"
echo "5. Start the sync process"
echo ""

if ! confirm "Continue?"; then
    echo "Aborted."
    exit 0
fi

# Phase 1: Cleanup
echo ""
echo "Phase 1: Cleaning up old explorer..."
echo "-------------------------------------"

print_status "Stopping existing services..."
pkill -f sync.js 2>/dev/null || true
systemctl stop badcoin-explorer 2>/dev/null || true
systemctl stop mongod 2>/dev/null || true
systemctl disable mongod 2>/dev/null || true

if confirm "Remove MongoDB completely to save resources?"; then
    print_status "Removing MongoDB..."
    apt-get remove -y mongodb-org mongodb-org-* 2>/dev/null || true
    rm -rf /var/log/mongodb /var/lib/mongodb
    print_status "MongoDB removed"
fi

if [ -d ~/explorer ]; then
    print_status "Removing Iquidus explorer..."
    rm -rf ~/explorer
fi

print_status "Cleanup complete"

# Phase 2: Install Dependencies
echo ""
echo "Phase 2: Installing dependencies..."
echo "-----------------------------------"

print_status "Updating package list..."
apt-get update

print_status "Installing build dependencies..."
apt-get install -y \
  build-essential \
  git \
  wget \
  pkg-config \
  libzmq3-dev \
  libgflags-dev \
  libsnappy-dev \
  zlib1g-dev \
  libbz2-dev \
  liblz4-dev \
  libzstd-dev \
  graphviz

# Install Go if not present or wrong version
if ! command -v go &> /dev/null || [[ $(go version | cut -d' ' -f3 | cut -d'o' -f2) != "$GO_VERSION" ]]; then
    print_status "Installing Go ${GO_VERSION}..."
    cd /tmp
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    rm go${GO_VERSION}.linux-amd64.tar.gz

    # Add to PATH if not already there
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi
    export PATH=$PATH:/usr/local/go/bin

    print_status "Go installed: $(go version)"
else
    print_status "Go already installed: $(go version)"
fi

# Phase 3: Build BlockBook
echo ""
echo "Phase 3: Building BlockBook..."
echo "-------------------------------"

cd ~
if [ ! -d "blockbook" ]; then
    print_status "Cloning BlockBook repository..."
    git clone https://github.com/trezor/blockbook.git
else
    print_status "BlockBook repository already exists"
    cd blockbook
    git pull
fi

cd ~/blockbook

print_status "Creating Badcoin configuration..."
mkdir -p configs/coins/badcoin

cat > configs/coins/badcoin.json << EOF
{
  "coin": {
    "name": "Badcoin",
    "shortcut": "BAD",
    "label": "Badcoin",
    "alias": "badcoin"
  },
  "ports": {
    "backend_rpc": 9332,
    "backend_message_queue": 39332,
    "blockbook_internal": 10332,
    "blockbook_public": 11332
  },
  "ipc": {
    "rpc_url_template": "http://127.0.0.1:{{.Ports.BackendRPC}}",
    "rpc_user": "${RPC_USER}",
    "rpc_pass": "${RPC_PASS}",
    "rpc_timeout": 25,
    "message_queue_binding_template": "tcp://127.0.0.1:{{.Ports.BackendMessageQueue}}"
  },
  "backend": {
    "package_name": "backend-badcoin",
    "package_revision": "satoshilabs-1",
    "system_user": "badcoin",
    "version": "1.0.0",
    "binary_url": "",
    "verification_type": "sha256",
    "verification_source": "",
    "extract_command": "",
    "exclude_files": [],
    "exec_command_template": "",
    "logrotate_files_template": "",
    "postinst_script_template": "",
    "service_type": "simple",
    "service_additional_params_template": "",
    "protect_memory": false,
    "mainnet": true,
    "server_config_file": "",
    "client_config_file": ""
  },
  "blockbook": {
    "package_name": "blockbook-badcoin",
    "system_user": "blockbook",
    "internal_binding_template": ":{{.Ports.BlockbookInternal}}",
    "public_binding_template": ":{{.Ports.BlockbookPublic}}",
    "explorer_url": "",
    "additional_params": "-resyncindexperiod=1000 -resyncmempoolperiod=5000",
    "block_chain": {
      "parse": true,
      "mempool_workers": 4,
      "mempool_sub_workers": 8,
      "block_addresses_to_keep": 100,
      "xpub_magic": 0,
      "xpub_magic_segwit_p2sh": 0,
      "xpub_magic_segwit_native": 0,
      "slip44": 0,
      "additional_params": {}
    }
  },
  "meta": {
    "package_maintainer": "Badcoin Community",
    "package_maintainer_email": "admin@badcoin.net"
  }
}
EOF

print_status "Building BlockBook (this will take 10-15 minutes)..."
go build -o blockbook-badcoin blockbook.go

print_status "Setting up BlockBook directory..."
mkdir -p /opt/blockbook/badcoin/data
cp blockbook-badcoin /opt/blockbook/badcoin/
cp configs/coins/badcoin.json /opt/blockbook/badcoin/

print_status "Build complete"

# Phase 4: Create SystemD Service
echo ""
echo "Phase 4: Creating SystemD service..."
echo "------------------------------------"

cat > /etc/systemd/system/blockbook-badcoin.service << 'EOF'
[Unit]
Description=BlockBook Badcoin Explorer
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/blockbook/badcoin
ExecStart=/opt/blockbook/badcoin/blockbook-badcoin \
  -blockchaincfg=badcoin.json \
  -datadir=/opt/blockbook/badcoin/data \
  -sync \
  -workers=2 \
  -internal=:10332 \
  -public=:11332 \
  -logtostderr
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
print_status "SystemD service created"

# Phase 5: Configure Nginx
echo ""
echo "Phase 5: Configuring Nginx..."
echo "-----------------------------"

# Remove old config
rm -f /etc/nginx/sites-enabled/badcoin-explorer
rm -f /etc/nginx/sites-enabled/blockbook-badcoin

cat > /etc/nginx/sites-available/blockbook-badcoin << EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://localhost:11332;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -s /etc/nginx/sites-available/blockbook-badcoin /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
print_status "Nginx configured"

# Phase 6: SSL Certificate
echo ""
echo "Phase 6: SSL Certificate..."
echo "---------------------------"

if confirm "Setup SSL certificate with Let's Encrypt?"; then
    certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos --register-unsafely-without-email --redirect
    print_status "SSL certificate configured"
else
    print_warning "Skipping SSL setup - you can run: certbot --nginx -d ${DOMAIN}"
fi

# Phase 7: Start Services
echo ""
echo "Phase 7: Starting BlockBook..."
echo "-------------------------------"

# Check if badcoind is running
if ! pgrep -x "badcoind" > /dev/null; then
    print_error "badcoind is not running! Please start it first:"
    echo "  cd ~/badcoin && ./src/badcoind -daemon"
    exit 1
fi

print_status "Starting BlockBook service..."
systemctl enable blockbook-badcoin
systemctl start blockbook-badcoin

sleep 5

# Check if service started
if systemctl is-active --quiet blockbook-badcoin; then
    print_status "BlockBook is running!"
else
    print_error "BlockBook failed to start. Check logs:"
    echo "  journalctl -u blockbook-badcoin -n 50"
    exit 1
fi

# Final Summary
echo ""
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "BlockBook is now syncing the blockchain."
echo ""
echo "Monitor progress:"
echo "  journalctl -u blockbook-badcoin -f"
echo ""
echo "Check sync status:"
echo "  curl http://localhost:11332/api/"
echo ""
echo "Expected sync time: 3-6 hours"
echo ""
echo "Once synced, access at:"
echo "  https://${DOMAIN}"
echo ""
print_status "Setup script completed successfully!"

# Optional: Start monitoring
if confirm "Watch the sync progress now?"; then
    journalctl -u blockbook-badcoin -f
fi