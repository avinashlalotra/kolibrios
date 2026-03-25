#!/usr/bin/env bash
set -e

ROOT=$(pwd)
TOOLCHAIN_DIR=$HOME/koli-toolchain


mkdir -p $TOOLCHAIN_DIR

echo "[*] Building C--"
cd $ROOT/programs/develop/cmm/
make -f Makefile.lin32
chmod +x c--
mv c-- $TOOLCHAIN_DIR/c--
cp $ROOT/programs/cmm/c--/c--.ini $TOOLCHAIN_DIR/c--.ini
make -f Makefile.lin32 clean

echo "[*] Installing TCC"
cp $ROOT/programs/develop/ktcc/trunk/bin/kos32-tcc $TOOLCHAIN_DIR/
chmod +x $TOOLCHAIN_DIR/kos32-tcc

echo "[*] Building objconv"
cd $ROOT/programs/develop/objconv/
g++ -o $TOOLCHAIN_DIR/objconv -O2 *.cpp
chmod +x $TOOLCHAIN_DIR/objconv

echo "[*] Building kerpack + kpack"
export PATH=$TOOLCHAIN_DIR:$PATH
cd $ROOT/programs/other/kpack/kerpack_linux/
make
chmod +x kerpack kpack
mv kerpack $TOOLCHAIN_DIR/
mv kpack $TOOLCHAIN_DIR/

echo "[*] Building clink"
cd $ROOT/programs/develop/clink
gcc main.c -o clink
chmod +x clink
mv clink $TOOLCHAIN_DIR/

echo "export PATH=$PATH:$TOOLCHAIN_DIR" >> $HOME/.bashrc
source $HOME/.bashrc
echo "[*] Toolchain setup complete"


