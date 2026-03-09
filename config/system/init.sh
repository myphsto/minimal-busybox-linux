#!/bin/sh

# This init script sets up the basic system environment

export PATH="/bin:/sbin:/usr/bin:/usr/sbin"

# Function to print colored output
print_msg() {
    echo -e "\033[32m[INIT]\033[0m $1"
}

print_msg "Starting minimal Linux system..."

# Mount essential filesystems
print_msg "Mounting essential filesystems..."
/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev

# Create additional device nodes if needed
[ -c /dev/console ] || /bin/mknod /dev/console c 5 1
[ -c /dev/tty ] || /bin/mknod /dev/tty c 5 0
[ -c /dev/null ] || /bin/mknod /dev/null c 1 3
[ -c /dev/zero ] || /bin/mknod /dev/zero c 1 5
[ -c /dev/random ] || /bin/mknod /dev/random c 1 8
[ -c /dev/urandom ] || /bin/mknod /dev/urandom c 1 9

# Create additional directories
mkdir -p /tmp /var/log /var/run /var/lib

# Set up basic environment
export HOME=/root
export TERM=linux

# Display system information
print_msg "System information:"
echo "  Kernel: $(uname -r)"
echo "  Architecture: $(uname -m)"
echo "  Hostname: $(hostname)"
echo "  Memory: $(cat /proc/meminfo | grep MemTotal)"

print_msg "minimal Linux system ready!"
print_msg "Available commands: $(ls /bin | tr '\n' ' ')"

# Start shell on tty1 (VGA console) for GUI/keyboard access
# This allows keyboard input to work in QEMU GUI mode
setsid /bin/sh -c 'exec /bin/sh </dev/tty1 >/dev/tty1 2>&1' &

# Start interactive shell on main console (serial port)
# This is used for headless mode and serial console
# setsid + cttyhack ensures the shell has a controlling terminal for job control
print_msg "Starting shell on console..."
exec setsid cttyhack /bin/sh
