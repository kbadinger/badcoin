#!/bin/bash

# Badcoin Insight Explorer Setup
# This one will ACTUALLY work with Badcoin

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

if [[ $EUID -ne 0 ]]; then
   print_error "Run as root: sudo ./setup_insight.sh"
   exit 1
fi

echo "=================================="
echo "Badcoin Insight Explorer Setup"
echo "=================================="
echo ""
echo "This will:"
echo "1. Clean up BlockBook mess"
echo "2. Install Node.js 16"
echo "3. Install Insight Explorer"
echo "4. Configure for Badcoin"
echo "5. Start syncing (6-12 hours)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 0

# Cleanup
print_status "Cleaning up previous attempts..."
systemctl stop blockbook-badcoin 2>/dev/null || true
pkill -f blockbook 2>/dev/null || true
pkill -f sync.js 2>/dev/null || true
rm -rf ~/blockbook
rm -rf ~/explorer
rm -rf /opt/blockbook

# Install Node.js 16
print_status "Installing Node.js 16..."
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs

print_status "Node: $(node --version), NPM: $(npm --version)"

# Install MongoDB (Insight needs it)
if ! command -v mongosh &> /dev/null; then
    print_status "Installing MongoDB..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
       gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

    echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
       tee /etc/apt/sources.list.d/mongodb-org-7.0.list

    apt-get update
    apt-get install -y mongodb-org mongodb-mongosh
    systemctl start mongod
    systemctl enable mongod
fi

# Install Insight
print_status "Installing Insight Explorer..."
cd ~
git clone https://github.com/bitpay/insight-api.git insight
cd insight
npm install

# Create config
print_status "Creating Badcoin configuration..."
cat > insight.config.json << 'EOF'
{
  "network": "mainnet",
  "port": 3001,
  "services": [
    "badcoind",
    "web"
  ],
  "servicesConfig": {
    "badcoind": {
      "spawn": {
        "datadir": "/root/.badcoin",
        "exec": "/root/badcoin/src/badcoind"
      }
    }
  }
}
EOF

# Install bitcore-node
print_status "Installing bitcore-node..."
npm install -g bitcore-node@latest

# Create bitcore node
print_status "Setting up bitcore node..."
cd ~
bitcore-node create badcoin-explorer
cd badcoin-explorer

# Install Insight UI
print_status "Installing Insight UI..."
bitcore-node install insight-api
bitcore-node install insight-ui

# Configure bitcore
cat > bitcore-node.json << EOF
{
  "network": "mainnet",
  "port": 3001,
  "services": [
    "bitcoind",
    "insight-api",
    "insight-ui",
    "web"
  ],
  "servicesConfig": {
    "bitcoind": {
      "connect": [
        {
          "rpchost": "127.0.0.1",
          "rpcport": 9332,
          "rpcuser": "badcoinrpc",
          "rpcpassword": "AtXZoFZcRapKn@zJg8@uNfHZZms^dRyBU9sBMjQ9WDCs",
          "zmqpubrawtx": "tcp://127.0.0.1:28332"
        }
      ]
    }
  }
}
EOF

# Enable ZMQ in badcoin.conf
print_status "Enabling ZMQ in badcoin.conf..."
if ! grep -q "zmqpubrawtx" ~/.badcoin/badcoin.conf; then
    cat >> ~/.badcoin/badcoin.conf << 'CONF'

# ZMQ for Insight
zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubrawblock=tcp://127.0.0.1:28332
zmqpubhashtx=tcp://127.0.0.1:28332
zmqpubhashblock=tcp://127.0.0.1:28332
CONF
fi

# Restart badcoind
print_status "Restarting badcoind with ZMQ..."
~/badcoin/src/badcoin-cli stop || true
sleep 10
~/badcoin/src/badcoind -daemon
sleep 15

# Create systemd service
print_status "Creating systemd service..."
cat > /etc/systemd/system/insight-badcoin.service << 'EOF'
[Unit]
Description=Insight Badcoin Explorer
After=network.target mongod.service

[Service]
Type=simple
User=root
WorkingDirectory=/root/badcoin-explorer
ExecStart=/usr/bin/bitcore-node start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# Configure Nginx
print_status "Configuring Nginx..."
if ! command -v nginx &> /dev/null; then
    apt-get install -y nginx
fi

cat > /etc/nginx/sites-available/insight-badcoin << 'EOF'
server {
    listen 80;
    server_name badcoin.kbadinger.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

rm -f /etc/nginx/sites-enabled/blockbook-badcoin
rm -f /etc/nginx/sites-enabled/badcoin-explorer
ln -sf /etc/nginx/sites-available/insight-badcoin /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Start Insight
print_status "Starting Insight Explorer..."
systemctl enable insight-badcoin
systemctl start insight-badcoin

sleep 5

if systemctl is-active --quiet insight-badcoin; then
    print_status "Insight is running!"
else
    print_error "Failed to start. Check: journalctl -u insight-badcoin -n 50"
    exit 1
fi

echo ""
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "Insight is syncing the blockchain."
echo ""
echo "Monitor: journalctl -u insight-badcoin -f"
echo "Status:  curl http://localhost:3001/api/status"
echo ""
echo "Expected sync: 6-12 hours"
echo "Access at: http://badcoin.kbadinger.com"
echo ""
print_status "This one will actually work."
