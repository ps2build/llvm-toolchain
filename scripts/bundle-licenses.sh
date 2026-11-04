#!/bin/bash
# Copies the license texts of everything the toolchain is built from into <dest>/LICENSES.
# Usage: bundle-licenses.sh <build-root> <dest> [windows]
#   <build-root>  directory holding the llvm, newlib-llvm and pthread-embedded checkouts
#   windows       also bundle the notices for the mingw-w64 runtime linked into the Windows binaries
set -e

ROOT="$1"
DEST="$2/LICENSES"
WINDOWS="$3"
REPO="$(cd "$(dirname "$0")/.." && pwd)"

: "${ROOT:?usage: bundle-licenses.sh <build-root> <dest> [windows]}"
: "${2:?usage: bundle-licenses.sh <build-root> <dest> [windows]}"

copy() {
  test -f "$1" || { echo "missing license file: $1" >&2; exit 1; }
  mkdir -p "$(dirname "$DEST/$2")"
  cp "$1" "$DEST/$2"
}

for p in llvm clang lld compiler-rt libcxx libcxxabi libunwind; do
  if test "$p" = llvm; then
    copy "$ROOT/llvm/llvm/LICENSE.TXT" llvm-project/llvm-LICENSE.TXT
  else
    copy "$ROOT/llvm/$p/LICENSE.TXT" "llvm-project/$p-LICENSE.TXT"
  fi
done

for f in COPYING COPYING.NEWLIB COPYING.LIB COPYING.LIBGLOSS COPYING3 COPYING3.LIB; do
  copy "$ROOT/newlib-llvm/$f" "newlib/$f"
done

for f in "$ROOT"/pthread-embedded/COPYING*; do
  copy "$f" "pthread-embedded/$(basename "$f")"
done

if test -f "$REPO/LICENSE"; then
  cp "$REPO/LICENSE" "$2/LICENSE"
fi

if test "$WINDOWS" = windows; then
  # libstdc++, libgcc, the mingw-w64 CRT and winpthreads are linked statically into the .exe files
  for pkg in g++-mingw-w64-x86-64-posix gcc-mingw-w64-x86-64-posix gcc-mingw-w64-base mingw-w64-x86-64-dev mingw-w64-common; do
    copy "/usr/share/doc/$pkg/copyright" "mingw-w64-runtime/$pkg.copyright"
  done
  for l in GPL-3 LGPL-3; do
    copy "/usr/share/common-licenses/$l" "mingw-w64-runtime/$l"
  done
fi

cat > "$DEST/README.txt" <<'EOF'
This toolchain is built from the following projects. Each license text is in this directory.

llvm-project/   LLVM, clang, lld, compiler-rt, libc++, libc++abi, libunwind
                (Apache License 2.0 with LLVM Exceptions; third-party notices are in llvm-LICENSE.TXT)
newlib/         newlib and libgloss, the C library installed in the target sysroots (many per-file licenses)
pthread-embedded/  pthreads-embedded, installed in the target sysroots (LGPL 2.1 and pthreads-win32 terms)
EOF
if test "$WINDOWS" = windows; then
  cat >> "$DEST/README.txt" <<'EOF'
mingw-w64-runtime/  The Windows executables are statically linked with libstdc++ and libgcc
                (GPL 3 with the GCC Runtime Library Exception), the mingw-w64 C runtime and
                winpthreads. See the package copyright files in this directory.
EOF
fi
