#!/usr/bin/env bash
# Builds libc++, libc++abi, libunwind and libatomic for the EE and installs them into the sysroot.
# Usage: LLVM_SRC=dir LLVM_BIN=dir [LIBCXX_EXCEPTIONS=OFF] [INSTALL_ROOT=dir] build-libcxx.sh <build-dir> <sysroot>
set -euo pipefail

tc="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

llvm_src="${LLVM_SRC:?LLVM_SRC must point at the LLVM source tree}"
llvm_bin="${LLVM_BIN:?LLVM_BIN must point at the installed LLVM bin directory}"
build="${1:?usage: build-libcxx.sh <build-dir> <sysroot>}"
sysroot="${2:?usage: build-libcxx.sh <build-dir> <sysroot>}"
install_root="${INSTALL_ROOT:-$sysroot}"

exe=""
if test -f "$llvm_bin/clang.exe"; then exe=".exe"; fi

cc="$llvm_bin/clang$exe"
flags="--target=mips64el-unknown-elf -mcpu=r5900 -mabi=n32 -fno-pic -femulated-tls -G0 -D_EE -D__ps2sdk__ -D_GNU_SOURCE -nostdlibinc --sysroot=$sysroot -isystem $sysroot/include"

runtimes="libcxx;libcxxabi"
targets=(cxx cxxabi)
eh_args=(
  -DLIBCXX_ENABLE_EXCEPTIONS=OFF -DLIBCXXABI_ENABLE_EXCEPTIONS=OFF
  -DLIBCXX_ENABLE_RTTI=OFF -DLIBCXXABI_USE_LLVM_UNWINDER=OFF
)
if test "${LIBCXX_EXCEPTIONS:-ON}" = ON; then
  runtimes="libunwind;libcxx;libcxxabi"
  targets=(cxx cxxabi unwind)
  eh_args=(
    -DLIBCXX_ENABLE_EXCEPTIONS=ON -DLIBCXXABI_ENABLE_EXCEPTIONS=ON
    -DLIBCXX_ENABLE_RTTI=ON -DLIBCXXABI_USE_LLVM_UNWINDER=ON
    -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON
    -DLIBUNWIND_IS_BAREMETAL=ON -DLIBUNWIND_ENABLE_SHARED=OFF -DLIBUNWIND_ENABLE_THREADS=OFF
    -DLIBUNWIND_ENABLE_ASSERTIONS=OFF -DLIBUNWIND_ENABLE_PEDANTIC=OFF
    -DLIBUNWIND_INCLUDE_TESTS=OFF
  )
fi

cmake -G Ninja -S "$llvm_src/runtimes" -B "$build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_DISABLE_FIND_PACKAGE_LLVM=ON \
  -DCMAKE_SYSTEM_NAME=Generic \
  -DCMAKE_C_COMPILER="$cc" -DCMAKE_CXX_COMPILER="$cc" \
  -DCMAKE_AR="$llvm_bin/llvm-ar$exe" -DCMAKE_RANLIB="$llvm_bin/llvm-ranlib$exe" \
  -DCMAKE_C_FLAGS="$flags" -DCMAKE_CXX_FLAGS="$flags" -DCMAKE_ASM_FLAGS="$flags" \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DLLVM_ENABLE_RUNTIMES="$runtimes" \
  -DRUNTIMES_USE_LIBC=newlib \
  -DLIBCXX_ENABLE_SHARED=OFF -DLIBCXXABI_ENABLE_SHARED=OFF \
  "${eh_args[@]}" \
  -DLIBCXX_ENABLE_FILESYSTEM=ON -DLIBCXX_HAS_RT_LIB=OFF -DLIBCXX_ENABLE_RANDOM_DEVICE=OFF \
  -DLIBCXX_ENABLE_WIDE_CHARACTERS=OFF -DLIBCXX_ENABLE_TIME_ZONE_DATABASE=OFF \
  -DLIBCXX_ENABLE_LOCALIZATION=ON \
  -DLIBCXX_ENABLE_THREADS=ON -DLIBCXX_HAS_PTHREAD_API=ON \
  -DLIBCXXABI_ENABLE_THREADS=ON -DLIBCXXABI_HAS_PTHREAD_API=ON -DLIBCXXABI_FORCE_THREAD_ATEXIT=ON -DLIBCXXABI_HAS_CXA_THREAD_ATEXIT_IMPL=OFF \
  -DLIBCXX_INCLUDE_TESTS=OFF -DLIBCXX_INCLUDE_BENCHMARKS=OFF -DLIBCXXABI_INCLUDE_TESTS=OFF

ninja -C "$build" "${targets[@]}"

atomic_obj="$build/atomic.o"
"$cc" $flags -O2 -c "$tc/src/atomic/atomic.c" -o "$atomic_obj"
rm -f "$build/lib/libatomic.a"
"$llvm_bin/llvm-ar$exe" rcs "$build/lib/libatomic.a" "$atomic_obj"

mkdir -p "$install_root/lib" "$install_root/include/c++/v1"
cp "$build/lib/libc++.a" "$build/lib/libc++experimental.a" "$build/lib/libc++abi.a" "$build/lib/libatomic.a" "$install_root/lib/"
if test -f "$build/lib/libunwind.a"; then
  cp "$build/lib/libunwind.a" "$install_root/lib/"
  for h in unwind.h libunwind.h __libunwind_config.h unwind_itanium.h unwind_arm_ehabi.h; do
    cp "$llvm_src/libunwind/include/$h" "$install_root/include/"
  done
fi
cp -r "$build/include/c++/v1/." "$install_root/include/c++/v1/"
echo "installed libc++, libc++abi, libatomic into $install_root"
