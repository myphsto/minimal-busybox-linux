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
CACHE_DIR="${PROJECT_ROOT}/cache"
CACHE_TTL=86400 # 24 hours

mkdir -p ${OUTPUT_DIR}
mkdir -p ${CACHE_DIR}

echo "Building Linux kernel ${KERNEL_VERSION}..."

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

CACHE_FILE="${CACHE_DIR}/linux-${KERNEL_VERSION}.tar.xz"

if [ -f "${CACHE_FILE}" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "${CACHE_FILE}")))
    if [ ${CACHE_AGE} -lt ${CACHE_TTL} ]; then
        echo "Using cached kernel source: ${CACHE_FILE}"
    else
        echo "Cached kernel expired, redownloading..."
        rm -f "${CACHE_FILE}"
    fi
fi

if [ ! -d "linux-${KERNEL_VERSION}" ]; then
    if [ -f "${CACHE_FILE}" ]; then
        echo "Extracting kernel from cache..."
        tar -xf "${CACHE_FILE}"
    else
        echo "Downloading Linux kernel ${KERNEL_VERSION}..."
        wget -q https://cdn.kernel.org/pub/linux/kernel/v$(echo ${KERNEL_VERSION} | cut -d. -f1).x/linux-${KERNEL_VERSION}.tar.xz
        cp linux-${KERNEL_VERSION}.tar.xz "${CACHE_FILE}"
        echo "Extracting kernel..."
        tar -xf linux-${KERNEL_VERSION}.tar.xz
        rm linux-${KERNEL_VERSION}.tar.xz
    fi
fi

cd linux-${KERNEL_VERSION}

echo "Applying minimal kernel config..."
cp ${CONFIG_DIR}/minimal.config .config
make olddefconfig

echo "Compiling kernel..."
make -j$(nproc) bzImage

echo "Kernel build completed successfully!"
echo "Kernel image: ${BUILD_DIR}/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage"