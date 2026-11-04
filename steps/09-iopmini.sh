#!/bin/bash
# libiopmini: the string functions a freestanding IOP module links against.

source "$(dirname "$0")/../lib/common.sh"
source "$(dirname "$0")/../config.sh"

LLVM_BIN="$PS2DEV/llvm/bin" "$(dirname "$0")/../scripts/build-iopmini.sh" "$PS2DEV/iop/mipsel-none-elf"
