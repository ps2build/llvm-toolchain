#!/bin/bash
# EE newlib, built with the clang wrapper, installed into the EE sysroot.

source "$(dirname "$0")/../lib/common.sh"
source "$(dirname "$0")/../config.sh"

fetch_source "$NEWLIB_URL" "$NEWLIB_REF" "$1"
cd "$REPO_FOLDER"

TARGET="mips64r5900el-ps2-elf"
BIN="$PS2DEV/ee/bin"

rm -rf "build-$TARGET"
mkdir "build-$TARGET"
cd "build-$TARGET"

CC_FOR_TARGET="$BIN/$TARGET-clang" \
AR_FOR_TARGET="$BIN/$TARGET-ar" \
RANLIB_FOR_TARGET="$BIN/$TARGET-ranlib" \
NM_FOR_TARGET="$BIN/$TARGET-nm" \
CFLAGS_FOR_TARGET="-O2 -gdwarf-2" \
../configure \
  --prefix="$PS2DEV/ee" \
  --target="$TARGET" \
  --enable-newlib-retargetable-locking \
  --enable-newlib-multithread \
  --enable-newlib-io-c99-formats

make -j "$PROC_NR" all
make -j "$PROC_NR" install
