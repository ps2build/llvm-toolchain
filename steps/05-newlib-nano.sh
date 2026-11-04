#!/bin/bash
# EE newlib-nano: size-optimized libc, libm and libg installed beside the full
# ones as libc_nano.a, libm_nano.a and libg_nano.a.

source "$(dirname "$0")/../lib/common.sh"
source "$(dirname "$0")/../config.sh"

fetch_source "$NEWLIB_URL" "$NEWLIB_REF" "$1"
cd "$REPO_FOLDER"

TARGET="mips64r5900el-ps2-elf"
BIN="$PS2DEV/ee/bin"
SCRATCH_PREFIX="$PWD/nano-prefix"

rm -rf "$SCRATCH_PREFIX" "build-nano-$TARGET"
mkdir "$SCRATCH_PREFIX" "build-nano-$TARGET"
cd "build-nano-$TARGET"

CC_FOR_TARGET="$BIN/$TARGET-clang" \
AR_FOR_TARGET="$BIN/$TARGET-ar" \
RANLIB_FOR_TARGET="$BIN/$TARGET-ranlib" \
NM_FOR_TARGET="$BIN/$TARGET-nm" \
CFLAGS_FOR_TARGET="-DPREFER_SIZE_OVER_SPEED=1 -Os -gdwarf-2" \
../configure \
  --prefix="$SCRATCH_PREFIX/ee" \
  --target="$TARGET" \
  --disable-newlib-supplied-syscalls \
  --enable-newlib-reent-small \
  --disable-newlib-fvwrite-in-streamio \
  --disable-newlib-fseek-optimization \
  --disable-newlib-wide-orient \
  --enable-newlib-nano-malloc \
  --disable-newlib-unbuf-stream-opt \
  --enable-lite-exit \
  --enable-newlib-global-atexit \
  --enable-newlib-nano-formatted-io \
  --enable-newlib-retargetable-locking \
  --enable-newlib-multithread \
  --disable-nls

make -j "$PROC_NR" all
make -j "$PROC_NR" install

for lib in c g m; do
  mv "$SCRATCH_PREFIX/ee/$TARGET/lib/lib$lib.a" "$PS2DEV/ee/$TARGET/lib/lib${lib}_nano.a"
done
