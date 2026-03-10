#!/bin/bash

set -e

# Check for required environment variable
if [ -z "$KERNEL_VERSION" ]; then
    echo "Error: KERNEL_VERSION environment variable is not set"
    echo "Please set it in your .env file or export it:"
    echo "  export KERNEL_VERSION=6.6.58"
    echo "Or specify it when running make:"
    echo "  KERNEL_VERSION=6.6.58 make kernel"
    exit 1
fi

# Use environment variable or default to /build (Docker default)
PROJECT_ROOT="${PROJECT_ROOT:-/build}"
BUILD_DIR="${PROJECT_ROOT}/build/kernel"
CONFIG_DIR="${PROJECT_ROOT}/config/kernel"
OUTPUT_DIR="${PROJECT_ROOT}/output"

mkdir -p ${OUTPUT_DIR}
echo "Building Linux kernel ${KERNEL_VERSION}..."

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

if [ ! -d "linux-${KERNEL_VERSION}" ]; then
    echo "Downloading Linux kernel ${KERNEL_VERSION}..."
    wget -q https://cdn.kernel.org/pub/linux/kernel/v$(echo ${KERNEL_VERSION} | cut -d. -f1).x/linux-${KERNEL_VERSION}.tar.xz
    tar -xf linux-${KERNEL_VERSION}.tar.xz
    rm linux-${KERNEL_VERSION}.tar.xz
fi

cd linux-${KERNEL_VERSION}

echo "Applying minimal kernel config..."
cp ${CONFIG_DIR}/minimal.config .config
make olddefconfig

echo "Compiling kernel..."
make -j$(nproc) bzImage

echo "Kernel build completed successfully!"
echo "Kernel image: ${BUILD_DIR}/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage"