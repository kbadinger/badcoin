# BlockBook Setup for Badcoin

Complete guide for setting up Trezor's BlockBook explorer for Badcoin on Ubuntu VPS.

## Prerequisites
- Ubuntu VPS with 2GB+ RAM
- Badcoind running with RPC enabled
- Domain name pointed to VPS IP

## Phase 1: Clean Up Current Setup

### Stop Iquidus and Free Resources

```bash
# Kill any running sync
pkill -f sync.js

# Stop explorer service if running
systemctl stop badcoin-explorer 2>/dev/null

# Stop MongoDB (we won't need it)
systemctl stop mongod
systemctl disable mongod

# Free up space by removing Iquidus
cd ~
rm -rf explorer

# Optional: Remove MongoDB completely (saves ~500MB RAM)
apt-get remove -y mongodb-org mongodb-org-*
rm -rf /var/log/mongodb /var/lib/mongodb
```

## Phase 2: Install BlockBook Dependencies

### Install Go (required for building)

```bash
# Install Go 1.21
cd /tmp
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Add to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify
go version
# Should show: go version go1.21.5 linux/amd64
```

### Install Build Dependencies

```bash
apt-get update
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
```

## Phase 3: Build BlockBook

### Clone and Build

```bash
cd ~
git clone https://github.com/trezor/blockbook.git
cd blockbook
```

### Create Badcoin Configuration

```bash
cd ~/blockbook

# Create Badcoin config directory
mkdir -p configs/coins/badcoin

# Create the configuration file
cat > configs/coins/badcoin.json << 'EOF'
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
    "rpc_user": "badcoinrpc",
    "rpc_pass": "AtXZoFZcRapKn@zJg8@uNfHZZms^dRyBU9sBMjQ9WDCs",
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
```

### Build with Custom Config

```bash
cd ~/blockbook

# Build just the blockbook binary (faster than full package)
go build -o blockbook-badcoin blockbook.go

# Create working directory
mkdir -p /opt/blockbook/badcoin
cp blockbook-badcoin /opt/blockbook/badcoin/
cp configs/coins/badcoin.json /opt/blockbook/badcoin/
```

## Phase 4: Start BlockBook Backend

### Create Data Directory

```bash
mkdir -p /opt/blockbook/badcoin/data
```

### Start BlockBook (Test Mode)

```bash
cd /opt/blockbook/badcoin

# Start blockbook backend (this connects to badcoind)
./blockbook-badcoin \
  -blockchaincfg=badcoin.json \
  -datadir=/opt/blockbook/badcoin/data \
  -sync \
  -workers=1 \
  -internal=:10332 \
  -public=:11332 \
  -logtostderr
```

**This will start syncing!** You'll see output like:
```
I1119 20:45:23.123456 blockbook.go:123] Connected to backend
I1119 20:45:23.234567 blockbook.go:234] Syncing blockchain... Block 1000
```

## Phase 5: Run as Service (Once Sync Works)

Create systemd service:

```bash
cat > /etc/systemd/system/blockbook-badcoin.service << 'EOF'
[Unit]
Description=BlockBook Badcoin
After=network.target badcoind.service

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

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable blockbook-badcoin
systemctl start blockbook-badcoin
```

Check service status:
```bash
systemctl status blockbook-badcoin
journalctl -u blockbook-badcoin -f
```

## Phase 6: Web Access

### Set up Nginx Reverse Proxy

```bash
# Remove old config if exists
rm -f /etc/nginx/sites-enabled/badcoin-explorer

# Create new config
cat > /etc/nginx/sites-available/blockbook-badcoin << 'EOF'
server {
    listen 80;
    server_name badcoin.kbadinger.com;

    location / {
        proxy_pass http://localhost:11332;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

ln -s /etc/nginx/sites-available/blockbook-badcoin /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

### SSL Certificate with Let's Encrypt

```bash
certbot --nginx -d badcoin.kbadinger.com
# Follow prompts, choose option 2 to redirect HTTP to HTTPS
```

## Monitor Progress

### Check Sync Status
```bash
# Via API
curl http://localhost:11332/api/

# Via logs
journalctl -u blockbook-badcoin -f

# Check resource usage
htop
```

### Verify Web Access
Once synced, visit: https://badcoin.kbadinger.com

## Expected Timeline

- **Phase 1-2:** 15-20 minutes (cleanup and dependencies)
- **Phase 3:** 10-15 minutes (building BlockBook)
- **Phase 4:** 3-6 hours (blockchain sync)
- **Phase 5-6:** 10 minutes (service setup)

**Total time:** 4-7 hours (mostly unattended sync time)

## Troubleshooting

### BlockBook won't connect to badcoind
- Verify RPC credentials in badcoin.json match ~/.badcoin/badcoin.conf
- Ensure badcoind is running: `ps aux | grep badcoind`
- Check RPC port is listening: `netstat -tlnp | grep 9332`

### Build fails
- Ensure Go version is 1.19 or higher
- Check all dependencies are installed
- Try `go mod download` in blockbook directory

### Sync is slow
- Normal for first sync (3-6 hours expected)
- Can reduce workers to 1 if VPS is struggling
- Monitor with `htop` to check resource usage

## Post-Setup

Once running:
1. Take screenshots for community announcement
2. Share URL: https://badcoin.kbadinger.com
3. Monitor logs for any issues
4. Set up monitoring/alerts (optional)

## Benefits Over Iquidus

- **10-20x faster sync** (hours vs days)
- **Better performance** (Go vs Node.js)
- **More features** (full API, xpub support, websockets)
- **Active development** (Trezor maintains it)
- **Professional appearance** (same UI as Trezor's explorers)

## Support

- BlockBook GitHub: https://github.com/trezor/blockbook
- Badcoin Community: [Telegram/Discord/BitcoinTalk]
- System Admin: admin@badcoin.net