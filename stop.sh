#!/bin/bash

# Get the absolute path of the script directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== tty0tty Local Teardown ==="

# 1. Check and unload Kernel Module
echo "[*] Checking if driver is loaded..."
if lsmod | grep -q "tty0tty"; then
    echo "[*] Unloading driver via sudo rmmod..."
    sudo rmmod tty0tty
    if [ $? -eq 0 ]; then
        echo "[+] Driver unloaded successfully."
    else
        echo "[-] Error: Failed to unload driver."
        exit 1
    fi
else
    echo "[+] Driver tty0tty is already stopped/unloaded."
fi

# 2. Handle optional deep cleaning of build artifacts
if [ "$1" == "clean" ]; then
    echo "[*] Cleaning up local precompiled binaries and artifacts..."
    
    # Clean user-space utilities
    if [ -d "$ROOT_DIR/pts" ]; then
        cd "$ROOT_DIR/pts" && make clean &>/dev/null
        rm -f tty0tty
    fi
    if [ -d "$ROOT_DIR/ssniffer" ]; then
        cd "$ROOT_DIR/ssniffer" && make clean &>/dev/null
        rm -f ssniffer
    fi
    
    # Clean kernel module artifacts
    if [ -d "$ROOT_DIR/module" ]; then
        cd "$ROOT_DIR/module" && make clean &>/dev/null
    fi
    
    echo "[+] Workspace cleaned completely."
fi

echo "[+] Teardown complete."
