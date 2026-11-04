#!/bin/bash
# compiler-rt builtins for the EE and IOP, installed into each target's sysroot.

source "$(dirname "$0")/../lib/common.sh"
source "$(dirname "$0")/../config.sh"

fetch_source "$LLVM_URL" "$LLVM_REF" "$1"
SRC="$PWD/$REPO_FOLDER"

build_builtins() {
  local dir="$1" prefix="$2" triple="$3" arch="$4"
  local bin="$PS2DEV/$dir/bin" sysroot="$PS2DEV/$dir/$prefix"
  local build="$PWD/build-compiler-rt-$dir"

  cmake -G Ninja -S "$SRC/compiler-rt" -B "$build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_DISABLE_FIND_PACKAGE_LLVM=ON \
    -DCMAKE_SYSTEM_NAME=Generic \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCMAKE_C_COMPILER="$bin/$prefix-clang" \
    -DCMAKE_CXX_COMPILER="$bin/$prefix-clang" \
    -DCMAKE_ASM_COMPILER="$bin/$prefix-clang" \
    -DCMAKE_C_COMPILER_TARGET="$triple" \
    -DCMAKE_AR="$bin/$prefix-ar" -DCMAKE_RANLIB="$bin/$prefix-ranlib" -DCMAKE_NM="$bin/$prefix-nm" \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF -DCOMPILER_RT_BUILD_XRAY=OFF -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_PROFILE=OFF -DCOMPILER_RT_BUILD_MEMPROF=OFF -DCOMPILER_RT_BUILD_ORC=OFF \
    -DCOMPILER_RT_BUILD_GWP_ASAN=OFF -DCOMPILER_RT_BUILD_CTX_PROFILE=OFF \
    -DCOMPILER_RT_BAREMETAL_BUILD=ON \
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
    -DCOMPILER_RT_OS_DIR=baremetal \
    -DCOMPILER_RT_EXCLUDE_ATOMIC_BUILTIN=ON \
    -DCOMPILER_RT_INCLUDE_TESTS=OFF

  ninja -C "$build" builtins

  mkdir -p "$sysroot/lib"
  cp "$build/lib/baremetal/libclang_rt.builtins-$arch.a" "$sysroot/lib/"
}

build_builtins ee mips64r5900el-ps2-elf mips64el-unknown-elf mips64el
build_builtins iop mipsel-none-elf mipsel-unknown-elf mipsel
