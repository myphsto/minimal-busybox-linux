# minimal-busybox-linux

A minimal Linux distribution build system for creating lightweight Linux environments using BusyBox and a custom kernel configuration. Now with **Hybrid BIOS/UEFI** support.

## Overview

This project builds a complete Linux system from scratch using:
- **Linux Kernel 6.17**: Minimal configuration with EFI support
- **BusyBox 1.36.1**: Provides ~300 Unix utilities in a single static binary
- **Custom Init Script**: Shell script at `/init` that runs as PID 1
- **GRUB2 Bootloader**: Configured for both Legacy BIOS and UEFI
- **Docker Build Environment**: Ensures reproducible builds across platforms (macOS/Linux)

**Final Result**: ~20-30MB bootable Hybrid ISO with full Linux functionality.

## Features

- **Hybrid BIOS/UEFI support**: Boots on almost any x86_64 hardware
- **Stealth Boot**: Instant direct-to-shell boot (zero timeout)
- **Cross-Platform**: Built in Docker, tested on macOS and Linux
- **Minimal footprint**: Built with only essential components
- **Fast boot**: Optimized kernel configuration for quick startup (~3-5 seconds)
- **Reproducible builds**: Docker-based build environment ensures consistency
- **Local testing**: QEMU integration with UEFI (OVMF) support

## Quick Start

1. **Build the complete system:**
   ```bash
   make iso   # Builds kernel, rootfs, and ISO
   ```

2. **Test locally with QEMU:**
   ```bash
   # BIOS Mode (Default)
   make test          # GUI mode
   make test-headless # Console mode

   # UEFI Mode
   ./scripts/test-scripts/test-local.sh --uefi
   ./scripts/test-scripts/test-headless.sh --uefi
   ```

   **QEMU Controls:**
   - **GUI mode**: Click X on window to exit. Press `Ctrl+Alt+G` to release mouse/keyboard
   - **Headless mode**: Type `poweroff` in VM shell, or `killall qemu-system-x86_64` from another terminal

3. **Create bootable USB:**
   ```bash
   sudo dd if=output/minimal-busybox-linux.iso of=/dev/sdX bs=1M status=progress
   ```

## Build Targets

| Target | Description |
|--------|-------------|
| `make iso` | Build complete system (kernel + rootfs + ISO) |
| `make kernel` | Build Linux kernel only |
| `make rootfs` | Build root filesystem only |
| `make test` | Test ISO with QEMU (GUI mode) |
| `make test-headless` | Test ISO with QEMU (console mode) |
| `make clean` | Clean build artifacts |
| `make clean-all` | Clean build artifacts and download cache |
| `make help` | Show all available targets |

## How It Works

### Build Process Flow

```
1. make iso
   ↓
2. docker build (create build environment)
   ↓
3. make kernel
   - Download Linux kernel source
   - Apply minimal configuration from config/kernel/minimal.config
   - Compile kernel (bzImage)
   - Copy to output/vmlinuz
   ↓
4. make rootfs
   - Download BusyBox source
   - Compile static binary
   - Create filesystem structure
   - Copy init script from config/system/init.sh
   - Generate initramfs.gz
   ↓
5. Build ISO
   - Combine kernel + initramfs
   - Add GRUB2 bootloader (Hybrid BIOS/UEFI)
   - Create hybrid ISO using grub-mkrescue
   - Output: minimal-busybox-linux.iso
```

### Architecture Decisions

**Why Docker for builds?**
- Ensures consistent build environment across different host systems
- Isolates build dependencies from host system
- Reproducible builds regardless of host distro

**Why BusyBox?**
- Single static binary provides 300+ Unix commands
- No shared library dependencies
- Proven reliability in embedded systems
- ~1MB total size

## Directory Structure

```
minimal-busybox-linux/
├── README.md              # This file
├── Makefile               # Build orchestration
├── Dockerfile             # Build environment definition
├── .env                   # Build configuration (versions)
├── build/                 # Build artifacts (generated)
│   ├── kernel/            # Kernel build workspace
│   ├── rootfs/            # Root filesystem build workspace
│   └── iso/               # ISO assembly workspace
├── config/                # Configuration files
│   ├── kernel/            # Kernel configurations
│   │   └── minimal.config # Minimal kernel config
│   └── system/            # System configurations
│       └── init.sh        # Custom init script
├── scripts/               # Build and utility scripts
│   ├── build-scripts/     # Core build scripts
│   │   ├── build-kernel.sh   # Kernel compilation
│   │   ├── build-rootfs.sh   # Root filesystem creation
│   │   └── build-iso.sh      # ISO image creation
│   └── test-scripts/      # QEMU test scripts
│       ├── test-local.sh     # GUI mode testing
│       └── test-headless.sh  # Headless mode testing
├── src/                   # Source files and customization
│   ├── rootfs/            # Files to be merged into the root filesystem
│   └── patches/           # Kernel/BusyBox patches
└── output/                # Final build outputs
    ├── vmlinuz            # Compiled kernel
    ├── initramfs.gz       # Root filesystem archive
    └── minimal-busybox-linux.iso # Bootable ISO image
```

## Requirements

- **Docker**: For containerized build environment
- **Make**: Build orchestration
- **QEMU** (optional): For local testing
- **2GB+ free disk space**: For build artifacts
- **Internet connection**: For downloading source packages

## Configuration & Customization

### Build Versions
Edit `.env` to change package versions:
```bash
KERNEL_VERSION=6.17     # Linux kernel version
BUSYBOX_VERSION=1.36.1  # BusyBox version
```

Or override for a single build:
```bash
KERNEL_VERSION=6.7.0 BUSYBOX_VERSION=1.35.0 make iso
```

### Kernel Configuration
Edit `config/kernel/minimal.config` to modify kernel features:
- Enable/disable hardware support
- Add filesystem types
- Configure networking protocols
- Security features

### System Behavior
Edit `config/system/init.sh` to customize:
- Boot sequence
- Default services
- Environment setup

## Testing with QEMU

The project includes two QEMU test modes located in `scripts/test-scripts/`:

### GUI Mode (`make test`)
Runs QEMU with a graphical window - best for visual interaction.

**Controls:**
- **Click in window** - Capture keyboard/mouse to VM (required for input!)
- `Ctrl+Alt+G` - Release mouse/keyboard from VM
- `Ctrl+Alt+1` - Switch to VM console
- `Ctrl+Alt+2` - Switch to QEMU monitor
- **Click X on window** - Exit QEMU (easiest method)

**Important**:
- You must click inside the QEMU window to send keyboard input to the VM
- The shell runs on the VGA console (tty1) - you'll see the shell prompt in the graphical window
- Headless mode uses the serial console instead

**Use when:**
- You want to see the graphical boot process
- Testing interactively with mouse/keyboard
- Exploring the system visually

### Headless Mode (`make test-headless`)
Runs QEMU in the terminal with serial console output - best for debugging.

**How to exit:**
- **Recommended**: Type `poweroff` in the VM shell
- **Alternative**: Open another terminal and run `killall qemu-system-x86_64`

**Note**:
- All kernel/system messages appear in terminal
- Ctrl+C and Ctrl+A commands don't work reliably - use `poweroff` instead

**Use when:**
- Debugging boot issues
- Capturing boot logs
- Running in SSH/remote sessions
- CI/CD environments

### Direct Script Usage

You can also run the test scripts directly:
```bash
./scripts/test-scripts/test-local.sh      # GUI mode
./scripts/test-scripts/test-headless.sh   # Headless mode
```

Both scripts check that `output/minimal-busybox-linux.iso` exists before starting.

## Troubleshooting

### Common Issues

**Build fails with permission errors:**
- The build system handles Docker volume permissions automatically
- If issues persist, try `make clean` and rebuild

**Kernel panic on boot:**
- Check that init script is executable
- Verify kernel configuration includes essential features
- Use `make test-headless` for detailed boot logs

**System hangs after "crng init done":**
- This is normal - system is ready for input
- Try pressing Enter or typing commands

**Can't exit QEMU in headless mode:**
- Type `poweroff` in the VM shell - this is the correct way
- Or from another terminal: `killall qemu-system-x86_64`
- Ctrl+C and Ctrl+A don't work due to how serial console is configured

### Debugging

**View detailed build logs:**
```bash
make kernel 2>&1 | tee kernel-build.log
```

**Test with verbose kernel output:**
Edit `scripts/build-scripts/build-iso.sh` and change boot parameters to include `debug loglevel=7`

**Access QEMU monitor:**
In QEMU GUI: Ctrl+Alt+2 (Ctrl+Alt+1 to return to VM)

### Source Caching

The build system implements a caching mechanism for source downloads:
- Cache is stored in the `cache/` directory
- `make clean` preserves the cache for faster rebuilds
- `make clean-all` removes cached downloads to ensure fresh source fetching

## Use Cases

**Perfect for:**
- Embedded systems and IoT devices
- Minimal VM images
- CI/CD build environments
- Testing and development environments
- Security research and testing
- Educational purposes (Linux internals)

## Contributing

This project demonstrates building a minimal Linux distribution from scratch. Key learning areas:
- Linux kernel configuration and compilation
- Root filesystem creation with BusyBox
- Bootloader setup (ISOLINUX)
- Docker-based build systems
- QEMU testing and debugging

## License

See LICENSE file for details.
