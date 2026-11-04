#!/bin/bash
# Emulated-TLS runtime (__emutls_get_address) for EE thread_local.

source "$(dirname "$0")/../lib/common.sh"
source "$(dirname "$0")/../config.sh"

fetch_source "$LLVM_URL" "$LLVM_REF" "$1"

LLVM_SRC="$PWD/$REPO_FOLDER" LLVM_BIN="$PS2DEV/llvm/bin" \
  "$(dirname "$0")/../scripts/build-emutls.sh" "$PS2DEV/ee/mips64r5900el-ps2-elf"
