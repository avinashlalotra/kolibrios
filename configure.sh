#!/usr/bin/env bash
set -e

ROOT=$(pwd)

echo "[*] Generating config files"

echo "CONFIG_KPACK_CMD= && kpack --nologo %o" > en_US.config
echo "CONFIG_KERPACK_CMD= && kerpack %o" >> en_US.config
echo "CONFIG_PESTRIP_CMD= && EXENAME=%o fasm $ROOT/data/common/pestrip.asm %o" >> en_US.config
echo "CONFIG_NO_MSVC=full" >> en_US.config
echo "CONFIG_INSERT_REVISION_ID=1" >> en_US.config


echo "[*] Initializing tup"
tup init

# en_US
echo "CONFIG_LANG=en_US" >> en_US.config
echo "CONFIG_BUILD_TYPE=en_US" >> en_US.config
echo "CONFIG_NO_JWASM=full" >> en_US.config
tup variant en_US.config

echo "[*] Tup configuration complete"
