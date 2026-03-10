#!/bin/bash

set -e

if [ -z "$BUSYBOX_VERSION" ]; then
    echo "Error: BUSYBOX_VERSION environment variable is not set"
    echo "Please set it in your .env file or export it:"
    echo "  export BUSYBOX_VERSION=1.36.1"
    echo "Or specify it when running make:"
    echo "  BUSYBOX_VERSION=1.36.1 make rootfs"
    exit 1
fi

PROJECT_ROOT="${PROJECT_ROOT:-/build}"
BUILD_DIR="${PROJECT_ROOT}/build/rootfs"
OUTPUT_DIR="${PROJECT_ROOT}/output"

echo "Building minimal root filesystem with BusyBox ${BUSYBOX_VERSION}..."

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

if [ ! -d "busybox-${BUSYBOX_VERSION}" ]; then
    echo "Downloading BusyBox ${BUSYBOX_VERSION}..."
    wget -q https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
    tar -xf busybox-${BUSYBOX_VERSION}.tar.bz2
    rm busybox-${BUSYBOX_VERSION}.tar.bz2
fi

cd busybox-${BUSYBOX_VERSION}

echo "Configuring BusyBox..."
make defconfig
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

echo "Compiling BusyBox..."
make -j$(nproc)
make install

ROOTFS_DIR="${BUILD_DIR}/rootfs"
rm -rf ${ROOTFS_DIR}
mkdir -p ${ROOTFS_DIR}

cp -r _install/* ${ROOTFS_DIR}/

cd ${ROOTFS_DIR}
mkdir -p dev proc sys tmp var/log etc/init.d

if [ -d "${PROJECT_ROOT}/src/rootfs" ]; then
    echo "Merging custom rootfs files from src/rootfs..."
    cp -r ${PROJECT_ROOT}/src/rootfs/. ${ROOTFS_DIR}/
fi

cp ${PROJECT_ROOT}/config/system/init.sh init
chmod +x init

cat > etc/passwd << 'EOF'
root:x:0:0:root:/root:/bin/sh
EOF

cat > etc/group << 'EOF'
root:x:0:
EOF

echo "Creating initramfs..."
cd ${ROOTFS_DIR}
find . | cpio -o -H newc | gzip > ${BUILD_DIR}/initramfs.gz

echo "Root filesystem build completed successfully!"
echo "Initramfs: ${BUILD_DIR}/initramfs.gz"
