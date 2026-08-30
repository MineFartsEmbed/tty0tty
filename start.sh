#!/bin/bash

# Get the absolute path of the script directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define exact binary paths matching where files exist post-compile
MODULE_PATH="$ROOT_DIR/module/tty0tty.ko"
PTS_BIN="$ROOT_DIR/pts/tty0tty"

echo "=== tty0tty Local Dependencies Check ==="

pkgs=(gcc-13 build-essential)
for pkg in "${pkgs[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        sudo apt install -y "$pkg"
    fi
done

echo "=== tty0tty Local Manager ==="

function maybeCompile() {
    local binary_path="$1"
    local label="$2"
    local build_dir="$3"
    local compile_cmd="$4"

    if [ ! -f "$binary_path" ]; then
        echo "[*] $label not found. Compiling..."
        
        ( cd "$build_dir" && eval "$compile_cmd" >/dev/null 2>&1 )
        
        # Immediate verification to confirm successful compilation output
        if [ ! -f "$binary_path" ]; then
            echo "[-] Error: Failed to compile $label."
            exit 1
        fi
    else
        echo "[+] $label binary exists (Loaded from cache)."
    fi
}

# 1. Check and cache Kernel Module
maybeCompile \
    "$MODULE_PATH" \
    "Kernel module" \
    "$ROOT_DIR/module" \
    "make CONFIG_DEBUG_INFO_BTF=n KCFLAGS=\"-w\""

# 2. Check and cache PTS Utility
maybeCompile \
    "$PTS_BIN" \
    "PTS utility" \
    "$ROOT_DIR/pts" \
    "gcc -Wall -O2 -D_GNU_SOURCE -Wno-unused-but-set-variable -Wno-format tty0tty.c -o \"$PTS_BIN\""

# 3. Load the Kernel Module
echo "[*] Checking if driver is loaded..."
if lsmod | grep -q "tty0tty"; then
    echo "[+] Driver tty0tty is already loaded."
else
    echo "[*] Loading driver via sudo insmod..."
    sudo insmod "$MODULE_PATH"
    if [ $? -eq 0 ]; then
        echo "[+] Driver loaded successfully."
        
        # Deterministic wait loop for /dev entries (Max 5 seconds)
        echo "[*] Waiting for kernel to initialize device entries..."
        COUNTER=0
        while [ ! -e /dev/tnt0 ] && [ $COUNTER -lt 50 ]; do
            sleep 0.1
            ((COUNTER++))
        done
    else
        echo "[-] Error: Failed to insert kernel module."
        exit 1
    fi
fi

# 4. Grant permissions to created ports
echo "[*] Setting permissions for /dev/tnt*..."
if ls /dev/tnt* &>/dev/null; then
    sudo chmod 666 /dev/tnt*
    echo "[+] Port permissions set successfully."
fi

echo "[+] Setup complete. Ready to use."
