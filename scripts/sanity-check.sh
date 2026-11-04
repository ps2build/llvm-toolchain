#!/bin/bash
# Compiles small EE (C and C++) and IOP programs with the installed toolchain
# and checks the produced libraries link. Usage: sanity-check.sh <ps2dev-root>
set -e
ROOT="${1:-$PS2DEV}"
EE="$ROOT/ee/bin/mips64r5900el-ps2-elf"
IOP="$ROOT/iop/bin/mipsel-none-elf"
LLD="$ROOT/llvm/bin/ld.lld"
EESYS="$ROOT/ee/mips64r5900el-ps2-elf"
IOPSYS="$ROOT/iop/mipsel-none-elf"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

cat > ee.c <<'SRC'
#include <stdio.h>
#include <pthread.h>
int main(void) { printf("%d\n", (int)sizeof(pthread_t)); return 0; }
SRC
cat > ee.cpp <<'SRC'
#include <atomic>
#include <string>
#include <iostream>
#include <memory>
int main() {
  std::atomic<int> n{1};
  auto p = std::make_shared<std::string>("ps2");
  std::cout << n.load() << *p << std::endl;
  return 0;
}
SRC
cat > iop.c <<'SRC'
int add(int a, int b) { return a + b; }
SRC

"$EE-clang" -O2 -c ee.c -o ee_c.o
"$EE-clang" --driver-mode=g++ -std=c++20 -O2 -fno-exceptions -fno-rtti -c ee.cpp -o ee_cpp.o
"$IOP-clang" -O2 -c iop.c -o iop.o

"$LLD" -r -o ee_c_linked.o ee_c.o -L"$EESYS/lib" --start-group -lc -lm -lpthread -lclang_rt.builtins-mips64el --end-group
"$LLD" -r -o ee_c_nano_linked.o ee_c.o -L"$EESYS/lib" --start-group -lc_nano -lm_nano -lpthread -lclang_rt.builtins-mips64el --end-group
"$LLD" -r -o ee_cpp_nano_linked.o ee_cpp.o -L"$EESYS/lib" --start-group -lc++ -lc++abi -lunwind -latomic -lc_nano -lm_nano -lpthread -lclang_rt.builtins-mips64el --end-group
"$LLD" -r -o ee_cpp_linked.o ee_cpp.o -L"$EESYS/lib" --start-group -lc++ -lc++abi -lunwind -latomic -lc -lm -lpthread -lclang_rt.builtins-mips64el --end-group
"$LLD" -r -o iop_linked.o iop.o -L"$IOPSYS/lib" -lclang_rt.builtins-mipsel -liopmini

"$EE-readelf" -h ee_cpp.o | grep -q "MIPS"

NM="$ROOT/llvm/bin/llvm-nm"
READOBJ="$ROOT/llvm/bin/llvm-readobj"

for lib in "$EESYS/lib/libc.a" "$EESYS/lib/libm.a" "$EESYS/lib/libc++.a" "$EESYS/lib/libc++abi.a" \
  "$EESYS/lib/libpthread.a" "$EESYS/lib/libclang_rt.builtins-mips64el.a" \
  "$IOPSYS/lib/libclang_rt.builtins-mipsel.a" "$IOPSYS/lib/libiopmini.a"; do
  test -f "$lib" || { echo "missing library: $lib" >&2; exit 1; }
done

has_symbol() { "$NM" "$1" 2>/dev/null | grep -qE " [TtWw] $2\$"; }

for sym in memset memcpy memmove memcmp; do
  has_symbol "$IOPSYS/lib/libiopmini.a" "$sym" || { echo "libiopmini.a does not define $sym" >&2; exit 1; }
done
has_symbol "$EESYS/lib/libclang_rt.builtins-mips64el.a" __emutls_get_address || { echo "emulated TLS runtime missing" >&2; exit 1; }
"$NM" -C "$EESYS/lib/libc++.a" 2>/dev/null | grep -q "std::__1::__fs::filesystem" || { echo "libc++ was built without std::filesystem" >&2; exit 1; }

# No f32 operation may call the soft-float helpers: the compiler must use the FPU.
for lib in "$EESYS/lib/libc.a" "$EESYS/lib/libm.a" "$EESYS/lib/libc++.a"; do
  if "$NM" -A "$lib" 2>/dev/null | grep -qE " U __(add|sub|mul|div)sf3"; then
    echo "$lib calls soft-float f32 helpers" >&2
    exit 1
  fi
done

cat > tls.cpp <<'SRC'
thread_local int counter = 3;
int bump() { return ++counter; }
SRC
"$EE-clang" --driver-mode=g++ -std=c++20 -O2 -fno-exceptions -fno-rtti -c tls.cpp -o tls.o
"$LLD" -r -o tls_linked.o tls.o -L"$EESYS/lib" --start-group -lc -lm -lpthread -lclang_rt.builtins-mips64el --end-group
has_symbol tls_linked.o __emutls_get_address || { echo "thread_local did not pull in the emulated TLS runtime" >&2; exit 1; }

cat > fs.cpp <<'SRC'
#include <filesystem>
int main() { return std::filesystem::exists("mass:/x") ? 1 : 0; }
SRC
"$EE-clang" --driver-mode=g++ -std=c++20 -O2 -fno-exceptions -fno-rtti -c fs.cpp -o fs.o

cat > malloc_mix.cpp <<'SRC'
#include <malloc.h>
#include <stdlib.h>
#include <cstdlib>
int main() { void *p = malloc(4); free(p); return 0; }
SRC
"$EE-clang" --driver-mode=g++ -std=c++20 -fsyntax-only malloc_mix.cpp

# IRX1 needs each R_MIPS_HI16 directly followed by its R_MIPS_LO16.
cat > hilo.c <<'SRC'
static volatile struct { int a, b, c, d; } g = {1, 2, 3, 4};
int f(void) { g.a = g.b + 1; g.c = g.d + 1; g.b = g.a + g.c; return g.b; }
SRC
"$IOP-clang" -Os -c hilo.c -o hilo.o
"$READOBJ" --relocations hilo.o | grep -E "R_MIPS_(HI|LO)16" | awk '{print $2}' > hilo.rel
test -s hilo.rel
awk 'NR % 2 == 1 && $1 != "R_MIPS_HI16" { exit 1 } NR % 2 == 0 && $1 != "R_MIPS_LO16" { exit 1 }' hilo.rel \
  || { echo "IOP code has a HI16 without the LO16 right behind it" >&2; exit 1; }
echo "sanity check passed"
