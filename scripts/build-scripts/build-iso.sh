#!/bin/bash

set -e

# Check for required environment variable
if [ -z "$KERNEL_VERSION" ]; then
    echo "Error: KERNEL_VERSION environment variable is not set"
    echo "Please set it in your .env file or export it:"
    echo "  export KERNEL_VERSION=6.6.58"
    echo "Or specify it when running make:"
    echo "  KERNEL_VERSION=6.6.58 make iso"
    exit 1
fi

# Use environment variable or default to /build (Docker default)
PROJECT_ROOT="${PROJECT_ROOT:-/build}"
BUILD_DIR="${PROJECT_ROOT}/build"
OUTPUT_DIR="${PROJECT_ROOT}/output"
ISO_DIR="${PROJECT_ROOT}/build/iso_root"

echo "Creating bootable hybrid BIOS/UEFI ISO image..."

KERNEL_FILE="${BUILD_DIR}/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage"
INITRAMFS_FILE="${BUILD_DIR}/rootfs/initramfs.gz"

if [ ! -f "${KERNEL_FILE}" ]; then
    echo "Error: Kernel not found at ${KERNEL_FILE}. Run 'make kernel' first."
    exit 1
fi

if [ ! -f "${INITRAMFS_FILE}" ]; then
    echo "Error: Initramfs not found at ${INITRAMFS_FILE}. Run 'make rootfs' first."
    exit 1
fi

rm -rf ${ISO_DIR}
mkdir -p ${ISO_DIR}/boot/grub
mkdir -p ${BUILD_DIR}/iso

cp ${KERNEL_FILE} ${ISO_DIR}/boot/vmlinuz
cp ${INITRAMFS_FILE} ${ISO_DIR}/boot/initramfs.gz

cp ${PROJECT_ROOT}/config/system/grub.cfg ${ISO_DIR}/boot/grub/grub.cfg

echo "Generating hybrid ISO image with grub-mkrescue..."
grub-mkrescue -o ${BUILD_DIR}/iso/minimal-busybox-linux.iso ${ISO_DIR}

echo "ISO build completed successfully!"
echo "Bootable ISO: ${BUILD_DIR}/iso/minimal-busybox-linux.iso"
