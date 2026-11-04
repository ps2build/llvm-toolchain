#!/bin/bash
# Source repo/ref pins. Point $CONFIG_OVERRIDE at a file re-exporting any of
# these to change them.

LLVM_URL="https://github.com/ps2build/llvm.git"
LLVM_REF="r5900-ee"

NEWLIB_URL="https://github.com/ps2build/newlib-llvm.git"
NEWLIB_REF="ee-v4.6.0-llvm"

PTHREAD_EMBEDDED_URL="https://github.com/ps2build/pthread-embedded.git"
PTHREAD_EMBEDDED_REF="platform_agnostic"

if test -n "$CONFIG_OVERRIDE" && test -f "$CONFIG_OVERRIDE"; then
  source "$CONFIG_OVERRIDE"
fi
