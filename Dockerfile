FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    binutils \
    bison \
    flex \
    libncurses-dev \
    libssl-dev \
    libelf-dev \
    bc \
    kmod \
    cpio \
    gawk \
    wget \
    rsync \
    tar \
    xz-utils \
    git \
    python3 \
    python3-dev \
    grub-common \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    xorriso \
    libisoburn-dev \
    sudo \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

CMD ["/bin/bash"]