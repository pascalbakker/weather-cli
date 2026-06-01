#!/usr/bin/env bash
set -e

SOURCE="weather.scm"
OUTPUT_NAME="weather"

# Ensure the source exists
if [ ! -f "$SOURCE" ]; then
    echo "Error: $SOURCE not found."
    exit 1
fi

echo "Starting compilation pipeline..."

# ==============================================================================
# 1. HOST ARCHITECTURE (Native Linux x86_64 Static)
# ==============================================================================
echo "Building for Local Linux x86_64 (Static)..."
csc -O3 -d0 -b -strip -static \
    -o "${OUTPUT_NAME}_linux_x86_64" \
    "$SOURCE" -L -lssl -L -lcrypto -L -lz


# ==============================================================================
# 2. INTEL/AMD LINUX PORTABLE (via musl-libc)
#    Produces a zero-dependency binary that runs on any x86_64 Linux distro.
# ==============================================================================
if command -v musl-gcc &> /dev/null; then
    echo "Building for Portable Linux x86_64 (musl)..."
    csc -compiler musl-gcc -O3 -d0 -b -strip -static \
        -o "${OUTPUT_NAME}_linux_x86_64_musl" \
        "$SOURCE" -L -lssl -L -lcrypto -L -lz
else
    echo "Skipping musl build: musl-gcc not installed."
fi


# ==============================================================================
# 3. ARM64 / AARCH64 LINUX (e.g., Raspberry Pi 4/5, AWS Graviton)
#    Requires: aarch64-linux-gnu-gcc toolchain
# ==============================================================================
if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "Cross-compiling for Linux ARM64..."
    csc -compiler aarch64-linux-gnu-gcc -O3 -d0 -b -strip -static \
        -o "${OUTPUT_NAME}_linux_arm64" \
        "$SOURCE" -L -lssl -L -lcrypto -L -lz
else
    echo "Skipping ARM64 build: aarch64-linux-gnu-gcc not installed."
fi


# ==============================================================================
# 4. FREEBSD x86_64 (Cross-compiled from Linux)
#    Requires: x86_64-unknown-freebsd14-gcc toolchain
# ==============================================================================
if command -v x86_64-unknown-freebsd14-gcc &> /dev/null; then
    echo "Cross-compiling for FreeBSD x86_64..."
    csc -compiler x86_64-unknown-freebsd14-gcc -O3 -d0 -b -strip -static \
        -o "${OUTPUT_NAME}_freebsd_x86_64" \
        "$SOURCE" -L -lssl -L -lcrypto -L -lz
else
    echo "Skipping FreeBSD build: FreeBSD toolchain not found."
fi

echo "Compilation matrix complete."
