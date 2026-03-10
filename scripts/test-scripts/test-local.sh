#!/bin/bash

# Local testing script for minimal-busybox-linux
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/common.sh"

ISO_FILE="${PROJECT_ROOT}/output/minimal-busybox-linux.iso"

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: ISO file not found at $ISO_FILE. Run 'make iso' first."
    exit 1
fi

USE_UEFI=false
OTHER_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --uefi|-uefi) USE_UEFI=true; shift ;;
        *) OTHER_ARGS+=("$1"); shift ;;
    esac
done

echo "Starting QEMU (GUI mode)..."
QEMU_OPTS="-cdrom $ISO_FILE -m 512M -smp 2 -boot d"

if [ "$USE_UEFI" = true ]; then
    OVMF=$(get_ovmf_path)
    [ -f "$OVMF" ] && QEMU_OPTS="$QEMU_OPTS -drive if=pflash,format=raw,readonly=on,file=$OVMF"
fi

exec qemu-system-x86_64 $QEMU_OPTS $(get_display_opts "gui") $(get_accel_opts) "${OTHER_ARGS[@]}"
