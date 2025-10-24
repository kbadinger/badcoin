# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Badcoin is a Bitcoin Core fork implementing auxiliary proof-of-work (auxpow) merged mining. This is a cryptocurrency node implementation written primarily in C++ with Qt GUI support and Python-based functional tests.

## Build System

The project uses GNU Autotools for configuration and Make for building.

### Basic Build Commands

```bash
# Generate configuration scripts
./autogen.sh

# Configure the build (with common options)
./configure

# Build all targets
make

# Build with parallel jobs (faster)
make -j$(nproc)

# Install (optional)
make install
```

### Apple Silicon (ARM64) Build Instructions

On Apple Silicon Macs, the build requires specific configuration due to architecture and modern Boost compatibility:

```bash
# Generate configuration scripts
./autogen.sh

# Set PKG_CONFIG_PATH for libevent and configure for ARM64
export PKG_CONFIG_PATH="/opt/homebrew/opt/libevent/lib/pkgconfig:$PKG_CONFIG_PATH"

# Configure for ARM64 architecture
arch -arm64 ./configure \
  --without-gui \
  --with-boost=/opt/homebrew/opt/boost \
  --host=aarch64-apple-darwin \
  --enable-asm=no \
  --disable-tests \
  --disable-bench \
  CPPFLAGS="-DBOOST_BIND_GLOBAL_PLACEHOLDERS"

# Build
arch -arm64 make -j$(sysctl -n hw.ncpu)
```

**Required Homebrew packages:**
```bash
brew install boost libevent berkeley-db@4 openssl
```

**Known Issues (Already Fixed in This Repo):**
- Boost 1.88+ requires BOOST_BIND_GLOBAL_PLACEHOLDERS define
- Boost 1.69+ made boost::system header-only (removed AX_BOOST_SYSTEM from configure.ac)
- Modern Boost filesystem API changes (is_complete → is_absolute, copy_option → copy_options)
- SSE2 optimizations must be disabled on ARM64 (--enable-asm=no)
- Endian function conflicts with macOS system headers (fixed in crypto/scrypt/)
- Missing #include <list> in validation.h (fixed)
- Missing Boost includes in consensus library (added BOOST_CPPFLAGS to libbitcoinconsensus)

### Common Configure Options (x86_64/Linux)

```bash
# Build with debug symbols
./configure --enable-debug

# Build without wallet support
./configure --disable-wallet

# Build without GUI
./configure --without-gui

# Use incompatible BDB version (breaks wallet compatibility)
./configure --with-incompatible-bdb

# Enable test coverage
./configure --enable-lcov
```

## Testing

### Unit Tests

Run C++ unit tests:
```bash
make check
```

Run a specific unit test:
```bash
src/test/test_bitcoin --log_level=all --run_test=<test_suite_name>
```

### Functional Tests

Run all functional tests:
```bash
test/functional/test_runner.py
```

Run extended test suite:
```bash
test/functional/test_runner.py --extended
```

Run specific functional test:
```bash
test/functional/test_runner.py <test_name>.py
```

Run tests in parallel (4 jobs by default):
```bash
test/functional/test_runner.py --jobs=8
```

Run individual test directly:
```bash
test/functional/<test_name>.py
```

Common test options:
- `--nocleanup`: Leave test data directory after run
- `--tracerpc`: Trace RPC calls to console
- `-l DEBUG`: Set console log level
- `--coverage`: Track RPC coverage

### Util Tests

Test bitcoin utilities:
```bash
test/util/bitcoin-util-test.py -v
```

## Code Architecture

### Source Directory Structure

- **src/**: Core daemon and library code
  - **consensus/**: Consensus-critical code (validation rules, parameters)
  - **crypto/**: Cryptographic primitives (hashing, signing)
  - **policy/**: Policy settings (fees, mempool rules)
  - **primitives/**: Basic data structures (block, transaction)
  - **rpc/**: RPC server implementation and handlers
  - **script/**: Script interpreter and verification
  - **wallet/**: Wallet functionality (key management, coin selection)
  - **qt/**: Qt GUI application
  - **test/**: Unit tests
  - **zmq/**: ZeroMQ notification interface

### Key Components

#### Validation Pipeline
Core validation logic is in `validation.cpp` (the largest file at ~220KB). This handles:
- Block and transaction validation
- Chain state management
- UTXO set updates
- Consensus rule enforcement

#### Network Layer
- `net.cpp` / `net.h`: P2P networking, connection management
- `net_processing.cpp`: Message handling and peer logic
- `protocol.cpp` / `protocol.h`: Network message definitions

#### Consensus
- `consensus/consensus.h`: Consensus parameters
- `consensus/validation.h`: Validation result types
- `chainparams.cpp`: Network-specific parameters (mainnet, testnet, regtest)

#### Merged Mining (Auxpow)
- `auxpow.cpp` / `auxpow.h`: Auxiliary proof-of-work implementation
- Badcoin-specific feature allowing merged mining with other chains

#### RPC Interface
RPC handlers are organized by category:
- `rpc/blockchain.cpp`: Blockchain queries
- `rpc/mining.cpp`: Mining-related calls
- `rpc/net.cpp`: Network information
- `rpc/rawtransaction.cpp`: Transaction creation/signing
- `wallet/rpcwallet.cpp`: Wallet operations

### Testing Infrastructure

Functional tests use Python framework in `test/functional/`:
- `test_framework/`: Reusable test infrastructure
  - `test_framework.py`: Base test class
  - `util.py`: Helper functions
  - `mininode.py`: P2P interface
  - `authproxy.py`: RPC client
- Tests are named by category: `feature_`, `interface_`, `mempool_`, `mining_`, `p2p_`, `rpc_`, `wallet_`

## Coding Standards

### C++ Style (from developer-notes.md)

- **Indentation**: 4 spaces (no tabs), except no indentation for namespaces
- **Braces**: New lines for namespaces/classes/functions, same line for control structures
- **Naming**:
  - Variables/namespaces: `snake_case`
  - Class members: `m_` prefix
  - Global variables: `g_` prefix
  - Constants: `UPPER_CASE`
  - Classes/functions: `PascalCase` (no `C` prefix for classes)
- **Preferences**:
  - `++i` over `i++`
  - `nullptr` over `NULL`
  - `static_assert` over `assert` where possible
- **Formatting**: Use `.clang-format` specification in `src/.clang-format`

### Python Style (Functional Tests)

- Follow PEP-8 guidelines
- Use module-level docstrings
- Avoid wildcard imports
- Method order in test classes: `set_test_params()`, `add_options()`, `setup_xxxx()`, helper methods, `run_test()`

## Development Modes

### Debug Mode

Compile with debug flags:
```bash
./configure --enable-debug
# or
./configure CXXFLAGS="-g -ggdb -O0"
```

### Test Networks

Run with test network:
```bash
bitcoind -testnet  # Use test network
bitcoind -regtest  # Use regression test mode (local testing)
```

Regtest mode allows on-demand block generation, useful for functional testing.

### Debug Logging

Check `debug.log` in the data directory for error messages:
```bash
bitcoind -debug      # Enable all debug categories
bitcoind -debug=qt   # Enable specific category
```

### Multithreading Debug

Compile with lock order checking:
```bash
./configure CXXFLAGS="-DDEBUG_LOCKORDER -g"
```

## Pull Request Guidelines

### PR Title Prefixes

Use area-specific prefixes:
- **Consensus**: Consensus-critical code changes
- **Docs**: Documentation updates
- **Qt**: GUI changes
- **Mining**: Mining code
- **Net** or **P2P**: Network/P2P changes
- **RPC/REST/ZMQ**: API changes
- **Scripts and tools**: Utility scripts
- **Tests**: Test updates
- **Trivial**: Non-code changes (comments, whitespace)
- **Utils and libraries**: Utility/library changes
- **Wallet**: Wallet code

### Commit Guidelines

- Atomic commits with clear messages
- Short subject line (50 chars max)
- Detailed explanation in body
- Reference issues: `refs #1234` or `fixes #4321`

### Code Review Terms

- **ACK**: Tested and approved
- **NACK**: Disagree (with justification)
- **utACK**: Code review only, not tested
- **Concept ACK**: Agree with general approach
- **Nit**: Minor non-blocking issue

## Dependencies

Required:
- libssl (crypto operations)
- libboost (utility library)
- libevent (networking)

Optional:
- miniupnpc (UPnP support)
- libdb4.8 (Berkeley DB for wallet)
- Qt 5 (GUI)
- protobuf (payment protocol)
- libqrencode (QR codes)
- libzmq3 (ZMQ notifications)

## License

MIT License - contributions must be licensed under MIT unless specified otherwise.
