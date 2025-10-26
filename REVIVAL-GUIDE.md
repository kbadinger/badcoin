# Badcoin Blockchain Revival Guide

**Created:** October 24, 2025
**Status:** Searching for original blockchain data

## Overview

This guide documents the effort to revive the Badcoin network and recover the original blockchain history from 2018-2020(?). The network appears to have been abandoned, with 0 active nodes found via DNS seeds.

## Current Situation

### What We Have
- ✅ Working build on Apple Silicon (ARM64)
- ✅ Functional badcoind daemon
- ✅ Fresh genesis block (block 0)
- ✅ Successfully mined 1 new block (block 1) - **FRESH START, NOT ORIGINAL CHAIN**
- ✅ Backup of fresh-start blockchain in `~/badcoin-data-fresh/`

### What We're Missing
- ❌ Original blockchain data (blocks 1+)
- ❌ Historical transactions
- ❌ Active peer nodes
- ❌ DNS seed responses (got 0 addresses)

### Genesis Block Info
```
Hash: 00000631170923bb3d28727d9a8b3166ec0c5db3bc816a2be27657d6caa93942
Date: 2018-11-12 19:31:21
Height: 0
```

## Understanding Blockchain Recovery

### How Blockchain Data Works

A blockchain is NOT stored "in the cloud" or "on the network." It's stored **locally on each node's hard drive**.

**The data structure:**
```
~/badcoin-data/
├── blocks/              # Actual blockchain blocks
│   ├── blk00000.dat    # First ~130MB of blocks
│   ├── blk00001.dat    # Next batch of blocks
│   ├── rev00000.dat    # Undo data for blocks
│   └── index/          # Block index database
├── chainstate/          # UTXO set (current state)
│   └── *.ldb           # LevelDB files
├── wallet.dat          # Your private keys and addresses
├── peers.dat           # Known peer addresses
└── debug.log           # Node logs
```

### What Happened to Original Badcoin

**Timeline:**
1. **2018**: Badcoin launched (genesis block Nov 12, 2018)
2. **2018-????**: Network was active, blocks were mined
3. **????**: Last active node shut down
4. **2025**: 0 DNS seed addresses = network dead

**Where did the blockchain go?**
- It exists only on hard drives of people who ran nodes
- When they:
  - Deleted `~/badcoin-data/`
  - Reformatted their drives
  - Lost interest and wiped the data
- The blockchain data disappeared

### Fresh Start vs. Revival

**What we did (Fresh Start):**
```
Block 0 (genesis) → Block 1 (NEW, mined by us) → ...
```
- This is a **new chain**
- Old transactions NOT included
- Clean slate

**What true revival requires:**
```
Block 0 (genesis) → Block 1 (original) → ... → Block N (last mined in 201X)
                                                      ↓
                                              Continue from here
```
- Need someone's **original blockchain data**
- Preserves all historical transactions
- Continues the "real" Badcoin history

## Where to Search for Original Blockchain

### Primary Sources

#### 1. Original Repository
- **URL:** https://github.com/ScriptProdigy/Badcoin
- **Look for:**
  - Issues mentioning blockchain data
  - Releases with bootstrap files
  - Community discussions
  - Fork repositories (people who ran nodes often fork)

#### 2. Bad Crypto Podcast Community
- **Website:** https://badcryptopodcast.com
- **Search for:**
  - Community forums/Discord/Telegram
  - Social media (Twitter, Reddit)
  - Contact podcast hosts directly
- **Ask:** "Does anyone still have Badcoin blockchain data from 2018-2020?"

#### 3. Block Explorers
These sites cache blockchain data:
- **Chainz Crypto ID:** https://chainz.cryptoid.info/
  - Search for "badcoin" or "BAD"
  - May have archived block data
- **CoinMarketCap / CoinGecko:** Historical data might point to explorers

#### 4. Mining Pools
If Badcoin had any mining pools, they often keep blockchain data:
- Search Google: `"badcoin mining pool"`
- Check: bitcointalk.org for pool announcements
- Pools need full blockchain to verify shares

#### 5. Cryptocurrency Exchanges
If Badcoin was ever listed:
- Exchanges run full nodes
- Contact support asking about archived blockchain data
- Even defunct exchanges might have backups

#### 6. Internet Archive
- **URL:** https://archive.org
- **Search:**
  - `badcoin blockchain bootstrap`
  - Archive of Badcoin website
  - Archived forum posts with download links

#### 7. Reddit / Bitcointalk
- **Reddit:** Search `/r/cryptocurrency`, `/r/badcoin` (if exists)
- **Bitcointalk:** Search forums for "badcoin"
- **Look for:**
  - Announcement threads
  - People offering bootstrap files
  - Technical support threads mentioning blockchain sync

#### 8. Discord / Telegram Archives
- Cryptocurrency project channels
- Ask if anyone has old Badcoin data
- Check pinned messages for bootstrap links

### Search Terms to Use

```
"badcoin blockchain bootstrap"
"badcoin blockchain backup"
"badcoin blocks.tar.gz"
"badcoin chainstate"
"badcoin full node backup"
"badcoin snapshot"
site:github.com badcoin blockchain
site:reddit.com badcoin bootstrap
```

## How to Import Original Blockchain (When Found)

### Step 1: Obtain the Data

**Ideal formats:**
- `blocks/` directory (with .dat files)
- `chainstate/` directory (LevelDB database)
- Complete `badcoin-data/` backup
- `.tar.gz` or `.zip` archive of blockchain

**Minimum required:**
- `blocks/blk*.dat` files
- `blocks/rev*.dat` files (undo data)
- `blocks/index/` directory

### Step 2: Stop Your Node (if running)

```bash
# Stop daemon
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data stop

# Verify it stopped
ps aux | grep badcoind
```

### Step 3: Prepare Data Directory

```bash
# Create fresh data directory for old blockchain
mkdir -p ~/badcoin-data

# If you received a complete backup:
# Just extract it to ~/badcoin-data/
tar -xzf badcoin-blockchain-backup.tar.gz -C ~/badcoin-data/
```

### Step 4: Import Blockchain Files

**If you only have blocks/ directory:**

```bash
# Copy blocks directory
cp -r /path/to/old/blocks ~/badcoin-data/

# Node will rebuild chainstate on first startup
# This takes time but works
```

**If you have complete backup:**

```bash
# Copy everything
cp -r /path/to/badcoin-data-backup/* ~/badcoin-data/

# Keep your wallet or use theirs
# If keeping yours from fresh-start:
cp ~/badcoin-data-fresh/wallet.dat ~/badcoin-data/wallet.dat
```

### Step 5: Start Node and Verify

```bash
# Start with old blockchain
./src/badcoind -datadir=/Users/kevinbadinger/badcoin-data -daemon

# Wait for initialization (check debug.log)
tail -f ~/badcoin-data/debug.log

# Verify blockchain height
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getblockchaininfo

# Look for:
# "blocks": <should be > 1>
# "headers": <same as blocks>
# "verificationprogress": <should complete to 1.0>
```

### Step 6: Validate Integrity

```bash
# Get best block hash
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getbestblockhash

# Get block details
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getblock "<hash>"

# Check if it matches known block explorer data (if available)
```

## Verification Checklist

When you import old blockchain data, verify:

- [ ] `blocks` count is > 1 (not just genesis)
- [ ] `verificationprogress` reaches 1.0
- [ ] No errors in `debug.log` about corruption
- [ ] Block hashes match (if you have reference data)
- [ ] Chainwork increases properly
- [ ] No "InvalidChain" errors

## Fallback: Restore Fresh-Start

If imported blockchain is corrupt or doesn't work:

```bash
# Stop daemon
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data stop

# Remove bad data
rm -rf ~/badcoin-data

# Restore your fresh-start
cp -r ~/badcoin-data-fresh ~/badcoin-data

# Start again
./src/badcoind -datadir=/Users/kevinbadinger/badcoin-data -daemon
```

## Continue Mining After Import

Once you have the original blockchain:

```bash
# Generate address for mining rewards
ADDR=$(./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getnewaddress)

# Mine blocks to continue the chain
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data generatetoaddress 10 "$ADDR"

# Check new height
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getblockcount
```

## Network Revival Options

### Option 1: Solo Mining (No Network Needed)
- Mine blocks yourself
- Don't need peers
- Full control of chain

### Option 2: Local Multi-Node Network
```bash
# Start second node
mkdir -p ~/badcoin-data-node2
./src/badcoind -datadir=~/badcoin-data-node2 -port=9013 -rpcport=9033 -daemon

# Connect nodes
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data addnode "127.0.0.1:9013" "add"

# Verify connection
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getpeerinfo
```

### Option 3: Public Network Revival
1. **Port forward** router port 9012 to your machine
2. **Get public IP:** `curl ifconfig.me`
3. **Share IP** with others who want to join
4. **Keep mining** to produce new blocks
5. **Run 24/7** to be a reliable seed node
6. **Consider DNS seed** (advanced - need domain + seedserver software)

## Technical Details

### Block File Format
- **Location:** `~/badcoin-data/blocks/blk*.dat`
- **Format:** Binary, concatenated blocks
- **Size:** Each file ~130MB typically
- **Sequential:** blk00000.dat, blk00001.dat, etc.

### Chainstate Database
- **Location:** `~/badcoin-data/chainstate/`
- **Format:** LevelDB
- **Contents:** UTXO set (current unspent outputs)
- **Rebuilding:** Can be rebuilt from blocks/ if missing

### Wallet Data
- **Location:** `~/badcoin-data/wallet.dat`
- **Format:** Berkeley DB 4.8
- **CRITICAL:** Contains private keys - NEVER delete or share!
- **Backup:** Always keep backup: `cp wallet.dat wallet.backup`

### Known Network Info
```
Chain: main
Default Port: 9012
RPC Port: 9332
Genesis Hash: 00000631170923bb3d28727d9a8b3166ec0c5db3bc816a2be27657d6caa93942
Genesis Time: 2018-11-12 19:31:21
Multi-algo: SHA256d, Scrypt, Groestl, Skein, Yescrypt
```

## Commands Reference

### Node Management
```bash
# Start daemon
./src/badcoind -datadir=/Users/kevinbadinger/badcoin-data -daemon

# Stop daemon
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data stop

# Get info
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getblockchaininfo
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getnetworkinfo
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getpeerinfo
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getmininginfo

# Get block count
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getblockcount

# Get specific block
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getblockhash <height>
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getblock <hash>
```

### Wallet Management
```bash
# Get new address
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getnewaddress

# Check balance
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getbalance

# List transactions
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data listtransactions

# Backup wallet
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data backupwallet "/path/to/backup.dat"
```

### Mining Commands
```bash
# Generate address
ADDR=$(./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getnewaddress)

# Mine 1 block
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data generatetoaddress 1 "$ADDR"

# Mine 100 blocks (for coinbase maturity)
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data generatetoaddress 100 "$ADDR"

# Check mining info
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getmininginfo
```

### Network Management
```bash
# Add peer manually
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data addnode "IP:PORT" "add"

# Remove peer
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data addnode "IP:PORT" "remove"

# List peers
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getpeerinfo

# Get connection count
./src/badcoin-cli -datadir=/Users/kevinbadinger/badcoin-data getconnectioncount
```

## Progress Tracking

### Fresh-Start Blockchain (Current Backup)
- **Location:** `~/badcoin-data-fresh/`
- **Blocks:** 1 (just genesis + 1 mined block)
- **Wallet Address:** B6Lzr3TUJSejzP266crCRFkK9c3hwqUjqz
- **Status:** Clean backup if revival fails

### Original Blockchain Search
- **Status:** SEARCHING
- **Started:** October 24, 2025
- **Blocks Found:** TBD
- **Source:** TBD

## Questions to Ask When Finding Data

If you find someone with old Badcoin blockchain:

1. **What block height did they reach?**
   - This tells you how complete the data is

2. **When did they last run the node?**
   - Helps verify data currency

3. **Do they have:**
   - [ ] `blocks/` directory?
   - [ ] `chainstate/` directory?
   - [ ] `blocks/index/` directory?

4. **File sizes?**
   - Bigger = more blocks = better

5. **Checksums available?**
   - Helps verify download integrity

6. **Compressed format?**
   - `.tar.gz`, `.zip`, or raw files?

## Success Indicators

You'll know the revival succeeded when:

- ✅ Block count > 1000 (or whatever max existed)
- ✅ Blocks validate without errors
- ✅ Can mine new blocks on top of old chain
- ✅ Wallet synchronizes properly
- ✅ Historical transactions appear in blockchain
- ✅ `verificationprogress` = 1.0

## Next Steps After Revival

1. **Document the chain**
   - Record final block height
   - Note any interesting transactions
   - Archive block explorer data

2. **Share the blockchain**
   - Upload to IPFS or torrent
   - Make available for others
   - Preserve the history

3. **Restart mining**
   - Continue chain from last block
   - Become the new longest chain

4. **Rebuild network**
   - Get others to run nodes
   - Establish new DNS seeds
   - Create block explorer

## Resources

- **Badcoin Repo:** https://github.com/ScriptProdigy/Badcoin
- **Bad Crypto Podcast:** https://badcryptopodcast.com
- **Build Guide:** See CLAUDE.md in this repo
- **Fresh Backup:** ~/badcoin-data-fresh/

## Contact / Updates

If you find original blockchain data, document here:

- **Found Date:** _____________
- **Source:** _____________
- **Block Height:** _____________
- **Download URL:** _____________
- **Notes:** _____________

---

**Good luck with the search!** 🔍⛏️

The blockchain data is out there somewhere... or it's lost to time. Either way, we've got a working node ready to go.
