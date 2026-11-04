#!/usr/bin/env bash
# Builds compiler-rt's emutls.c (excluded from baremetal builtins) and adds it to the EE
# libclang_rt.builtins archive, so -femulated-tls thread_local works without PT_TLS.
# Usage: LLVM_SRC=dir LLVM_BIN=dir build-emutls.sh <sysroot>
set -euo pipefail

llvm_src="${LLVM_SRC:?LLVM_SRC must point at the LLVM source tree}"
llvm_bin="${LLVM_BIN:?LLVM_BIN must point at the installed LLVM bin directory}"
sysroot="${1:?usage: build-emutls.sh <sysroot>}"

exe=""
if test -f "$llvm_bin/clang.exe"; then exe=".exe"; fi

obj="$(mktemp -d)/emutls.o"
"$llvm_bin/clang$exe" --target=mips64el-unknown-elf -mcpu=r5900 -mabi=n32 -fno-pic -G0 -O2 \
  -D_EE -D__ps2sdk__ -D_GNU_SOURCE -nostdlibinc --sysroot="$sysroot" -isystem "$sysroot/include" \
  -I "$llvm_src/compiler-rt/lib/builtins" -c "$llvm_src/compiler-rt/lib/builtins/emutls.c" -o "$obj"

lib="$sysroot/lib/libclang_rt.builtins-mips64el.a"
"$llvm_bin/llvm-ar$exe" d "$lib" emutls.o 2>/dev/null || true
"$llvm_bin/llvm-ar$exe" qs "$lib" "$obj"
echo "added emutls.o to $lib"
