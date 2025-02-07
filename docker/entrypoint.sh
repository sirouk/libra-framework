#!/bin/sh
set -e

# Remove any existing build signal
rm -f /build-signal/build-complete

cd $HOME
#rm -rf ./libra-framework
if [ ! -d "$HOME/libra-framework" ]; then
    echo "Fetching dependencies..."
    apt update && apt install -y curl git tmux jq build-essential cmake clang llvm libgmp-dev pkg-config libssl-dev lld libpq-dev

    curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
    . "$HOME/.cargo/env" -- -y
    
    # Configure cargo to use the shared cache
    mkdir -p "$HOME/.cargo"
    cat > "$HOME/.cargo/config.toml" << EOF
[build]
target-dir = "$HOME/.cargo/target"

[cache]
shared = true
EOF
    
    echo "Fetching libra-source code..."
    git clone https://github.com/0o-de-lally/libra-framework -b easy-testnet
fi

if [ "$ME" = "alice" ]; then
    echo "This is $ME, performing the build..."

    echo "Building libra-framework..."
    . "$HOME/.cargo/env" -- -y
    cd $HOME/libra-framework/
    cargo build --release -p libra

    echo "Build complete, sending signal..."
    touch /build-signal/build-complete
else
    echo "This is $ME, waiting for alice to complete the build..."
    # Wait for the build-complete signal
    while [ ! -f "/build-signal/build-complete" ]; do
        echo "Waiting for build to complete..."
        sleep 15
    done
    echo "Build is complete, proceeding..."
fi

# PATCH: copy mainnet.mrb to head.mrb
cp -rf $HOME/libra-framework/framework/releases/mainnet.mrb $HOME/libra-framework/framework/releases/head.mrb

echo "Starting Libra node: $ME"
export LIBRA_CI=1
export MODE_0L="TESTNET"
$HOME/.cargo/target/release/libra ops genesis testnet --framework-mrb-path $HOME/libra-framework/framework/releases/head.mrb --me "$ME" --host-list alice:6180 --host-list bob:6180 --host-list carol:6180 

echo "Starting up the libra node..."
RUST_LOG=INFO $HOME/.cargo/target/release/libra node
