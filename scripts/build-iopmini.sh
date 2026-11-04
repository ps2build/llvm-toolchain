#!/usr/bin/env bash
# Builds libiopmini.a, the memset/memcpy/memmove/memcmp a freestanding IOP module links against.
# Usage: LLVM_BIN=dir build-iopmini.sh <sysroot>
set -euo pipefail

tc="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

llvm_bin="${LLVM_BIN:?LLVM_BIN must point at the installed LLVM bin directory}"
sysroot="${1:?usage: build-iopmini.sh <sysroot>}"

exe=""
if test -f "$llvm_bin/clang.exe"; then exe=".exe"; fi

work="$(mktemp -d)"
"$llvm_bin/clang$exe" --target=mipsel-unknown-elf -mcpu=r3000a -mabi=32 -msoft-float -mno-abicalls -G0 -O2 \
  -ffreestanding -fno-builtin -mllvm -mips-split-hi16 -c "$tc/src/iopmini/iopmini.c" -o "$work/iopmini.o"

mkdir -p "$sysroot/lib"
rm -f "$sysroot/lib/libiopmini.a"
"$llvm_bin/llvm-ar$exe" qs "$sysroot/lib/libiopmini.a" "$work/iopmini.o"
echo "built $sysroot/lib/libiopmini.a"
