#!/bin/bash
# EE pthread-embedded, built with the clang wrapper. Its headers replace newlib's
# pthread headers because libpthread.a is built against them (the types differ).

source "$(dirname "$0")/../lib/common.sh"
source "$(dirname "$0")/../config.sh"

fetch_source "$PTHREAD_EMBEDDED_URL" "$PTHREAD_EMBEDDED_REF" "$1"
cd "$REPO_FOLDER/platform/ps2"

TARGET="mips64r5900el-ps2-elf"
BIN="$PS2DEV/ee/bin"

make clean || true
make -j "$PROC_NR" \
  CC="$BIN/$TARGET-clang" \
  AR="$BIN/$TARGET-ar" \
  CFLAGS="-G0 -Wall -O3 -gdwarf-2 -I. -I../.. -I../helper" \
  all
make install \
  CC="$BIN/$TARGET-clang" \
  AR="$BIN/$TARGET-ar" \
  PS2DEV="$PS2DEV"
