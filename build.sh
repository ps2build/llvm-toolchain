#!/bin/bash
# Builds the LLVM-based EE/IOP toolchain into $PS2DEV. Run with no arguments
# for a full build, or with step numbers (e.g. `./build.sh 3`) to re-run
# only those steps. Set PS2_CROSS_HOST (e.g. x86_64-w64-mingw32) to build
# the Windows-hosted compiler from Linux.

set -e
TARGET_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$TARGET_DIR"

source "lib/common.sh"
source "config.sh"

: "${PS2DEV:?PS2DEV must point at the install prefix}"

run_build \
  "$LLVM_URL" "$LLVM_REF" \
  "$NEWLIB_URL" "$NEWLIB_REF" \
  "$PTHREAD_EMBEDDED_URL" "$PTHREAD_EMBEDDED_REF" \
  -- "$@"
