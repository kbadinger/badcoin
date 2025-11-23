#!/bin/bash

# BlockBook Monitoring Script
# Shows sync status and progress

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=================================="
echo "BlockBook Sync Monitor"
echo "=================================="
echo ""

# Check service status
if systemctl is-active --quiet blockbook-badcoin; then
    echo -e "${GREEN}[✓]${NC} BlockBook service is running"
else
    echo -e "${YELLOW}[!]${NC} BlockBook service is not running"
    echo "    Start with: systemctl start blockbook-badcoin"
    exit 1
fi

echo ""
echo "Fetching sync status..."
echo "------------------------"

# Get API status
API_RESPONSE=$(curl -s http://localhost:11332/api/ 2>/dev/null)

if [ -z "$API_RESPONSE" ]; then
    echo "API not responding yet. Service might still be starting..."
    echo "Check logs: journalctl -u blockbook-badcoin -f"
else
    # Parse JSON response (requires jq)
    if command -v jq &> /dev/null; then
        echo "$API_RESPONSE" | jq .

        # Extract specific values
        BLOCKS=$(echo "$API_RESPONSE" | jq -r '.blockbook.bestHeight // "0"')
        BACKEND_BLOCKS=$(echo "$API_RESPONSE" | jq -r '.backend.blocks // "0"')

        if [ "$BLOCKS" != "null" ] && [ "$BACKEND_BLOCKS" != "null" ]; then
            PERCENT=$(awk "BEGIN { printf \"%.2f\", ($BLOCKS / $BACKEND_BLOCKS) * 100 }")
            echo ""
            echo "Sync Progress: $BLOCKS / $BACKEND_BLOCKS blocks ($PERCENT%)"

            if [ "$BLOCKS" -eq "$BACKEND_BLOCKS" ] && [ "$BLOCKS" -ne "0" ]; then
                echo -e "${GREEN}✓ Fully synced!${NC}"
            else
                REMAINING=$((BACKEND_BLOCKS - BLOCKS))
                echo "Blocks remaining: $REMAINING"
            fi
        fi
    else
        # No jq, just show raw response
        echo "$API_RESPONSE"
        echo ""
        echo "(Install 'jq' for better formatting: apt-get install -y jq)"
    fi
fi

echo ""
echo "Commands:"
echo "  View logs:    journalctl -u blockbook-badcoin -f"
echo "  Restart:      systemctl restart blockbook-badcoin"
echo "  Stop:         systemctl stop blockbook-badcoin"
echo ""