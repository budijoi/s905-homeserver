#!/bin/bash

set -e

clear

VERSION="1.0"

echo "====================================="
echo " Budijoi Home Server Installer"
echo " Version $VERSION"
echo "====================================="
echo

#
# COLOR
#
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

ok() {
    echo -e "${GREEN}[ OK ]${NC} $1"
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    exit 1
}

#
# 1/9 SYSTEM CHECK
#
echo "[1/9] System Check"
echo

#
# ROOT CHECK
#
if [ "$EUID" -ne 0 ]; then
    fail "Run as root"
fi

ok "Root Access"

#
# INTERNET CHECK
#
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    ok "Internet Connection"
else
    fail "No Internet Connection"
fi

#
# ARCH CHECK
#
ARCH=$(uname -m)

case "$ARCH" in
    aarch64)
        ok "Architecture : $ARCH"
        ;;
    *)
        fail "Unsupported Architecture : $ARCH"
        ;;
esac

#
# SYSTEM INFO
#
CPU=$(grep "model name" /proc/cpuinfo | head -1 | cut -d ':' -f2)

[ -z "$CPU" ] && CPU="Amlogic S905X"

RAM=$(free -m | awk '/Mem:/ {print $2}')
HOST=$(hostname)
OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')

echo
echo "Hostname : $HOST"
echo "OS       : $OS"
echo "CPU      : $CPU"
echo "RAM      : ${RAM} MB"
echo

ok "System Information Loaded"

echo
echo "[2/9] Storage Setup"
echo

#
# STORAGE DIR
#
mkdir -p /mnt/storage

mkdir -p /mnt/storage/documents
mkdir -p /mnt/storage/pictures
mkdir -p /mnt/storage/music
mkdir -p /mnt/storage/videos
mkdir -p /mnt/storage/videos/cctv
mkdir -p /mnt/storage/backups
mkdir -p /mnt/storage/downloads
mkdir -p /mnt/storage/web

ok "Storage Directories Created"

#
# FRIENDLY FOLDERS
#
mkdir -p "/mnt/storage/My Documents"
mkdir -p "/mnt/storage/My Pictures"
mkdir -p "/mnt/storage/My Music"
mkdir -p "/mnt/storage/My Videos"

ok "User Folders Created"

#
# STORAGE INFO
#
STORAGE=$(df -h /mnt/storage | awk 'NR==2 {print $2}')
USED=$(df -h /mnt/storage | awk 'NR==2 {print $3}')

echo
echo "Storage Total : $STORAGE"
echo "Storage Used  : $USED"
echo

ok "Storage Ready"

echo
echo "====================================="
echo " Part 1 Complete"
echo "====================================="
echo
echo "Next:"
echo "3/9 ZRAM + Swap"
echo

apt update -qq
apt install -y zram-tools

cat >/etc/default/zramswap <<EOF
ALGO=zstd
PERCENT=50
PRIORITY=100
EOF

systemctl restart zramswap.service

ok "ZRAM Configured"

if [ ! -f /swapfile ]; then

    fallocate -l 1G /swapfile

    chmod 600 /swapfile

    mkswap /swapfile

fi

swapon /swapfile

grep -q "/swapfile" /etc/fstab || \
echo "/swapfile none swap sw 0 0" >> /etc/fstab

ok "Swapfile 1GB Berhasil Dibuat"

echo
echo "Memory Status"
echo "-------------"

free -h

echo
echo
echo "[4/9] S905X Optimization"
echo
cat >/etc/sysctl.d/99-budijoi.conf <<EOF

vm.swappiness=10
vm.vfs_cache_pressure=50

net.core.somaxconn=1024

EOF

sysctl --system >/dev/null 2>&1

ok "Kernel Parameters Applied"

mkdir -p /etc/systemd/journald.conf.d

cat >/etc/systemd/journald.conf.d/budijoi.conf <<EOF
[Journal]
SystemMaxUse=100M
RuntimeMaxUse=50M
EOF

systemctl restart systemd-journald

ok "Journal Limited"

grep -q "/tmp tmpfs" /etc/fstab || \
echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,size=128M 0 0" >> /etc/fstab

ok "Tmpfs Enabled"

if [ -d /sys/devices/system/cpu/cpufreq/policy0 ]; then

    echo ondemand \
    > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor

    ok "CPU Governor Set"
fi

echo
echo "Optimization Summary"
echo "--------------------"

echo "ZRAM      : Enabled"
echo "Swapfile  : 1 GB"
echo "Swappiness: 10"
echo "Cache     : 50"

echo
