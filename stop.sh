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

echo "[+] Teardown complete."
