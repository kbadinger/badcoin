#!/usr/bin/env python3
"""
Add Badcoin Explorer Setup task to TickTick
"""
import sys
import os

# Add ticktick-api-client to path
sys.path.insert(0, '/Users/kevinbadinger/Projects/ticktick-api-client')

from dotenv import load_dotenv
from ticktick.oauth2 import OAuth2
from ticktick.api import TickTickClient

# Load environment variables
load_dotenv('/Users/kevinbadinger/Projects/ticktick-api-client/.env')

def create_explorer_todo():
    """Create a todo for Badcoin Explorer setup"""

    # Initialize TickTick client
    client_id = os.getenv('TICKTICK_CLIENT_ID')
    client_secret = os.getenv('TICKTICK_CLIENT_SECRET')
    username = os.getenv('TICKTICK_USERNAME')
    password = os.getenv('TICKTICK_PASSWORD')

    if not all([client_id, client_secret, username, password]):
        print("❌ Missing credentials in .env file")
        return

    print("🔐 Authenticating with TickTick...")
    auth_client = OAuth2(
        client_id=client_id,
        client_secret=client_secret,
        redirect_uri='http://127.0.0.1:8080'
    )

    client = TickTickClient(username, password, auth_client)
    print("✅ Authenticated successfully")

    # Task details
    title = "Deploy Badcoin Block Explorer"

    description = """Deploy Iquidus Explorer at badcoin.kbadinger.com

**Total Time:** 3-4 hours (1-3 hours unattended database sync)

**Prerequisites:**
- badcoin1 VPS synced to block 1,773,011+
- Access to kbadinger.com DNS settings
- $12/month for 2GB VPS upgrade

**Phases:**
1. VPS Preparation (30 min)
   - Shutdown node safely
   - Resize VPS to 2GB RAM
   - Configure DNS: badcoin.kbadinger.com
   - Add RPC credentials to badcoin.conf

2. Software Installation (30 min)
   - Install MongoDB 7.0
   - Install Node.js 18.x
   - Clone & install Iquidus Explorer

3. Explorer Configuration (30 min)
   - Setup MongoDB database & user
   - Get genesis block/transaction info
   - Configure settings.json with Badcoin details

4. Database Sync (1-3 hours - UNATTENDED)
   - Start explorer: npm start
   - Run sync script: node scripts/sync.js index update
   - Monitor progress: mongo explorerdb --eval "db.txes.count()"

5. Web Server Setup (20 min)
   - Install Nginx reverse proxy
   - Get free SSL certificate (Let's Encrypt)
   - Setup systemd service for auto-start

6. Verification & Customization (30 min)
   - Test https://badcoin.kbadinger.com
   - Upload Badcoin logo
   - Customize branding
   - Setup hourly sync cron job

**Documentation:**
- Complete guide: EXPLORER_SETUP.md
- Timeline with checkpoints: EXPLORER_TIMELINE.md

**After Deployment:**
- Test all features (search, addresses, transactions)
- Take screenshots for promotion
- Update STATUS.md and README.md
- Announce to community (Telegram, BitcoinTalk)
- Recruit miners with live explorer proof!

**Cost:** $12/month (VPS upgrade), SSL is free
"""

    print("\n📝 Creating task...")

    # Calculate next Tuesday
    from datetime import datetime, timedelta
    today = datetime.now()
    days_until_tuesday = (1 - today.weekday()) % 7  # Tuesday is 1 (0=Monday)
    if days_until_tuesday == 0 and today.weekday() == 1:
        # If today is Tuesday, use next Tuesday
        days_until_tuesday = 7
    next_tuesday = today + timedelta(days=days_until_tuesday)
    due_date = next_tuesday.strftime("%Y-%m-%dT17:00:00+0000")  # 5 PM on Tuesday

    print(f"📅 Due date set to: {next_tuesday.strftime('%A, %B %d, %Y')}")

    # Create the task
    task = client.task.builder(
        title=title,
        content=description,
        priority=5,  # High priority
        dueDate=due_date,
        tags=["badcoin", "blockchain", "devops", "deployment"]
    )

    created_task = client.task.create(task)

    print(f"✅ Task created successfully!")
    print(f"📋 Title: {title}")
    print(f"🔗 Task ID: {created_task.get('id', 'N/A')}")
    print(f"\n✨ Check your TickTick inbox for the new task!")

if __name__ == "__main__":
    try:
        create_explorer_todo()
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
