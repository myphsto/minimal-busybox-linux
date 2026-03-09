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

BUILD_DIR="/build/build"
OUTPUT_DIR="/build/output"
ISO_DIR="/build/build/iso_root"

echo "Creating bootable hybrid BIOS/UEFI ISO image..."

# Check if kernel and initramfs exist in build directories
KERNEL_FILE="/build/build/kernel/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage"
INITRAMFS_FILE="/build/build/rootfs/initramfs.gz"

if [ ! -f "${KERNEL_FILE}" ]; then
    echo "Error: Kernel not found at ${KERNEL_FILE}. Run 'make kernel' first."
    exit 1
fi

if [ ! -f "${INITRAMFS_FILE}" ]; then
    echo "Error: Initramfs not found at ${INITRAMFS_FILE}. Run 'make rootfs' first."
    exit 1
fi

# Create ISO directory structure
rm -rf ${ISO_DIR}
mkdir -p ${ISO_DIR}/boot/grub
mkdir -p ${BUILD_DIR}/iso

# Copy kernel and initramfs from build directories
cp ${KERNEL_FILE} ${ISO_DIR}/boot/vmlinuz
cp ${INITRAMFS_FILE} ${ISO_DIR}/boot/initramfs.gz

# Copy GRUB configuration
cp /build/config/system/grub.cfg ${ISO_DIR}/boot/grub/grub.cfg

# Create ISO image using grub-mkrescue
echo "Generating hybrid ISO image with grub-mkrescue..."
grub-mkrescue -o ${BUILD_DIR}/iso/minimal-busybox-linux.iso ${ISO_DIR}

echo "ISO build completed successfully!"
echo "Bootable ISO: ${BUILD_DIR}/iso/minimal-busybox-linux.iso"
