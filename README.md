Badcoin Core - Revived November 2025
=====================================

[![Build Status](https://travis-ci.org/ScriptProdigy/Badcoin.svg?branch=master)](https://travis-ci.org/ScriptProdigy/Badcoin)

**Network Status:** ✅ ACTIVE (Revived Nov 1, 2025)
**Current Height:** 1,773,000+ blocks
**Website:** https://badcryptopodcast.com

What is Badcoin?
----------------

Badcoin is a Bitcoin Core fork implementing auxiliary proof-of-work (auxpow) merged mining with 5 algorithms (SHA256d, Scrypt, Groestl, Skein, Yescrypt). Originally created for the Bad Crypto Podcast community in 2018, the network went dormant in 2024 and was successfully revived in November 2025.

## Quick Start

### Dependencies

**macOS (Apple Silicon):**
```bash
brew install boost libevent berkeley-db@4 openssl autoconf automake libtool
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install -y \
  build-essential libtool autotools-dev automake autoconf \
  pkg-config libssl-dev libevent-dev bsdmainutils git \
  libboost-system-dev libboost-filesystem-dev \
  libboost-program-options-dev libboost-thread-dev \
  libboost-chrono-dev libdb-dev libdb++-dev
```

### Building

**macOS (Apple Silicon):**
```bash
./autogen.sh

export PKG_CONFIG_PATH="/opt/homebrew/opt/libevent/lib/pkgconfig:$PKG_CONFIG_PATH"

arch -arm64 ./configure \
  --without-gui \
  --with-boost=/opt/homebrew/opt/boost \
  --host=aarch64-apple-darwin \
  --enable-asm=no \
  --disable-tests \
  --disable-bench \
  CPPFLAGS="-DBOOST_BIND_GLOBAL_PLACEHOLDERS"

arch -arm64 make -j$(sysctl -n hw.ncpu)
```

**Linux (x86_64 servers like Hetzner, DigitalOcean, etc.):**
```bash
./autogen.sh

./configure \
  --without-gui \
  --disable-tests \
  --disable-bench \
  --with-incompatible-bdb \
  CPPFLAGS="-DBOOST_BIND_GLOBAL_PLACEHOLDERS"

make -j$(nproc)
```

**Linux (Raspberry Pi / ARM64):**
```bash
./autogen.sh

./configure \
  --without-gui \
  --disable-tests \
  --disable-bench \
  --with-incompatible-bdb \
  --with-boost-libdir=/usr/lib/aarch64-linux-gnu \
  CPPFLAGS="-DBOOST_BIND_GLOBAL_PLACEHOLDERS"

make -j$(nproc)
```

⚠️ **IMPORTANT:** Do NOT use `--disable-wallet` or you won't be able to mine!

### Running

**Start the daemon (REQUIRED FLAGS):**
```bash
./src/badcoind \
  -maxtipage=120000000 \
  -algo=yescrypt \
  -noonion \
  -daemon
```

**Critical flags explained:**
- `-maxtipage=120000000` - Accept old blockchain timestamps (REQUIRED)
- `-algo=yescrypt` - Easiest CPU mining algorithm
- `-noonion` - Disable TOR (prevents random shutdowns on macOS)

**Mining:**
```bash
# Get a mining address
./src/badcoin-cli getnewaddress

# Mine blocks (replace ADDRESS with yours)
./src/badcoin-cli -rpcclienttimeout=1800 generatetoaddress 10 "ADDRESS"
```

**Mining on remote servers (persist after SSH disconnect):**
```bash
# Option 1: Use screen
screen -S mining
./src/badcoin-cli -rpcclienttimeout=1800 generatetoaddress 1000 "YOUR_ADDRESS"
# Press Ctrl+A, then D to detach
# Reconnect later: screen -r mining

# Option 2: Use tmux
tmux new -s mining
./src/badcoin-cli -rpcclienttimeout=1800 generatetoaddress 1000 "YOUR_ADDRESS"
# Press Ctrl+B, then D to detach
# Reconnect later: tmux attach -t mining
```

**Monitoring:**
```bash
# Check current block height
./src/badcoin-cli getblockcount

# Check wallet balance
./src/badcoin-cli getbalance

# Check blockchain sync status
./src/badcoin-cli getblockchaininfo
```

**Stop the daemon:**
```bash
./src/badcoin-cli stop
```

### GUI Wallet (macOS Only)

**Additional dependencies for GUI:**
```bash
brew install qt@5 qrencode
brew unlink protobuf
brew install protobuf@21
```

**Build with GUI:**
```bash
export PKG_CONFIG_PATH="/opt/homebrew/opt/libevent/lib/pkgconfig:/opt/homebrew/opt/qt@5/lib/pkgconfig:/opt/homebrew/opt/protobuf@21/lib/pkgconfig:$PKG_CONFIG_PATH"
export PATH="/opt/homebrew/opt/qt@5/bin:/opt/homebrew/opt/protobuf@21/bin:$PATH"

arch -arm64 ./configure \
  --with-gui=qt5 \
  --with-boost=/opt/homebrew/opt/boost \
  --host=aarch64-apple-darwin \
  --enable-asm=no \
  --disable-tests \
  --disable-bench \
  CPPFLAGS="-DBOOST_BIND_GLOBAL_PLACEHOLDERS -I/opt/homebrew/opt/protobuf@21/include" \
  LDFLAGS="-L/opt/homebrew/opt/protobuf@21/lib"

arch -arm64 make -j$(sysctl -n hw.ncpu)
```

**Launch GUI wallet:**
```bash
./src/qt/badcoin-qt -datadir=/path/to/data -maxtipage=120000000 -noonion &
```

**Mining via GUI:**
- Go to: Help → Debug window → Console tab
- Type: `generatetoaddress 10 "YOUR_ADDRESS"`

**Note:** GUI wallet includes badcoind, so don't run both simultaneously.

## Important Notes

### Consensus Bug Fix (Nov 2025)

This codebase includes a critical fix for floating-point arithmetic in block reward calculation that caused non-deterministic validation across different systems. Blocks before height 1,400,000 use lenient validation; future blocks enforce strict consensus.

### Troubleshooting

**"Method not found" error on createwallet:**
- This version doesn't have `createwallet` - the wallet is created automatically
- Just use `./src/badcoin-cli getnewaddress` directly

**"Method not found" error on getnewaddress:**
- Wallet support wasn't compiled in
- Rebuild WITHOUT `--disable-wallet` flag
- Make sure to include `--with-incompatible-bdb`

**generatetoaddress returns empty array `[]`:**
- Node thinks it's still syncing
- Restart daemon with `-maxtipage=120000000` flag
- Or add `maxtipage=120000000` to your badcoin.conf

**libdb_cxx headers missing:**
```bash
sudo apt-get install libdb-dev libdb++-dev
# or
sudo apt-get install libdb5.3-dev libdb5.3++-dev
```

**Found Berkeley DB other than 4.8:**
- Add `--with-incompatible-bdb` to configure command

### Known Issues

1. **TOR Controller** - Always use `-noonion` flag or daemon will randomly shutdown (macOS issue)
2. **Old Timestamps** - Must use `-maxtipage=120000000` to accept historical blockchain
3. **Mining Timeouts** - RPC may timeout during mining, but block generation continues (this is normal)

## Network Information

- **Default P2P Port:** 9012
- **Default RPC Port:** 9332
- **Genesis Block:** Nov 12, 2018
- **Block Time:** ~2-10 minutes (varies by algorithm)
- **Total Supply:** 21 billion BAD
- **Algorithms:** SHA256d, Scrypt, Groestl, Skein, Yescrypt

## Revival Status

See [STATUS.md](STATUS.md) for current blockchain state, roadmap, and community revival progress.

## Community

- **Original Repo:** https://github.com/ScriptProdigy/Badcoin
- **Telegram:** Bad Crypto community
- **BitcoinTalk:** https://bitcointalk.org/index.php?topic=5140081.0

## License

Badcoin Core is released under the terms of the MIT license. See [COPYING](COPYING) for more information.