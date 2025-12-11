#!/bin/bash
# Create Badcoin Explorer todo in TickTick
# Run this interactively: bash create_explorer_todo.sh

cd /Users/kevinbadinger/Projects/ticktick-api-client

echo "🚀 Creating Badcoin Explorer Setup todo in TickTick..."
echo ""
echo "This will open a browser for OAuth authentication."
echo "Please authorize the app and copy the redirect URL when prompted."
echo ""
read -p "Press Enter to continue..."

python3 /Users/kevinbadinger/Projects/badcoin/add_explorer_todo.py
