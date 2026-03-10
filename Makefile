# Minimal Linux Distribution Build System
# For minimal-busybox-linux

# Load environment variables from .env file
# Environment variables set externally (e.g., CI/CD) take precedence
-include .env

# Ensure required variables are set
ifndef KERNEL_VERSION
$(error KERNEL_VERSION is not set. Check .env file or set environment variable)
endif

ifndef BUSYBOX_VERSION
$(error BUSYBOX_VERSION is not set. Check .env file or set environment variable)
endif

BUILD_DIR := $(CURDIR)/build
CONFIG_DIR := $(CURDIR)/config
SCRIPTS_DIR := $(CURDIR)/scripts
SRC_DIR := $(CURDIR)/src
OUTPUT_DIR := $(CURDIR)/output

DOCKER_IMAGE := minimal-busybox-linux-builder
DOCKER_RUN := docker run --rm -v $(CURDIR):/build --user $(shell id -u):$(shell id -g) \
	-e KERNEL_VERSION=$(KERNEL_VERSION) \
	-e BUSYBOX_VERSION=$(BUSYBOX_VERSION) \
	$(DOCKER_IMAGE)

.PHONY: all clean docker-build kernel rootfs iso test test-headless

docker-build:
	@echo "Building Docker build environment..."
	docker build -t $(DOCKER_IMAGE) .

kernel: docker-build
	@echo "Building Linux kernel $(KERNEL_VERSION)..."
	@$(DOCKER_RUN) bash /build/scripts/build-scripts/build-kernel.sh
	@mkdir -p $(OUTPUT_DIR)
	@if [ -f $(BUILD_DIR)/kernel/linux-$(KERNEL_VERSION)/arch/x86/boot/bzImage ]; then \
		cp $(BUILD_DIR)/kernel/linux-$(KERNEL_VERSION)/arch/x86/boot/bzImage $(OUTPUT_DIR)/vmlinuz; \
	else \
		echo "Error: Kernel not found"; exit 1; \
	fi

rootfs: docker-build
	@echo "Building minimal root filesystem..."
	@$(DOCKER_RUN) bash /build/scripts/build-scripts/build-rootfs.sh
	@mkdir -p $(OUTPUT_DIR)
	@if [ -f $(BUILD_DIR)/rootfs/initramfs.gz ]; then \
		cp $(BUILD_DIR)/rootfs/initramfs.gz $(OUTPUT_DIR)/initramfs.gz; \
	else \
		echo "Error: Initramfs not found"; exit 1; \
	fi

iso: kernel rootfs
	@echo "Creating bootable ISO image..."
	@$(DOCKER_RUN) bash /build/scripts/build-scripts/build-iso.sh
	@if [ -f $(BUILD_DIR)/iso/minimal-busybox-linux.iso ]; then \
		cp $(BUILD_DIR)/iso/minimal-busybox-linux.iso $(OUTPUT_DIR)/minimal-busybox-linux.iso; \
	else \
		echo "Error: ISO not found"; exit 1; \
	fi

test:
	@echo "Testing ISO with QEMU (GUI mode)..."
	./scripts/test-scripts/test-local.sh $(ARGS)

test-headless:
	@echo "Testing ISO with QEMU (headless mode)..."
	./scripts/test-scripts/test-headless.sh $(ARGS)

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)/* $(OUTPUT_DIR)/*
	rm -rf /build/cache/*
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true

help:
	@echo "Available targets:"
	@echo "  iso           - Build complete system (kernel + rootfs + ISO)"
	@echo "  kernel        - Build Linux kernel only"
	@echo "  rootfs        - Build root filesystem only"
	@echo "  test          - Test ISO with QEMU (GUI mode)"
	@echo "  test-headless - Test ISO with QEMU (headless mode)"
	@echo "  clean         - Clean all build artifacts"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  Build versions are set in .env file:"
	@echo "    KERNEL_VERSION  = $(KERNEL_VERSION)"
	@echo "    BUSYBOX_VERSION = $(BUSYBOX_VERSION)"
	@echo ""
	@echo "  Override for single build:"
	@echo "    KERNEL_VERSION=6.7.0 make kernel"
	@echo "    KERNEL_VERSION=6.7.0 BUSYBOX_VERSION=1.35.0 make iso"