#!/bin/bash
# clang, lld and the LLVM binutils replacements, installed to $PS2DEV/llvm.

source "$(dirname "$0")/../lib/common.sh"
source "$(dirname "$0")/../config.sh"

fetch_source "$LLVM_URL" "$LLVM_REF" "$1"
SRC="$PWD/$REPO_FOLDER"

BUILD="$PWD/build-llvm${PS2_CROSS_HOST:+-$PS2_CROSS_HOST}"
mkdir -p "$BUILD"

CROSS_ARGS=()
if test -n "$PS2_CROSS_HOST"; then
  if test "$LLVM_HOST_COMPILER" = clang; then
    # The mingw-w64 GCC package has -win32 and -posix trees and clang picks -win32,
    # which has no std::thread. A sysroot that only links the -posix tree selects it.
    GCC_POSIX="$(ls -d /usr/lib/gcc/$PS2_CROSS_HOST/*-posix | sort -V | tail -1)"
    MINGW_SYSROOT="$PWD/mingw-posix-sysroot"
    rm -rf "$MINGW_SYSROOT"
    mkdir -p "$MINGW_SYSROOT/lib/gcc/$PS2_CROSS_HOST"
    ln -s "$GCC_POSIX" "$MINGW_SYSROOT/lib/gcc/$PS2_CROSS_HOST/$(basename "$GCC_POSIX")"
    ln -s "/usr/$PS2_CROSS_HOST" "$MINGW_SYSROOT/$PS2_CROSS_HOST"
    CROSS_ARGS=(
      -DCMAKE_SYSTEM_NAME=Windows
      -DCMAKE_C_COMPILER=clang
      -DCMAKE_CXX_COMPILER=clang++
      -DCMAKE_C_COMPILER_TARGET="$PS2_CROSS_HOST"
      -DCMAKE_CXX_COMPILER_TARGET="$PS2_CROSS_HOST"
      -DCMAKE_C_FLAGS="--sysroot=$MINGW_SYSROOT -femulated-tls"
      -DCMAKE_CXX_FLAGS="--sysroot=$MINGW_SYSROOT -femulated-tls"
      -DCMAKE_ASM_COMPILER=clang
      -DCMAKE_ASM_COMPILER_TARGET="$PS2_CROSS_HOST"
      -DCMAKE_ASM_FLAGS="--sysroot=$MINGW_SYSROOT"
      -DCMAKE_RC_COMPILER="$PS2_CROSS_HOST-windres"
      -DCMAKE_EXE_LINKER_FLAGS="-static -pthread -fuse-ld=lld"
    )
  else
    CROSS_ARGS=(
      -DCMAKE_SYSTEM_NAME=Windows
      -DCMAKE_C_COMPILER="$PS2_CROSS_HOST-gcc-posix"
      -DCMAKE_CXX_COMPILER="$PS2_CROSS_HOST-g++-posix"
      -DCMAKE_RC_COMPILER="$PS2_CROSS_HOST-windres"
      -DCMAKE_EXE_LINKER_FLAGS="-static"
    )
  fi
  # Reuse the native build's tablegen tools when it ran in this build root.
  if test -x "$PWD/build-llvm/bin/llvm-tblgen" && test -x "$PWD/build-llvm/bin/clang-tblgen"; then
    CROSS_ARGS+=(-DLLVM_NATIVE_TOOL_DIR="$PWD/build-llvm/bin")
  fi
fi

HOST_ARGS=()
if test -z "$PS2_CROSS_HOST" && test "$LLVM_HOST_COMPILER" = clang; then
  HOST_ARGS+=(-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_USE_LINKER=lld)
fi
if test -n "$LLVM_USE_CCACHE"; then
  HOST_ARGS+=(-DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache)
fi

cmake -G Ninja -S "$SRC/llvm" -B "$BUILD" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PS2DEV/llvm" \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD=Mips \
  -DLLVM_ENABLE_ASSERTIONS=OFF \
  -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_ZSTD=OFF -DLLVM_ENABLE_LIBXML2=OFF \
  -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF -DLLVM_INCLUDE_BENCHMARKS=OFF \
  -DLLVM_INCLUDE_DOCS=OFF -DCLANG_INCLUDE_TESTS=OFF -DCLANG_INCLUDE_DOCS=OFF \
  -DCLANG_ENABLE_STATIC_ANALYZER=OFF -DCLANG_ENABLE_ARCMT=OFF \
  -DLLVM_PARALLEL_COMPILE_JOBS="${LLVM_COMPILE_JOBS:-$PROC_NR}" \
  -DLLVM_PARALLEL_LINK_JOBS="${LLVM_LINK_JOBS:-2}" \
  -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
  -DLLVM_DISTRIBUTION_COMPONENTS="clang;clang-resource-headers;lld;llvm-ar;llvm-ranlib;llvm-nm;llvm-objcopy;llvm-strip;llvm-objdump;llvm-readobj;llvm-size" \
  "${CROSS_ARGS[@]}" "${HOST_ARGS[@]}"

ninja -C "$BUILD" install-distribution
