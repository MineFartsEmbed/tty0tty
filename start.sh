#!/bin/bash

# Get the absolute path of the script directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Explicitly map binaries where the native Makefiles output them
MODULE_PATH="$ROOT_DIR/module/tty0tty.ko"
PTS_BIN="$ROOT_DIR/pts/tty0tty"

echo "=== tty0tty Local Dependencies Check ==="

# Check and install missing system build tools dynamically
if ! command -v gcc-13 &> /dev/null || ! command -v make &> /dev/null; then
    echo "[*] Missing compiler or build tools. Installing..."
    sudo apt update
    sudo apt install gcc-13 build-essential -y
else
    echo "[+] System build dependencies are already met."
fi

echo "=== tty0tty Local Manager ==="

# 1. Check and compile Kernel Module (Cached evaluation)
if [ ! -f "$MODULE_PATH" ]; then
    echo "[*] Kernel module not found. Compiling..."
    cd "$ROOT_DIR/module" && make CONFIG_DEBUG_INFO_BTF=n KCFLAGS="-w"
    if [ $? -ne 0 ]; then
        echo "[-] Error: Failed to compile kernel module."
        exit 1
    fi
else
    echo "[+] Kernel module binary exists (using cached build)."
fi

# 2. Check and compile PTS Utility (Cached evaluation)
if [ ! -f "$PTS_BIN" ]; then
    echo "[*] PTS utility not found. Compiling..."
    # Using explicit -o flag ensures it drops exactly where $PTS_BIN expects it
    cd "$ROOT_DIR/pts" && gcc -Wall -O2 -D_GNU_SOURCE -Wno-unused-but-set-variable -Wno-format tty0tty.c -o "$PTS_BIN"
    if [ $? -ne 0 ]; then
        echo "[-] Error: Failed to compile PTS utility."
        exit 1
    fi
else
    echo "[+] PTS utility binary exists (using cached build)."
fi

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
        
        if [ ! -e /dev/tnt0 ]; then
            echo "[!] Warning: Kernel loaded, but /dev/tnt0 did not appear within 5 seconds."
        fi
    else
        echo "[-] Error: Failed to load driver."
        exit 1
    fi
fi

# 4. Grant permissions to created ports
echo "[*] Setting permissions for /dev/tnt*..."
if ls /dev/tnt* &>/dev/null; then
    sudo chmod 666 /dev/tnt*
    echo "[+] Port permissions set successfully."
else
    echo "[!] No active /dev/tnt ports found."
fi

echo "[+] Setup complete. Ready to use."
