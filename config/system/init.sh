#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin"

print_msg() {
    echo -e "\033[32m[INIT]\033[0m $1"
}

print_msg "Starting minimal Linux system..."

/bin/mount -t proc proc /proc
/bin/mount -t sysfs sysfs /sys
/bin/mount -t devtmpfs devtmpfs /dev

[ -c /dev/console ] || /bin/mknod /dev/console c 5 1
[ -c /dev/tty ] || /bin/mknod /dev/tty c 5 0
[ -c /dev/null ] || /bin/mknod /dev/null c 1 3
[ -c /dev/zero ] || /bin/mknod /dev/zero c 1 5
[ -c /dev/random ] || /bin/mknod /dev/random c 1 8
[ -c /dev/urandom ] || /bin/mknod /dev/urandom c 1 9

mkdir -p /tmp /var/log /var/run /var/lib

export HOME=/root
export TERM=linux

print_msg "System information:"
echo "  Kernel: $(uname -r)"
echo "  Architecture: $(uname -m)"
echo "  Hostname: $(hostname)"
echo "  Memory: $(cat /proc/meminfo | grep MemTotal)"

print_msg "minimal Linux system ready!"

# Start shell on tty1 (VGA console)
setsid /bin/sh -c 'exec /bin/sh </dev/tty1 >/dev/tty1 2>&1' &

# Start interactive shell on main console (serial port)
print_msg "Starting shell on console..."
exec setsid cttyhack /bin/sh
