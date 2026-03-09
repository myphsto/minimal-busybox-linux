#!/bin/bash

# Local testing script for minimal-busybox-linux
# This script makes it easy to test the ISO locally with QEMU

set -e

ISO_FILE="./output/minimal-busybox-linux.iso"

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: ISO file not found at $ISO_FILE"
    echo "Run 'make iso' first to build the ISO"
    exit 1
fi

USE_UEFI=false
OVMF_PATH="/usr/share/ovmf/OVMF.fd"
OTHER_ARGS=()

# Simple argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        --uefi|-uefi)
            USE_UEFI=true
            shift
            ;;
        *)
            OTHER_ARGS+=("$1")
            shift
            ;;
    esac
done

echo "Starting QEMU with minimal-busybox-linux ISO..."
[ "$USE_UEFI" = true ] && echo "Mode: UEFI" || echo "Mode: BIOS"
echo ""

QEMU_OPTS="-cdrom $ISO_FILE -m 512M -smp 2 -boot d"

if [ "$USE_UEFI" = true ]; then
    # Try to find OVMF if default path doesn't exist
    if [ ! -f "$OVMF_PATH" ]; then
        # Check common macOS Homebrew path
        if [ -f "/opt/homebrew/share/qemu/edk2-x86_64-code.fd" ]; then
            OVMF_PATH="/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
        elif [ -f "/usr/local/share/qemu/edk2-x86_64-code.fd" ]; then
            OVMF_PATH="/usr/local/share/qemu/edk2-x86_64-code.fd"
        fi
    fi
    
    if [ -f "$OVMF_PATH" ]; then
        # Use -drive for UEFI as it's more robust than -bios on some QEMU versions
        QEMU_OPTS="$QEMU_OPTS -drive if=pflash,format=raw,readonly=on,file=$OVMF_PATH"
    else
        echo "Warning: OVMF firmware not found. UEFI boot might fail."
        echo "Install ovmf (Linux) or qemu (macOS Homebrew) to get UEFI support."
    fi
fi

# Determine display and acceleration based on platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    DISPLAY_OPT="-display cocoa"
    # HVF only works if host and guest architectures match (x86_64 on x86_64)
    if [[ "$(uname -m)" == "x86_64" ]]; then
        ACCEL_OPT="-accel hvf -cpu host"
    else
        echo "Note: Running x86_64 guest on $(uname -m) host. Using TCG emulation (slower)."
        ACCEL_OPT="-cpu max"
    fi
else
    # Linux/Other
    DISPLAY_OPT="-display gtk"
    # Check if KVM is available
    if [ -e /dev/kvm ]; then
        ACCEL_OPT="-enable-kvm -cpu host"
    else
        ACCEL_OPT="-cpu max"
    fi
fi

exec qemu-system-x86_64 $QEMU_OPTS $DISPLAY_OPT $ACCEL_OPT "${OTHER_ARGS[@]}"
