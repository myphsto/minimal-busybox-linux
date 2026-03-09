#!/bin/bash

# Headless testing script for minimal-busybox-linux
# This runs the VM in text mode only - faster for debugging

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

echo "Starting QEMU in headless mode..."
[ "$USE_UEFI" = true ] && echo "Mode: UEFI" || echo "Mode: BIOS"
echo "All output will appear in this terminal"
echo ""

QEMU_OPTS="-cdrom $ISO_FILE -m 512M -smp 2 -boot d -nographic -serial stdio -monitor none"

if [ "$USE_UEFI" = true ]; then
    if [ ! -f "$OVMF_PATH" ]; then
        if [ -f "/opt/homebrew/share/qemu/edk2-x86_64-code.fd" ]; then
            OVMF_PATH="/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
        elif [ -f "/usr/local/share/qemu/edk2-x86_64-code.fd" ]; then
            OVMF_PATH="/usr/local/share/qemu/edk2-x86_64-code.fd"
        fi
    fi
    
    if [ -f "$OVMF_PATH" ]; then
        QEMU_OPTS="$QEMU_OPTS -drive if=pflash,format=raw,readonly=on,file=$OVMF_PATH"
    fi
fi

# Determine acceleration based on platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    # HVF only works if host and guest architectures match (x86_64 on x86_64)
    if [[ "$(uname -m)" == "x86_64" ]]; then
        ACCEL_OPT="-accel hvf -cpu host"
    else
        echo "Note: Running x86_64 guest on $(uname -m) host. Using TCG emulation (slower)."
        ACCEL_OPT="-cpu max"
    fi
else
    if [ -e /dev/kvm ]; then
        ACCEL_OPT="-enable-kvm -cpu host"
    else
        ACCEL_OPT="-cpu max"
    fi
fi

exec qemu-system-x86_64 $QEMU_OPTS $ACCEL_OPT "${OTHER_ARGS[@]}"
