#!/bin/bash

# Proper fix: Modify BlockBook source and rebuild

set -e

echo "================================================"
echo "BlockBook Color Fix - Proper Method"
echo "================================================"
echo ""

# Clone BlockBook if not present
if [ ! -d ~/blockbook ]; then
    echo "[1/5] Cloning BlockBook repository..."
    cd ~
    git clone https://github.com/trezor/blockbook.git
else
    echo "[1/5] BlockBook repository exists, updating..."
    cd ~/blockbook
    git pull
fi

cd ~/blockbook

echo "[2/5] Finding static assets..."
# BlockBook uses embedded assets in static/ directory
if [ -d "static" ]; then
    echo "  Found static directory"
elif [ -d "build/static" ]; then
    echo "  Found build/static directory"
    cd build
else
    echo "  Creating static customization..."
fi

echo "[3/5] Creating custom CSS file..."

# BlockBook typically has CSS in static/css/
mkdir -p static/css

cat > static/css/custom-badcoin.css << 'EOF'
/* Badcoin BlockBook Color Customizations */

/* Fix BADCOIN text/logo visibility */
.navbar-brand,
.logo-text,
h1.d-inline-block {
  color: #e74c3c !important;
  font-weight: bold !important;
  text-shadow: 1px 1px 2px rgba(0,0,0,0.3);
}

/* Fix address links - make them bright and readable */
a.address,
td a,
.address-link,
.text-monospace a {
  color: #3498db !important;
  font-weight: 500 !important;
}

a.address:hover,
td a:hover {
  color: #2980b9 !important;
  text-decoration: underline !important;
}

/* Improve table contrast */
.table {
  color: #ecf0f1 !important;
}

.table thead th {
  background-color: rgba(52, 73, 94, 0.6) !important;
  color: #fff !important;
}

.table tbody tr:hover {
  background-color: rgba(52, 152, 219, 0.1) !important;
}

/* Card backgrounds for better readability */
.card {
  background-color: rgba(44, 62, 80, 0.4) !important;
}

.card-body {
  color: #ecf0f1 !important;
}
EOF

echo "[4/5] Modifying HTML template to include custom CSS..."

# Find the main template file (usually index.html or base.html)
TEMPLATE_FILE=$(find . -name "index.html" -o -name "base.html" | grep -E "(static|templates)" | head -1)

if [ -n "$TEMPLATE_FILE" ]; then
    echo "  Found template: $TEMPLATE_FILE"

    # Backup original
    cp "$TEMPLATE_FILE" "${TEMPLATE_FILE}.backup"

    # Inject custom CSS link before </head>
    if ! grep -q "custom-badcoin.css" "$TEMPLATE_FILE"; then
        sed -i.bak 's|</head>|<link rel="stylesheet" href="/static/css/custom-badcoin.css">\n</head>|' "$TEMPLATE_FILE"
        echo "  ✓ Injected custom CSS link"
    else
        echo "  ✓ Custom CSS already present"
    fi
else
    echo "  WARNING: Could not find template file"
    echo "  You'll need to manually add this to your HTML:"
    echo '  <link rel="stylesheet" href="/static/css/custom-badcoin.css">'
fi

echo "[5/5] Building BlockBook with custom colors..."
echo ""
echo "This will take 10-15 minutes..."
echo ""

# Build BlockBook
go build -o blockbook-badcoin blockbook.go

echo ""
echo "================================================"
echo "Build complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Copy the binary to your server:"
echo "   scp ~/blockbook/blockbook-badcoin root@badcoin.kbadinger.com:/opt/blockbook/badcoin/"
echo ""
echo "2. Restart BlockBook service on server:"
echo "   ssh root@badcoin.kbadinger.com 'systemctl restart blockbook-badcoin'"
echo ""
echo "3. Visit https://badcoin.kbadinger.com to see the color changes"
echo ""
