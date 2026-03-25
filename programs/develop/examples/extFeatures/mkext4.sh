#!/bin/bash
set -e

IMG=ext4.img
SIZE_MB=16

echo "[*] Creating EXT4 image..."

# 1. Create empty file
dd if=/dev/zero of=$IMG bs=1M count=$SIZE_MB status=none

# 2. Format as EXT4
mkfs.ext4 -q -F $IMG

# 3. Set label
e2label $IMG GSoC2026