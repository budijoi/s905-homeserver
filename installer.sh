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
