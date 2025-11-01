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

**Linux / Raspberry Pi:**
```bash
sudo apt-get install -y \
  build-essential libtool autotools-dev automake autoconf \
  pkg-config libssl-dev libevent-dev bsdmainutils git \
  libboost-system-dev libboost-filesystem-dev \
  libboost-program-options-dev libboost-thread-dev \
  libboost-chrono-dev libdb5.3-dev libdb5.3++-dev
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

**Linux / Raspberry Pi:**
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

**Stop the daemon:**
```bash
./src/badcoin-cli stop
```

## Important Notes

### Consensus Bug Fix (Nov 2025)

This codebase includes a critical fix for floating-point arithmetic in block reward calculation that caused non-deterministic validation across different systems. Blocks before height 1,400,000 use lenient validation; future blocks enforce strict consensus.

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