#!/bin/bash
# libc++, libc++abi and libatomic for the EE.

source "$(dirname "$0")/../lib/common.sh"
source "$(dirname "$0")/../config.sh"

fetch_source "$LLVM_URL" "$LLVM_REF" "$1"

LLVM_SRC="$PWD/$REPO_FOLDER" LLVM_BIN="$PS2DEV/llvm/bin" \
  "$(dirname "$0")/../scripts/build-libcxx.sh" "$PWD/build-libcxx" "$PS2DEV/ee/mips64r5900el-ps2-elf"
